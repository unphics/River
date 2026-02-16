#ifndef keyboard_hh
#define keyboard_hh

#if defined(__ANDROID__)
#include <android/native_activity.h>
#include <jni.h>

void show_android_keyboard(bool show) {
    // 获取 NativeActivity 句柄（sokol_app 内部维护）
    ANativeActivity* activity = (ANativeActivity*)sapp_android_get_native_activity();
    JavaVM* jvm = activity->vm;
    JNIEnv* env = NULL;
    jvm->GetEnv((void**)&env, JNI_VERSION_1_6);
    
    // 如果当前线程没挂载，需要 Attach
    bool attached = false;
    if (env == NULL) {
        jvm->AttachCurrentThread(&env, NULL);
        attached = true;
    }

    jclass cls = env->GetObjectClass(activity->clazz);
    jmethodID method = env->GetMethodID(cls, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;");
    jstring service_name = env->NewStringUTF("input_method");
    jobject imm = env->CallObjectMethod(activity->clazz, method, service_name);

    jclass imm_cls = env->GetObjectClass(imm);
    if (show) {
        // 显示键盘
        jmethodID show_method = env->GetMethodID(imm_cls, "showSoftInput", "(Landroid/view/View;I)Z");
        jmethodID get_window_method = env->GetMethodID(cls, "getWindow", "()Landroid/view/Window;");
        jobject window = env->CallObjectMethod(activity->clazz, get_window_method);
        jclass window_cls = env->FindClass("android/view/Window");
        jmethodID get_decor_method = env->GetMethodID(window_cls, "getDecorView", "()Landroid/view/View;");
        jobject view = env->CallObjectMethod(window, get_decor_method);
        
        env->CallBooleanMethod(imm, show_method, view, 0);
    } else {
        // 隐藏键盘
        jmethodID hide_method = env->GetMethodID(imm_cls, "hideSoftInputFromWindow", "(Landroid/os/IBinder;I)Z");
        // 这里需要获取 WindowToken，简化处理可以使用 toggleSoftInput 或者获取 View 的 Token
        // ... 
    }

    if (attached) jvm->DetachCurrentThread();
}
#endif

#endif