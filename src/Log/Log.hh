#ifndef Log_Log_hh
#define Log_Log_hh

#include <android/log.h>

#define LOG_TAG "River"

#define debugf(...)\
__android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, ...);

#define infof(...)\
__android_log_print(ANDROID_LOG_INFO, LOG_TAG, ...);

#define warnf(...)\
__android_log_print(ANDROID_LOG_WARNF, LOG_TAG, ...);

#define errorf(...)\
__android_log_print(ANDROID_LOG_ERROR, LOG_TAG, ...);

#define fatalf(...)\
__android_log_print(ANDROID_LOG_FATALF, LOG_TAG, ...);

#endif