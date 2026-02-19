#ifndef keyboard_hh
#define keyboard_hh

#include <android/native_activity.h>
#include <jni.h>

void show_android_keyboard(jobject activity, JavaVM* jvm, bool show) {
    JNIEnv* env = nullptr;
    bool needDetach = false;
    if (jvm->GetEnv((void**)&env, JNI_VERSION_1_6) != JNI_OK) {
        jvm->AttachCurrentThread(&env, nullptr);
        needDetach = true;
    }
    jclass javaClass = env->GetObjectClass(activity);
    __android_log_print(ANDROID_LOG_DEBUG, "River", "print java class %p", javaClass);
    jmethodID fnId = env->GetMethodID(javaClass, "showKeyBoard", "()V");
    if (!fnId) {
        __android_log_print(ANDROID_LOG_DEBUG, "River", "invalid fn id");
        env->ExceptionDescribe(); // 非常重要，能看到真正错误
        env->ExceptionClear();
        return;
    }
    env->CallVoidMethod(activity, fnId);
    env->DeleteLocalRef(javaClass);
    if (needDetach) {
        jvm->DetachCurrentThread();
    }
}

#endif