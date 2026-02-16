#ifndef inputchar_hh
#define inputchar_hh

#include <jni.h>

// 辅助函数：将 Android Key Event 转换为 Unicode 字符
uint32_t get_unicode_char(int device_id, int key_code, int meta_state) {
    ANativeActivity* activity = (ANativeActivity*)sapp_android_get_native_activity();
    JavaVM* jvm = activity->vm;
    JNIEnv* env = NULL;
    jvm->GetEnv((void**)&env, JNI_VERSION_1_6);
    jvm->AttachCurrentThread(&env, NULL);

    // 调用 Java 的 KeyEvent 类来获取字符
    jclass key_event_cls = env->FindClass("android/view/KeyEvent");
    jmethodID constructor = env->GetMethodID(key_event_cls, "<init>", "(II)V");
    jobject key_event_obj = env->NewObject(key_event_cls, constructor, 0, key_code); // 0 为 ActionDown
    
    jmethodID get_unicode_method = env->GetMethodID(key_event_cls, "getUnicodeChar", "(I)I");
    uint32_t unicode_char = (uint32_t)env->CallIntMethod(key_event_obj, get_unicode_method, meta_state);

    // 释放资源
    env->DeleteLocalRef(key_event_obj);
    // jvm->DetachCurrentThread(); // 注意：在主线程频繁调用时 Detach 会影响性能，建议只在线程退出时 Detach
    
    return unicode_char;
}

// Sokol 的事件回调
void on_event(const sapp_event* ev) {
    if (ev->type == SAPP_EVENTTYPE_KEY_DOWN) {
        // 如果 ImGui 想要文字输入
        if (ImGui::GetIO().WantTextInput) {
            // 这里我们需要 Android 原始的 key_code，Sokol 有时会封装它
            // 如果是在 Android 平台，sokol_app 会填充这个值
            uint32_t c = get_unicode_char(0, ev->android_keycode, ev->android_metastate);
            
            if (c != 0) {
                // 手动构造一个 CHAR 事件喂给 ImGui
                sapp_event char_ev = {0};
                char_ev.type = SAPP_EVENTTYPE_CHAR;
                char_ev.char_code = c;
                simgui_handle_event(&char_ev);
            }
        }
    }
    
    // 正常的事件转发
    simgui_handle_event(ev);
}

#endif