set_xmakever("3.0.6")

add_rules("mode.debug", "mode.release")

if is_plat("android") then
    set_toolchains("ndk")
end

--[[
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
--]]

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
            package_name = "com.river.app",
            use_glue = false,   -- 禁用 native_app_glue，避免与 sokol 冲突
            native_app_glue = false,
        })
    end
    after_build(function (target)
        import("scripts.android_packer").main(target)
    end)
target_end()