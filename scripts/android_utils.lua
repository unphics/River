
-- 获取 Android 工具链环境
function get_android_context(target)
    local conf = target:extraconf("rules", "android.native_app")
    local ndk = target:toolchain("ndk")
    local sdk_dir = ndk:config("android_sdk")
    local build_toolver = ndk:config("build_toolver")
    local sdk_tool_path = path.join(sdk_dir, "build-tools", build_toolver)

    return {
        sdk_version = conf.android_sdk_version,
        manifest    = path.absolute(conf.android_manifest),
        res         = conf.android_res and path.absolute(conf.android_res) or nil,
        assets      = conf.android_assets and path.absolute(conf.android_assets) or nil,
        keystore    = { path = path.absolute(conf.keystore), pass = conf.keystore_pass },
        tools = {
            aapt      = path.join(sdk_tool_path, "aapt" .. (os.host() == "windows" and ".exe" or "")),
            d8        = path.join(sdk_tool_path, os.host() == "windows" and "d8.bat" or "d8"),
            zipalign  = path.join(sdk_tool_path, os.host() == "windows" and "zipalign" .. (os.host() == "windows" and ".exe" or "")),
            apksigner = path.join(sdk_tool_path, os.host() == "windows" and "apksigner" .. (os.host() == "windows" and ".bat" or "")),
            android_jar = path.join(sdk_dir, "platforms", "android-" .. conf.android_sdk_version, "android.jar")
        },
        tmp_path = path.join(target:autogendir(), "packing")
    }
end

-- 编译 Java
function build_java_dex(target, ctx)
    import("lib.detect.find_tool")
    local java_srcdir = path.join(os.projectdir(), "java") 
    if not os.isdir(java_srcdir) then return false end

    local javac = find_tool("javac").program
    local classes_dir = path.join(ctx.tmp_path, "classes")
    os.mkdir(classes_dir)

    local java_files = os.files(path.join(java_srcdir, "**.java"))
    os.vrunv(javac, {"-d", classes_dir, "-classpath", ctx.tools.android_jar, table.unpack(java_files)})

    local class_files = os.files(path.join(classes_dir, "**.class"))
    os.vrunv(ctx.tools.d8, {"--output", ctx.tmp_path, table.unpack(class_files)})
    return true
end

-- 组装 APK
function assemble_apk(target, ctx, final_apk, has_dex)
    local tmp = ctx.tmp_path
    local res_apk = "res_only.apk"
    local libname = "libmain.so" 

    local aapt_args = {"package", "-f", "-M", ctx.manifest, "-I", ctx.tools.android_jar, "-F", res_apk}
    if ctx.res then table.insert(aapt_args, "-S"); table.insert(aapt_args, ctx.res) end
    if ctx.assets then table.insert(aapt_args, "-A"); table.insert(aapt_args, ctx.assets) end
    os.vrunv(ctx.tools.aapt, aapt_args, {curdir = tmp})

    local lib_dest = path.join("lib", target:arch(), libname)
    os.cp(target:targetfile(), path.join(tmp, lib_dest))
    os.vrunv(ctx.tools.aapt, {"add", res_apk, lib_dest}, {curdir = tmp})

    if has_dex then
        os.vrunv(ctx.tools.aapt, {"add", res_apk, "classes.dex"}, {curdir = tmp})
    end

    os.vrunv(ctx.tools.zipalign, {"-f", "4", res_apk, "unsigned.apk"}, {curdir = tmp})
    os.vrunv(ctx.tools.apksigner, {"sign", "--ks", ctx.keystore.path, "--ks-pass", "pass:" .. ctx.keystore.pass, "--out", final_apk, "unsigned.apk"}, {curdir = tmp})
end