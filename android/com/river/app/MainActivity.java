package com.river.app;

import android.app.NativeActivity;
import android.view.View;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.BaseInputConnection;
import android.text.InputType;
import android.os.Bundle;

public class MainActivity extends NativeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    // 注意: 这个方法在Activity中不是重写(Override)而是自定义方法
    // 如果你是想拦截输入法, 通常需要作用在View上
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        outAttrs.inputType = InputType.TYPE_CLASS_TEXT;
        outAttrs.imeOptions = EditorInfo.IME_ACTION_DONE;

        return new BaseInputConnection(getWindow().getDecorView(), true) {
            @Override
            public boolean commitText(CharSequence text, int newCursorPosition) {
                for (int i = 0; i < text.length(); i++) {
                    sendCharToNative(text.charAt(i));
                }
                return true;
            }
        };
    }

    // 声明一个 native 函数，在 C++ 里实现它
    public native void sendCharToNative(int unicodeChar);
}