#ifndef UI_UIManager_hh
#define UI_UIManager_hh

#include "UI/UIWindowBase.hh"
#include "imgui.h"

#include <vector>
#include <type_traits>

namespace River {

// class UIWindowBase;

class UIManager {
    // instance
public:
        static UIManager* GetUIManager();
private:
    UIManager() {}
    static UIManager* _instance;
    ~UIManager();

    // init
public:
    void InitUIManager();
private:
    void _InitImGuiEnv();
    void _InitConfigFile();

    // tick
public:
    void TickUIManager();
    void MakeRender();

    // screenSize
public:
    ImVec2 GetScreenSize() const {return ImGui::GetIO().DisplaySize;}

    // window
public:
    template<typename T>
    void OpenUI() {
        static_assert(std::is_base_of<River::UIWindowBase, T>::value, "T must be derived from UIWindowBase");
        River::UIWindowBase* wdn = new T();
        this->_Windows.push_back(wdn);
    }
    void CloseUI(River::UIWindowBase* wdn);
private:
    void _OpenDefaultUI();
    std::vector<River::UIWindowBase*> _Windows;
};

}

#endif