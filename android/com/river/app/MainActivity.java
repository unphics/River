package com.river.app;

import android.app.NativeActivity;
import android.os.Bundle;
import android.util.Log;
import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import android.text.InputType; // 注意：InputType 在 android.text 包下

public class MainActivity extends NativeActivity {

    static {
        System.loadLibrary("main");
    }

    public native void sendCharToNative(int unicodeChar);

    // 声明一个变量来保存我们的拦截 View
    private InterceptInputView mInputView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.e("River", "MainActivity onCreate");

        // 1. 创建拦截 View
        mInputView = new InterceptInputView(this);
        
        // 2. 将它添加到 Activity 的布局中（虽然它是不可见的，但必须存在于 View 树里）
        ViewGroup.LayoutParams params = new ViewGroup.LayoutParams(1, 1);
        addContentView(mInputView, params);

        // 3. 让他可以获得焦点
        mInputView.setFocusable(true);
        mInputView.setFocusableInTouchMode(true);
        // this.showKeyboard();
    }

    // 内部类：专门处理输入法逻辑的 View
    private class InterceptInputView extends View {
        public InterceptInputView(Context context) {
            super(context);
        }

        // 核心：系统询问该 View 如何输入时，返回我们的拦截器
        @Override
        public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
            Log.e("River", "onCreateInputConnection called");
            
            outAttrs.inputType = InputType.TYPE_CLASS_TEXT;
            outAttrs.imeOptions = EditorInfo.IME_ACTION_DONE;

            return new BaseInputConnection(this, true) {
                @Override
                public boolean commitText(CharSequence text, int newCursorPosition) {
                    for (int i = 0; i < text.length(); ) {
                        int codePoint = Character.codePointAt(text, i);
                        sendCharToNative(codePoint);
                        i += Character.charCount(codePoint); // 自动跳过辅助字符
                    }
                    return true;
                }

                @Override
                public boolean deleteSurroundingText(int beforeLength, int afterLength) {
                    if (beforeLength == 1 && afterLength == 0) {
                        sendCharToNative(8); // 发送退格键
                    }
                    return super.deleteSurroundingText(beforeLength, afterLength);
                }
            };
        }

        @Override
        public boolean onCheckIsTextEditor() {
            return true;
        }
    }

    // 提供一个给 C++ 调用的方法，用来弹出键盘
    public void showKeyboard() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mInputView.requestFocus();
                InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
                if (imm != null) {
                    imm.showSoftInput(mInputView, InputMethodManager.SHOW_FORCED);
                }
            }
        });
    }
}