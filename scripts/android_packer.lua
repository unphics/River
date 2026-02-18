-- android_packer.lua

import("core.project.depend")
import("lib.detect.find_tool")

--[[
file dir:
- root
    -android/
        -AndroidManifest.xml
        /com/river/app/MainActivity.java
    -libs
        -sokol/
        -imgui/
    -script/android_packer.lua
    -src/
    -xmake.lua
]]

local function cinfof(fmt, ...)
    cprint("${white}[AndroidPacker][INFO]"..fmt, ...)
end

local function cerrf(fmt, ...)
    cprint("${red}[AndroidPacker][ERROR]"..fmt, ...)
end

local function dev(fmt, ...)
    cprint("${red}[AndroidPacker][DEV]"..fmt, ...)
end

-- 获取并初始化环境配置
function get_context(target)
    local conf = target:extraconf("rules", "android.native_app")

    local ndk = target:toolchain("ndk")
    local sdk_dir = ndk:config("android_sdk")
    local build_toolver = ndk:config("build_toolver")
    local sdk_tool_path = path.join(sdk_dir, "build-tools", build_toolver)
    local is_win = os.host() == "windows"
    local android_dir = path.join(os.projectdir(), "android")
    
    -- 获取架构对应的标准 ABI 名称
    local arch = target:arch()
    local abi = arch
    if arch == "arm64" or arch == "arm64-v8a" then
        abi = "arm64-v8a"
    elseif arch == "armv7" or arch == "armeabi-v7a" then
        abi = "armeabi-v7a"
    end
    
    return {
        sdk_ver  = conf.android_sdk_version,
        abi      = abi,
        tmp      = path.absolute(path.join(target:autogendir(), "packing")),
        manifest = path.absolute(path.join(android_dir, "AndroidManifest.xml")),
        res      = path.absolute(path.join(android_dir, "res")),
        assets   = path.absolute(path.join(os.projectdir(), "assets")),
        java_src = path.absolute(android_dir),
        keystore = { 
            path = path.absolute(path.join(android_dir, "debug.jks")), 
            pass = conf.keystore_pass
        },
        tools = {
            aapt      = path.join(sdk_tool_path, "aapt" .. (is_win and ".exe" or "")),
            d8        = path.join(sdk_tool_path, is_win and "d8.bat" or "d8"),
            zipalign  = path.join(sdk_tool_path, "zipalign" .. (is_win and ".exe" or "")),
            apksigner = path.join(sdk_tool_path, "apksigner" .. (is_win and ".bat" or "")),
            jar       = path.join(sdk_dir, "platforms", "android-" .. conf.android_sdk_version, "android.jar")
        }
    }
end

-- 步骤 1: 编译 Java 源码并生成 classes.dex
function build_dex(ctx)
    local java_files = os.files(path.join(ctx.java_src, "**.java"))
    if #java_files == 0 then
        cerrf("build_dex(): Failed to load any java files!")
        return false
    end

    cinfof("build_dex(): Compiling Java: Found %d files", #java_files)
    local classes_dir = path.join(ctx.tmp, "classes")
    os.mkdir(classes_dir)
    
    local javac = find_tool("javac")
    if not javac then
        raise("javac not found! Please install JDK.") -- raise即为panic
    end

    -- 编译为 .class
    os.vrunv(javac.program, {"-d", classes_dir, "-classpath", ctx.tools.jar, table.unpack(java_files)})
    
    -- 转换为 .dex
    local class_files = os.files(path.join(classes_dir, "**.class"))
    if #class_files > 0 then
        os.vrunv(ctx.tools.d8, {"--output", ctx.tmp, table.unpack(class_files)})
        cinfof("build_dex(): Succeed to build dex.")
        return true
    end
    cerrf("build_dex(): Failed to convert any dex files!")
    return false
end

-- 一个更强力的拷贝函数，带重试机制
local function secure_cp(src, dst)
    if not os.isfile(src) then raise("Source file missing: " .. src) end
    
    -- 确保目标目录存在
    os.mkdir(path.directory(dst))
    
    for i = 1, 5 do -- 最多重试 5 次
        try {
            function() 
                os.cp(src, dst) 
            end
        }
        if os.isfile(dst) then return true end
        os.sleep(200)
    end
    raise("Critical failure: Could not copy file to " .. dst)
end

-- 步骤 2: 使用 aapt 打包资源并添加 Native 库
function build_apk_structure(ctx, target, has_dex)
    local res_apk = "res_only.apk"
    
    -- 1. 基础打包（必须正确包含 -S 和 -A 参数）
    local aapt_args = {"package", "-f", "-M", ctx.manifest, "-I", ctx.tools.jar, "-F", res_apk}
    
    -- 重新加上资源路径检查逻辑
    if os.isdir(ctx.res) then 
        table.insert(aapt_args, "-S")
        table.insert(aapt_args, ctx.res) 
        -- cinfof("Adding resources from: %s", ctx.res) -- 调试用
    end
    
    if os.isdir(ctx.assets) then 
        table.insert(aapt_args, "-A")
        table.insert(aapt_args, ctx.assets) 
        -- cinfof("Adding assets from: %s", ctx.assets) -- 调试用
    end

    -- 执行打包
    os.vrunv(ctx.tools.aapt, aapt_args, {curdir = ctx.tmp})

    -- 2. 拷贝 so (保持刚才那个 secure_cp 逻辑)
    local arch = ctx.abi
    local lib_name = "libmain.so"
    local abs_lib_dir = path.join(ctx.tmp, "lib", arch)
    local abs_lib_path = path.join(abs_lib_dir, lib_name)

    os.mkdir(abs_lib_dir)
    secure_cp(target:targetfile(), abs_lib_path)

    -- 3. aapt add so
    local aapt_rel_path = "lib/" .. arch .. "/" .. lib_name
    os.vrunv(ctx.tools.aapt, {"add", res_apk, aapt_rel_path}, {curdir = ctx.tmp})

    -- 4. 放入 dex
    if has_dex then
        os.vrunv(ctx.tools.aapt, {"add", res_apk, "classes.dex"}, {curdir = ctx.tmp})
    end
    
    return res_apk
end

-- 步骤 3: 对齐并签名
function finalize_apk(ctx, res_apk, final_apk_path)
    local unsigned_apk = "unsigned.apk"
    
    -- 对齐
    os.vrunv(ctx.tools.zipalign, {"-f", "4", res_apk, unsigned_apk}, {curdir = ctx.tmp})
    
    -- 签名
    os.vrunv(ctx.tools.apksigner, {
        "sign", 
        "--ks", ctx.keystore.path, 
        "--ks-pass", "pass:" .. ctx.keystore.pass, 
        "--out", final_apk_path, 
        unsigned_apk
    }, {curdir = ctx.tmp})
end

-- 主入口函数
function main(target)
    local ctx = get_context(target)
    local final_apk = path.absolute(path.join(target:targetdir(), target:basename()..".apk"))
    local depfiles = {target:targetfile(), ctx.manifest, ctx.keystore.path}
    table.join2(depfiles, os.files(path.join(ctx.java_src, "**.java")))

    depend.on_changed(function ()
        cinfof("Packaging APK for %s...", ctx.abi)
        
        -- 修复：不要直接整个删掉 ctx.tmp，这在 Windows 上很不稳
        -- 换成只清理里面的文件，或者确保根目录一直存在
        if not os.isdir(ctx.tmp) then
            os.mkdir(ctx.tmp)
        end

        local has_dex = build_dex(ctx)
        local res_apk = build_apk_structure(ctx, target, has_dex)
        finalize_apk(ctx, res_apk, final_apk)
        
        cinfof("APK Generated: %s", final_apk)
    end, {dependfile = target:dependfile(final_apk .. ".dep"), files = depfiles})
end