#ifndef UI_ImGui_hh
#define UI_ImGui_hh

/**
 * 常用api简介
 *  1. 窗口生命周期
 *      所有界面的容器, 用begin和end包围起来
 *          // 开始一个名为MyWindow的窗口
 *          ImGui::Begin("MyWindow");
 *          // 结束当前窗口
 *          ImGui::End();
 *      Begin和End必须成对出现
 *      如果窗口是折叠或不可见的, Begin()会返回false, 告诉你控件是否被激活
 *  2. 基础控件
 *      构建界面的积木, 他们都返回一个bool值, 告诉你控件是否被激活
 *          // 按钮: 点击的瞬间返回true
 *          if (ImGui::Button("click me")) {
 *              // 按钮被点击时执行的逻辑
 *          }
 *          // 单行文本输入, 需要传入一个可变的字符缓冲区
 *          char inputBuf[128] = "Edit Me";
 *          ImGui::InputText("Label", inputBuf, IM_ARRAYSIZE(inputBuf));
 *          // 复选框, 绑定到一个布尔变量
 *          bool myBool = true;
 *          ImGui::CheckBox("My CheckBox", &myBool);
 *          // 滑动条, 绑定到一个浮点变量
 *          float myFloat = 0.5f;
 *          ImGui::SliderFloat("My Slider", &myFloat, 0.0f, 1.0f);
 *      可以看到, InputText/CheckBox这类控件会直接修改你传入的变量, 实现了数据和界面的双向绑定
 *  3. 布局与组织
 *      ImGui会自动计算控件位置, 但这些工具可以帮你微调布局
 *          // 接下来的控件放在同一行
 *          ImGui::SameLine();
 *          // 绘制一条分割线
 *          ImGui::Separator();
 *          // 开始一个垂直布局组, 内部控件会垂直排列
 *          ImGui::BeginGroup();
 *          ImGui::EndGroup();
 *      此外, BeginChild()可以创建一个可独立滚动的子窗口区域, 用于复杂布局
 *  4. 交互与状态
 *      可以查询各种全局状态, 以实现更复杂的交互逻辑
 *          // 获取ImGui的全局IO对象, 包含鼠标/键盘/配置等信息
 *          ImGui& io = ImGui::GetIO();
 *          // 判断鼠标是否在当前ImGui窗口上, 常用于阻止3D场景中的摄像机旋转
 *          if (io.WantCaptureMouse) {
 *              // 鼠标正在与ImGui交互, 游戏不应该处理鼠标输入
 *          }
 *          // 判断某个特定项是否被悬停(需要在控件之后调用)
 *          if (ImGui::IsItemHovered()) {
 *              ImGui::SetTooltip("This is a tooltip"); // 显示提示框
 *          }
 *          // 判断某个特定项是否被激活(例如, 正在拖动滑块)
 *          if (ImGui::IsItemActive()) {}
 *      io.WantCaptureMouse和io.WantCaptureKeyboard是集成ImGui到游戏引擎时最关键的标志
 *  5. 风格和自定义
 *      可以修改界面的外观
 *          // 使用内置的几种配色风格
 *          ImGui::StyleColorDark(); // 默认的暗色风格
 *          ImGui::StyleColorLight(); // 亮色风格
 *          ImGui::StyleColorClassic(); // 经典的ImGui风格
 *          // 更精细地控制：修改全局颜色
 *          ImVec4* colors = ImGui::GetStyle().Colors;
 *          colors[ImGuiCol_Button] = ImVec4(0.2f, 0.3f, 0.4f, 1.0f); // 改变按钮颜色
 *          // 或者临时压入一个颜色修改，之后弹出
 *          ImGui::PushStyleColor(ImGuiCol_Text, IM_COL32(255, 0, 0, 255));
 *          ImGui::Text("This text is red");
 *          ImGui::PopStyleColor();
 *      ImGuiCol_枚举包含了所有可着色的UI元素
 *  6. 高级绘图
 *      如果需要绘制ImGui标准控件以外的图形(如图表/自定义组件), 可以使用ImDrawList
 *          // 获取当前窗口的绘制列表
 *          ImDrawList* draw_list = ImGui::GetWindowDrawList();
 *          // 在屏幕上绘制一条线(坐标是绝对屏幕坐标)
 *          draw_list->AddLine(ImVec2(10, 10), ImVec2(10, 10), IM_COL32(255, 255, 0, 255), 3.0f);
 *          // 绘制一个带圆角的填充矩形
 *          draw_list->AddRectFilled(ImVec2(50, 50), ImVec2(150, 100), IM_COL32(0, 255, 0, 128), 5.0f);
 *          
 */

#include "Sokol/Sokol.hh"

#endif