
#include "Log/Log.hh"
#include "Sokol/Sokol.hh"
#include "Input/keyboard.hh"
#include "File/FileSystem.hh"
#include "UI/UIManager.hh"
#include "Env/Env.hh"

#include <android/native_activity.h>
#include <string>

static JavaVM* g_vm = nullptr;
static jobject g_activity = nullptr;

static void init(void) {
    // 先初始化渲染器
    sg_desc gfx_desc = {};
    gfx_desc.environment = sglue_environment();
    gfx_desc.logger.func = slog_func;
    sg_setup(gfx_desc);

    River::UIManager* ui = River::UIManager::GetUIManager();
    ui->InitUIManager();
}

static void frame(void) {
    if (!sg_isvalid()) {
        errorf("!sg_isvalid()!")
        return;
    }
    
    River::UIManager::GetUIManager()->TickUIManager();

    // 渲染
    sg_pass pass = {};
    pass.action.colors[0].load_action = SG_LOADACTION_CLEAR;
    pass.action.colors[0].clear_value = {0.1f, 0.1f, 0.1f, 1.0f};
    pass.swapchain = sglue_swapchain();
    
    sg_begin_pass(&pass);
    River::UIManager::GetUIManager()->MakeRender();
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
    River::InternalStoragePath = std::string(pathStr);
    env->ReleaseStringUTFChars(path, pathStr);
    infof("River::InternalStoragePath [%s]", River::InternalStoragePath.c_str())
}

}