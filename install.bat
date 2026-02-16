adb logcat -c
xmake
xmake install -o River
adb logcat -c
@REM adb logcat -s RiverTag SDL
@REM adb logcat *:E River:I

@REM adb logcat RiverTag:I SDL:I