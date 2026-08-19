-- Файл: MFTools/ui/theme.lua
local imgui = require "mimgui"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local theme = {}

function theme.initFonts()
    local config = imgui.ImFontConfig()
    config.MergeMode = false
    local ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    
    local font_path = os.getenv("WINDIR") .. "\\Fonts\\trebuc.ttf"
    local font_bold = os.getenv("WINDIR") .. "\\Fonts\\trebucbd.ttf"

    local f = io.open(font_path, "r")
    if f then
        io.close(f)
        MFT.fonts.main = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 18.0, config, ranges)
        MFT.fonts.title = imgui.GetIO().Fonts:AddFontFromFileTTF(font_bold, 22.0, config, ranges)
        MFT.fonts.logo = imgui.GetIO().Fonts:AddFontFromFileTTF(font_bold, 32.0, config, ranges)
        MFT.fonts.small = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 14.0, config, ranges)
    else
        -- Защита от краша: если шрифта Trebuchet нет, грузим Arial
        local fallback = os.getenv("WINDIR") .. "\\Fonts\\arial.ttf"
        MFT.fonts.main = imgui.GetIO().Fonts:AddFontFromFileTTF(fallback, 18.0, config, ranges)
        MFT.fonts.title = imgui.GetIO().Fonts:AddFontFromFileTTF(fallback, 22.0, config, ranges)
        MFT.fonts.logo = imgui.GetIO().Fonts:AddFontFromFileTTF(fallback, 32.0, config, ranges)
        MFT.fonts.small = imgui.GetIO().Fonts:AddFontFromFileTTF(fallback, 14.0, config, ranges)
    end
end

function theme.applyGlobalStyle()
    local style = imgui.GetStyle()
    style.WindowRounding, style.ChildRounding, style.FrameRounding = 14.0, 12.0, 10.0
    style.PopupRounding, style.ScrollbarRounding, style.GrabRounding = 10.0, 10.0, 10.0
    style.ScrollbarSize = 10.0
    style.WindowPadding = imgui.ImVec2(0, 0)
    
    local colors = style.Colors
    local c_bg = MFT.settings.colorBg or {0.05, 0.06, 0.08, 1.0}
    local c_btn = MFT.settings.colorBtn or {0.18, 0.20, 0.25, 1.0}
    local c_accent = MFT.settings.colorAccent or {0.20, 0.60, 0.85, 1.0}
    local c_text = MFT.settings.colorText or {0.9, 0.9, 0.95, 1.0}

    colors[imgui.Col.WindowBg] = imgui.ImVec4(c_bg[1], c_bg[2], c_bg[3], c_bg[4])
    colors[imgui.Col.Border] = imgui.ImVec4(0, 0, 0, 0)
    colors[imgui.Col.FrameBg] = imgui.ImVec4(c_bg[1] + 0.05, c_bg[2] + 0.05, c_bg[3] + 0.05, 1.0)
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(c_bg[1] + 0.1, c_bg[2] + 0.1, c_bg[3] + 0.1, 1.0)
    colors[imgui.Col.FrameBgActive] = imgui.ImVec4(c_bg[1] + 0.15, c_bg[2] + 0.15, c_bg[3] + 0.15, 1.0)
    colors[imgui.Col.Button] = imgui.ImVec4(c_btn[1], c_btn[2], c_btn[3], 1.0)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(c_btn[1] + 0.08, c_btn[2] + 0.08, c_btn[3] + 0.08, 1.0)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(c_btn[1] - 0.05, c_btn[2] - 0.05, c_btn[3] - 0.05, 1.0)
    colors[imgui.Col.SliderGrab] = imgui.ImVec4(c_btn[1], c_btn[2], c_btn[3], 1.0)
    colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0)
    colors[imgui.Col.Text] = imgui.ImVec4(c_text[1], c_text[2], c_text[3], c_text[4])
    colors[imgui.Col.CheckMark] = imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0)
end

return theme