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
import android.text.InputType;
import android.view.KeyEvent;

public class MainActivity extends NativeActivity {

    static {
        try {
            System.loadLibrary("main");
        } catch (UnsatisfiedLinkError e) {
            Log.e("River", "Could not load native library 'main': " + e.getMessage());
        }
    }

    // java call cpp
    public native void sendCharToNative(int unicodeChar);
    public native void sendBackspaceToNative();
    public native void sendEnterToNative();
    public native void nativeSetActivity(MainActivity activity);

    // 保存拦截View
    private InterceptInputView mInputView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.e("River", "MainActivity onCreate");
        // 创建拦截View
        mInputView = new InterceptInputView(this);
        // 将它添加到Activity的布局中(虽然它是不可见的, 但必须存在于View树里)
        ViewGroup.LayoutParams params = new ViewGroup.LayoutParams(1, 1);
        addContentView(mInputView, params);
        // 让他可以获得焦点
        mInputView.setFocusable(true);
        mInputView.setFocusableInTouchMode(true);
        // this.showKeyboard();
        this.nativeSetActivity(this);
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
            return new InputConnEx(this, true);
        }
        private class InputConnEx extends BaseInputConnection {
            InputConnEx(View targetView, boolean fullEditor) {
                super(targetView, fullEditor);
            }
            @Override
            public boolean commitText(CharSequence text, int newCursorPosition) {
                for (int i = 0; i < text.length(); i++) {
                    sendCharToNative(text.charAt(i));
                }
                return super.commitText(text, newCursorPosition);
            }
            @Override
            public boolean deleteSurroundingText(int beforeLength, int afterLength) {
                // Log.i("River", "deleteSurroundingText");
                sendBackspaceToNative();
                // return super.deleteSurroundingText(beforeLength, afterLength);
                return true;
            }
            @Override
            public boolean deleteSurroundingTextInCodePoints(int beforeLength, int afterLength) {
                // Log.i("River", "deleteSurroundingTextInCodePoints");
                sendBackspaceToNative();
                // return super.deleteSurroundingTextInCodePoints(beforeLength, afterLength);
                return true;
            }
            @Override
            public boolean sendKeyEvent(KeyEvent event) {
                if (event.getAction() == KeyEvent.ACTION_DOWN && event.getKeyCode() == KeyEvent.KEYCODE_DEL) {
                    // Log.i("River", "sendKeyEvent DEL");
                    sendBackspaceToNative();
                    return true;
                }
                return super.sendKeyEvent(event);
            }
            @Override
            public boolean performEditorAction(int actionCode) {
                if (actionCode == EditorInfo.IME_ACTION_DONE ||
                    actionCode == EditorInfo.IME_ACTION_GO ||
                    actionCode == EditorInfo.IME_ACTION_SEND ||
                    actionCode == EditorInfo.IME_ACTION_NEXT ||
                    actionCode == EditorInfo.IME_ACTION_UNSPECIFIED) {
                    sendEnterToNative();
                    return true;
                }
                return super.performEditorAction(actionCode);
            }
        }
        @Override
        public boolean onKeyDown(int keyCode, KeyEvent event) {
            if (keyCode == KeyEvent.KEYCODE_DEL) {
                Log.i("River", "onKeyDown DEL received");
                sendBackspaceToNative();
                return true;
            }
            return super.onKeyDown(keyCode, event);
        }
        @Override
        public boolean onCheckIsTextEditor() {
            return true;
        }
        @Override
        public boolean isFocused() {
            return true;
        }
        // @Override
        // public boolean onKeyPreIme(int keyCode, KeyEvent event) {
        //     return false;
        // }
    }

    // cpp call java
    public void showKeyBoard() {
        Log.e("River", "showKeyboard call");
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