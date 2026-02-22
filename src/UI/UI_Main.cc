#include "UI/UI_Main.hh"

#include "UIManager.hh"
#include "UI/ImGui.hh"
#include "Env/Env.hh"
#include "Log/Log.hh"

#include <string>

#define MAIN_TOP_SCALE 0.2
#define MAIN_DOWN_SCALE 0.8

River::UI_Main::UI_Main() {
    this->_CurPath = new fs::path(River::InternalStoragePath.c_str());
}
River::UI_Main::~UI_Main() {
    delete this->_CurPath;
}

void River::UI_Main::TickWindow() {
    ImVec2 size = River::UIManager::GetUIManager()->GetScreenSize();
    ImGui::SetNextWindowPos(ImVec2(0, size.y * MAIN_TOP_SCALE));
    ImGui::SetNextWindowSize(ImVec2(size.x, size.y * (MAIN_DOWN_SCALE - MAIN_TOP_SCALE)));
    ImGui::Begin("UI_Main");
    {
        ImGui::Text("StoragePath = [%s]", this->_CurPath->string().c_str());

        if (fs::exists(*this->_CurPath) && fs::is_directory(*this->_CurPath)) {
            int selected_item = 0;
            std::vector<std::string> items = std::vector<std::string>();
            std::vector<const char*> itemptrs = std::vector<const char*>();
            for (const auto& entry : fs::directory_iterator(*this->_CurPath)) {
                items.push_back(entry.path().filename().string());
                itemptrs.push_back(items.back().c_str());
            }
            ImGui::ListBox("Content", &selected_item, itemptrs.data(), itemptrs.size());
        }
    }
    ImGui::End();
}