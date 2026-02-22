#include "UI/UI_Main.hh"

#include "UIManager.hh"
#include "UI/ImGui.hh"
#include "Env/Env.hh"
#include "Log/Log.hh"

#include <string>

#define MAIN_TOP_SCALE 0.2
#define MAIN_DOWN_SCALE 0.8

void River::UI_Main::TickWindow() {
    ImVec2 size = River::UIManager::GetUIManager()->GetScreenSize();
    ImGui::SetNextWindowPos(ImVec2(0, size.y * MAIN_TOP_SCALE));
    ImGui::SetNextWindowSize(ImVec2(size.x, size.y * (MAIN_DOWN_SCALE - MAIN_TOP_SCALE)));
    ImGui::Begin("UI_Main");
    {
        ImGui::Text("InternalStoragePath = [%s]", River::InternalStoragePath.c_str());
    }
    ImGui::End();
}