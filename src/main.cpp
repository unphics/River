
#include "sokol_impl.hh"
#include "keyboard.hh"
// #include "inputchar.hh"

#include "imgui.h"
#include "sokol_imgui.h"
#include <android/native_activity.h>

static void init(void) {
    // 先初始化渲染器
    sg_desc gfx_desc = {};
    gfx_desc.environment = sglue_environment();
    gfx_desc.logger.func = slog_func;
    sg_setup(gfx_desc);

    // 初始化sokol-imgui
    simgui_desc_t imgui_desc = {};
    imgui_desc.logger.func = slog_func;
    simgui_setup(&imgui_desc);
    ImGui::SetCurrentContext(ImGui::GetCurrentContext()); 
    ImGui::GetIO().FontGlobalScale = 2.5f;

    unsigned char* pixels;
    int width, height;
    ImGui::GetIO().Fonts->GetTexDataAsRGBA32(&pixels, &width, &height);

    __android_log_print(ANDROID_LOG_INFO, "River", "ImGui Setup Done!");
}

static void frame(void) {
    if (!sg_isvalid()) {
        __android_log_print(ANDROID_LOG_ERROR, "River", "!sg_isvalid()!");
        return;
    }
    // 调试打印：检查当前上下文
    if (ImGui::GetCurrentContext() == nullptr) {
        __android_log_print(ANDROID_LOG_ERROR, "River", "CRITICAL: ImGui Context is NULL!");
        return;
    }

    // 2. 检查字体库是否准备好
    ImGuiIO& io = ImGui::GetIO();
    if (!io.Fonts->IsBuilt()) {
        __android_log_print(ANDROID_LOG_ERROR, "River", "ERROR: ImGui Fonts not built!");
        // 如果没 build，simgui 会尝试在 new_frame 里处理，但这里可能已经晚了
        // return;
    }

    // 开始imgui新的一帧
    simgui_new_frame({sapp_width(), sapp_height(), sapp_frame_duration()});
    
    // 编写UI界面逻辑
    ImGui::SetNextWindowPos(ImVec2(50, 50), ImGuiCond_FirstUseEver);
    ImGui::Begin("River Debug Tools");
    ImGui::Text("Hello, Android");
    if (ImGui::Button("TapMe")) {
        // 处理点击
        // ANativeActivity_showSoftInput((ANativeActivity*)sapp_android_get_native_activity(), ANATIVEACTIVITY_SHOW_SOFT_INPUT_FORCED);
        show_android_keyboard(true);
    }
    static char buf[128] = ""; // 必须是静态的或者在类成员里，保证生命周期
    if (ImGui::InputText("InputText", buf, IM_ARRAYSIZE(buf))) {
        show_android_keyboard(true);
    }
    if (ImGui::GetIO().WantTextInput) {
        show_android_keyboard(true);
    }
    ImGui::End();

    // 渲染
    sg_pass pass = {};
    pass.action.colors[0].load_action = SG_LOADACTION_CLEAR;
    pass.action.colors[0].clear_value = {0.1f, 0.1f, 0.1f, 1.0f};
    pass.swapchain = sglue_swapchain();

    sg_begin_pass(&pass);
    simgui_render(); // 在Pass结束前渲染Imgui;
    sg_end_pass();
    sg_commit();
}

// Sokol 入口
sapp_desc sokol_main(int argc, char* argv[]) {
    sapp_desc desc = {};
    desc.init_cb = init;
    desc.frame_cb = frame;
    desc.event_cb = [](const sapp_event* event) {
        // 没有这一步点不动UI
        simgui_handle_event(event);
    };
    desc.cleanup_cb = []() {
        simgui_shutdown();
        sg_shutdown();
    };
    desc.width = 800;
    desc.height = 600;
    desc.window_title = "River Test";
    desc.logger.func = slog_func;
    return desc;
}