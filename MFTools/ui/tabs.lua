-- Файл: MFTools/ui/tabs.lua
local imgui = require "mimgui"
local ffi = require "ffi"
local vk = require "vkeys"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local engine = require "MFTools.core.engine"
local utils = require "MFTools.ui.utils"
local uistate = require "MFTools.ui.uistate"
local presets_data = require "MFTools.data.presets"

local tab_about = require "MFTools.ui.tab_about"
local tab_binds = require "MFTools.ui.tab_binds"
local tab_create = require "MFTools.ui.tab_create"
local tab_settings = require "MFTools.ui.tab_settings"
local tab_radial = require "MFTools.ui.tab_radial"
local tab_interactions = require "MFTools.ui.tab_interactions"

local tabs = {}

function tabs.init(dash)
end

function tabs.onTabChange(tabIndex)
    MFT.state.currentTab = tabIndex
    ffi.copy(uistate.newBindName, "")
    ffi.copy(uistate.newBindText, "")
    uistate.newBindDelay[0] = 1000
    uistate.newBindOverlay[0] = true
    uistate.newBindHotkey[0] = 0
end

function tabs.drawDialog(sw, sh, accentColorVec)
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, 1.0)
    imgui.SetNextWindowPos(imgui.ImVec2(sw/2, sh/2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.98))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(accentColorVec.x, accentColorVec.y, accentColorVec.z, 0.8))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
    imgui.Begin(u8"Ожидание ввода", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
    
    if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
    utils.CenterText(u8"Ожидание ввода данных", accentColorVec)
    if MFT.fonts.title then imgui.PopFont() end
    imgui.Separator(); imgui.Spacing()
    
    utils.CenterText(MFT.state.dialogPrompt)
    imgui.Spacing(); imgui.Spacing()
    
    imgui.PushItemWidth(300)
    local inputX = (imgui.GetWindowWidth() - 300) / 2
    imgui.SetCursorPosX(inputX)
    imgui.InputText("##dialoginput", MFT.state.dialogText, 256)
    imgui.PopItemWidth()
    
    imgui.Spacing(); imgui.Spacing()
    imgui.SetCursorPosX(inputX)
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(accentColorVec.x, accentColorVec.y, accentColorVec.z, 1.0))
    if imgui.Button(u8"Продолжить", imgui.ImVec2(300, 40)) or imgui.IsKeyPressed(vk.VK_RETURN) then MFT.state.dialogActive = false end
    imgui.PopStyleColor(); imgui.PopStyleVar()
    
    imgui.End()
    imgui.PopStyleVar(2); imgui.PopStyleColor(2); imgui.PopStyleVar()
end

function tabs.drawContent(dash, dt, c_accent, sb_color, c_text)
    local availWidth = imgui.GetContentRegionAvail().x
    
    if MFT.state.currentTab == 1 then
        tab_about.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    elseif MFT.state.currentTab == 2 then
        tab_binds.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    elseif MFT.state.currentTab == 3 then
        tab_create.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    elseif MFT.state.currentTab == 4 then
        tab_settings.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    elseif MFT.state.currentTab == 5 then
        tab_radial.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    elseif MFT.state.currentTab == 6 then
        tab_interactions.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    end
end

function tabs.drawModalsAndOverlay(dash, dt, c_accent, sw, sh)
    if dash.anims.presetModalOpen > 0.01 and MFT.state.previewPresetId ~= -1 then
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, dash.anims.presetModalOpen)
        
        local mw, mh = 920, 620
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2 - mw/2, sh/2 - mh/2), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(mw, mh), imgui.Cond.Always)
        
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.98))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 15.0)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(25, 25))
        
        if MFT.fonts.main then imgui.PushFont(MFT.fonts.main) end
        imgui.Begin("PresetModal", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
        
        local fName = ""
        for _, f in ipairs(uistate.factions) do if f.id == MFT.state.previewPresetId then fName = f.name break end end
        
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
        utils.CenterText(u8"Предпросмотр: " .. fName, c_accent)
        if MFT.fonts.title then imgui.PopFont() end
        imgui.Separator(); imgui.Spacing()
        
        if type(MFT.state.folderPath) == "table" and #MFT.state.folderPath > 0 then
            utils.CenterText(u8"Эти бинды загрузятся прямо в открытую папку")
        else
            utils.CenterText(u8"Эти бинды загрузятся в корень вашей базы")
        end
        imgui.Spacing(); imgui.Spacing()
        
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.04, 0.04, 0.04, 1.0))
        imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, 8.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(20, 20))
        imgui.BeginChild("PM_List", imgui.ImVec2(-1, 390), true, imgui.WindowFlags.AlwaysVerticalScrollbar)
        
        local prData = presets_data[MFT.state.previewPresetId]
        if prData then
            local dl = imgui.GetWindowDrawList()
            for i, bind in ipairs(prData) do
                local startPos = imgui.GetCursorScreenPos()
                
                if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
                imgui.SetCursorPosX(imgui.GetCursorPosX() + 15)
                imgui.TextColored(c_accent, tostring(i) .. ". " .. (bind.name and u8(bind.name) or u8"Бинд"))
                if MFT.fonts.title then imgui.PopFont() end
                
                imgui.Spacing()
                
                for j, line in ipairs(bind.lines) do
                    imgui.SetCursorPosX(imgui.GetCursorPosX() + 25)
                    imgui.PushTextWrapPos(imgui.GetWindowWidth() - 30)
                    imgui.TextColored(imgui.ImVec4(0.85, 0.85, 0.85, 1.0), u8(utils.sanitizePresetText(line)))
                    imgui.PopTextWrapPos()
                end
                
                local endPos = imgui.GetCursorScreenPos()
                dl:AddLine(imgui.ImVec2(startPos.x + 8, startPos.y + 5), imgui.ImVec2(startPos.x + 8, endPos.y - 5), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.6)), 3.0)
                imgui.Spacing(); imgui.Separator(); imgui.Spacing(); imgui.Spacing()
            end
        end
        imgui.EndChild()
        imgui.PopStyleColor(); imgui.PopStyleVar(2)
        
        imgui.Spacing(); imgui.Spacing()
        
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0))
        local btnW = (imgui.GetContentRegionAvail().x - 15) / 2
        
        if imgui.Button(u8"Добавить базу", imgui.ImVec2(btnW, 45)) then
            if prData then
                local currentList = MFT.binds
                if type(MFT.state.folderPath) == "table" then
                    for _, idx in ipairs(MFT.state.folderPath) do
                        if currentList[idx] then currentList = currentList[idx].items end
                    end
                end
                
                local function deepcopy(orig)
                    local copy = {}
                    for k, v in pairs(orig) do
                        if type(v) == 'table' then copy[k] = deepcopy(v) else copy[k] = v end
                    end
                    return copy
                end
                
                for _, b in ipairs(prData) do table.insert(currentList, deepcopy(b)) end
                engine.saveData()
                sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Пресет успешно загружен!", -1)
            end
            MFT.state.previewPresetId = -1
        end
        imgui.PopStyleColor()
        
        imgui.SameLine(0, 15)
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.4))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
        if imgui.Button(u8"Отмена", imgui.ImVec2(btnW, 45)) then MFT.state.previewPresetId = -1 end
        imgui.PopStyleColor(2)
        imgui.PopStyleVar()
        
        imgui.End()
        if MFT.fonts.main then imgui.PopFont() end
        imgui.PopStyleVar(3); imgui.PopStyleColor(2)
        imgui.PopStyleVar()
    end

    if dash.anims.editModalOpen > 0.01 and MFT.state.editingModalIndex ~= -1 then
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, dash.anims.editModalOpen)
        local mw, mh = 800, 520
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2 - mw/2, sh/2 - mh/2), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(mw, mh), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.98))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 15.0)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(25, 25))
        
        if MFT.fonts.main then imgui.PushFont(MFT.fonts.main) end
        imgui.Begin("EditBindModal", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
        
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
        utils.CenterText(u8"Настройка", c_accent)
        if MFT.fonts.title then imgui.PopFont() end
        imgui.Separator(); imgui.Spacing(); imgui.Spacing()
        
        imgui.Columns(2, "em_name_hk_cols", false)
        imgui.SetColumnWidth(0, (mw - 50) * 0.65)
        
        imgui.Text(u8"Название:")
        imgui.PushItemWidth(-1)
        imgui.InputText("##em_Name", uistate.newBindName, ffi.sizeof(uistate.newBindName))
        imgui.PopItemWidth()
        
        imgui.NextColumn()
        imgui.Text(u8"Кнопка активации:")
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        if dash.anims.capturingHotkeyModal then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.5, 0.2, 0.6))
            if imgui.Button(u8"Ожидание...##em_hk", imgui.ImVec2(-1, 30)) then dash.anims.capturingHotkeyModal = false end
            imgui.PopStyleColor()
            for k = 8, 255 do
                if imgui.IsKeyPressed(k) then
                    if k == vk.VK_BACK or k == vk.VK_ESCAPE then uistate.newBindHotkey[0] = 0
                    else uistate.newBindHotkey[0] = k end
                    dash.anims.capturingHotkeyModal = false
                    break
                end
            end
        else
            local kn = (uistate.newBindHotkey[0] == 0) and u8"Не назначена" or vk.id_to_name(uistate.newBindHotkey[0])
            if imgui.Button(kn.."##em_hk", imgui.ImVec2(-1, 30)) then dash.anims.capturingHotkeyModal = true end
        end
        imgui.PopStyleVar()
        imgui.Columns(1)
        
        imgui.Spacing(); imgui.Spacing()
        
        imgui.Text(u8"Текст (Enter = новая строка):")
        imgui.InputTextMultiline("##em_Text", uistate.newBindText, ffi.sizeof(uistate.newBindText), imgui.ImVec2(-1, 180))
        imgui.Spacing(); imgui.Spacing()
        
        imgui.Columns(2, "em_delay_ovl_cols", false)
        imgui.SetColumnWidth(0, (mw - 50) * 0.65)
        
        imgui.Text(u8"Задержка между строками (мс):")
        imgui.PushItemWidth(-1)
        imgui.SliderInt("##em_Delay", uistate.newBindDelay, 100, 5000)
        imgui.PopItemWidth()
        
        imgui.NextColumn()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 20)
        imgui.Checkbox(u8"Видно в оверлее", uistate.newBindOverlay)
        imgui.Columns(1)
        
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0))
        local btnW = (imgui.GetContentRegionAvail().x - 15) / 2
        if imgui.Button(u8"Сохранить", imgui.ImVec2(btnW, 45)) then
            local nameStr, textStr = ffi.string(uistate.newBindName), ffi.string(uistate.newBindText)
            if #nameStr > 0 and #textStr > 0 then
                local lines = {}
                for line in textStr:gmatch("[^\r\n]+") do table.insert(lines, u8:decode(line)) end
                
                local currentList = MFT.binds
                if type(MFT.state.folderPath) == "table" then
                    for _, idx in ipairs(MFT.state.folderPath) do
                        if currentList[idx] then currentList = currentList[idx].items end
                    end
                end
                
                local targetBind = currentList[MFT.state.editingModalIndex]
                if targetBind then
                    targetBind.name = u8:decode(nameStr)
                    targetBind.lines = lines
                    targetBind.delay = tonumber(uistate.newBindDelay[0])
                    targetBind.showInOverlay = (uistate.newBindOverlay[0] == true)
                    targetBind.hotkey = tonumber(uistate.newBindHotkey[0])
                end
                
                engine.saveData(); sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Изменения сохранены!", -1)
                MFT.state.editingModalIndex = -1
            end
        end
        imgui.PopStyleColor()
        
        imgui.SameLine(0, 15)
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.4))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
        if imgui.Button(u8"Отмена", imgui.ImVec2(btnW, 45)) then MFT.state.editingModalIndex = -1 end
        imgui.PopStyleColor(2)
        imgui.PopStyleVar()
        
        imgui.End()
        if MFT.fonts.main then imgui.PopFont() end
        imgui.PopStyleVar(3); imgui.PopStyleColor(2)
        imgui.PopStyleVar()
    end

    -- === СИСТЕМА УМНЫХ ОВЕРЛЕЕВ (С ПОДОКНАМИ) ===
    if type(MFT.state.ovlWindows) ~= "table" or #MFT.state.ovlWindows == 0 then
        MFT.state.ovlWindows = { { path = {}, pos = nil } }
    end

    local current_ovl_w = ffi.new("float[1]", MFT.settings.overlayWidth or 220.0)
    local isScrollMode = MFT.settings.overlayScrollMode == nil and true or MFT.settings.overlayScrollMode
    local max_items = MFT.settings.overlayMaxItems or 10

    if dash.anims.overlayOpen > 0.01 or MFT.state.isPlacingOverlay then
        if MFT.fonts.main then imgui.PushFont(MFT.fonts.main) end
        
        for ovlIdx, ovlData in ipairs(MFT.state.ovlWindows) do
            local ovlList = MFT.binds
            local ovlTitle = u8"База биндов"
            
            for _, idx in ipairs(ovlData.path) do
                if ovlList[idx] then
                    ovlTitle = u8(ovlList[idx].name or "Папка")
                    ovlList = ovlList[idx].items or {}
                end
            end

            local activeCount = 0 
            for _, b in ipairs(ovlList) do 
                if (b.showInOverlay == nil and true or b.showInOverlay) then activeCount = activeCount + 1 end 
            end
            if activeCount == 0 then activeCount = 1 end
            
            local fixedH = isScrollMode and (MFT.settings.overlayHeight or 250.0) or (55.0 + (math.min(activeCount, max_items) * 40.0))
            if fixedH < 50.0 then fixedH = 250.0 end

            local nx = (ovlIdx == 1) and (tonumber(MFT.settings.overlayX) or 20.0) or ovlData.pos.x
            local ny = (ovlIdx == 1) and (tonumber(MFT.settings.overlayY) or 300.0) or ovlData.pos.y

            if MFT.state.isPlacingOverlay and ovlIdx == 1 then
                local mp = imgui.GetMousePos()
                nx = math.floor(tonumber(mp.x))
                ny = math.floor(tonumber(mp.y))
                local ovl_w = math.floor(tonumber(current_ovl_w[0]))
                
                if nx < 0.0 then nx = 0.0 end; if nx > sw - ovl_w then nx = sw - ovl_w end
                if ny < 0.0 then ny = 0.0 end; if ny > sh - fixedH then ny = sh - fixedH end
                MFT.settings.overlayX = nx; MFT.settings.overlayY = ny
                
                local dl = imgui.GetBackgroundDrawList()
                local hintText = u8"Пробел - сохранить"
                local boxMin = imgui.ImVec2(nx, ny - 35)
                local boxMax = imgui.ImVec2(nx + imgui.CalcTextSize(hintText).x + 20, ny - 5)
                dl:AddRectFilled(boxMin, boxMax, imgui.GetColorU32Vec4(imgui.ImVec4(0.08, 0.07, 0.12, 0.95)), 6.0)
                dl:AddRect(boxMin, boxMax, imgui.GetColorU32Vec4(c_accent), 6.0, 0, 1.2)
                dl:AddText(imgui.ImVec2(nx + 10, ny - 28), imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, 1)), hintText)
            end
            
            local slideX = (1.0 - dash.anims.overlayOpen) * -30.0
            imgui.SetNextWindowPos(imgui.ImVec2(nx + slideX, ny), imgui.Cond.Always)
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, dash.anims.overlayOpen)
            imgui.SetNextWindowSize(imgui.ImVec2(tonumber(current_ovl_w[0]), fixedH), imgui.Cond.Always)
            
            -- ФИКС СЛОЕВ: Принудительный фокус на новое окно (поверх всех)
            if MFT.state.focusOverlay == ovlIdx then
                imgui.SetNextWindowFocus()
                if ovlIdx == #MFT.state.ovlWindows then MFT.state.focusOverlay = nil end
            end
            
            local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
            if not isScrollMode then flags = bit.bor(flags, imgui.WindowFlags.NoScrollbar) end
            if not sampIsChatInputActive() and not MFT.state.isPlacingOverlay then flags = bit.bor(flags, imgui.WindowFlags.NoInputs) end
            
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 15.0)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 15))
            imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 8.0)
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 1.5)
            
            imgui.Begin("MFToolsOverlay_" .. ovlIdx, imgui.new.bool(true), flags)
            
            -- Кнопка закрытия (маленькая справа) для дополнительных оверлеев
            if ovlIdx > 1 then
                imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - 35, 12))
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0,0,0,0))
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0))
                if imgui.Button("X##close_ovl_"..ovlIdx, imgui.ImVec2(20, 20)) then
                    while #MFT.state.ovlWindows >= ovlIdx do table.remove(MFT.state.ovlWindows) end
                    imgui.PopStyleColor(2)
                    if isScrollMode then imgui.EndChild() end
                    imgui.End()
                    imgui.PopStyleVar(4); imgui.PopStyleColor(1)
                    break 
                end
                imgui.PopStyleColor(2)
                imgui.SetCursorPos(imgui.ImVec2(15, 15)) -- возвращаем курсор
            end

            if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
            utils.CenterText(ovlTitle, c_accent)
            if MFT.fonts.title then imgui.PopFont() end
            
            imgui.Separator(); imgui.Spacing()
            
            if isScrollMode then imgui.BeginChild("OvlScrollRegion_"..ovlIdx, imgui.ImVec2(-1, -1), false, imgui.WindowFlags.AlwaysVerticalScrollbar) end
            
            imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
            
            local displayed = 0
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.4))
            
            for i, bind in ipairs(ovlList) do
                if bind.showInOverlay == nil and true or bind.showInOverlay then
                    displayed = displayed + 1
                    if displayed > max_items and not isScrollMode then break end
                    
                    if bind.type == "folder" then
                        local fName = bind.name and u8(bind.name) or u8"Папка"
                        
                        -- Выделяем папку жирным шрифтом и цветом темы
                        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0))
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.15))
                        
                        if imgui.Button(fName .. "##ovl_f_" .. ovlIdx .. "_" .. i, imgui.ImVec2(-1, 35)) then
                            -- Закрываем все окна, которые были открыты ПОСЛЕ текущего
                            while #MFT.state.ovlWindows > ovlIdx do table.remove(MFT.state.ovlWindows) end
                            
                            local newPath = {}
                            for _, p in ipairs(ovlData.path) do table.insert(newPath, p) end
                            table.insert(newPath, i)
                            
                            local mp = imgui.GetMousePos()
                            
                            -- УМНЫЙ РАСЧЕТ ОВЕРЛЕЯ
                            local newCount = 0
                            for _, b in ipairs(bind.items or {}) do if b.showInOverlay ~= false then newCount = newCount + 1 end end
                            if newCount == 0 then newCount = 1 end
                            local newFixedH = isScrollMode and (MFT.settings.overlayHeight or 250.0) or (55.0 + (math.min(newCount, max_items) * 40.0))
                            if newFixedH < 50.0 then newFixedH = 250.0 end
                            local newW = tonumber(current_ovl_w[0])
                            
                            local targetX = mp.x + 10
                            local targetY = mp.y - 10
                            
                            -- Если нет места справа, открываем влево
                            if targetX + newW > sw then targetX = mp.x - newW - 10 end
                            -- Если нет места снизу, открываем вверх
                            if targetY + newFixedH > sh then targetY = mp.y - newFixedH + 10 end
                            
                            if targetY < 0 then targetY = 10 end
                            if targetX < 0 then targetX = 10 end
                            
                            table.insert(MFT.state.ovlWindows, { path = newPath, pos = { x = targetX, y = targetY } })
                            MFT.state.focusOverlay = #MFT.state.ovlWindows
                        end
                        imgui.PopStyleColor(2)
                        if MFT.fonts.title then imgui.PopFont() end
                    else
                        local bName = bind.name and u8(bind.name) or u8"Без названия"
                        if imgui.Button(bName .. "##ovl_btn_" .. ovlIdx .. "_" .. i, imgui.ImVec2(-1, 35)) then 
                            engine.executeBind(bind) 
                            -- АВТОЗАКРЫТИЕ ПОДОКНА ПРИ ЗАПУСКЕ БИНДА
                            if ovlIdx > 1 then
                                while #MFT.state.ovlWindows > 1 do table.remove(MFT.state.ovlWindows) end
                            end
                        end
                    end
                    imgui.Spacing()
                end
            end
            imgui.PopStyleColor(); imgui.PopStyleVar()
            
            if displayed == 0 then utils.CenterText(u8"Пусто", imgui.ImVec4(0.6, 0.6, 0.6, 1.0)) end
            if isScrollMode then imgui.EndChild() end
            imgui.End()
            
            imgui.PopStyleVar(4); imgui.PopStyleColor(1)
        end
        if MFT.fonts.main then imgui.PopFont() end
    end
end

return tabs