#ifndef UI_UIManager_hh
#define UI_UIManager_hh

#include <vector>

namespace River {

class UIWindowBase;
    
class UIManager {
    // instance
    public:
        static UIManager* GetUIManager();
private:
    UIManager() {}
    static UIManager* _instance;

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
    ImVec2 GetScrrenSize() const {return this->_ScrrenSize;}
private:
    ImVec2 _ScrrenSize;

    // window
};
    
}

#endif