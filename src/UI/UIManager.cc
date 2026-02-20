#include "UI/UIManager.hh"

#include "ImGui.hh"
#include "File/FileSystem.hh"
#include "Env/Env.hh"
#include "Log/Log.hh"

#include "Sokol/Sokol.hh"

River::UIManager* River::UIManager::_instance = nullptr;

River::UIManager* River::UIManager::GetUIManager() {
    if (!UIManager::_instance) {
        UIManager::_instance = new UIManager();
    }
    return UIManager::_instance;
}

void River::UIManager::InitUIManager() {
    this->_InitImGuiEnv();
    this->_InitConfigFile();
    ImGui::GetIO().FontGlobalScale = 2.5f;
    ImGui::GetIO().ConfigFlags |= ImGuiConfigFlags_DockingEnable;
    infof("UIManager:InitUIManager(): Init done")
}

void River::UIManager::_InitImGuiEnv() {
    simgui_desc_t imgui_desc = {};
    imgui_desc.logger.func = slog_func;
    simgui_setup(&imgui_desc);
}

void River::UIManager::_InitConfigFile() {
    fs::path path = fs::path(River::InternalStoragePath) / "imgui.ini";
    if (!fs::exists(path.parent_path().parent_path())) {
        fatalf("UIManager:_InitConfigFile(): Invalid InternalStoragePath")
        return;
    }
    
    ImGuiIO& io = ImGui::GetIO();

    io.IniFilename = strdup(path.string().c_str());
    ImGui::LoadIniSettingsFromDisk(io.IniFilename);
    
#if test
    FILE* testFile = fopen(path.string().c_str(), "a");
    if (testFile) {
        fclose(testFile);
        infof("Ini path is writable: %s", path.string().c_str());
    } else {
        errorf("Ini path is NOT writable: %s", path.string().c_str());
    }
#endif
}

void River::UIManager::TickUIManager() {
    simgui_new_frame({sapp_width(), sapp_height(), sapp_frame_duration()}); // 开始imgui新的一帧
    
    ImGui::DockSpaceOverViewport(0, nullptr, ImGuiConfigFlags_DockingEnable);

    ImGui::Begin("River Top Line");
    ImGui::End();
    
    ImGui::Begin("River Content");

    static char content[1024] = "qqqqqqqqqqqq\nwwwwwwwwwwww    \nrrrr";
    ImGui::InputTextMultiline("content", content, sizeof(content), ImVec2(500, 500), ImGuiInputTextFlags_AllowTabInput);
    if (ImGui::IsItemActivated()) {
        // show_android_keyboard(g_activity, g_vm, true);
    }
    ImGui::End();
    
    ImGui::Begin("River Bottom Line");

    if (ImGui::BeginTable("button table", 4, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_Borders)) {
        float avail_width = ImGui::GetContentRegionAvail().x;
        float col_width = avail_width / 4.0f;
        for (int i = 0; i < 4; i++) {
            ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, col_width);
        }
        ImGui::TableNextRow();
        for (int i = 0; i < 4; i++) {
            ImGui::TableSetColumnIndex(i);
            std::string btnLabel = "Btn" + std::to_string(i+1);
            if (ImGui::Button(btnLabel.c_str(), ImVec2(-FLT_MIN, 0.0f))) {
                // 按钮点击处理
            }
        }
        ImGui::EndTable();
    }
    
    ImGui::End();
}

void River::UIManager::MakeRender() {
    simgui_render();
}