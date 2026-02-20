#ifndef UI_UIManager_hh
#define UI_UIManager_hh

namespace River {

class UIManager {
    // instance
private:
    UIManager() {}
    static UIManager* _instance;
public:
    static UIManager* GetUIManager();

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
};
    
}

#endif