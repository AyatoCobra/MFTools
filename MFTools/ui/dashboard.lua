-- Файл: MFTools/ui/dashboard.lua
local imgui = require "mimgui"
local ffi = require "ffi"
local vk = require "vkeys"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local theme = require "MFTools.ui.theme"
local engine = require "MFTools.core.engine"
local tabs = require "MFTools.ui.tabs"

local dashboard = {}
dashboard.icons = nil

dashboard.anims = {
    menuOpen = 0.0, overlayOpen = 0.0, dialogOpen = 0.0, presetModalOpen = 0.0,
    editModalOpen = 0.0, customThemeModalOpen = 0.0, colorPickerModalOpen = 0.0,
    tabSwitch = 1.0, currentTab = 1, viewToggle = nil, cardCascade = {}, hover = {},
    capturingHotkeyCreate = false, capturingHotkeyModal = false, capturingHotkeyBase = -1, presetsExpanded = 0.0,
    f8Notif = 0.0, seqOvl = 0.0
}

local function getHover(id, isHovered, speed)
    speed = speed or 12.0
    dashboard.anims.hover[id] = dashboard.anims.hover[id] or 0.0
    local target = isHovered and 1.0 or 0.0
    dashboard.anims.hover[id] = dashboard.anims.hover[id] + (target - dashboard.anims.hover[id]) * math.min(1.0, speed * imgui.GetIO().DeltaTime)
    return dashboard.anims.hover[id]
end

function dashboard.shouldDraw()
    local ovl = MFT.settings.overlayEnabled == nil and true or MFT.settings.overlayEnabled
    local showOvl = ovl
    if showOvl and MFT.settings.overlayOnlyOnChat then showOvl = isSampAvailable() and sampIsChatInputActive() or false end
    
    local showF8 = (MFT.state.f8NotifTimer and os.clock() < MFT.state.f8NotifTimer) or (dashboard.anims.f8Notif > 0.01)
    local showSeq = (MFT.settings.seqOverlay and MFT.settings.seqOverlay.enabled) or MFT.state.isPlacingSeqOverlay or (dashboard.anims.seqOvl > 0.01)
    
    return MFT.state.isMenuOpen or MFT.state.dialogActive or showOvl or MFT.state.isPlacingOverlay or MFT.state.isPlacingAROverlay or MFT.state.isCalibratingScreen
        or (dashboard.anims.menuOpen > 0.01) or (dashboard.anims.dialogOpen > 0.01) or (dashboard.anims.overlayOpen > 0.01)
        or MFT.state.ar.isRunning or showF8 or showSeq
end

function dashboard.updateState(uiFrame)
    local menu = dashboard.anims.menuOpen > 0.01
    local dialog = dashboard.anims.dialogOpen > 0.01
    local modal1 = dashboard.anims.presetModalOpen > 0.01
    local modal2 = dashboard.anims.customThemeModalOpen > 0.01
    local modal3 = dashboard.anims.editModalOpen > 0.01
    local modal4 = dashboard.anims.colorPickerModalOpen > 0.01
    local ovl = MFT.settings.overlayEnabled == nil and true or MFT.settings.overlayEnabled
    local chat = isSampAvailable() and sampIsChatInputActive() or false
    
    uiFrame.HideCursor = not (menu or dialog or modal1 or modal2 or modal3 or modal4 or (ovl and chat) or MFT.state.isPlacingOverlay or MFT.state.isPlacingAROverlay or MFT.state.isCalibratingScreen or MFT.state.isPlacingSeqOverlay)
end

function dashboard.processOverlayPlacement()
    if MFT.state.isPlacingOverlay and os.clock() > MFT.state.placingTimer then
        if wasKeyPressed(vk.VK_SPACE) then
            MFT.state.isPlacingOverlay = false
            MFT.state.isMenuOpen = true
            engine.saveData()
            sampAddChatMessage(u8:decode(u8"{88FF88}[MFTools] {FFFFFF}Позиция оверлея сохранена!"), -1)
        end
    end
    if MFT.state.isPlacingAROverlay and os.clock() > MFT.state.placingTimer then
        if wasKeyPressed(vk.VK_SPACE) then
            MFT.state.isPlacingAROverlay = false
            MFT.state.isMenuOpen = true
            engine.saveData()
            sampAddChatMessage(u8:decode(u8"{88FF88}[MFTools] {FFFFFF}Позиция автодокладов сохранена!"), -1)
        end
    end
    if MFT.state.isPlacingSeqOverlay and os.clock() > MFT.state.placingTimer then
        if wasKeyPressed(vk.VK_SPACE) then
            MFT.state.isPlacingSeqOverlay = false
            MFT.state.isMenuOpen = true
            engine.saveData()
            sampAddChatMessage(u8:decode(u8"{88FF88}[MFTools] {FFFFFF}Позиция пошаговых биндов сохранена!"), -1)
        end
    end
end

function dashboard.draw()
    local dt = imgui.GetIO().DeltaTime
    
    dashboard.anims.menuOpen = dashboard.anims.menuOpen + ((MFT.state.isMenuOpen and 1.0 or 0.0) - dashboard.anims.menuOpen) * math.min(1.0, 15.0 * dt)
    dashboard.anims.dialogOpen = dashboard.anims.dialogOpen + ((MFT.state.dialogActive and 1.0 or 0.0) - dashboard.anims.dialogOpen) * math.min(1.0, 15.0 * dt)
    dashboard.anims.presetModalOpen = dashboard.anims.presetModalOpen + (((MFT.state.previewPresetId ~= -1) and 1.0 or 0.0) - dashboard.anims.presetModalOpen) * math.min(1.0, 15.0 * dt)
    dashboard.anims.customThemeModalOpen = dashboard.anims.customThemeModalOpen + ((MFT.state.isCustomThemeOpen and 1.0 or 0.0) - dashboard.anims.customThemeModalOpen) * math.min(1.0, 15.0 * dt)
    dashboard.anims.editModalOpen = dashboard.anims.editModalOpen + (((MFT.state.editingModalIndex ~= -1) and 1.0 or 0.0) - dashboard.anims.editModalOpen) * math.min(1.0, 15.0 * dt)
    dashboard.anims.colorPickerModalOpen = dashboard.anims.colorPickerModalOpen + ((MFT.state.colorPickerActive and 1.0 or 0.0) - dashboard.anims.colorPickerModalOpen) * math.min(1.0, 15.0 * dt)
    
    local showOvl = MFT.settings.overlayEnabled == nil and true or MFT.settings.overlayEnabled
    if showOvl and MFT.settings.overlayOnlyOnChat then showOvl = isSampAvailable() and sampIsChatInputActive() or false end
    dashboard.anims.overlayOpen = dashboard.anims.overlayOpen + ((showOvl and 1.0 or 0.0) - dashboard.anims.overlayOpen) * math.min(1.0, 12.0 * dt)
    
    local tPresets = MFT.state.presetsExpanded and 1.0 or 0.0
    dashboard.anims.presetsExpanded = dashboard.anims.presetsExpanded + (tPresets - dashboard.anims.presetsExpanded) * math.min(1.0, 15.0 * dt)

    if dashboard.anims.currentTab ~= MFT.state.currentTab then
        dashboard.anims.tabSwitch = 0.1
        dashboard.anims.currentTab = MFT.state.currentTab
        dashboard.anims.cardCascade = {} 
    end
    dashboard.anims.tabSwitch = dashboard.anims.tabSwitch + (1.0 - dashboard.anims.tabSwitch) * math.min(1.0, 8.0 * dt)

    if dashboard.icons == nil then
        dashboard.icons = { presets = {} }
        local pFiles = {"list.png", "grid.png", "POLICE.png", "FBI.png", "MZ.png", "SMI.png", "PRAVO.png", "ghetto.png", "KB.png", "biker.png", "SV.png", "ALCATRAZ.png", "sc.png"}
        for i, file in ipairs(pFiles) do
            local path = MFT.paths.assets .. file
            local f = io.open(path, "rb")
            if f then 
                f:close()
                if i == 1 then dashboard.icons.list = imgui.CreateTextureFromFile(path)
                elseif i == 2 then dashboard.icons.grid = imgui.CreateTextureFromFile(path)
                else dashboard.icons.presets[i-2] = imgui.CreateTextureFromFile(path) end
            end
        end
    end

    if not MFT.settings.colorBg then MFT.settings.colorBg = {0.06, 0.06, 0.06, 1.0} end
    if not MFT.settings.colorSidebar then MFT.settings.colorSidebar = {0.10, 0.10, 0.10, 1.0} end
    if not MFT.settings.colorBtn then MFT.settings.colorBtn = {0.15, 0.15, 0.15, 1.0} end
    if not MFT.settings.colorAccent then MFT.settings.colorAccent = {0.35, 0.55, 0.85, 1.0} end
    if not MFT.settings.colorText then MFT.settings.colorText = {0.95, 0.95, 0.95, 1.0} end

    local sw, sh = getScreenResolution()
    local c_accent = MFT.settings.colorAccent
    local accentColorVec = imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0)
    local sb_color = MFT.settings.colorSidebar
    local c_text = MFT.settings.colorText
    local tAlpha = MFT.settings.menuTransparency or 0.98
    local dIntens = MFT.settings.dimmingIntensity or 0.80
    
    theme.applyGlobalStyle()
    tabs.init(dashboard)

    if dashboard.anims.dialogOpen > 0.01 then tabs.drawDialog(sw, sh, accentColorVec) end

    if dashboard.anims.menuOpen > 0.01 then
        local bgDl = imgui.GetBackgroundDrawList()
        bgDl:AddRectFilled(imgui.ImVec2(0, 0), imgui.ImVec2(sw, sh), imgui.GetColorU32Vec4(imgui.ImVec4(0, 0, 0, dIntens * dashboard.anims.menuOpen)))
        
        if MFT.fonts.main then imgui.PushFont(MFT.fonts.main) end
        
        local winW, winH = 1280, 780
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.Always)
        local slideY = (1.0 - dashboard.anims.menuOpen) * 40.0
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2 - winW/2, (sh/2 - winH/2) + slideY), imgui.Cond.Always)
        
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(MFT.settings.colorBg[1], MFT.settings.colorBg[2], MFT.settings.colorBg[3], tAlpha))
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, dashboard.anims.menuOpen)
        imgui.Begin("MFTools Main Window", imgui.new.bool(true), imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings)
        
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(sb_color[1], sb_color[2], sb_color[3], 0.8))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.6))
        imgui.PushStyleVarFloat(imgui.StyleVar.ChildBorderSize, 2.0)
        imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, 15.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(20, 12))
        imgui.BeginChild("TopBar", imgui.ImVec2(0, 75), true, imgui.WindowFlags.NoScrollbar)
        
        if MFT.fonts.logo then imgui.PushFont(MFT.fonts.logo) end
        imgui.SetCursorPos(imgui.ImVec2(25, 12))
        imgui.TextColored(accentColorVec, "%s", "MFTools")
        if MFT.fonts.logo then imgui.PopFont() end
        
        -- === ДИНАМИЧЕСКИЙ ВЫВОД ВЕРСИИ СКРИПТА ===
        if MFT.fonts.small then imgui.PushFont(MFT.fonts.small) end
        imgui.SetCursorPos(imgui.ImVec2(30, 44))
        imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), "%s", "v" .. tostring(MFT.version or "1.0"))
        if MFT.fonts.small then imgui.PopFont() end
        -- =========================================
        
        local tabNames = {u8"О скрипте", u8"База биндов", u8"Создание бинда", u8"Настройки", u8"Радиал меню", u8"Взаимодействия"}
        local tabWidth = 150
        local tabSpacing = 5
        local totalTabsW = (#tabNames * tabWidth) + ((#tabNames - 1) * tabSpacing)
        
        local startX = (winW - totalTabsW) / 2
        if startX < 150 then startX = 150 end 
        
        imgui.SameLine(startX)
        imgui.SetCursorPosY(13)
        
        local dl = imgui.GetWindowDrawList()
        for i, t in ipairs(tabNames) do
            local isActive = (MFT.state.currentTab == i)
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0, 0, 0, 0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0, 0, 0, 0))
            
            local cpos = imgui.GetCursorScreenPos()
            if imgui.Button("##toptab_"..i, imgui.ImVec2(tabWidth, 48)) then
                MFT.state.currentTab = i
                dashboard.anims.capturingHotkeyCreate = false
                tabs.onTabChange(i)
            end
            
            local isHovered = imgui.IsItemHovered()
            local anim_hover = getHover("tab_h_"..i, isHovered, 15.0)
            local anim_active = getHover("tab_a_"..i, isActive, 15.0)
            
            local cX, cY = cpos.x, cpos.y
            local w, h = tabWidth, 48
            
            local p1 = imgui.ImVec2(cX + 8, cY)
            local p2 = imgui.ImVec2(cX + w - 8, cY)
            local p3 = imgui.ImVec2(cX + w, cY + 8)
            local p4 = imgui.ImVec2(cX + w, cY + h - 8)
            local p5 = imgui.ImVec2(cX + w - 8, cY + h)
            local p6 = imgui.ImVec2(cX + 8, cY + h)
            local p7 = imgui.ImVec2(cX, cY + h - 8)
            local p8 = imgui.ImVec2(cX, cY + 8)
            
            local bgAlpha = 0.05 + (0.10 * anim_hover) + (0.25 * anim_active)
            dl:AddConvexPolyFilled(ffi.new("ImVec2[8]", {p1, p2, p3, p4, p5, p6, p7, p8}), 8, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], bgAlpha)))
            
            local lineAlpha = 0.3 + (0.3 * anim_hover) + (0.4 * anim_active)
            local thickness = 1.0 + (1.5 * anim_active) 
            local lineCol = imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], lineAlpha))
            
            dl:AddPolyline(ffi.new("ImVec2[9]", {p1, p2, p3, p4, p5, p6, p7, p8, p1}), 9, lineCol, false, thickness)
            
            local textCol = imgui.GetColorU32Vec4(imgui.ImVec4(c_text[1], c_text[2], c_text[3], 0.5 + (0.3 * anim_hover) + (0.2 * anim_active)))
            if isActive then textCol = imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, 1)) end
            
            if MFT.fonts.main then imgui.PushFont(MFT.fonts.main) end
            local tSize = imgui.CalcTextSize(t)
            dl:AddText(imgui.ImVec2(cX + (w - tSize.x)/2, cY + (h - tSize.y)/2), textCol, t)
            if MFT.fonts.main then imgui.PopFont() end
            
            imgui.PopStyleColor(3)
            if i < #tabNames then imgui.SameLine(0, tabSpacing) end
        end
        
        imgui.SameLine(winW - 85)
        imgui.SetCursorPosY(13)
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0,0,0,0))
        
        local btnPos = imgui.GetCursorScreenPos()
        if imgui.Button("##closebtn", imgui.ImVec2(48, 48)) then MFT.state.isMenuOpen = false end
        local hClose = getHover("btn_close", imgui.IsItemHovered())
        dl:AddRectFilled(btnPos, imgui.ImVec2(btnPos.x + 48, btnPos.y + 48), imgui.GetColorU32Vec4(imgui.ImVec4(0.9, 0.2, 0.2, 0.1 + (0.5 * hClose))), 12.0)
        local crossCol = imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, 0.6 + (0.4 * hClose)))
        local ccx, ccy = btnPos.x + 24, btnPos.y + 24
        local cSize = 6 + (2 * hClose)
        dl:AddLine(imgui.ImVec2(ccx - cSize, ccy - cSize), imgui.ImVec2(ccx + cSize, ccy + cSize), crossCol, 2.5)
        dl:AddLine(imgui.ImVec2(ccx + cSize, ccy - cSize), imgui.ImVec2(ccx - cSize, ccy + cSize), crossCol, 2.5)
        
        imgui.PopStyleColor(3)
        imgui.EndChild()
        imgui.PopStyleVar(3); imgui.PopStyleColor(2)
        imgui.Spacing(); imgui.Spacing()
        
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(10, 10))
        imgui.BeginChild("MainContent", imgui.ImVec2(0, 0), false, imgui.WindowFlags.AlwaysUseWindowPadding)
        
        local rawAlpha = dashboard.anims.tabSwitch
        local easeOutAlpha = 1.0 - math.pow(1.0 - rawAlpha, 3)
        
        local globalSlideY = (1.0 - easeOutAlpha) * 20.0
        imgui.SetCursorPosY(imgui.GetCursorPosY() + globalSlideY)
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, easeOutAlpha)

        dashboard.cardCounter = 0
        tabs.drawContent(dashboard, dt, accentColorVec, sb_color, c_text)
        
        imgui.PopStyleVar()
        imgui.EndChild() 
        imgui.PopStyleVar()

        imgui.End()
        imgui.PopStyleVar() 
        if MFT.fonts.main then imgui.PopFont() end
    end

    if MFT.state.isCalibratingScreen then
        local sf8 = MFT.settings.smartScreen
        
        imgui.SetNextWindowPos(imgui.ImVec2(sf8.x, sf8.y), imgui.Cond.Appearing)
        imgui.SetNextWindowSize(imgui.ImVec2(sf8.w, sf8.h), imgui.Cond.Appearing)
        
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
        
        imgui.Begin("ScreenCalibrationWin", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoSavedSettings)
        
        local pos = imgui.GetWindowPos()
        local size = imgui.GetWindowSize()
        sf8.x, sf8.y, sf8.w, sf8.h = pos.x, pos.y, size.x, size.y
        
        local dlbg = imgui.GetBackgroundDrawList()
        local cDark = imgui.GetColorU32Vec4(imgui.ImVec4(0, 0, 0, 0.7))
        dlbg:AddRectFilled(imgui.ImVec2(0, 0), imgui.ImVec2(sw, sf8.y), cDark) 
        dlbg:AddRectFilled(imgui.ImVec2(0, sf8.y + sf8.h), imgui.ImVec2(sw, sh), cDark)
        dlbg:AddRectFilled(imgui.ImVec2(0, sf8.y), imgui.ImVec2(sf8.x, sf8.y + sf8.h), cDark)
        dlbg:AddRectFilled(imgui.ImVec2(sf8.x + sf8.w, sf8.y), imgui.ImVec2(sw, sf8.y + sf8.h), cDark)
        
        local dl = imgui.GetWindowDrawList()
        dl:AddRectFilled(pos, imgui.ImVec2(pos.x + size.x, pos.y + 70), imgui.GetColorU32Vec4(imgui.ImVec4(0, 0, 0, 0.85)))
        
        if MFT.fonts.main then imgui.PushFont(MFT.fonts.main) end
        
        local t = u8"КАЛИБРОВКА УМНОГО СКРИНШОТА (Тяните за правый нижний угол)"
        local tSize = imgui.CalcTextSize(t)
        imgui.SetCursorPos(imgui.ImVec2((size.x - tSize.x)/2, 12))
        imgui.TextColored(imgui.ImVec4(1,1,1,1), "%s", t)
        
        local btnSaveW = 120
        local btnCancelW = 100
        local spaceBetween = 15
        local btnsTotalW = btnSaveW + spaceBetween + btnCancelW
        
        imgui.SetCursorPos(imgui.ImVec2((size.x - btnsTotalW)/2, 35))
        
        if imgui.Button(u8"СОХРАНИТЬ", imgui.ImVec2(btnSaveW, 30)) then
            MFT.state.isCalibratingScreen = false
            MFT.state.isMenuOpen = true
            engine.saveData()
            if sf8.showNotif then
                MFT.state.f8NotifText = "Размеры рамки успешно сохранены!"
                MFT.state.f8NotifTimer = os.clock() + 5.0
            end
        end
        imgui.SameLine(0, spaceBetween)
        if imgui.Button(u8"ОТМЕНА", imgui.ImVec2(btnCancelW, 30)) then
            MFT.state.isCalibratingScreen = false
            MFT.state.isMenuOpen = true
        end
        
        if MFT.fonts.main then imgui.PopFont() end
        
        local br_x = pos.x + size.x
        local br_y = pos.y + size.y
        imgui.SetCursorScreenPos(imgui.ImVec2(br_x - 25, br_y - 25))
        imgui.InvisibleButton("##resizerScreen", imgui.ImVec2(25, 25))
        if imgui.IsItemHovered() or imgui.IsItemActive() then imgui.SetMouseCursor(imgui.MouseCursor.ResizeNWSE) end
        
        local c_a = imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0))
        dl:AddLine(imgui.ImVec2(br_x - 14, br_y - 4), imgui.ImVec2(br_x - 4, br_y - 14), c_a, 2.0)
        dl:AddLine(imgui.ImVec2(br_x - 9, br_y - 4), imgui.ImVec2(br_x - 4, br_y - 9), c_a, 2.0)
        
        imgui.End()
        imgui.PopStyleColor(2); imgui.PopStyleVar()
    end
    
    tabs.drawModalsAndOverlay(dashboard, dt, accentColorVec, sw, sh)
    
    -- УВЕДОМЛЕНИЯ УМНОГО СКРИНШОТА
    local showF8Notif = MFT.state.f8NotifTimer and os.clock() < MFT.state.f8NotifTimer
    dashboard.anims.f8Notif = dashboard.anims.f8Notif + ((showF8Notif and 1.0 or 0.0) - dashboard.anims.f8Notif) * math.min(1.0, 15.0 * dt)
    
    if dashboard.anims.f8Notif > 0.01 then
        local slideY = sh + 100 - (180 * dashboard.anims.f8Notif)
        local winName = "ScreenNotifWin"
        
        local text1 = u8"[УМНЫЙ СКРИНШОТ]"
        local text2 = u8(MFT.state.f8NotifText or "Скриншот успешно сохранен!")
        
        local tSize1 = imgui.CalcTextSize(text1)
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title); tSize1 = imgui.CalcTextSize(text1); imgui.PopFont() end
        local tSize2 = imgui.CalcTextSize(text2)
        
        local maxW = math.max(tSize1.x, tSize2.x)
        local windowW = maxW + 80 
        local windowH = 80 
        
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, slideY), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(windowW, windowH), imgui.Cond.Always)
        
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, dashboard.anims.f8Notif)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(MFT.settings.colorBg[1], MFT.settings.colorBg[2], MFT.settings.colorBg[3], 0.95))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.8))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))

        imgui.Begin(winName, nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoFocusOnAppearing + imgui.WindowFlags.NoNav)
        
        imgui.SetCursorPosY(15)
        
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
        imgui.SetCursorPosX((windowW - tSize1.x) / 2)
        imgui.TextColored(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0), "%s", text1)
        if MFT.fonts.title then imgui.PopFont() end
        
        imgui.Spacing()
        
        imgui.SetCursorPosX((windowW - tSize2.x) / 2)
        imgui.TextColored(imgui.ImVec4(1.0, 1.0, 1.0, 1.0), "%s", text2)

        imgui.End()
        
        imgui.PopStyleVar(4)
        imgui.PopStyleColor(2)
    end
    
    local seq = MFT.state.seq
    local showSeqOvl = (MFT.settings.seqOverlay and MFT.settings.seqOverlay.enabled) or MFT.state.isPlacingSeqOverlay
    
    dashboard.anims.seqOvl = dashboard.anims.seqOvl or 0.0
    dashboard.anims.seqOvl = dashboard.anims.seqOvl + ((showSeqOvl and 1.0 or 0.0) - dashboard.anims.seqOvl) * math.min(1.0, 15.0 * dt)
    
    if dashboard.anims.seqOvl > 0.01 then
        local so = MFT.settings.seqOverlay
        
        local winW = 380
        local winH = 175
        
        if MFT.state.isPlacingSeqOverlay then
            local mx, my = imgui.GetMousePos().x, imgui.GetMousePos().y
            so.x = mx - (winW / 2)
            so.y = my - (winH / 2)
        end
        
        imgui.SetNextWindowPos(imgui.ImVec2(so.x, so.y), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.Always)
        
        local ovlAlpha = tonumber(so.alpha) or 0.8
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, dashboard.anims.seqOvl)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(MFT.settings.colorBg[1], MFT.settings.colorBg[2], MFT.settings.colorBg[3], ovlAlpha))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.8))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
        
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(10, 10))
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 4))

        local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings
        if not MFT.state.isPlacingSeqOverlay then flags = flags + imgui.WindowFlags.NoInputs end

        imgui.Begin("SeqOverlayWin", nil, flags)
        
        local dl = imgui.GetWindowDrawList()
        
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
        local tStr = u8"[ПОШАГОВЫЙ БИНД]"
        local tSz = imgui.CalcTextSize(tStr)
        imgui.SetCursorPosX((winW - tSz.x) / 2)
        imgui.TextColored(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0), "%s", tStr)
        if MFT.fonts.title then imgui.PopFont() end
        
        local hkName = (MFT.settings.seqOverlay.hotkey and MFT.settings.seqOverlay.hotkey ~= 0) and vk.id_to_name(MFT.settings.seqOverlay.hotkey) or u8"Не назначена"
        local hkStr = u8"Клавиша: [" .. hkName .. "]"
        
        if MFT.fonts.small then imgui.PushFont(MFT.fonts.small) end
        local hSz = imgui.CalcTextSize(hkStr)
        imgui.SetCursorPosX((winW - hSz.x) / 2)
        imgui.TextColored(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.8), "%s", hkStr)
        if MFT.fonts.small then imgui.PopFont() end
        
        imgui.Separator()
        
        if seq and seq.activeBind then
            local total = #(seq.activeBind.lines)
            local step = seq.step
            
            for i = math.max(1, step - 1), math.min(total, step + 3) do
                local lineText = seq.activeBind.lines[i]
                if #lineText > 40 then lineText = lineText:sub(1, 37) .. "..." end
                
                if i < step then
                    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "%s", u8"[+] " .. u8(lineText))
                elseif i == step then
                    local cp = imgui.GetCursorScreenPos()
                    local fullText = u8" ->  " .. u8(lineText)
                    local itemW = winW - 30
                    dl:AddRectFilled(imgui.ImVec2(cp.x - 5, cp.y - 2), imgui.ImVec2(cp.x + itemW, cp.y + 18), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.3)), 4.0)
                    
                    imgui.TextColored(imgui.ImVec4(1.0, 1.0, 1.0, 1.0), "%s", fullText)
                else
                    imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), "%s", u8"[ ] " .. u8(lineText))
                end
            end
        else
            imgui.Spacing(); imgui.Spacing()
            if MFT.fonts.main then imgui.PushFont(MFT.fonts.main) end
            local s1 = u8"Нет активного сценария."
            local s2 = u8"Включите его в базе."
            imgui.SetCursorPosX((winW - imgui.CalcTextSize(s1).x) / 2)
            imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), "%s", s1)
            imgui.SetCursorPosX((winW - imgui.CalcTextSize(s2).x) / 2)
            imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "%s", s2)
            if MFT.fonts.main then imgui.PopFont() end
        end
        
        if MFT.state.isPlacingSeqOverlay then
            local c_a = imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0))
            local p = imgui.GetWindowPos()
            local winSz = imgui.GetWindowSize()
            dl:AddRect(p, imgui.ImVec2(p.x + winSz.x, p.y + winSz.y), c_a, 12.0, 0, 2.0)
            
            imgui.Spacing()
            imgui.SetCursorPosY(winH - 25)
            if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
            local pt = u8"ПРОБЕЛ - СОХРАНИТЬ"
            local ptSz = imgui.CalcTextSize(pt)
            imgui.SetCursorPosX((winSz.x - ptSz.x) / 2)
            imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.2, 1.0), "%s", pt)
            if MFT.fonts.title then imgui.PopFont() end
        end
        
        imgui.End()
        imgui.PopStyleVar(4); imgui.PopStyleColor(2)
    end
    
    local suggest = require "MFTools.core.suggest"
    suggest.drawUI()
end

return dashboard