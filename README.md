# River

adb exec-out run-as com.river.app cat /data/user/0/com.river.app/files/imgui.ini > imgui.ini

adb exec-out run-as com.river.app rm /data/user/0/com.river.app/files/imgui.ini

```
任务:设计一个ImGui的UIManager
    调整窗口大小
        ImGui::SetNextWindowSize(ImVec2(400, 300)); 设置窗口大小为 400x300 像素
        ImGui::SetNextWindowSizeConstraints(ImVec2(200, 150), ImVec2(800, 600)); 设置最小尺寸 200x150，最大尺寸 800x600
        ImGui::SetWindowSize(ImVec2(600, 400)); 在Begin和End中间可以直接设置
    禁止调整窗口大小
        ImGui::Begin("Fixed Window", nullptr, ImGuiWindowFlags_NoResize);
        ImGui::Begin("Locked Window", nullptr, 
             ImGuiWindowFlags_NoResize |  // 不能调整大小
             ImGuiWindowFlags_NoMove |     // 不能移动
             ImGuiWindowFlags_NoCollapse); // 不能折叠
        常用flags:
            ImGuiWindowFlags_NoResize	禁止调整大小
            ImGuiWindowFlags_NoMove	禁止移动窗口
            ImGuiWindowFlags_NoCollapse	禁止折叠（隐藏标题栏折叠按钮）
            ImGuiWindowFlags_NoTitleBar	隐藏标题栏
            ImGuiWindowFlags_NoScrollbar	隐藏滚动条
            ImGuiWindowFlags_NoDocking	（Docking 分支）禁止停靠
    窗口绘制优先级
        ImGui 默认的 Z-order 规则很简单：
            最后调用的 Begin() 窗口绘制在最上层
            当前获得焦点的窗口自动提到最上层
        所以建议搞容器来管理执行顺序来搞绘制顺序
```