-- Файл: MFTools/ui/tab_interactions.lua
local imgui = require "mimgui"
local ffi = require "ffi"
local vk = require "vkeys"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local engine = require "MFTools.core.engine"
local utils = require "MFTools.ui.utils"
local rmath = require "MFTools.radial.radial_math"
local uistate = require "MFTools.ui.uistate"

local tab_interactions = {}

local tState = {
    tempSectorCount = nil,
    selectedInner = 1,
    selectedOuter = -1
}

local function DrawDonutSector(dl, cx, cy, r_outer, r_inner, a_min, a_max, color)
    local segments = math.max(4, math.floor(32 * ((a_max - a_min) / (math.pi * 2))))
    local step = (a_max - a_min) / segments
    for i = 0, segments - 1 do
        local a1 = a_min + step * i
        local a2 = a_min + step * (i + 1)
        local p1 = imgui.ImVec2(cx + math.cos(a1) * r_inner, cy + math.sin(a1) * r_inner)
        local p2 = imgui.ImVec2(cx + math.cos(a1) * r_outer, cy + math.sin(a1) * r_outer)
        local p3 = imgui.ImVec2(cx + math.cos(a2) * r_outer, cy + math.sin(a2) * r_outer)
        local p4 = imgui.ImVec2(cx + math.cos(a2) * r_inner, cy + math.sin(a2) * r_inner)
        dl:AddQuadFilled(p1, p2, p3, p4, color)
    end
end

local function wrapText(str, lineLen)
    if #str <= lineLen then return str end
    local words = {}
    for w in str:gmatch("%S+") do table.insert(words, w) end
    local lines = {""}
    local currentLine = 1
    for _, word in ipairs(words) do
        if #(lines[currentLine] .. word) > lineLen and lines[currentLine] ~= "" then
            currentLine = currentLine + 1; lines[currentLine] = word
        else
            lines[currentLine] = lines[currentLine] == "" and word or (lines[currentLine] .. " " .. word)
        end
    end
    return table.concat(lines, "\n")
end

local function buildTreeForCombos(list, prefix, depth, names, keys)
    for i, item in ipairs(list) do
        local key = prefix == "" and tostring(i) or (prefix .. "_" .. i)
        local indent = string.rep("- ", depth)
        local rawName = item.name and u8(item.name) or u8"Без названия"
        if item.type == "folder" then
            table.insert(names, indent .. "> " .. rawName)
            table.insert(keys, key)
            buildTreeForCombos(item.items or {}, key, depth + 1, names, keys)
        else
            table.insert(names, indent .. ". " .. rawName)
            table.insert(keys, key)
        end
    end
end

function tab_interactions.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    local tSet = MFT.settings.target
    if not tSet then 
        MFT.settings.target = { enabled = true, radialKey = 82, sectorsCount = 6, radius = 150.0, transparency = 0.8, sectorColor = {0.1, 0.1, 0.1}, radialBinds = {}, quickKeys = {{key=0, bind=0}}, menuMode = 0 }
        tSet = MFT.settings.target
    end
    tSet.sectorsCount = tonumber(tSet.sectorsCount) or 6
    tSet.menuMode = tonumber(tSet.menuMode) or 0

    if type(tSet.groups) ~= "table" then
        tSet.groups = {}
        for i=1, 12 do tSet.groups[tostring(i)] = {name="ГРУППА "..i, count=6, binds={}} end
    end

    if not tState.tempSectorCount then tState.tempSectorCount = ffi.new("int[1]", tSet.sectorsCount) end

    imgui.BeginChild("TargetTabMain", imgui.ImVec2(0, 0), false)

    utils.BeginCard(dash, dt, "TargetSysToggle", 70, nil, c_accent, sb_color)
    imgui.SetCursorPos(imgui.ImVec2(20, 22))
    local enBool = imgui.new.bool(tSet.enabled == true)
    if imgui.Checkbox(u8"Включить систему захвата цели (ПКМ)", enBool) then
        tSet.enabled = (enBool[0] == true); engine.saveData()
    end
    imgui.SameLine(0, 30)
    imgui.SetCursorPosY(24)
    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"Используйте тег {radial} в биндах для взаимодействия")
    utils.EndCard()
    
    imgui.Spacing(); imgui.Spacing()

    if tSet.enabled then
        if not uistate.ctSettings.targetRadial then
            uistate.ctSettings.targetRadial = ffi.new("float[3]", {tSet.sectorColor[1], tSet.sectorColor[2], tSet.sectorColor[3]})
        end
        if not MFT.state.colorPickerActive and MFT.state.colorPickerTarget == "targetRadial" then
            local tr = uistate.ctSettings.targetRadial
            if tSet.sectorColor[1] ~= tr[0] or tSet.sectorColor[2] ~= tr[1] or tSet.sectorColor[3] ~= tr[2] then
                tSet.sectorColor = {tonumber(tr[0]), tonumber(tr[1]), tonumber(tr[2])}
                engine.saveData()
                MFT.state.colorPickerTarget = ""
            end
        end

        local leftW = availWidth * 0.55 - 5
        local rightW = availWidth - leftW - 10
        
        imgui.BeginChild("TargetLeftCol", imgui.ImVec2(leftW, 0), false)

        utils.BeginCard(dash, dt, "TargetRadialPreview", 420, u8"ПРЕВЬЮ МЕНЮ (Кликните на сектор для настройки)", c_accent, sb_color)
        
        local p = imgui.GetCursorScreenPos()
        local avail = imgui.GetContentRegionAvail()
        local dl = imgui.GetWindowDrawList()
        
        dl:AddRectFilled(p, imgui.ImVec2(p.x + avail.x, p.y + avail.y), imgui.GetColorU32Vec4(imgui.ImVec4(0.04, 0.04, 0.04, 1.0)), 8.0)
        dl:AddRect(p, imgui.ImVec2(p.x + avail.x, p.y + avail.y), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.2)), 8.0, 0, 1.0)

        local cx = p.x + (avail.x / 2)
        local cy = p.y + (avail.y / 2)
        
        local maxVisualRadius = math.min(avail.x, avail.y) / 2 - 20
        local userRadius = tSet.radius or 150.0
        local displayScale = 1.0
        if userRadius > maxVisualRadius then displayScale = maxVisualRadius / userRadius end 
        
        local outerRadius = userRadius * displayScale
        local innerRadius = outerRadius * 0.25
        local mx, my = imgui.GetMousePos().x, imgui.GetMousePos().y
        local distToCenter = math.sqrt((mx - cx)^2 + (my - cy)^2)

        local previewHoverInner = -1
        local previewHoverOuter = -1

        if tSet.menuMode == 0 then
            local sectorsCount = tSet.sectorsCount
            local sectorAngle = (math.pi * 2) / sectorsCount
            local startOffset = -math.pi / 2 - (sectorAngle / 2)

            dl:AddCircle(imgui.ImVec2(cx, cy), outerRadius + 6, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.3)), 48, 2.0)
            dl:AddCircle(imgui.ImVec2(cx, cy), outerRadius + 2, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8)), 48, 1.0)
            
            if distToCenter > innerRadius and distToCenter <= outerRadius then
                local a = math.atan2(my - cy, mx - cx)
                if a < startOffset then a = a + math.pi * 2 end
                local relA = (a - startOffset) % (math.pi * 2)
                previewHoverInner = math.floor(relA / sectorAngle) + 1
                if imgui.IsMouseClicked(0) then tState.selectedInner = previewHoverInner end
            end

            for i = 1, sectorsCount do
                local a_start = startOffset + (i - 1) * sectorAngle
                local a_end = startOffset + i * sectorAngle
                
                local isHovered = (previewHoverInner == i)
                local isActive = (tState.selectedInner == i)
                
                local baseAlpha = tSet.transparency or 0.8
                local secColor = imgui.ImVec4(tSet.sectorColor[1], tSet.sectorColor[2], tSet.sectorColor[3], baseAlpha)
                
                if isActive then 
                    secColor = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, baseAlpha + 0.3)
                elseif isHovered then
                    secColor = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, baseAlpha + 0.1)
                end
                
                DrawDonutSector(dl, cx, cy, outerRadius, innerRadius, a_start, a_end, imgui.GetColorU32Vec4(secColor))
                local bordColor = (isActive or isHovered) and imgui.GetColorU32Vec4(c_accent) or imgui.GetColorU32Vec4(imgui.ImVec4(0.2, 0.2, 0.2, baseAlpha))
                rmath.DrawArcLine(dl, cx, cy, outerRadius, a_start, a_end, bordColor, (isActive or isHovered) and 2.5 or 1.5)
                dl:AddLine(imgui.ImVec2(cx + math.cos(a_start)*innerRadius, cy + math.sin(a_start)*innerRadius), imgui.ImVec2(cx + math.cos(a_start)*outerRadius, cy + math.sin(a_start)*outerRadius), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.3)), 1.5)
                
                local textX, textY = rmath.GetSectorCenter(cx, cy, innerRadius + (outerRadius - innerRadius)/2, a_start, a_end)
                local secText = u8"Бинд "..i
                local tSize = imgui.CalcTextSize(secText)
                dl:AddText(imgui.ImVec2(textX - tSize.x/2, textY - tSize.y/2), imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, (isActive or isHovered) and 1.0 or 0.7)), secText)
            end
        else
            local groupCount = tSet.sectorsCount
            local groupAngle = (math.pi * 2) / groupCount
            local groupStart = -math.pi / 2 - (groupAngle / 2)
            local midRadius = outerRadius * 0.55
            local gap = 8
            local outerInnerRadius = midRadius + gap
            
            dl:AddCircle(imgui.ImVec2(cx, cy), midRadius + 2, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.6)), 48, 1.5)
            
            if distToCenter > innerRadius and distToCenter <= midRadius then
                local a = math.atan2(my - cy, mx - cx)
                if a < groupStart then a = a + math.pi * 2 end
                local relA = (a - groupStart) % (math.pi * 2)
                previewHoverInner = math.floor(relA / groupAngle) + 1
                if imgui.IsMouseClicked(0) then 
                    tState.selectedInner = previewHoverInner 
                    tState.selectedOuter = -1
                end
            elseif distToCenter > midRadius and distToCenter <= outerRadius then
                previewHoverInner = tState.selectedInner
                local grp = tSet.groups[tostring(tState.selectedInner)]
                local actionCount = grp and grp.count or 6
                local actionAngle = (math.pi * 2) / actionCount
                local actionStart = -math.pi / 2 - (actionAngle / 2)
                local a = math.atan2(my - cy, mx - cx)
                if a < actionStart then a = a + math.pi * 2 end
                local relA = (a - actionStart) % (math.pi * 2)
                previewHoverOuter = math.floor(relA / actionAngle) + 1
                if imgui.IsMouseClicked(0) then
                    tState.selectedOuter = previewHoverOuter
                end
            end
            
            for i = 1, groupCount do
                local a_start = groupStart + (i - 1) * groupAngle
                local a_end = groupStart + i * groupAngle
                local isHovered = (previewHoverInner == i)
                local isActive = (tState.selectedInner == i)
                
                local baseAlpha = tSet.transparency or 0.8
                local secColor = imgui.ImVec4(tSet.sectorColor[1], tSet.sectorColor[2], tSet.sectorColor[3], baseAlpha)
                
                if isActive then 
                    secColor = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, baseAlpha + 0.3)
                elseif isHovered then
                    secColor = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, baseAlpha + 0.1)
                end
                
                DrawDonutSector(dl, cx, cy, midRadius, innerRadius, a_start, a_end, imgui.GetColorU32Vec4(secColor))
                local bordColor = (isActive or isHovered) and imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0)) or imgui.GetColorU32Vec4(imgui.ImVec4(0.2, 0.2, 0.2, 0.8))
                rmath.DrawArcLine(dl, cx, cy, midRadius, a_start, a_end, bordColor, (isActive or isHovered) and 2.5 or 1.5)
                dl:AddLine(imgui.ImVec2(cx + math.cos(a_start)*innerRadius, cy + math.sin(a_start)*innerRadius), imgui.ImVec2(cx + math.cos(a_start)*midRadius, cy + math.sin(a_start)*midRadius), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.3)), 1.5)
                
                local grp = tSet.groups[tostring(i)]
                local rawText = grp and u8(grp.name) or u8"Группа "..i
                local textX, textY = rmath.GetSectorCenter(cx, cy, innerRadius + (midRadius - innerRadius)/2, a_start, a_end)
                local secText = wrapText(string.sub(rawText, 1, 10), 10)
                local tSize = imgui.CalcTextSize(secText)
                dl:AddText(imgui.ImVec2(textX - tSize.x/2, textY - tSize.y/2), imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, (isActive or isHovered) and 1.0 or 0.5)), secText)
            end
            
            local activeGroupPreview = tState.selectedInner
            if previewHoverInner ~= -1 then activeGroupPreview = previewHoverInner end
            
            if activeGroupPreview ~= -1 then
                dl:AddCircle(imgui.ImVec2(cx, cy), outerRadius + 2, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.3)), 48, 1.5)
                dl:AddCircle(imgui.ImVec2(cx, cy), outerInnerRadius - 2, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.3)), 48, 1.5)

                local grp = tSet.groups[tostring(activeGroupPreview)]
                local actionCount = grp and grp.count or 6
                local actionAngle = (math.pi * 2) / actionCount
                local actionStart = -math.pi / 2 - (actionAngle / 2)
                
                for j = 1, actionCount do
                    local a_start = actionStart + (j - 1) * actionAngle
                    local a_end = actionStart + j * actionAngle
                    
                    local isHoveredOuter = (previewHoverOuter == j)
                    local isActiveOuter = (tState.selectedInner == activeGroupPreview and tState.selectedOuter == j)
                    
                    local baseAlpha = tSet.transparency or 0.8
                    local secColor = imgui.ImVec4(tSet.sectorColor[1], tSet.sectorColor[2], tSet.sectorColor[3], baseAlpha - 0.1)
                    
                    if isActiveOuter then 
                        secColor = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, baseAlpha + 0.2)
                    elseif isHoveredOuter then
                        secColor = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, baseAlpha + 0.1)
                    end
                    
                    DrawDonutSector(dl, cx, cy, outerRadius, outerInnerRadius, a_start, a_end, imgui.GetColorU32Vec4(secColor))
                    local bordColor = (isHoveredOuter or isActiveOuter) and imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0)) or imgui.GetColorU32Vec4(imgui.ImVec4(0.2, 0.2, 0.2, 0.8))
                    rmath.DrawArcLine(dl, cx, cy, outerRadius, a_start, a_end, bordColor, (isHoveredOuter or isActiveOuter) and 2.5 or 1.5)
                    rmath.DrawArcLine(dl, cx, cy, outerInnerRadius, a_start, a_end, bordColor, (isHoveredOuter or isActiveOuter) and 2.5 or 1.5)
                    dl:AddLine(imgui.ImVec2(cx + math.cos(a_start)*outerInnerRadius, cy + math.sin(a_start)*outerInnerRadius), imgui.ImVec2(cx + math.cos(a_start)*outerRadius, cy + math.sin(a_start)*outerRadius), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.3)), 1.5)
                    
                    local textX, textY = rmath.GetSectorCenter(cx, cy, outerInnerRadius + (outerRadius - outerInnerRadius)/2, a_start, a_end)
                    local secText = u8"Бинд "..j
                    local tSize = imgui.CalcTextSize(secText)
                    dl:AddText(imgui.ImVec2(textX - tSize.x/2, textY - tSize.y/2), imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, (isHoveredOuter or isActiveOuter) and 1.0 or 0.6)), secText)
                end
            end
        end

        dl:AddCircleFilled(imgui.ImVec2(cx, cy), innerRadius, imgui.GetColorU32Vec4(imgui.ImVec4(sb_color[1], sb_color[2], sb_color[3], 1.0)), 32)
        dl:AddCircle(imgui.ImVec2(cx, cy), innerRadius, imgui.GetColorU32Vec4(c_accent), 32, 2.5)

        local centerText = tostring(tState.selectedInner)
        local ctSize = imgui.CalcTextSize(centerText)
        dl:AddText(imgui.ImVec2(cx - ctSize.x/2, cy - ctSize.y/2), imgui.GetColorU32Vec4(c_accent), centerText)

        utils.EndCard()
        imgui.Spacing()

        local bindNames = {u8"- Не назначено -"}
        local bindKeys = {""} 
        buildTreeForCombos(MFT.binds, "", 0, bindNames, bindKeys)
        local comboItems = ffi.new("const char*[?]", #bindNames)
        for i=1, #bindNames do comboItems[i-1] = bindNames[i] end

        if tSet.menuMode == 0 then
            local activeSec = tState.selectedInner
            local cardTitle = u8("ПРИВЯЗКА: СЕКТОР " .. tostring(activeSec))
            utils.BeginCard(dash, dt, "TargetSettingsSector", 140, cardTitle, c_accent, sb_color)
            
            local secKey = tostring(activeSec)
            local curIdx = 0
            local savedPath = tostring(tSet.radialBinds[secKey] or "")
            if savedPath ~= "" then
                for i, k in ipairs(bindKeys) do
                    if k == savedPath then curIdx = i - 1; break end
                end
            end
            
            local comboIdx = ffi.new("int[1]", curIdx)
            imgui.PushItemWidth(-1)
            if imgui.Combo("##bindSelect", comboIdx, comboItems, #bindNames) then
                if comboIdx[0] == 0 then tSet.radialBinds[secKey] = nil else tSet.radialBinds[secKey] = bindKeys[comboIdx[0] + 1] end
                engine.saveData()
            end
            imgui.PopItemWidth()
            
            imgui.Spacing(); imgui.Spacing()
            
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.3))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.8, 0.2, 0.2, 0.8))
            imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
            if imgui.Button(u8"Очистить сектор", imgui.ImVec2(-1, 35)) then
                tSet.radialBinds[secKey] = nil
                engine.saveData()
            end
            imgui.PopStyleVar()
            imgui.PopStyleColor(2)
            
            utils.EndCard()
            
        else
            if tState.selectedOuter == -1 then
                local cardTitle = u8("НАСТРОЙКА: ГРУППА " .. tostring(tState.selectedInner))
                utils.BeginCard(dash, dt, "TargetSettingsGroup", 160, cardTitle, c_accent, sb_color)
                local grp = tSet.groups[tostring(tState.selectedInner)]
                
                imgui.Columns(2, "tgrp_settings_cols", false)
                imgui.TextColored(c_accent, u8"Имя группы:")
                local grpName = ffi.new("char[256]", u8(grp.name))
                imgui.PushItemWidth(-1)
                if imgui.InputText("##grpName", grpName, 256) then
                    grp.name = u8:decode(ffi.string(grpName)); engine.saveData()
                end
                imgui.PopItemWidth()
                
                imgui.NextColumn()
                imgui.TextColored(c_accent, u8"Количество биндов (внешних секторов):")
                local grpCount = ffi.new("int[1]", grp.count)
                imgui.PushItemWidth(-1)
                if imgui.InputInt("##grpCount", grpCount, 1, 2) then
                    if grpCount[0] < 4 then grpCount[0] = 4 end
                    if grpCount[0] > 12 then grpCount[0] = 12 end
                    grp.count = tonumber(grpCount[0]); engine.saveData()
                end
                imgui.PopItemWidth()
                imgui.Columns(1)
                utils.EndCard()
            else
                local grp = tSet.groups[tostring(tState.selectedInner)]
                local actIdx = tState.selectedOuter
                local cardText = u8("ПРИВЯЗКА: ГРУППА " .. tostring(tState.selectedInner)) .. u8(" -> БИНД " .. tostring(actIdx))
                utils.BeginCard(dash, dt, "TargetSettingsAction", 140, cardText, c_accent, sb_color)
                
                local curIdx = 0
                local savedPath = tostring(grp.binds[tostring(actIdx)] or "")
                if savedPath ~= "" then
                    for i, k in ipairs(bindKeys) do
                        if k == savedPath then curIdx = i - 1; break end
                    end
                end
                
                local comboIdx = ffi.new("int[1]", curIdx)
                imgui.PushItemWidth(-1)
                if imgui.Combo("##gbnd_"..actIdx, comboIdx, comboItems, #bindNames) then
                    if comboIdx[0] == 0 then grp.binds[tostring(actIdx)] = nil else grp.binds[tostring(actIdx)] = bindKeys[comboIdx[0] + 1] end
                    engine.saveData()
                end
                imgui.PopItemWidth()
                
                imgui.Spacing(); imgui.Spacing()
                
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.3))
                imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.8, 0.2, 0.2, 0.8))
                imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
                if imgui.Button(u8"Очистить бинд", imgui.ImVec2(-1, 35)) then
                    grp.binds[tostring(actIdx)] = nil
                    engine.saveData()
                end
                imgui.PopStyleVar()
                imgui.PopStyleColor(2)
                
                utils.EndCard()
            end
        end
        imgui.EndChild()
        
        imgui.SameLine(0, 10)
        
        imgui.BeginChild("TargetRightCol", imgui.ImVec2(rightW, 0), false, imgui.WindowFlags.AlwaysVerticalScrollbar)

        utils.BeginCard(dash, dt, "TargetGeneral", 300, u8"ОБЩИЕ НАСТРОЙКИ", c_accent, sb_color)
        
        imgui.TextColored(c_accent, u8"Режим работы:")
        if imgui.RadioButtonBool(u8"Стандартное", tSet.menuMode == 0) then tSet.menuMode = 0; engine.saveData() end
        imgui.SameLine(0, 15)
        if imgui.RadioButtonBool(u8"С группами (Двойное кольцо)", tSet.menuMode == 1) then tSet.menuMode = 1; engine.saveData() end
        
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        imgui.TextColored(c_accent, u8"Количество основных секторов/групп (4-12):")
        imgui.PushItemWidth(100)
        if imgui.InputInt("##secCount", tState.tempSectorCount, 1, 2) then
            if tState.tempSectorCount[0] < 4 then tState.tempSectorCount[0] = 4 end
            if tState.tempSectorCount[0] > 12 then tState.tempSectorCount[0] = 12 end
            tSet.sectorsCount = tonumber(tState.tempSectorCount[0]) 
            if tState.selectedInner > tSet.sectorsCount then tState.selectedInner = 1 end
            engine.saveData()
        end
        imgui.PopItemWidth()

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        imgui.TextColored(c_accent, u8"Кнопка вызова (УДЕРЖИВАТЬ ПКМ + Кнопка):")
        local rk = tSet.radialKey
        local rkName = (rk == 0) and u8"Не назначена" or vk.id_to_name(rk)
        
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.6))
        if MFT.state.capturingTargetRadial then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.5, 0.2, 0.6))
            if imgui.Button(u8"Ожидание...##trk", imgui.ImVec2(-1, 30)) then MFT.state.capturingTargetRadial = false end
            imgui.PopStyleColor()
            for k=8, 255 do
                if imgui.IsKeyPressed(k) then
                    tSet.radialKey = (k == vk.VK_BACK or k == vk.VK_ESCAPE) and 0 or k
                    MFT.state.capturingTargetRadial = false; engine.saveData()
                    break
                end
            end
        else
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0,0,0,0))
            if imgui.Button(rkName.."##trk", imgui.ImVec2(-1, 30)) then MFT.state.capturingTargetRadial = true end
            imgui.PopStyleColor()
        end
        imgui.PopStyleColor(); imgui.PopStyleVar()

        utils.EndCard()
        imgui.Spacing()
        
        utils.BeginCard(dash, dt, "TargetVisuals", 160, u8"ВНЕШНИЙ ВИД", c_accent, sb_color)
        imgui.PushItemWidth(-1)
        local fRad = ffi.new("float[1]", tSet.radius or 150.0)
        if imgui.SliderFloat("##t_rad_size", fRad, 100.0, 300.0, u8"Размер: %.1f") then
            tSet.radius = tonumber(fRad[0]); engine.saveData() 
        end
        local fTrans = ffi.new("float[1]", tSet.transparency or 0.8)
        if imgui.SliderFloat("##t_rad_trans", fTrans, 0.1, 1.0, u8"Прозрачность: %.2f") then
            tSet.transparency = tonumber(fTrans[0]); engine.saveData() 
        end
        imgui.PopItemWidth()
        utils.EndCard()
        imgui.Spacing()

        local quickKeysCount = #tSet.quickKeys
        local qH = math.max(120, 110 + (quickKeysCount * 45))
        
        utils.BeginCard(dash, dt, "TargetQuickBinds", qH, u8"БЫСТРЫЕ БИНДЫ (ПКМ + КНОПКА)", c_accent, sb_color)
        imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1), u8"Используйте тег {radial} в этих биндах, чтобы подставить ID цели.")
        imgui.Spacing(); imgui.Spacing()

        local toRemove = -1

        for i, q in ipairs(tSet.quickKeys) do
            local qkName = (q.key == 0) and u8"Кнопка" or vk.id_to_name(q.key)

            imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.6))
            if MFT.state.capturingTargetQuick == i then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.5, 0.2, 0.6))
                if imgui.Button(u8"Ожидание...##qhk"..i, imgui.ImVec2(120, 30)) then MFT.state.capturingTargetQuick = 0 end
                imgui.PopStyleColor()
                for k=8, 255 do
                    if imgui.IsKeyPressed(k) then
                        q.key = (k == vk.VK_BACK or k == vk.VK_ESCAPE) and 0 or k
                        MFT.state.capturingTargetQuick = 0; engine.saveData()
                        break
                    end
                end
            else
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0,0,0,0))
                if imgui.Button(qkName.."##qhk"..i, imgui.ImVec2(120, 30)) then MFT.state.capturingTargetQuick = i end
                imgui.PopStyleColor()
            end
            imgui.PopStyleVar(); imgui.PopStyleColor()

            imgui.SameLine(0, 15)
            
            imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
            imgui.Text(u8"Привязка:")
            imgui.SameLine(0, 10)
            imgui.SetCursorPosY(imgui.GetCursorPosY() - 4)

            local curQkIdx = 0
            local savedQkPath = tostring(q.bind or "")
            if savedQkPath ~= "" and savedQkPath ~= "0" then
                for j, k in ipairs(bindKeys) do
                    if k == savedQkPath then curQkIdx = j - 1; break end
                end
            end
            local comboQkIdx = ffi.new("int[1]", curQkIdx)
            
            local availForCombo = imgui.GetContentRegionAvail().x - 45
            imgui.PushItemWidth(availForCombo)
            if imgui.Combo("##qb"..i, comboQkIdx, comboItems, #bindNames) then
                if comboQkIdx[0] == 0 then q.bind = 0
                else q.bind = bindKeys[comboQkIdx[0] + 1] end
                engine.saveData()
            end
            imgui.PopItemWidth()
            
            imgui.SameLine()
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.3))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.8, 0.2, 0.2, 0.8))
            imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
            if imgui.Button("X##delqk"..i, imgui.ImVec2(30, 30)) then toRemove = i end
            imgui.PopStyleVar(); imgui.PopStyleColor(2)
            
            imgui.Spacing()
        end

        if toRemove ~= -1 then
            table.remove(tSet.quickKeys, toRemove)
            engine.saveData()
        end

        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.15, 0.15, 1.0))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.4, 0.4, 0.4, 1.0))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        if imgui.Button(u8"Добавить быструю кнопку", imgui.ImVec2(-1, 35)) then
            table.insert(tSet.quickKeys, {key = 0, bind = 0})
            engine.saveData()
        end
        imgui.PopStyleVar(); imgui.PopStyleColor(2)

        utils.EndCard()
        
        imgui.EndChild() 
    end
    
    imgui.EndChild() 
end

return tab_interactions