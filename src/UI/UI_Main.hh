#ifndef UI_UI_Main_hh
#define UI_UI_Main_hh

#include "UI/UIWindowBase.hh"

namespace River {

class UI_Main: public UIWindowBase {
public:
    virtual void TickWindow() override;
};

}

#endif