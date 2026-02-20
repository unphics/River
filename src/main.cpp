
#include "Log/Log.hh"
#include "sokol_impl.hh"
#include "keyboard.hh"
// #include "inputchar.hh"
#include "FileSystem.hh"
#include "imgui.h"
#include "sokol_imgui.h"
#include <android/native_activity.h>
#include <string>

static JavaVM* g_vm = nullptr;
static jobject g_activity = nullptr;
static std::string InternalStoragePath;

void SetupImGuiIniPath() {
    // 构建一个明确的、可写的路径：内部存储目录 + 文件名
    fs::path writablePath = fs::path(InternalStoragePath) / "imgui.ini";
    ImGuiIO& io = ImGui::GetIO();
    // 将默认的 "imgui.ini" 改为这个完整路径
    io.IniFilename = strdup(writablePath.string().c_str()); 
    
    // 检查该路径是否可写（可选，用于调试）
    std::error_code ec;
    if (!fs::exists(writablePath.parent_path())) {
        fs::create_directories(writablePath.parent_path(), ec);
    }
    // 可以尝试创建或打开一个测试文件来验证权限
    FILE* testFile = fopen(writablePath.string().c_str(), "a");
    if (testFile) {
        fclose(testFile);
        infof("Ini path is writable: %s", writablePath.string().c_str());
    } else {
        errorf("Ini path is NOT writable: %s", writablePath.string().c_str());
    }
    ImGui::LoadIniSettingsFromDisk(io.IniFilename);
}

static void init(void) {
    // 先初始化渲染器
    sg_desc gfx_desc = {};
    gfx_desc.environment = sglue_environment();
    gfx_desc.logger.func = slog_func;
    sg_setup(gfx_desc);

    // 初始化sokol-imgui
    simgui_desc_t imgui_desc = {};
    imgui_desc.logger.func = slog_func;
    simgui_setup(&imgui_desc);
    ImGui::SetCurrentContext(ImGui::GetCurrentContext());
    SetupImGuiIniPath();
    ImGuiIO io = ImGui::GetIO();
    infof("IniFilename = %s", io.IniFilename ? io.IniFilename : "null")
    
    ImGui::GetIO().FontGlobalScale = 2.5f;
    ImGui::GetIO().ConfigFlags |= ImGuiConfigFlags_DockingEnable;
    unsigned char* pixels;
    int width, height;
    ImGui::GetIO().Fonts->GetTexDataAsRGBA32(&pixels, &width, &height);

    infof("River", "ImGui Setup Done!")
}

static void frame(void) {
    if (!sg_isvalid()) {
        errorf("!sg_isvalid()!")
        return;
    }
    // 调试打印：检查当前上下文
    if (ImGui::GetCurrentContext() == nullptr) {
        errorf("CRITICAL: ImGui Context is NULL!")
        return;
    }

    // 2. 检查字体库是否准备好
    ImGuiIO& io = ImGui::GetIO();
    if (!io.Fonts->IsBuilt()) {
        __android_log_print(ANDROID_LOG_ERROR, "River", "ERROR: ImGui Fonts not built!");
        // 如果没 build，simgui 会尝试在 new_frame 里处理，但这里可能已经晚了
        // return;
    }

    // 开始imgui新的一帧
    simgui_new_frame({sapp_width(), sapp_height(), sapp_frame_duration()});
    ImGui::DockSpaceOverViewport(0, nullptr, ImGuiConfigFlags_DockingEnable);
    // 编写UI界面逻辑
    ImGui::SetNextWindowPos(ImVec2(50, 50), ImGuiCond_FirstUseEver);
    /*
    ImGui::Begin("River Debug Tools");
    ImGui::Text("Hello, Android");
    if (ImGui::Button("TapMe")) {
        // 处理点击
        // ANativeActivity_showSoftInput((ANativeActivity*)sapp_android_get_native_activity(), ANATIVEACTIVITY_SHOW_SOFT_INPUT_FORCED);
        show_android_keyboard(g_activity, g_vm, true);
    }
    static char buf[128] = ""; // 必须是静态的或者在类成员里，保证生命周期
    if (ImGui::InputText("InputText", buf, IM_ARRAYSIZE(buf))) {
        show_android_keyboard(g_activity, g_vm, true);
    }
    if (ImGui::GetIO().WantTextInput) {
        show_android_keyboard(g_activity, g_vm, true);
    }
    ImGui::End();
    */

    ImGui::Begin("River Top Line");
    ImGui::End();
    
    ImGui::Begin("River Content");

    static char content[1024] = "qqqqqqqqqqqq\nwwwwwwwwwwww    \nrrrr";
    ImGui::InputTextMultiline("content", content, sizeof(content), ImVec2(500, 500), ImGuiInputTextFlags_AllowTabInput);
    if (ImGui::IsItemActivated()) {
        show_android_keyboard(g_activity, g_vm, true);
    }
    ImGui::End();
    
    ImGui::Begin("River Bottom Line");

    // if (ImGui::Button("Btn1")) {}
    // ImGui::SameLine();
    // ImGui::Button("Btn2");
    // ImGui::SameLine();
    // ImGui::Button("Btn3");
    // ImGui::SameLine();
    // ImGui::Button("Btn4");

    if (ImGui::BeginTable("button table", 4, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_Borders)) {
        float avail_width = ImGui::GetContentRegionAvail().x;
        float col_width = avail_width / 4.0f;
        for (int i = 0; i < 4; i++) {
            ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, col_width);
        }
        ImGui::TableNextRow();
        for (int i = 0; i < 4; i++) {
            ImGui::TableSetColumnIndex(i);
            std::string btnLabel = "Btn" + std::to_string(i+1);
            if (ImGui::Button(btnLabel.c_str(), ImVec2(-FLT_MIN, 0.0f))) {
                // 按钮点击处理
            }
        }
        ImGui::EndTable();
    }
    
    ImGui::End();

    // 渲染
    sg_pass pass = {};
    pass.action.colors[0].load_action = SG_LOADACTION_CLEAR;
    pass.action.colors[0].clear_value = {0.1f, 0.1f, 0.1f, 1.0f};
    pass.swapchain = sglue_swapchain();

    sg_begin_pass(&pass);
    simgui_render(); // 在Pass结束前渲染Imgui;
    sg_end_pass();
    sg_commit();
}

// Sokol 入口
sapp_desc sokol_main(int argc, char* argv[]) {
    sapp_desc desc = {};
    desc.init_cb = init;
    desc.frame_cb = frame;
    desc.event_cb = [](const sapp_event* event) {
        // 没有这一步点不动UI
        simgui_handle_event(event);
    };
    desc.cleanup_cb = []() {
        simgui_shutdown();
        sg_shutdown();
    };
    desc.width = 800;
    desc.height = 600;
    desc.window_title = "River Test";
    desc.logger.func = slog_func;
    return desc;
}

#include <jni.h>
#include <android/log.h>
#include <string>
// 将 Unicode 编号转换为 UTF-8 字符串
std::string UnicodeToUTF8(int cp) {
    std::string out;
    if (cp <= 0x7F) {
        out += (char)cp;
    } else if (cp <= 0x7FF) {
        out += (char)((cp >> 6) | 0xC0);
        out += (char)((cp & 0x3F) | 0x80);
    } else if (cp <= 0xFFFF) {
        out += (char)((cp >> 12) | 0xE0);
        out += (char)(((cp >> 6) & 0x3F) | 0x80);
        out += (char)((cp & 0x3F) | 0x80);
    } else if (cp <= 0x10FFFF) {
        out += (char)((cp >> 18) | 0xF0);
        out += (char)(((cp >> 12) & 0x3F) | 0x80);
        out += (char)(((cp >> 6) & 0x3F) | 0x80);
        out += (char)((cp & 0x3F) | 0x80);
    }
    return out;
}

extern "C" {
// JNI的函数名必须严格匹配包名; Java_包名_类名_方法名
JNIEXPORT void JNICALL Java_com_river_app_MainActivity_sendCharToNative(JNIEnv* env, jobject obj, jint unicodeChar) {
    std::string utf8_char = UnicodeToUTF8(unicodeChar);
    // __android_log_print(ANDROID_LOG_DEBUG, "River", "Received: %s (CodePoint: %d)", utf8_char.c_str(), unicodeChar);
}
JNIEXPORT void JNICALL Java_com_river_app_MainActivity_sendBackspaceToNative(JNIEnv* env, jobject obj) {
    // __android_log_print(ANDROID_LOG_DEBUG, "River", "Received: Backspace");
}
JNIEXPORT void JNICALL Java_com_river_app_MainActivity_sendEnterToNative(JNIEnv* env, jobject obj) {
    // __android_log_print(ANDROID_LOG_DEBUG, "River", "Received: Enter");
}
JNIEXPORT void JNICALL Java_com_river_app_MainActivity_nativeSetActivity(JNIEnv* env, jobject thiz) {
    env->GetJavaVM(&g_vm);
    g_activity = env->NewGlobalRef(thiz);
    // __android_log_print(ANDROID_LOG_DEBUG, "River", "Activity captured from Java. env=[%p] vm=[%p] activity=[%p]", env, g_vm, g_activity);
    // show_android_keyboard(g_activity, g_vm, true);
}
JNIEXPORT void JNICALL Java_com_river_app_MainActivity_setNativeStoragePath(JNIEnv* env, jobject obj, jstring path) {
    const char* pathStr = env->GetStringUTFChars(path, nullptr);
    InternalStoragePath = pathStr;
    env->ReleaseStringUTFChars(path, pathStr);
}

}