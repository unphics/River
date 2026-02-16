-- Android SDK/NDK 自动下载安装并配置到 xmake 全局配置
-- 使用方法: xmake lua setup_android_env.lua
-- 匹配项目配置：NDK API 21 (r21e), Android SDK 35

import("core.base.option")
import("net.http")
import("utils.archive")
import("core.project.config")

-- NDK r21e 下载链接（匹配 sdkver = "21"）
local ndk_urls = {
    windows = "https://dl.google.com/android/repository/android-ndk-r21e-windows-x86_64.zip",
    linux = "https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip",
    macosx = "https://dl.google.com/android/repository/android-ndk-r21e-darwin-x86_64.zip"
}

-- SDK Command-line Tools 下载链接
local sdk_urls = {
    windows = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip",
    linux = "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip",
    macosx = "https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
}

-- 检查Java环境
function check_java()
    cprint("${bright cyan}========================================")
    cprint("  检查 Java 环境")
    cprint("${bright cyan}========================================${clear}")
    
    local java_home = os.getenv("JAVA_HOME")
    if java_home then
        cprint("${dim}检测到 JAVA_HOME: %s", java_home)
    end
    
    local java_version_output = try { function() 
        local _, result = os.iorun("java -version")
        return result
    end}
    
    if java_version_output then
        cprint("${green}✓ Java 环境已安装")
        -- 从输出中提取版本信息
        local version_lines = java_version_output:split("\n")
        for _, line in ipairs(version_lines) do
            if line:find("version") then
                cprint("  版本信息: %s", line:trim())
                break
            end
        end
        return true
    else
        cprint("${yellow}⚠ 未检测到 Java 环境")
        return false
    end
end

-- 使用系统包管理工具安装Java
function install_java_with_package_manager(os_name)
    cprint("${bright cyan}========================================")
    cprint("  使用包管理工具安装 Java")
    cprint("${bright cyan}========================================${clear}")
    
    if os_name == "windows" then
        cprint("正在尝试使用 winget 安装 Azul Zulu 25 JDK...")
        local ok, _, _, errors = os.run("winget install -e --id Azul.Zulu.25.JDK")
        if ok then
            cprint("${green}✓ Windows 上 Java 安装命令已执行")
            cprint("${yellow}请重新打开命令行窗口或重启系统以使环境变量生效")
            return true
        else
            cprint("${red}✗ winget 安装 Java 失败: %s", errors or "")
            return false
        end
    elseif os_name == "linux" then
        -- 检查是否有apt命令
        if os.isexec("apt") then
            cprint("正在尝试使用 apt 安装 OpenJDK 17...")
            local ok, _, _, errors = os.run("sudo apt update && sudo apt install -y openjdk-17-jdk")
            if ok then
                cprint("${green}✓ Linux 上 Java 安装命令已执行")
                cprint("${yellow}请运行以下命令设置环境变量:")
                cprint("  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64")
                cprint("  export PATH=$JAVA_HOME/bin:$PATH")
                return true
            else
                cprint("${red}✗ apt 安装 Java 失败: %s", errors or "")
                return false
            end
        else
            cprint("${red}✗ 系统中未找到 apt 包管理工具")
            return false
        end
    else
        cprint("${red}✗ 当前操作系统暂不支持自动安装 Java")
        return false
    end
end

-- 下载并安装 NDK r21e
function install_ndk(os_name, install_base_dir)
    local ndk_version = "r21e"
    
    cprint("${bright cyan}========================================")
    cprint("  安装 Android NDK ${green}%s", ndk_version)
    cprint("${bright cyan}========================================${clear}")
    
    local download_url = ndk_urls[os_name]
    if not download_url then
        raise("当前操作系统 %s 不支持", os_name)
    end
    
    local ndk_dir = path.join(install_base_dir, "ndk", "android-ndk-" .. ndk_version)
    
    -- 检查是否已安装
    if os.isdir(ndk_dir) then
        cprint("${yellow}⚠ NDK %s 已安装，跳过下载", ndk_version)
        return ndk_dir
    end
    
    os.mkdir(path.join(install_base_dir, "ndk"))
    
    local filename = path.filename(download_url)
    local download_path = path.join(install_base_dir, "ndk", filename)
    
    cprint("${dim}下载地址: %s", download_url)
    cprint("正在下载...")
    
    http.download(download_url, download_path, {
        progress = true
    })
    
    cprint("${green}下载完成，正在解压...")
    archive.extract(download_path, path.join(install_base_dir, "ndk"))
    os.rm(download_path)
    
    cprint("${bright green}✓ NDK %s 安装成功!", ndk_version)
    return ndk_dir
end

-- 下载并安装 SDK
function install_sdk(os_name, install_base_dir)
    cprint("")
    cprint("${bright cyan}========================================")
    cprint("  安装 Android SDK Command-line Tools")
    cprint("${bright cyan}========================================${clear}")
    
    local download_url = sdk_urls[os_name]
    if not download_url then
        raise("当前操作系统 %s 不支持", os_name)
    end
    
    local sdk_dir = path.join(install_base_dir, "sdk")
    local cmdline_tools_dir = path.join(sdk_dir, "cmdline-tools", "latest")
    
    -- 检查是否已安装
    if os.isdir(cmdline_tools_dir) then
        cprint("${yellow}⚠ Android SDK 已安装，跳过下载")
        return sdk_dir
    end
    
    os.mkdir(sdk_dir)
    
    local filename = path.filename(download_url)
    local download_path = path.join(sdk_dir, filename)
    
    cprint("${dim}下载地址: %s", download_url)
    cprint("正在下载...")
    
    http.download(download_url, download_path, {
        progress = true
    })
    
    cprint("${green}下载完成，正在解压...")
    
    local temp_dir = path.join(sdk_dir, "temp")
    archive.extract(download_path, temp_dir)
    
    local extracted_dir = path.join(temp_dir, "cmdline-tools")
    os.mkdir(path.join(sdk_dir, "cmdline-tools"))
    os.mv(extracted_dir, cmdline_tools_dir)
    os.rmdir(temp_dir)
    os.rm(download_path)
    
    cprint("${bright green}✓ Android SDK 安装成功!")
    return sdk_dir
end

-- 安装必要的 SDK 组件
function install_sdk_components(sdk_path, os_name)
    cprint("")
    cprint("${bright cyan}========================================")
    cprint("  安装必要的 SDK 组件")
    cprint("${bright cyan}========================================${clear}")
    
    local sdkmanager
    if os_name == "windows" then
        sdkmanager = path.join(sdk_path, "cmdline-tools", "latest", "bin", "sdkmanager.bat")
    else
        sdkmanager = path.join(sdk_path, "cmdline-tools", "latest", "bin", "sdkmanager")
        -- 添加执行权限
        os.run("chmod +x %s", sdkmanager)
    end
    
    -- 检查sdkmanager是否存在
    if not os.isexec(sdkmanager) then
        cprint("${red}✗ 错误: 未能找到 sdkmanager 工具")
        return false
    end
    
    -- 设置接受许可协议的环境变量
    os.setenv("ANDROID_SDK_ROOT", sdk_path)
    
    cprint("正在安装 platforms;android-35...")
    local ok, _, _, errors = os.runv(sdkmanager, {"--verbose", "platforms;android-35"}, {envs = {ANDROID_SDK_ROOT = sdk_path, JAVA_OPTS = "-XX:+IgnoreUnrecognizedVMOptions --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.util.concurrent=ALL-UNNAMED --add-opens java.base/java.text=ALL-UNNAMED --add-opens java.desktop/java.awt.font=ALL-UNNAMED"}})
    if not ok then
        cprint("${yellow}⚠ 安装 platforms;android-35 失败: %s", errors or "")
    else
        cprint("${green}✓ platforms;android-35 安装成功")
    end
    
    cprint("正在安装 build-tools;35.0.0...")
    ok, _, _, errors = os.runv(sdkmanager, {"--verbose", "build-tools;35.0.0"}, {envs = {ANDROID_SDK_ROOT = sdk_path, JAVA_OPTS = "-XX:+IgnoreUnrecognizedVMOptions --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.util.concurrent=ALL-UNNAMED --add-opens java.base/java.text=ALL-UNNAMED --add-opens java.desktop/java.awt.font=ALL-UNNAMED"}})
    if not ok then
        cprint("${yellow}⚠ 安装 build-tools;35.0.0 失败: %s", errors or "")
    else
        cprint("${green}✓ build-tools;35.0.0 安装成功")
    end
    
    cprint("正在安装 platform-tools...")
    ok, _, _, errors = os.runv(sdkmanager, {"--verbose", "platform-tools"}, {envs = {ANDROID_SDK_ROOT = sdk_path, JAVA_OPTS = "-XX:+IgnoreUnrecognizedVMOptions --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.util.concurrent=ALL-UNNAMED --add-opens java.base/java.text=ALL-UNNAMED --add-opens java.desktop/java.awt.font=ALL-UNNAMED"}})
    if not ok then
        cprint("${yellow}⚠ 安装 platform-tools 失败: %s", errors or "")
    else
        cprint("${green}✓ platform-tools 安装成功")
    end
    
    return true
end

-- 设置 xmake 全局配置
function set_global_config(ndk_path, sdk_path)
    cprint("")
    cprint("${bright cyan}========================================")
    cprint("  设置 xmake 全局配置")
    cprint("${bright cyan}========================================${clear}")
    
    -- 使用 xmake g 命令设置全局配置
    local ok, err = os.run("xmake g --ndk=%s", ndk_path)
    if not ok then
        cprint("${yellow}⚠ 设置 NDK 全局配置失败: %s", err or "")
    end
    
    ok, err = os.run("xmake g --android_sdk=%s", sdk_path)
    if not ok then
        cprint("${yellow}⚠ 设置 SDK 全局配置失败: %s", err or "")
    end
    
    cprint("${bright green}✓ 全局配置已保存!")
    cprint("")
    cprint("${bright}NDK 路径: ${cyan}%s", ndk_path)
    cprint("${bright}SDK 路径: ${cyan}%s", sdk_path)
end

-- 显示后续步骤提示
function show_next_steps(sdk_path, os_name)
    cprint("")
    cprint("${bright green}========================================")
    cprint("  🎉 安装完成！")
    cprint("${bright green}========================================${clear}")
    cprint("")
    cprint("${bright yellow}📝 后续步骤：${clear}")
    cprint("")
    
    -- 1. 配置项目
    cprint("${bright}1. 配置项目（xmake 会自动使用全局配置）：${clear}")
    cprint("   ${cyan}xmake f -p android -a arm64-v8a${clear}")
    cprint("")
    
    -- 2. 构建项目
    cprint("${bright}2. 构建项目：${clear}")
    cprint("   ${cyan}xmake build${clear}")
    cprint("")
    
    -- 3. 生成 APK
    cprint("${bright}3. 生成 APK：${clear}")
    cprint("   ${cyan}xmake install${clear}")
    cprint("")
    
    -- 4. 运行
    cprint("${bright}4. 安装并运行 APK（需要连接设备或启动模拟器）：${clear}")
    cprint("   ${cyan}xmake run${clear}")
    cprint("")
    
    cprint("${bright green}========================================${clear}")
    cprint("")
    cprint("${dim}提示：全局配置已保存，以后新建项目也会自动使用这些路径。")
    cprint("${dim}如需查看全局配置：${cyan}xmake g --ndk${clear} 或 ${cyan}xmake g --android_sdk${clear}")
    cprint("")
end

-- 主函数
function main()
    cprint("")
    cprint("${bright magenta}╔════════════════════════════════════════╗")
    cprint("║  Android 开发环境自动配置工具         ║")
    cprint("║  Powered by xmake                      ║")
    cprint("╚════════════════════════════════════════╝${clear}")
    cprint("")
    
    -- 解析命令行参数
    local install_base_dir = option.get("install-dir") or path.join(os.projectdir(), ".xmake", "android")
    
    -- 检测操作系统
    local os_name = os.host()
    cprint("${dim}操作系统: %s", os_name)
    cprint("${dim}NDK 版本: r21e (API 21)")
    cprint("${dim}SDK 版本: 35")
    cprint("${dim}安装目录: %s${clear}", install_base_dir)
    cprint("")
    
    -- 检查Java环境
    if not check_java() then
        cprint("${yellow}正在尝试使用系统包管理工具安装 Java...")
        if not install_java_with_package_manager(os_name) then
            cprint("${red}✗ 使用包管理工具安装 Java 失败，请手动安装后再运行此脚本")
            cprint("Windows: 访问 https://www.azul.com/downloads/?package=jdk 或使用 winget install -e --id Azul.Zulu.25.JDK")
            cprint("Linux: 使用命令 sudo apt install openjdk-17-jdk")
            cprint("macOS: 使用命令 brew install openjdk@17")
            return
        else
            cprint("${yellow}请在重新打开命令行窗口或重启系统后再运行此脚本")
            return
        end
    end
    
    -- 安装 NDK
    local ndk_path = install_ndk(os_name, install_base_dir)
    
    -- 安装 SDK
    local sdk_path = install_sdk(os_name, install_base_dir)
    
    -- 安装必要的 SDK 组件
    if not install_sdk_components(sdk_path, os_name) then
        cprint("${red}✗ 错误: 安装 SDK 组件失败")
        return
    end
    
    -- 设置全局配置
    set_global_config(ndk_path, sdk_path)
    
    -- 显示后续步骤
    show_next_steps(sdk_path, os_name)
end

-- 运行主函数
main()