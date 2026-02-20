#ifndef Log_Log_hh
#define Log_Log_hh

#include <android/log.h>

#define LOG_TAG "River"

#define debugf(...)\
__android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__);

#define infof(...)\
__android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__);

#define warnf(...)\
__android_log_print(ANDROID_LOG_WARNF, LOG_TAG, __VA_ARGS__);

#define errorf(...)\
__android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__);

#define fatalf(...)\
__android_log_print(ANDROID_LOG_FATAL, LOG_TAG, __VA_ARGS__);

#endif