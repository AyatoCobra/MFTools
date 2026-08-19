-- Файл: MFTools/ui/tab_settings.lua
local imgui = require "mimgui"
local ffi = require "ffi"
local vk = require "vkeys"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local engine = require "MFTools.core.engine"
local utils = require "MFTools.ui.utils"
local uistate = require "MFTools.ui.uistate"

local tab_settings = {}

local function DrawBounceButton(id, label, size, c_accent, col_bg, col_hov)
    local p = imgui.GetCursorScreenPos()
    local isHovered = imgui.IsMouseHoveringRect(p, imgui.ImVec2(p.x + size.x, p.y + size.y))
    local isActive = isHovered and imgui.IsMouseDown(0)

    MFT.state.btnAnims = MFT.state.btnAnims or {}
    MFT.state.btnAnims[id] = MFT.state.btnAnims[id] or 0.0

    local target = isActive and 1.0 or 0.0
    MFT.state.btnAnims[id] = MFT.state.btnAnims[id] + (target - MFT.state.btnAnims[id]) * 20.0 * imgui.GetIO().DeltaTime
    
    local shrink = MFT.state.btnAnims[id] * 2.5 

    local dl = imgui.GetWindowDrawList()
    local bgCol = isHovered and col_hov or col_bg
    
    dl:AddRectFilled(imgui.ImVec2(p.x + shrink, p.y + shrink), imgui.ImVec2(p.x + size.x - shrink, p.y + size.y - shrink), imgui.GetColorU32Vec4(bgCol), 6.0)
    dl:AddRect(imgui.ImVec2(p.x + shrink, p.y + shrink), imgui.ImVec2(p.x + size.x - shrink, p.y + size.y - shrink), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.5)), 6.0, 0, 1.5)

    local tSize = imgui.CalcTextSize(label)
    dl:AddText(imgui.ImVec2(p.x + (size.x - tSize.x)/2, p.y + (size.y - tSize.y)/2), imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, 1)), label)

    imgui.Dummy(size)
    if isActive and imgui.IsMouseReleased(0) then return true end
    
    imgui.SetCursorScreenPos(p)
    return imgui.InvisibleButton(id, size)
end

local function BeginAccordion(title, c_accent, stateKey, dt, defaultState)
    local p = imgui.GetCursorScreenPos()
    local w = imgui.GetContentRegionAvail().x - 10 
    local h = 45
    local dl = imgui.GetWindowDrawList()
    
    if MFT.settings.accordions[stateKey] == nil then MFT.settings.accordions[stateKey] = defaultState end
    local isOpen = MFT.settings.accordions[stateKey]
    
    local isHovered = imgui.IsMouseHoveringRect(p, imgui.ImVec2(p.x + w, p.y + h))
    if isHovered and imgui.IsMouseClicked(0) then 
        MFT.settings.accordions[stateKey] = not MFT.settings.accordions[stateKey]
        engine.saveData() 
    end
    
    MFT.state.accHovAnims = MFT.state.accHovAnims or {}
    MFT.state.accHovAnims[stateKey] = MFT.state.accHovAnims[stateKey] or 0.0
    local targetHov = isHovered and 1.0 or 0.0
    MFT.state.accHovAnims[stateKey] = MFT.state.accHovAnims[stateKey] + (targetHov - MFT.state.accHovAnims[stateKey]) * math.min(1.0, 15.0 * dt)
    local hov = MFT.state.accHovAnims[stateKey]

    local bgAlpha = 0.05 + (0.10 * hov) + (isOpen and 0.08 or 0.0)
    local bgCol = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, bgAlpha)
    dl:AddRectFilled(p, imgui.ImVec2(p.x + w, p.y + h), imgui.GetColorU32Vec4(bgCol), 8.0)
    
    local lineW = 4 + (4 * hov) + (isOpen and 2 or 0)
    dl:AddRectFilled(p, imgui.ImVec2(p.x + lineW, p.y + h), imgui.GetColorU32Vec4(c_accent), 8.0)
    
    local borderAlpha = 0.2 + (0.3 * hov) + (isOpen and 0.4 or 0.0)
    local borderThickness = isOpen and 1.5 or 1.0
    dl:AddRect(p, imgui.ImVec2(p.x + w, p.y + h), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, borderAlpha)), 8.0, 0, borderThickness)
    
    local textCol = imgui.ImVec4(1, 1, 1, 0.6 + (0.4 * hov) + (isOpen and 0.4 or 0.0))
    
    if isOpen and MFT.fonts.title then 
        imgui.PushFont(MFT.fonts.title) 
    elseif MFT.fonts.main then 
        imgui.PushFont(MFT.fonts.main) 
    end
    
    local textY = p.y + (h - imgui.CalcTextSize(title).y) / 2
    dl:AddText(imgui.ImVec2(p.x + 20, textY), imgui.GetColorU32Vec4(textCol), title)
    
    if (isOpen and MFT.fonts.title) or MFT.fonts.main then 
        imgui.PopFont() 
    end
    
    local statusText = isOpen and u8"Свернуть" or u8"Развернуть"
    if MFT.fonts.main then imgui.PushFont(MFT.fonts.main) end
    local stSize = imgui.CalcTextSize(statusText)
    local stCol = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.5 + (0.5 * hov))
    dl:AddText(imgui.ImVec2(p.x + w - stSize.x - 20, p.y + (h - stSize.y) / 2), imgui.GetColorU32Vec4(stCol), statusText)
    if MFT.fonts.main then imgui.PopFont() end
    
    imgui.Dummy(imgui.ImVec2(w, h))

    MFT.state.accAnims = MFT.state.accAnims or {}
    MFT.state.accHeights = MFT.state.accHeights or {}
    MFT.state.accStartY = MFT.state.accStartY or {}
    
    local targetAlpha = isOpen and 1.0 or 0.0
    MFT.state.accAnims[stateKey] = MFT.state.accAnims[stateKey] or targetAlpha
    MFT.state.accAnims[stateKey] = MFT.state.accAnims[stateKey] + (targetAlpha - MFT.state.accAnims[stateKey]) * math.min(1.0, 18.0 * dt)
    
    local animVal = MFT.state.accAnims[stateKey]
    
    if animVal > 0.01 then
        local maxH = MFT.state.accHeights[stateKey] or 150
        local currentH = maxH * animVal
        
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, animVal)
        
        if animVal < 0.99 then
            local cp = imgui.GetCursorScreenPos()
            local cw = imgui.GetContentRegionAvail().x - 10
            imgui.PushClipRect(cp, imgui.ImVec2(cp.x + cw, cp.y + currentH), true)
        end
        
        MFT.state.accStartY[stateKey] = imgui.GetCursorPosY()
        imgui.BeginGroup()
        imgui.SetCursorPosY(imgui.GetCursorPosY() - (1.0 - animVal) * 15.0)
        
        return true
    end
    return false
end

local function EndAccordion(stateKey)
    imgui.EndGroup()
    
    local animVal = MFT.state.accAnims[stateKey]
    local fullH = imgui.GetItemRectSize().y
    
    if animVal >= 0.99 then
        MFT.state.accHeights[stateKey] = fullH
    else
        imgui.PopClipRect()
        local startY = MFT.state.accStartY[stateKey]
        local maxH = MFT.state.accHeights[stateKey] or fullH
        imgui.SetCursorPosY(startY + maxH * animVal)
    end
    imgui.PopStyleVar()
end

function tab_settings.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    local tAlpha = dash.anims.tabSwitch
    local slideX = (1.0 - tAlpha) * 30.0
    imgui.SetCursorPosX(imgui.GetCursorPosX() + slideX)
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, tAlpha)

    if not MFT.state.lastArFocus then MFT.state.lastArFocus = {} end

    local blockW = (availWidth - 15) / 2

    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.04, 0.04, 0.04, 0.6))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.4))
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, 12.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildBorderSize, 2.0)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(10, 15))

    -- ==========================================
    -- === ЛЕВЫЙ БЛОК (НАСТРОЙКИ ЧАТА) ===
    -- ==========================================
    imgui.BeginChild("LeftSettingsBlock", imgui.ImVec2(blockW, 0), true, imgui.WindowFlags.AlwaysVerticalScrollbar)
    
    if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
    local leftTitle = u8"ВЗАИМОДЕЙСТВИЕ С ЧАТОМ"
    imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(leftTitle).x) / 2)
    imgui.TextColored(c_accent, leftTitle)
    if MFT.fonts.title then imgui.PopFont() end
    imgui.Separator(); imgui.Spacing(); imgui.Spacing()
    
    -- === БЛОК 1: ЧАТ++ ===
    local isChatBugged = MFT.state.chatEdited == true
    local chatColor = isChatBugged and imgui.ImVec4(0.9, 0.2, 0.2, 1.0) or c_accent
    
    if BeginAccordion(u8"Редактор чата (Chat++)", chatColor, "setChatOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        
        if isChatBugged then
            imgui.TextColored(imgui.ImVec4(1.0, 0.3, 0.3, 1.0), u8"Внимание: Вы редактировали или удалили сообщение!")
            imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.8, 1.0), u8"Если предупреждение в чате мешает, нажмите кнопку ниже.")
            imgui.Spacing()
            
            if DrawBounceButton("btn_chat_reset", u8"ПЕРЕЗАГРУЗИТЬ ЧАТ", imgui.ImVec2(300, 45), chatColor, imgui.ImVec4(0.8, 0.2, 0.2, 0.5), imgui.ImVec4(0.9, 0.3, 0.3, 0.8)) then
                local ce = require("MFTools.core.chatedit")
                if ce and ce.restoreBackup then pcall(ce.restoreBackup) end
                MFT.state.chatEdited = false
                MFT.state.isEditingChatLine = false
                engine.saveData()
            end
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
        end
        
        local chatEditBool = imgui.new.bool(MFT.settings.chatEditEnabled == true)
        if imgui.Checkbox(u8"Включить редактор чата (Chat++)", chatEditBool) then 
            MFT.settings.chatEditEnabled = (chatEditBool[0] == true); engine.saveData() 
        end
        
        if MFT.settings.chatEditEnabled then
            imgui.SetCursorPosX(35)
            local bEmpty = imgui.new.bool(MFT.settings.chatDeleteLeaveEmpty == true)
            if imgui.Checkbox(u8"Оставлять пустую строку при удалении", bEmpty) then MFT.settings.chatDeleteLeaveEmpty = (bEmpty[0] == true); engine.saveData() end
            
            imgui.Spacing()
            if DrawBounceButton("btn_chatcalib", u8"ВИЗУАЛЬНОЕ КАЛИБРОВАНИЕ СЕТКИ", imgui.ImVec2(300, 35), c_accent, imgui.ImVec4(0.15, 0.15, 0.15, 1.0), imgui.ImVec4(0.25, 0.25, 0.25, 1.0)) then 
                MFT.state.isCalibratingChat = true; MFT.state.isMenuOpen = false 
            end
        end
        
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setChatOpen")
    end
    
    -- === БЛОК 2: АВТОПЕРЕНОС ДЛИННЫХ СООБЩЕНИЙ ===
    if BeginAccordion(u8"Умный автоперенос", c_accent, "setLineBreakOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        local lbSet = MFT.settings.autoLineBreak
        
        local bEn = imgui.new.bool(lbSet.enabled == true)
        if imgui.Checkbox(u8"Включить умный автоперенос длинных строк в чате", bEn) then
            lbSet.enabled = (bEn[0] == true); engine.saveData()
        end
        
        if lbSet.enabled then
            imgui.Spacing()
            
            imgui.PushItemWidth(250)
            local fMaxLen = ffi.new("int[1]", lbSet.maxLength)
            if imgui.SliderInt(u8"Макс. символов##lb_max", fMaxLen, 50, 120) then
                lbSet.maxLength = tonumber(fMaxLen[0]); engine.saveData()
            end
            imgui.PopItemWidth()
            imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), u8"Рекомендовано: 90-100 символов")
            
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.TextColored(c_accent, u8"Символы переноса:")
            
            if not uistate.lbSuffix then uistate.lbSuffix = imgui.new.char[32](lbSet.suffix or "") end
            if not uistate.lbPrefix then uistate.lbPrefix = imgui.new.char[32](lbSet.prefix or "") end
            
            imgui.PushItemWidth(100)
            if imgui.InputTextWithHint("##lb_suf", u8"В конце", uistate.lbSuffix, 32) then
                lbSet.suffix = u8:decode(ffi.string(uistate.lbSuffix)); engine.saveData()
            end
            imgui.SameLine()
            imgui.Text(u8"В конце обрезанной строки")
            
            if imgui.InputTextWithHint("##lb_pref", u8"В начале", uistate.lbPrefix, 32) then
                lbSet.prefix = u8:decode(ffi.string(uistate.lbPrefix)); engine.saveData()
            end
            imgui.SameLine()
            imgui.Text(u8"В начале новой строки")
            imgui.PopItemWidth()

            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.TextColored(c_accent, u8"Использовать в командах:")
            
            imgui.BeginGroup()
            imgui.Columns(3, "lb_cols", false)
            
            local cbNorm = imgui.new.bool(lbSet.cmds.normal == true)
            if imgui.Checkbox(u8"Чат", cbNorm) then lbSet.cmds.normal = cbNorm[0] == true; engine.saveData() end
            
            local cbR = imgui.new.bool(lbSet.cmds.r == true)
            if imgui.Checkbox("/r", cbR) then lbSet.cmds.r = cbR[0] == true; engine.saveData() end
            
            local cbRn = imgui.new.bool(lbSet.cmds.rn == true)
            if imgui.Checkbox("/rn", cbRn) then lbSet.cmds.rn = cbRn[0] == true; engine.saveData() end
            
            imgui.NextColumn()
            
            local cbF = imgui.new.bool(lbSet.cmds.f == true)
            if imgui.Checkbox("/f", cbF) then lbSet.cmds.f = cbF[0] == true; engine.saveData() end
            
            local cbFn = imgui.new.bool(lbSet.cmds.fn == true)
            if imgui.Checkbox("/fn", cbFn) then lbSet.cmds.fn = cbFn[0] == true; engine.saveData() end
            
            local cbFr = imgui.new.bool(lbSet.cmds.fr == true)
            if imgui.Checkbox("/fr", cbFr) then lbSet.cmds.fr = cbFr[0] == true; engine.saveData() end
            
            local cbFrn = imgui.new.bool(lbSet.cmds.frn == true)
            if imgui.Checkbox("/frn", cbFrn) then lbSet.cmds.frn = cbFrn[0] == true; engine.saveData() end
            
            imgui.NextColumn()
            
            local cbMe = imgui.new.bool(lbSet.cmds.me == true)
            if imgui.Checkbox("/me", cbMe) then lbSet.cmds.me = cbMe[0] == true; engine.saveData() end
            
            local cbDo = imgui.new.bool(lbSet.cmds.do_ == true)
            if imgui.Checkbox("/do", cbDo) then lbSet.cmds.do_ = cbDo[0] == true; engine.saveData() end
            
            local cbA = imgui.new.bool(lbSet.cmds.a == true)
            if imgui.Checkbox("/a", cbA) then lbSet.cmds.a = cbA[0] == true; engine.saveData() end
            
            imgui.Columns(1)
            imgui.EndGroup()
        end
        
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setLineBreakOpen")
    end
    
    -- === БЛОК 3: РЕЖИМ СС ===
    if BeginAccordion(u8"Режим создания СС", c_accent, "setSSOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        local ssMode = imgui.new.bool(MFT.settings.ssMode == true)
        if imgui.Checkbox(u8"Включить режим СС (Очистка чата)", ssMode) then MFT.settings.ssMode = (ssMode[0] == true); engine.saveData() end
        
        if MFT.settings.ssMode then
            local ssF = MFT.settings.ssFilters
            imgui.SetCursorPosX(35)
            imgui.BeginGroup()
            imgui.Columns(2, "ss_cols", false)
            local b_ooc = imgui.new.bool(ssF.ooc == true)
            if imgui.Checkbox(u8"OOC Чаты (/n, /b)", b_ooc) then ssF.ooc = (b_ooc[0] == true); engine.saveData() end
            local b_rad = imgui.new.bool(ssF.radio == true)
            if imgui.Checkbox(u8"Рации (/r, /f, /d)", b_rad) then ssF.radio = (b_rad[0] == true); engine.saveData() end
            local b_vip = imgui.new.bool(ssF.vip == true)
            if imgui.Checkbox(u8"VIP и Семья", b_vip) then ssF.vip = (b_vip[0] == true); engine.saveData() end
            local b_afk = imgui.new.bool(ssF.afk == true)
            if imgui.Checkbox(u8"AFK сообщения", b_afk) then ssF.afk = (b_afk[0] == true); engine.saveData() end
            imgui.NextColumn()
            local b_ads = imgui.new.bool(ssF.ads == true)
            if imgui.Checkbox(u8"Объявления (СМИ)", b_ads) then ssF.ads = (b_ads[0] == true); engine.saveData() end
            local b_sys = imgui.new.bool(ssF.sys == true)
            if imgui.Checkbox(u8"Системные", b_sys) then ssF.sys = (b_sys[0] == true); engine.saveData() end
            local b_pd = imgui.new.bool(ssF.pd_alerts == true)
            if imgui.Checkbox(u8"Розыск/Уведомления", b_pd) then ssF.pd_alerts = (b_pd[0] == true); engine.saveData() end
            local b_events = imgui.new.bool(ssF.events == true)
            if imgui.Checkbox(u8"Серверные ивенты", b_events) then ssF.events = (b_events[0] == true); engine.saveData() end
            imgui.Columns(1)
            imgui.EndGroup()
        end
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setSSOpen")
    end
    
    -- === БЛОК 4: УМНЫЙ ДЕПАРТАМЕНТ ===
    if BeginAccordion(u8"Умный департамент", c_accent, "setDeptOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        local dSet = MFT.settings.smartDept
        
        local bEn = imgui.new.bool(dSet.enabled == true)
        if imgui.Checkbox(u8"Включить подсказки тегов при вводе /d", bEn) then
            dSet.enabled = (bEn[0] == true); engine.saveData()
        end
        
        if dSet.enabled then
            imgui.Spacing()
            
            imgui.PushItemWidth(250)
            local fDMaxItems = ffi.new("int[1]", dSet.maxItems)
            if imgui.SliderInt(u8"Макс. тегов на экране##dept_max", fDMaxItems, 1, 20) then
                dSet.maxItems = tonumber(fDMaxItems[0]); engine.saveData()
            end
            imgui.PopItemWidth()
            
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.TextColored(c_accent, u8"Список тегов для автозаполнения:")
            
            if not uistate.deptTags then uistate.deptTags = {} end
            local tagToRemove = -1
            
            local tagsPerRow = 2
            for i, tag in ipairs(dSet.tags) do
                if not uistate.deptTags[i] then uistate.deptTags[i] = imgui.new.char[128](tag or "") end
                
                imgui.PushItemWidth(160)
                if imgui.InputTextWithHint("##dtag_"..i, u8"Тег (напр: to [LSPD])", uistate.deptTags[i], 128) then
                    dSet.tags[i] = u8:decode(ffi.string(uistate.deptTags[i]))
                    engine.saveData()
                end
                imgui.PopItemWidth()
                
                imgui.SameLine()
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.3))
                if imgui.Button("X##dt_"..i, imgui.ImVec2(24, 24)) then tagToRemove = i end
                imgui.PopStyleColor()
                
                if i % tagsPerRow ~= 0 and i < #dSet.tags then
                    imgui.SameLine(0, 10)
                else
                    imgui.Spacing()
                end
            end
            
            if tagToRemove ~= -1 then
                table.remove(dSet.tags, tagToRemove)
                table.remove(uistate.deptTags, tagToRemove)
                engine.saveData()
            end
            
            imgui.Spacing()
            if DrawBounceButton("btn_add_dept", u8"+ ДОБАВИТЬ ТЕГ", imgui.ImVec2(200, 35), c_accent, imgui.ImVec4(0.15, 0.15, 0.15, 1.0), imgui.ImVec4(0.25, 0.25, 0.25, 1.0)) then
                table.insert(dSet.tags, "to [NEW]")
                engine.saveData()
            end
        end
        
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setDeptOpen")
    end
    
    -- === БЛОК 5: ПОДСКАЗКИ КОМАНД ===
    if BeginAccordion(u8"Подсказки команд", c_accent, "setSuggestOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        local sugSet = MFT.settings
        
        local bEn = imgui.new.bool(sugSet.cmdSuggestEnabled == true)
        if imgui.Checkbox(u8"Включить систему подсказки команд", bEn) then
            sugSet.cmdSuggestEnabled = (bEn[0] == true); engine.saveData()
        end
        
        if sugSet.cmdSuggestEnabled then
            imgui.Spacing()
            
            imgui.PushItemWidth(250)
            local fMaxItems = ffi.new("int[1]", sugSet.cmdMaxItems)
            if imgui.SliderInt(u8"Макс. подсказок##sug_max", fMaxItems, 1, 20) then
                sugSet.cmdMaxItems = tonumber(fMaxItems[0]); engine.saveData()
            end
            
            local fSize = ffi.new("int[1]", sugSet.cmdFontSize)
            if imgui.SliderInt(u8"Размер шрифта##sug_size", fSize, 8, 24) then
                sugSet.cmdFontSize = tonumber(fSize[0]); engine.saveData()
            end
            
            local fOffsetY = ffi.new("int[1]", sugSet.cmdOffsetY)
            if imgui.SliderInt(u8"Отступ по высоте (Y)##sug_y", fOffsetY, -200, 200) then
                sugSet.cmdOffsetY = tonumber(fOffsetY[0]); engine.saveData()
            end
            imgui.PopItemWidth()
            
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.TextColored(c_accent, u8"Настройка цветов:")
            
            local cSelArr = ffi.new("float[3]", sugSet.cmdColorSel[1], sugSet.cmdColorSel[2], sugSet.cmdColorSel[3])
            if imgui.ColorEdit3(u8"Цвет выбранной команды", cSelArr, imgui.ColorEditFlags.NoInputs) then
                sugSet.cmdColorSel = {tonumber(cSelArr[0]), tonumber(cSelArr[1]), tonumber(cSelArr[2])}
                engine.saveData()
            end
            
            local cUnselArr = ffi.new("float[3]", sugSet.cmdColorUnsel[1], sugSet.cmdColorUnsel[2], sugSet.cmdColorUnsel[3])
            if imgui.ColorEdit3(u8"Цвет остальных команд", cUnselArr, imgui.ColorEditFlags.NoInputs) then
                sugSet.cmdColorUnsel = {tonumber(cUnselArr[0]), tonumber(cUnselArr[1]), tonumber(cUnselArr[2])}
                engine.saveData()
            end
        end
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setSuggestOpen")
    end
    
    imgui.EndChild()
    
    imgui.SameLine(0, 15)
    
    -- ==========================================
    -- === ПРАВАЯ КОЛОНКА (ОСТАЛЬНЫЕ НАСТРОЙКИ) ===
    -- ==========================================

    imgui.BeginChild("RightSettingsBlock", imgui.ImVec2(blockW, 0), true, imgui.WindowFlags.AlwaysVerticalScrollbar)
    
    if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
    local rightTitle = u8"СИСТЕМЫ И ИНТЕРФЕЙС"
    imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(rightTitle).x) / 2)
    imgui.TextColored(c_accent, rightTitle)
    if MFT.fonts.title then imgui.PopFont() end
    imgui.Separator(); imgui.Spacing(); imgui.Spacing()

    -- === БЛОК 6: ВИЗУАЛ ===
    if BeginAccordion(u8"Визуальное оформление", c_accent, "setVisOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        imgui.TextColored(c_accent, u8"Отображение стилей:")
        local tvMode = tonumber(MFT.settings.themeViewMode) or 0
        if imgui.RadioButtonBool(u8"Плитка", tvMode == 0) then MFT.settings.themeViewMode = 0; engine.saveData() end
        imgui.SameLine(0, 15)
        if imgui.RadioButtonBool(u8"Список", tvMode == 1) then MFT.settings.themeViewMode = 1; engine.saveData() end
        
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()
        
        if tvMode == 0 then
            local sqSize = 38
            local sqSpacing = 15
            local colsInRow = 7
            for i=1, 9 do
                local isActiveTheme = (MFT.settings.activeThemeId == i)
                local bCol = isActiveTheme and imgui.ImVec4(1,1,1,1) or imgui.ImVec4(0,0,0,0)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(uistate.pThemes[i].col[1], uistate.pThemes[i].col[2], uistate.pThemes[i].col[3], 1.0))
                imgui.PushStyleColor(imgui.Col.Border, bCol)
                imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.5)
                if imgui.Button("##col"..i, imgui.ImVec2(sqSize, sqSize)) then utils.applyThemePreset(i) end
                if imgui.IsItemHovered() then imgui.SetTooltip(uistate.pThemes[i].name) end
                imgui.PopStyleVar(); imgui.PopStyleColor(2)
                if i % colsInRow ~= 0 then imgui.SameLine(0, sqSpacing) else imgui.Spacing() end
            end
        else
            for i=1, 9 do
                if imgui.Button(uistate.pThemes[i].name.."##clst"..i, imgui.ImVec2(200, 25)) then utils.applyThemePreset(i) end
            end
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()
        imgui.TextColored(c_accent, u8"Мои кастомные стили:")
        if type(MFT.settings.savedThemes) == "table" and #MFT.settings.savedThemes > 0 then
            local toDel = -1
            local sqSize = 38
            local sqSpacing = 15
            for i, st in ipairs(MFT.settings.savedThemes) do
                local tIdStr = "custom_"..i
                local isActiveTheme = (MFT.settings.activeThemeId == tIdStr)
                local bCol = isActiveTheme and imgui.ImVec4(1,1,1,1) or imgui.ImVec4(0,0,0,0)
                
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(st.accent[1], st.accent[2], st.accent[3], 1.0))
                imgui.PushStyleColor(imgui.Col.Border, bCol)
                imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.5)
                if imgui.Button("##scol"..i, imgui.ImVec2(sqSize, sqSize)) then utils.applyThemePreset(tIdStr) end
                if imgui.IsItemHovered() then imgui.SetTooltip(u8"[ПКМ] - Удалить стиль") end
                if imgui.IsItemClicked(1) then toDel = i end
                imgui.PopStyleVar(); imgui.PopStyleColor(2)
                imgui.SameLine(0, sqSpacing)
            end
            if toDel ~= -1 then
                local deletedIdStr = "custom_" .. toDel
                table.remove(MFT.settings.savedThemes, toDel)
                if MFT.settings.activeThemeId == deletedIdStr then utils.applyThemePreset(1) end
                engine.saveData()
            end
            imgui.NewLine()
        end

        if DrawBounceButton("btn_createtheme", u8"+ СОЗДАТЬ СВОЙ СТИЛЬ", imgui.ImVec2(300, 35), c_accent, imgui.ImVec4(0.15, 0.15, 0.15, 1.0), imgui.ImVec4(0.25, 0.25, 0.25, 1.0)) then
            ffi.copy(uistate.newThemeName, "")
            -- Устанавливаем текущие цвета в буферы для палитры
            uistate.ctSettings.bg[0], uistate.ctSettings.bg[1], uistate.ctSettings.bg[2] = MFT.settings.colorBg[1], MFT.settings.colorBg[2], MFT.settings.colorBg[3]
            uistate.ctSettings.sidebar[0], uistate.ctSettings.sidebar[1], uistate.ctSettings.sidebar[2] = MFT.settings.colorSidebar[1], MFT.settings.colorSidebar[2], MFT.settings.colorSidebar[3]
            uistate.ctSettings.btn[0], uistate.ctSettings.btn[1], uistate.ctSettings.btn[2] = MFT.settings.colorBtn[1], MFT.settings.colorBtn[2], MFT.settings.colorBtn[3]
            uistate.ctSettings.accent[0], uistate.ctSettings.accent[1], uistate.ctSettings.accent[2] = MFT.settings.colorAccent[1], MFT.settings.colorAccent[2], MFT.settings.colorAccent[3]
            uistate.ctSettings.text[0], uistate.ctSettings.text[1], uistate.ctSettings.text[2] = MFT.settings.colorText[1], MFT.settings.colorText[2], MFT.settings.colorText[3]
            MFT.state.isCustomThemeOpen = true
        end
        
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()
        imgui.TextColored(c_accent, u8"Прозрачность и затенение:")
        imgui.PushItemWidth(300)
        local fAlpha = ffi.new("float[1]", tonumber(MFT.settings.menuTransparency) or 0.98)
        if imgui.SliderFloat("##ma", fAlpha, 0.3, 1.0, u8"Прозрачность: %.2f") then MFT.settings.menuTransparency = tonumber(fAlpha[0]); engine.saveData() end 
        local fDim = ffi.new("float[1]", tonumber(MFT.settings.dimmingIntensity) or 0.80)
        if imgui.SliderFloat("##md", fDim, 0.0, 1.0, u8"Затемнение игры: %.2f") then MFT.settings.dimmingIntensity = tonumber(fDim[0]); engine.saveData() end 
        imgui.PopItemWidth()
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setVisOpen")
    end

    -- === БЛОК 7: УМНЫЙ СКРИНШОТ ===
    if BeginAccordion(u8"Умный скриншот", c_accent, "setSmartScreenOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        local ss = MFT.settings.smartScreen
        
        local bEn = imgui.new.bool(ss.enabled == true)
        if imgui.Checkbox(u8"Включить Умный скриншот", bEn) then
            ss.enabled = (bEn[0] == true); MFT.settings.smartScreen = ss; engine.saveData()
        end
        
        if ss.enabled then
            imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), u8"Сохранит только выделенную область (без худа).")
            imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.8, 1.0), u8"Путь: moonloader/config/MFT_Screens/")
            
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            
            imgui.TextColored(c_accent, u8"Клавиша создания скриншота:")
            if MFT.state.capturingSmartScreenKey then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.5, 0.2, 0.6))
                if imgui.Button(u8"Ожидание...##ss_hk", imgui.ImVec2(200, 30)) then MFT.state.capturingSmartScreenKey = false end
                imgui.PopStyleColor()
                for k=8, 255 do
                    if imgui.IsKeyPressed(k) then
                        ss.hotkey = (k == vk.VK_BACK or k == vk.VK_ESCAPE) and 0 or k
                        MFT.state.capturingSmartScreenKey = false; engine.saveData()
                        break
                    end
                end
            else
                local kn = (ss.hotkey == 0) and u8"Не назначена" or vk.id_to_name(ss.hotkey)
                if imgui.Button(kn.."##ss_hk", imgui.ImVec2(200, 30)) then MFT.state.capturingSmartScreenKey = true end
            end

            imgui.Spacing()
            
            local bNotif = imgui.new.bool(ss.showNotif ~= false)
            if imgui.Checkbox(u8"Показывать уведомление после сохранения", bNotif) then
                ss.showNotif = (bNotif[0] == true); engine.saveData()
            end
            
            imgui.Spacing(); imgui.Spacing()
            if DrawBounceButton("btn_calib_f8", u8"КАЛИБРОВАТЬ РАМКУ", imgui.ImVec2(250, 35), c_accent, imgui.ImVec4(0.15, 0.15, 0.15, 1.0), imgui.ImVec4(0.25, 0.25, 0.25, 1.0)) then 
                MFT.state.isCalibratingScreen = true; MFT.state.isMenuOpen = false 
            end
        end
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setSmartScreenOpen")
    end

    -- === БЛОК 8: СИСТЕМНЫЙ ОВЕРЛЕЙ ===
    if BeginAccordion(u8"Системный оверлей", c_accent, "setOvlOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        local overlayWindowState = imgui.new.bool(MFT.settings.overlayEnabled ~= false)
        if imgui.Checkbox(u8"Включить плавающий оверлей биндов", overlayWindowState) then MFT.settings.overlayEnabled = (overlayWindowState[0] == true); engine.saveData() end
        
        local ovl_chat = imgui.new.bool(MFT.settings.overlayOnlyOnChat == true)
        if imgui.Checkbox(u8"Показывать только при открытом чате", ovl_chat) then MFT.settings.overlayOnlyOnChat = (ovl_chat[0] == true); engine.saveData() end
        
        local ovl_scroll = imgui.new.bool(MFT.settings.overlayScrollMode ~= false)
        if imgui.Checkbox(u8"Режим прокрутки колесиком", ovl_scroll) then MFT.settings.overlayScrollMode = (ovl_scroll[0] == true); engine.saveData() end
        
        imgui.Spacing()
        if DrawBounceButton("btn_posovl", u8"Изменить позицию оверлея биндов", imgui.ImVec2(300, 35), c_accent, imgui.ImVec4(0.15, 0.15, 0.15, 1.0), imgui.ImVec4(0.25, 0.25, 0.25, 1.0)) then
            MFT.state.isPlacingOverlay = true; MFT.state.isMenuOpen = false; MFT.state.placingTimer = os.clock() + 0.3
        end
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setOvlOpen")
    end

    -- === БЛОК 9: ПОШАГОВЫЕ БИНДЫ ===
    if BeginAccordion(u8"Пошаговые бинды (Собеседования)", c_accent, "setSeqOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        
        local seqEn = imgui.new.bool(MFT.settings.seqOverlay.enabled == true)
        if imgui.Checkbox(u8"Отображать оверлей (функционал работает и без него)", seqEn) then 
            MFT.settings.seqOverlay.enabled = (seqEn[0] == true)
            engine.saveData()
        end
        
        imgui.Spacing()
        
        imgui.PushItemWidth(300)
        local fOvlA = ffi.new("float[1]", tonumber(MFT.settings.seqOverlay.alpha) or 0.8)
        if imgui.SliderFloat(u8"Прозрачность оверлея##seq_a", fOvlA, 0.1, 1.0) then
            MFT.settings.seqOverlay.alpha = tonumber(fOvlA[0]); engine.saveData()
        end
        imgui.PopItemWidth()
        
        imgui.Spacing()
        imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), u8"Как это использовать:")
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"1. В Базе биндов нажмите кнопку 'Пошагово' возле нужного бинда.")
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"2. Нажимайте назначенную ниже клавишу для отправки по 1 строке.")
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"3. Оверлей автоматически закроется, когда строки закончатся.")
        
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()
        imgui.TextColored(c_accent, u8"Глобальная клавиша для следующего шага:")
        if MFT.state.capturingSeqKey then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.5, 0.2, 0.6))
            if imgui.Button(u8"Ожидание...##seq_hk", imgui.ImVec2(200, 30)) then MFT.state.capturingSeqKey = false end
            imgui.PopStyleColor()
            for k=8, 255 do
                if imgui.IsKeyPressed(k) then
                    MFT.settings.seqOverlay.hotkey = (k == vk.VK_BACK or k == vk.VK_ESCAPE) and 0 or k
                    MFT.state.capturingSeqKey = false; engine.saveData()
                    break
                end
            end
        else
            local kn = (MFT.settings.seqOverlay.hotkey == 0) and u8"Не назначена" or vk.id_to_name(MFT.settings.seqOverlay.hotkey)
            if imgui.Button(kn.."##seq_hk", imgui.ImVec2(200, 30)) then MFT.state.capturingSeqKey = true end
        end
        
        imgui.Spacing(); imgui.Spacing()
        if DrawBounceButton("btn_posseq", u8"Изменить позицию оверлея шагов", imgui.ImVec2(300, 35), c_accent, imgui.ImVec4(0.15, 0.15, 0.15, 1.0), imgui.ImVec4(0.25, 0.25, 0.25, 1.0)) then
            MFT.state.isPlacingSeqOverlay = true; MFT.state.isMenuOpen = false; MFT.state.placingTimer = os.clock() + 0.3
        end
        
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setSeqOpen")
    end

    -- === БЛОК 10: АВТОДОКЛАДЫ ===
    if BeginAccordion(u8"Автодоклады", c_accent, "setArOpen", dt, false) then
        imgui.Indent(10)
        imgui.Spacing()
        local arSet = MFT.settings.autoReport
        
        local bEn = imgui.new.bool(arSet.enabled == true)
        if imgui.Checkbox(u8"Включить систему автодокладов", bEn) then
            arSet.enabled = (bEn[0] == true); engine.saveData()
        end
        
        if arSet.enabled then
            imgui.Spacing()
            
            local fInt = ffi.new("int[1]", arSet.interval)
            imgui.PushItemWidth(150)
            if imgui.SliderInt(u8"Интервал (минуты)##ar_int", fInt, 1, 60) then
                arSet.interval = tonumber(fInt[0]); engine.saveData()
            end
            imgui.PopItemWidth()

            local bScr = imgui.new.bool(arSet.autoScreen == true)
            if imgui.Checkbox(u8"Авто-скриншот (F8) после отправки", bScr) then
                arSet.autoScreen = (bScr[0] == true); engine.saveData()
            end
            
            imgui.SameLine(0, 20)
            local bOvl = imgui.new.bool(arSet.showOverlay ~= false)
            if imgui.Checkbox(u8"Отображать оверлей (таймер)", bOvl) then
                arSet.showOverlay = (bOvl[0] == true); engine.saveData()
            end
            
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.TextColored(c_accent, u8"Структура докладов:")
            
            local repToRemove = -1
            if not uistate.arData then uistate.arData = {} end
            
            for i, rep in ipairs(arSet.reports) do
                if not uistate.arData[i] then uistate.arData[i] = { title = imgui.new.char[256](rep.title or ""), lines = {} } end
                local cd = uistate.arData[i]
                
                if not MFT.state.lastArFocus[i] then MFT.state.lastArFocus[i] = 1 end
                
                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.04, 0.04, 0.04, 0.8))
                imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.4))
                imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, 8.0)
                imgui.PushStyleVarFloat(imgui.StyleVar.ChildBorderSize, 1.0)
                
                local cH = 180 + (#rep.lines * 38)
                imgui.BeginChild("ARC_"..i, imgui.ImVec2(availWidth / 2 - 30, cH), true)
                
                imgui.SetCursorPos(imgui.ImVec2(10, 10))
                imgui.TextColored(c_accent, u8"Доклад #"..i..":")
                imgui.SameLine()
                
                imgui.PushItemWidth(-40)
                if imgui.InputTextWithHint("##art_"..i, u8"Название доклада...", cd.title, 256) then 
                    rep.title = u8:decode(ffi.string(cd.title))
                    engine.saveData() 
                end
                imgui.PopItemWidth()
                
                imgui.SameLine(imgui.GetWindowWidth() - 35)
                imgui.SetCursorPosY(8)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.3))
                if imgui.Button("X##ardel_"..i, imgui.ImVec2(25, 25)) then repToRemove = i end
                imgui.PopStyleColor()
                
                imgui.Spacing()
                
                imgui.SetCursorPosX(10)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"Теги (кликните, чтобы скопировать):")
                
                imgui.SetCursorPosX(10)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.2))
                
                local function TagBtn(tag, tt)
                    local tSize = imgui.CalcTextSize(tag)
                    if imgui.Button(tag.."##t_"..i, imgui.ImVec2(tSize.x + 12, 22)) then 
                        imgui.SetClipboardText(tag)
                    end
                    if imgui.IsItemHovered() then imgui.SetTooltip(tt) end
                    imgui.SameLine()
                end
                
                TagBtn("{id}", u8"Мой ID"); TagBtn("{name}", u8"Мой ник"); TagBtn("{loc}", u8"Район"); TagBtn("{dir}", u8"Направление")
                imgui.NewLine()
                imgui.SetCursorPosX(10)
                TagBtn("{weapon}", u8"Оружие"); TagBtn("{car}", u8"Авто"); TagBtn("{target}", u8"ID Цели")
                
                imgui.PopStyleColor()
                imgui.NewLine()
                
                local lineToRemove = -1
                for j, line in ipairs(rep.lines) do
                    if not cd.lines[j] then cd.lines[j] = imgui.new.char[256](line or "") end
                    
                    imgui.SetCursorPosX(10)
                    imgui.PushItemWidth(-40)
                    if imgui.InputTextWithHint("##arl_"..i.."_"..j, u8"Текст строки...", cd.lines[j], 256) then
                        rep.lines[j] = u8:decode(ffi.string(cd.lines[j]))
                        engine.saveData()
                    end
                    
                    if imgui.IsItemActive() or imgui.IsItemClicked() then MFT.state.lastArFocus[i] = j end
                    
                    imgui.PopItemWidth()
                    
                    imgui.SameLine()
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.3))
                    if imgui.Button("-##ld_"..i.."_"..j, imgui.ImVec2(25, 25)) then lineToRemove = j end
                    imgui.PopStyleColor()
                end
                
                if lineToRemove ~= -1 then
                    table.remove(rep.lines, lineToRemove)
                    table.remove(cd.lines, lineToRemove)
                    engine.saveData()
                end
                
                imgui.SetCursorPosX(10)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.2))
                if imgui.Button(u8"+ Добавить строку##al_"..i, imgui.ImVec2(200, 25)) then
                    table.insert(rep.lines, "")
                    engine.saveData()
                end
                imgui.PopStyleColor()
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                
                imgui.SetCursorPosX(10)
                if MFT.state.ar.activeId == i then
                    if DrawBounceButton("btn_stop_"..i, u8"ОСТАНОВИТЬ ДОКЛАД", imgui.ImVec2(imgui.GetContentRegionAvail().x - 10, 35), c_accent, imgui.ImVec4(0.8, 0.2, 0.2, 0.6), imgui.ImVec4(0.9, 0.3, 0.3, 0.8)) then
                        MFT.state.ar.activeId = -1
                        MFT.state.ar.isRunning = false
                    end
                else
                    if DrawBounceButton("btn_start_"..i, u8"ЗАПУСТИТЬ ДОКЛАД", imgui.ImVec2(imgui.GetContentRegionAvail().x - 10, 35), c_accent, imgui.ImVec4(0.2, 0.8, 0.2, 0.6), imgui.ImVec4(0.3, 0.9, 0.3, 0.8)) then
                        MFT.state.ar.activeId = i
                        MFT.state.ar.isRunning = true
                        MFT.state.ar.currentIndex = 1
                        MFT.state.ar.nextTime = 0
                    end
                end

                imgui.EndChild()
                imgui.PopStyleColor(2); imgui.PopStyleVar(2)
                imgui.Spacing()
            end
            
            if repToRemove ~= -1 then
                table.remove(arSet.reports, repToRemove)
                table.remove(uistate.arData, repToRemove)
                if MFT.state.ar.activeId == repToRemove then MFT.state.ar.activeId = -1; MFT.state.ar.isRunning = false end
                engine.saveData()
            end

            if DrawBounceButton("btn_addreport", u8"+ СОЗДАТЬ НОВЫЙ ДОКЛАД", imgui.ImVec2(300, 40), c_accent, imgui.ImVec4(0.15, 0.15, 0.15, 1.0), imgui.ImVec4(0.25, 0.25, 0.25, 1.0)) then
                table.insert(arSet.reports, { title = "", lines = {""} })
                engine.saveData()
            end
            
            imgui.Spacing(); imgui.Spacing()
            
            if DrawBounceButton("btn_posar", u8"Изменить позицию таймера", imgui.ImVec2(250, 45), c_accent, imgui.ImVec4(0.15, 0.15, 0.15, 1.0), imgui.ImVec4(0.25, 0.25, 0.25, 1.0)) then
                MFT.state.isPlacingAROverlay = true; MFT.state.isMenuOpen = false; MFT.state.placingTimer = os.clock() + 0.3
            end
        end
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        imgui.Unindent(10)
        EndAccordion("setArOpen")
    end

    imgui.Columns(1)
    imgui.EndChild()
    
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(3)
    imgui.PopStyleVar() 
    
    -- ==========================================
    -- === МОДАЛЬНОЕ ОКНО СОЗДАНИЯ СТИЛЯ ===
    -- ==========================================
    if MFT.state.isCustomThemeOpen then
        imgui.OpenPopup("CreateCustomThemePopup")
    end
    
    local mw, mh = 500, 430
    local sw, sh = utils.getScreenResolution and utils.getScreenResolution() or {x = 1920, y = 1080}
    if type(sw) == "table" then sw, sh = sw.x, sw.y end
    
    imgui.SetNextWindowPos(imgui.ImVec2(sw/2 - mw/2, sh/2 - mh/2), imgui.Cond.Appearing)
    imgui.SetNextWindowSize(imgui.ImVec2(mw, mh), imgui.Cond.Always)
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.98))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(25, 25))
    
    if imgui.BeginPopupModal("CreateCustomThemePopup", nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar) then
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
        utils.CenterText(u8"СОЗДАНИЕ СТИЛЯ", c_accent)
        if MFT.fonts.title then imgui.PopFont() end
        imgui.Separator(); imgui.Spacing(); imgui.Spacing()
        
        imgui.TextUnformatted(u8"Название стиля:")
        imgui.PushItemWidth(-1)
        imgui.InputText("##thm_name", uistate.newThemeName, 64)
        imgui.PopItemWidth()
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        
        imgui.TextColored(c_accent, u8"Палитра (нажмите на квадрат для выбора):")
        imgui.Spacing()
        
        local function DrawColorRow(label, colArr, id)
            imgui.TextUnformatted(label)
            -- Выравниваем квадратик с цветом по правому краю
            imgui.SameLine(imgui.GetWindowWidth() - 45) 
            local flags = bit.bor(imgui.ColorEditFlags.NoInputs, imgui.ColorEditFlags.NoLabel)
            imgui.ColorEdit3(id, colArr, flags)
            imgui.Spacing()
        end
        
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.04, 0.04, 0.04, 0.5))
        imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, 8.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))
        imgui.BeginChild("PaletteRegion", imgui.ImVec2(-1, 160), true)
        
        DrawColorRow(u8"Основной фон", uistate.ctSettings.bg, "##bg")
        DrawColorRow(u8"Сайдбары и Карточки", uistate.ctSettings.sidebar, "##sb")
        DrawColorRow(u8"Кнопки меню", uistate.ctSettings.btn, "##btn")
        DrawColorRow(u8"Акцентный цвет (Обводки/Текст)", uistate.ctSettings.accent, "##acc")
        DrawColorRow(u8"Обычный текст", uistate.ctSettings.text, "##txt")
        
        imgui.EndChild()
        imgui.PopStyleVar(2); imgui.PopStyleColor()
        
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        
        local btnW = (imgui.GetContentRegionAvail().x - 10) / 2
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.7, 0.2, 0.5))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.2, 0.8, 0.2, 0.8))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        
        if imgui.Button(u8"Сохранить", imgui.ImVec2(btnW, 35)) then
            local tName = ffi.string(uistate.newThemeName)
            if #tName > 0 then
                if type(MFT.settings.savedThemes) ~= "table" then MFT.settings.savedThemes = {} end
                local newTheme = {
                    name = u8:decode(tName),
                    bg = {uistate.ctSettings.bg[0], uistate.ctSettings.bg[1], uistate.ctSettings.bg[2]},
                    sidebar = {uistate.ctSettings.sidebar[0], uistate.ctSettings.sidebar[1], uistate.ctSettings.sidebar[2]},
                    btn = {uistate.ctSettings.btn[0], uistate.ctSettings.btn[1], uistate.ctSettings.btn[2]},
                    accent = {uistate.ctSettings.accent[0], uistate.ctSettings.accent[1], uistate.ctSettings.accent[2]},
                    text = {uistate.ctSettings.text[0], uistate.ctSettings.text[1], uistate.ctSettings.text[2]}
                }
                table.insert(MFT.settings.savedThemes, newTheme)
                engine.saveData()
                MFT.state.isCustomThemeOpen = false
                imgui.CloseCurrentPopup()
            end
        end
        imgui.PopStyleColor(2)
        
        imgui.SameLine()
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.5))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.8, 0.2, 0.2, 0.8))
        if imgui.Button(u8"Отмена", imgui.ImVec2(btnW, 35)) then
            MFT.state.isCustomThemeOpen = false
            imgui.CloseCurrentPopup()
        end
        imgui.PopStyleColor(2); imgui.PopStyleVar()
        
        imgui.EndPopup()
    end
    imgui.PopStyleVar(3); imgui.PopStyleColor(2)
end

return tab_settings