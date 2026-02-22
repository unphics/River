#ifndef UI_UIWindowBase_hh
#define UI_UIWindowBase_hh

namespace River {

class UIManager;

class UIWindowBase {
public:
    virtual ~UIWindowBase() {}
public:
    virtual void TickWindow() {}
};
    
}

#endif