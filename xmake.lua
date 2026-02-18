set_xmakever("3.0.6")
add_rules("mode.debug", "mode.release")
if is_plat("android") then
    set_toolchains("ndk")
end
rule("sokol_shaders")
    set_extensions(".glsl")
    before_buildcmd_file(function(target, batchcmds, shaderfile)
        import("lib.detect.find_tool")
        local headerdir = path.join(target:autogendir(), "shaders")
        local name = path.basename(shaderfile)
        local ext = path.extension(shaderfile)
		local headerfile = path.join(headerdir, string.format("%s%s.h", name, ext))
        target:add('includedirs', target:autogendir())
        batchcmds:mkdir(headerdir)
		batchcmds:show_progress("${color.build.object}generating headers for %s", shaderfile)
		batchcmds:vrunv("sokol-shdc", {"--input", shaderfile, "--output", headerfile, "--slang", "glsl330:hlsl5:metal_macos"})
		batchcmds:add_depfiles(shaderfile)
		batchcmds:set_depmtime(os.mtime(headerfile))
		batchcmds:set_depcache(target:dependfile(headerfile))
    end)
rule_end()

target("River")
	-- add_rules("sokol_shaders")
    set_kind("binary")
    set_languages("c++17")

    add_includedirs("libs/sokol")
    add_includedirs("libs/sokol/util")
    add_includedirs("libs/imgui")
    
    add_files("src/*.cpp")
    -- add_files("src/*.cc")
    add_files("libs/imgui/*.cpp")
	-- add_files("src/shaders/*.glsl")
    add_packages("opengl")
    
    if is_plat("android") then
        set_basename("main")
        set_kind("shared")
        add_syslinks("android", "log", "GLESv2", "EGL")
        -- add_syslinks("vulkan")
        add_rules("android.native_app", {
            android_sdk_version = "35",
            android_manifest = "android/AndroidManifest.xml",
            android_res = "android/res",
            android_assets = "assets",
            keystore = "android/debug.jks",
            keystore_pass = "123456",
            package_name = "com.river",
            use_glue = false,   -- 禁用 native_app_glue，避免与 sokol 冲突
            native_app_glue = false,
        })
    end
    after_build(function (target)
        import("core.project.depend")
        import("utils.progress")
        import("lib.detect.find_tool")

        -- 1. 获取上下文 (保持之前的逻辑)
        local function get_ctx(target)
            local conf = target:extraconf("rules", "android.native_app")
            local ndk = target:toolchain("ndk")
            local sdk_dir = ndk:config("android_sdk")
            local build_toolver = ndk:config("build_toolver")
            local sdk_tool_path = path.join(sdk_dir, "build-tools", build_toolver)
            local is_win = os.host() == "windows"
            local android_dir = path.join(os.projectdir(), "android")
            
            return {
                sdk_version = conf.android_sdk_version,
                manifest    = path.join(android_dir, "AndroidManifest.xml"),
                res         = path.join(android_dir, "res"),
                assets      = path.join(os.projectdir(), "assets"),
                keystore    = { 
                    path = path.join(android_dir, "debug.jks"), 
                    pass = conf.keystore_pass 
                },
                java_src    = path.join(android_dir, "java"),
                tools = {
                    aapt      = path.join(sdk_tool_path, "aapt" .. (is_win and ".exe" or "")),
                    d8        = path.join(sdk_tool_path, is_win and "d8.bat" or "d8"),
                    zipalign  = path.join(sdk_tool_path, is_win and "zipalign" .. (is_win and ".exe" or "")),
                    apksigner = path.join(sdk_tool_path, is_win and "apksigner" .. (is_win and ".bat" or "")),
                    jar       = path.join(sdk_dir, "platforms", "android-" .. conf.android_sdk_version, "android.jar")
                },
                tmp = path.join(target:autogendir(), "packing")
            }
        end

        local ctx = get_ctx(target)
        
        -- 【核心修正 1】：确保最终 APK 路径是绝对路径
        local final_apk = path.absolute(path.join(target:targetdir(), target:basename() .. ".apk"))
        
        local depfiles = {target:targetfile(), ctx.manifest, ctx.keystore.path}
        if os.isdir(ctx.java_src) then table.join2(depfiles, os.files(path.join(ctx.java_src, "**.java"))) end

        depend.on_changed(function ()
            cprint("${color.build.target}Packaging APK: %s", final_apk)
            
            -- 【核心修正 2】：确保输出目录存在
            os.mkdir(path.directory(final_apk))
            
            os.tryrm(ctx.tmp)
            os.mkdir(path.join(ctx.tmp, "lib", target:arch()))
            
            -- A. Java 编译
            local has_dex = false
            if os.isdir(ctx.java_src) then
                local classes_dir = path.join(ctx.tmp, "classes")
                os.mkdir(classes_dir)
                local javac = find_tool("javac")
                local java_files = os.files(path.join(ctx.java_src, "**.java"))
                if #java_files > 0 then
                    os.vrunv(javac.program, {"-d", classes_dir, "-classpath", ctx.tools.jar, table.unpack(java_files)})
                    local class_files = os.files(path.join(classes_dir, "**.class"))
                    if #class_files > 0 then
                        os.vrunv(ctx.tools.d8, {"--output", ctx.tmp, table.unpack(class_files)})
                        has_dex = true
                    end
                end
            end

            -- B. aapt 打包
            local res_apk = "res_only.apk"
            local aapt_args = {"package", "-f", "-M", ctx.manifest, "-I", ctx.tools.jar, "-F", res_apk}
            if os.isdir(ctx.res) then table.insert(aapt_args, "-S"); table.insert(aapt_args, ctx.res) end
            if os.isdir(ctx.assets) then table.insert(aapt_args, "-A"); table.insert(aapt_args, ctx.assets) end
            os.vrunv(ctx.tools.aapt, aapt_args, {curdir = ctx.tmp})

            -- C. 塞入库和 Dex
            -- 注意：target:targetfile() 也最好用绝对路径
            local lib_dest = path.join("lib", target:arch(), "libmain.so")
            os.cp(path.absolute(target:targetfile()), path.join(ctx.tmp, lib_dest))
            os.vrunv(ctx.tools.aapt, {"add", res_apk, lib_dest}, {curdir = ctx.tmp})
            if has_dex then
                os.vrunv(ctx.tools.aapt, {"add", res_apk, "classes.dex"}, {curdir = ctx.tmp})
            end

            -- D. 对齐
            os.vrunv(ctx.tools.zipalign, {"-f", "4", res_apk, "unsigned.apk"}, {curdir = ctx.tmp})
            
            -- E. 签名 (这里的 final_apk 现在是绝对路径了)
            os.vrunv(ctx.tools.apksigner, {"sign", "--ks", ctx.keystore.path, "--ks-pass", "pass:" .. ctx.keystore.pass, "--out", final_apk, "unsigned.apk"}, {curdir = ctx.tmp})
            
            os.touch(final_apk)
            cprint("${color.success}Done! APK generated at: %s", final_apk)
        end, {dependfile = target:dependfile(final_apk .. ".custom"), files = depfiles})
    end)
target_end()