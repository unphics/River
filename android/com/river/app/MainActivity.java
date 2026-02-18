
package app;


import android.app.NativeActivity;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.BaseInputConnection;
import android.text.InputType;

public class MainActivity extends NativeActivity {
    // 这个函数是关键：当输入法连接时，返回一个能接收文字的“管道”
    @Override
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        outAttrs.inputType = InputType.TYPE_CLASS_TEXT;
        outAttrs.imeOptions = EditorInfo.IME_ACTION_DONE;

        return new BaseInputConnection(this, true) {
            @Override
            public boolean commitText(CharSequence text, int newCursorPosition) {
                // 每当输入法提交一段文字（包括中文、字母）
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