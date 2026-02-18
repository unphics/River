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

-- 步骤 2: 使用 aapt 打包资源并添加 Native 库
function build_apk_structure(ctx, target, has_dex)
    local res_apk = "res_only.apk"
    
    -- 1. 确保基础资源打包
    local aapt_args = {"package", "-f", "-M", ctx.manifest, "-I", ctx.tools.jar, "-F", res_apk}
    if os.isdir(ctx.res) then table.insert(aapt_args, "-S"); table.insert(aapt_args, ctx.res) end
    if os.isdir(ctx.assets) then table.insert(aapt_args, "-A"); table.insert(aapt_args, ctx.assets) end
    os.vrunv(ctx.tools.aapt, aapt_args, {curdir = ctx.tmp})

    -- 2. 处理 .so 库
    local arch = ctx.abi
    local lib_name = "libmain.so"
    local disk_lib_dir = path.join(ctx.tmp, "lib", arch)
    local dst_so = path.join(disk_lib_dir, lib_name)
    local src_so = target:targetfile()

    -- 【优化：健壮性检查】确保源文件已生成
    if not os.isfile(src_so) then
        -- 有时候链接器刚跑完，系统还没刷新，等 200 毫秒
        os.sleep(200)
        if not os.isfile(src_so) then
            raise("Source so file not found: " .. src_so)
        end
    end

    -- 【优化：强制按需创建目录】
    if not os.isdir(disk_lib_dir) then
        os.mkdir(disk_lib_dir)
    end

    -- 执行拷贝
    os.cp(src_so, dst_so)

    -- 再次确认拷贝成功（防止 Windows 抽风）
    if not os.isfile(dst_so) then
        os.sleep(100) -- 再给一点时间
    end

    -- 3. aapt add
    -- 强制使用正斜杠路径，这是 aapt 在 APK 内部的要求
    local aapt_rel_path = "lib/" .. arch .. "/" .. lib_name
    
    -- vrunv 在 Windows 下有时会因为路径问题失败，我们确保在 tmp 目录下运行
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
    -- 定义依赖：只有源码或 Manifest 变了才重跑
    local depfiles = {target:targetfile(), ctx.manifest, ctx.keystore.path}
    table.join2(depfiles, os.files(path.join(ctx.java_src, "**.java")))

    depend.on_changed(function ()
        cinfof("Packaging APK for %s...", ctx.abi)
        
        os.tryrm(ctx.tmp)
        os.mkdir(ctx.tmp)

        local has_dex = build_dex(ctx)
        local res_apk = build_apk_structure(ctx, target, has_dex)
        finalize_apk(ctx, res_apk, final_apk)
        
        cinfof("APK Generated: %s", final_apk)
    end, {dependfile = target:dependfile(final_apk .. ".dep"), files = depfiles})
end