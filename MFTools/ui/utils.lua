-- ‘айл: MFTools/ui/utils.lua
local imgui = require "mimgui"
local ffi = require "ffi"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local engine = require "MFTools.core.engine"
local presets_data = require "MFTools.data.presets"
local uistate = require "MFTools.ui.uistate"

local utils = {}

function utils.getHover(dash, id, isHovered, speed)
    speed = speed or 12.0
    dash.anims.hover[id] = dash.anims.hover[id] or 0.0
    local target = isHovered and 1.0 or 0.0
    dash.anims.hover[id] = dash.anims.hover[id] + (target - dash.anims.hover[id]) * math.min(1.0, speed * imgui.GetIO().DeltaTime)
    return dash.anims.hover[id]
end

function utils.CenterText(text, color)
    local tw = imgui.CalcTextSize(text).x
    imgui.SetCursorPosX((imgui.GetWindowWidth() - tw) / 2)
    if color then imgui.TextColored(color, text) else imgui.Text(text) end
end

function utils.HelpMarker(desc)
    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "(?)")
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(imgui.GetFontSize() * 25.0)
        imgui.TextUnformatted(desc)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function utils.DrawWrapText(t)
    imgui.PushTextWrapPos(imgui.GetContentRegionAvail().x - 15)
    imgui.Text(t)
    imgui.PopTextWrapPos()
end

function utils.BeginCard(dash, dt, id, height, title, c_accent, sb_color)
    dash.cardCounter = (dash.cardCounter or 0) + 1
    local cCounter = dash.cardCounter
    
    dash.anims.cardCascade[cCounter] = dash.anims.cardCascade[cCounter] or 0.0
    local delay = (cCounter - 1) * 0.08
    local targetCard = (dash.anims.tabSwitch > delay) and 1.0 or 0.0
    dash.anims.cardCascade[cCounter] = dash.anims.cardCascade[cCounter] + (targetCard - dash.anims.cardCascade[cCounter]) * math.min(1.0, 15.0 * dt)
    
    local cAlpha = dash.anims.cardCascade[cCounter]
    
    -- ѕолучаем текущую глобальную прозрачность меню
    local menuAlpha = MFT.settings.menuTransparency or 0.98
    
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, cAlpha * dash.anims.menuOpen)
    
    -- ”множаем базовую прозрачность карточки (0.6) и обводки (0.4) на общую прозрачность меню
    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(sb_color[1], sb_color[2], sb_color[3], 0.6 * menuAlpha))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.4 * menuAlpha))
    
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildBorderSize, 1.5)
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, 12.0)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(20, 20))
    
    local cpos = imgui.GetCursorPos()
    imgui.SetCursorPos(imgui.ImVec2(cpos.x, cpos.y + (1.0 - cAlpha) * 20.0))
    
    imgui.BeginChild(id, imgui.ImVec2(-1, height), true, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
    
    if title then
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
        utils.CenterText(title, c_accent)
        if MFT.fonts.title then imgui.PopFont() end
        imgui.Separator()
        imgui.Spacing(); imgui.Spacing()
    end
end

function utils.EndCard()
    imgui.EndChild()
    imgui.PopStyleVar(3); imgui.PopStyleColor(2); imgui.PopStyleVar() 
end

function utils.sanitizePresetText(text)
    local clean = text
    clean = clean:gsub("Х∞Х∞%.Х∞Х∞:::", "=== ћузыкальна€ заставка ===")
    clean = clean:gsub("%?∞%?∞%.%?∞%?∞:::", "=== ћузыкальна€ заставка ===")
    clean = clean:gsub("%?%?%?%.%?%?%?%?:::", "=== ћузыкальна€ заставка ===")
    clean = clean:gsub("Х", "-")
    return clean
end

function utils.confirmAndLoadPreset(faction_id)
    local presetBinds = presets_data[faction_id]
    if presetBinds and #presetBinds > 0 then
        for _, bind in ipairs(presetBinds) do 
            local cleanLines = {}
            for _, line in ipairs(bind.lines) do table.insert(cleanLines, utils.sanitizePresetText(line)) end
            table.insert(MFT.binds, {
                name = bind.name, 
                lines = cleanLines, 
                delay = bind.delay, 
                showInOverlay = bind.showInOverlay, 
                hotkey = bind.hotkey
            })
        end
        engine.saveData()
        sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}ѕресет успешно добавлен в вашу базу!", -1)
    end
    MFT.state.previewPresetId = -1
end

function utils.applyThemePreset(preset_id)
    if type(preset_id) == "string" and preset_id:find("custom_") then
        local idx = tonumber(preset_id:match("%d+"))
        if MFT.settings.savedThemes and MFT.settings.savedThemes[idx] then
            local t = MFT.settings.savedThemes[idx]
            MFT.settings.colorBg = {t.bg[1], t.bg[2], t.bg[3], 1.0}
            MFT.settings.colorSidebar = {t.sidebar[1], t.sidebar[2], t.sidebar[3], 1.0}
            MFT.settings.colorBtn = {t.btn[1], t.btn[2], t.btn[3], 1.0}
            MFT.settings.colorAccent = {t.accent[1], t.accent[2], t.accent[3], 1.0}
            MFT.settings.colorText = {t.text[1], t.text[2], t.text[3], 1.0}
        end
    elseif uistate.pThemes[preset_id] then
        MFT.settings.colorBg = {0.06, 0.06, 0.06, 1.0}
        MFT.settings.colorSidebar = {0.10, 0.10, 0.10, 1.0}
        MFT.settings.colorBtn = {0.15, 0.15, 0.15, 1.0}
        MFT.settings.colorAccent = {uistate.pThemes[preset_id].col[1], uistate.pThemes[preset_id].col[2], uistate.pThemes[preset_id].col[3], 1.0}
        MFT.settings.colorText = {0.95, 0.95, 0.95, 1.0}
    end
    MFT.settings.activeThemeId = preset_id
    engine.saveData()
end

function utils.OpenEditModal(index, bind, dash)
    MFT.state.editingModalIndex = index
    ffi.copy(uistate.newBindName, u8(bind.name or ""))
    local lC = ""
    if type(bind.lines) == "table" then
        local dL = {}
        for _, l in ipairs(bind.lines) do table.insert(dL, u8(l)) end
        lC = table.concat(dL, "\n")
    end
    ffi.copy(uistate.newBindText, lC)
    uistate.newBindDelay[0] = bind.delay or 1000
    uistate.newBindOverlay[0] = bind.showInOverlay == nil and true or bind.showInOverlay
    uistate.newBindHotkey[0] = bind.hotkey or 0
    dash.anims.capturingHotkeyModal = false
end

return utils