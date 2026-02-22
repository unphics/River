#ifndef UI_UI_Main_hh
#define UI_UI_Main_hh

#include "UI/UIWindowBase.hh"
#include "File/FileSystem.hh"

namespace River {

class UI_Main: public UIWindowBase {
public:
    UI_Main();
    ~UI_Main();
    virtual void TickWindow() override;
private:
    fs::path* _CurPath;
};

}

#endif