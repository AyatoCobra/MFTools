-- ‘‡ÈÎ: MFTools/radial/radial_menu.lua
local imgui = require "mimgui"
local vk = require "vkeys"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local rmath = require "MFTools.radial.radial_math"
local engine = require "MFTools.core.engine"

local radial_menu = {
    isOpen = false,
    activeSector = -1,
    lockedGroup = -1,
    activeAction = -1,
    openAnim = 0.0,
    lastKeyState = false
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

local function resolvePath(pathStr)
    if type(pathStr) ~= "string" and type(pathStr) ~= "number" then return nil end
    pathStr = tostring(pathStr)
    if pathStr == "" or pathStr == "0" then return nil end
    
    local cur = MFT.binds
    local parts = {}
    for p in pathStr:gmatch("[^_]+") do table.insert(parts, tonumber(p)) end
    
    local lastItem = nil
    for i, p in ipairs(parts) do
        if not cur or not cur[p] then return nil end
        lastItem = cur[p]
        if i < #parts then cur = cur[p].items or {} end
    end
    return lastItem
end

function radial_menu.process()
    local rSet = MFT.settings.radial
    if not rSet or not rSet.enabled then return end

    local hk = tonumber(rSet.hotkey) 
    if not hk or hk == 0 then return end 

    local isPressed = isKeyDown(hk)
    local wasPressed = radial_menu.lastKeyState
    radial_menu.lastKeyState = isPressed

    if sampIsChatInputActive() or sampIsDialogActive() or MFT.state.isMenuOpen then
        radial_menu.isOpen = false
        radial_menu.lockedGroup = -1
        return
    end

    if isPressed and not wasPressed then
        if not radial_menu.isOpen then radial_menu.isOpen = true end
    elseif not isPressed and wasPressed then
        if radial_menu.isOpen then
            radial_menu.isOpen = false
            local style = tonumber(rSet.menuMode) or 0
            
            local binds = rSet.binds or {}
            local groups = rSet.groups or {}
            
            if style == 1 then
                if radial_menu.lockedGroup ~= -1 and radial_menu.activeAction ~= -1 then
                    local grp = groups[tostring(radial_menu.lockedGroup)]
                    if grp then
                        local grpBinds = grp.binds or {}
                        local item = resolvePath(grpBinds[tostring(radial_menu.activeAction)])
                        if item and item.type == "bind" then engine.executeBind(item) end
                    end
                end
            else
                if radial_menu.activeSector ~= -1 then
                    local item = resolvePath(binds[tostring(radial_menu.activeSector)])
                    if item and item.type == "bind" then engine.executeBind(item) end
                end
            end
            radial_menu.lockedGroup = -1
        end
    end
end

function radial_menu.drawUI()
    local dt = imgui.GetIO().DeltaTime
    local targetAlpha = radial_menu.isOpen and 1.0 or 0.0
    radial_menu.openAnim = radial_menu.openAnim + (targetAlpha - radial_menu.openAnim) * math.min(1.0, 15.0 * dt)

    if radial_menu.openAnim < 0.01 then return end

    local rSet = MFT.settings.radial
    local sw, sh = getScreenResolution()
    local cx, cy = sw / 2, sh / 2
    
    local outerRadius = rSet.radius or 260.0
    local innerRadius = outerRadius * 0.25
    local style = tonumber(rSet.menuMode) or 0
    
    local binds = rSet.binds or {}
    local groups = rSet.groups or {}

    imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
    
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, radial_menu.openAnim)
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.05, 0.05, 0.05, 0.5 * radial_menu.openAnim))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0.0)

    imgui.Begin("ActiveRadialMenu", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoInputs)

    local dl = imgui.GetWindowDrawList()
    local mx, my = imgui.GetMousePos().x, imgui.GetMousePos().y

    local c_accent = MFT.settings.colorAccent or {0.35, 0.55, 0.85, 1.0}
    local baseAlpha = rSet.transparency or 0.75
    local sCol = rSet.sectorColor or {0.08, 0.08, 0.08}
    local sb_color = MFT.settings.colorSidebar or {0.10, 0.10, 0.10}
    
    radial_menu.activeSector = -1
    radial_menu.activeAction = -1
    
    local distToCenter = math.sqrt((mx - cx)^2 + (my - cy)^2)

    if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end

    if style == 0 then
        -- === —“¿Õƒ¿–“ÕŒ≈ Ã≈Õﬁ ===
        local sectorsCount = rSet.sectorsCount or 6
        local sectorAngle = (math.pi * 2) / sectorsCount
        local startOffset = -math.pi / 2 - (sectorAngle / 2)
        
        dl:AddCircle(imgui.ImVec2(cx, cy), outerRadius + 8, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.3 * radial_menu.openAnim)), 64, 2.0)
        dl:AddCircle(imgui.ImVec2(cx, cy), outerRadius + 3, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.8 * radial_menu.openAnim)), 64, 1.5)

        if distToCenter > innerRadius and distToCenter <= outerRadius then
            local a = math.atan2(my - cy, mx - cx)
            if a < startOffset then a = a + math.pi * 2 end
            local relA = (a - startOffset) % (math.pi * 2)
            radial_menu.activeSector = math.floor(relA / sectorAngle) + 1
        end

        for i = 1, sectorsCount do
            local a_start = startOffset + (i - 1) * sectorAngle
            local a_end = startOffset + i * sectorAngle
            
            local isActive = (radial_menu.activeSector == i)
            local secColor = imgui.ImVec4(sCol[1], sCol[2], sCol[3], baseAlpha * radial_menu.openAnim)
            if isActive then secColor = imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], (baseAlpha + 0.2) * radial_menu.openAnim) end
            
            DrawDonutSector(dl, cx, cy, outerRadius, innerRadius, a_start, a_end, imgui.GetColorU32Vec4(secColor))
            
            local bordColor = isActive and imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0 * radial_menu.openAnim)) or imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.4 * radial_menu.openAnim))
            rmath.DrawArcLine(dl, cx, cy, outerRadius, a_start, a_end, bordColor, isActive and 2.5 or 1.5)
            dl:AddLine(imgui.ImVec2(cx + math.cos(a_start)*innerRadius, cy + math.sin(a_start)*innerRadius), imgui.ImVec2(cx + math.cos(a_start)*outerRadius, cy + math.sin(a_start)*outerRadius), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.3 * radial_menu.openAnim)), 1.5)

            -- »—œŒÀ‹«”≈Ã  ¿—“ŒÃÕŒ≈ »Ãﬂ
            local customName = rSet.names and rSet.names[tostring(i)]
            local secText = ""
            if customName and customName ~= "" then
                secText = customName
            else
                local item = resolvePath(binds[tostring(i)])
                local rawText = item and (item.name and u8(item.name) or u8"¡ËÌ‰") or u8"œÛÒÚÓ"
                local cleanText = rawText:gsub("{%x%x%x%x%x%x}", "")
                secText = cleanText:match("^%s*(%S+)") or cleanText
            end
            
            local textX, textY = rmath.GetSectorCenter(cx, cy, innerRadius + (outerRadius - innerRadius)/2, a_start, a_end)
            local tSize = imgui.CalcTextSize(secText)
            local textCol = imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, isActive and 1.0 or 0.6))
            
            if isActive then
                dl:AddText(imgui.ImVec2(textX - tSize.x/2 + 1, textY - tSize.y/2), textCol, secText)
                dl:AddText(imgui.ImVec2(textX - tSize.x/2, textY - tSize.y/2 + 1), textCol, secText)
            end
            dl:AddText(imgui.ImVec2(textX - tSize.x/2, textY - tSize.y/2), textCol, secText)
        end
    else
        -- === Ã≈Õﬁ — √–”œœ¿Ã» (‘» —¿÷»ﬂ Ã€ÿ») ===
        local groupCount = rSet.sectorsCount or 6
        local groupAngle = (math.pi * 2) / groupCount
        local groupStart = -math.pi / 2 - (groupAngle / 2)
        local midRadius = outerRadius * 0.55
        local gap = 8
        local outerInnerRadius = midRadius + gap
        
        dl:AddCircle(imgui.ImVec2(cx, cy), midRadius + 2, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.6 * radial_menu.openAnim)), 64, 1.5)
        
        if distToCenter > innerRadius and distToCenter <= midRadius then
            local a = math.atan2(my - cy, mx - cx)
            if a < groupStart then a = a + math.pi * 2 end
            local relA = (a - groupStart) % (math.pi * 2)
            radial_menu.lockedGroup = math.floor(relA / groupAngle) + 1
            radial_menu.activeAction = -1
        elseif distToCenter > midRadius and distToCenter <= outerRadius then
            if radial_menu.lockedGroup == -1 then
                local a = math.atan2(my - cy, mx - cx)
                if a < groupStart then a = a + math.pi * 2 end
                local relA = (a - groupStart) % (math.pi * 2)
                radial_menu.lockedGroup = math.floor(relA / groupAngle) + 1
            end
            
            local grp = groups[tostring(radial_menu.lockedGroup)]
            local actionCount = grp and grp.count or 6
            local actionAngle = (math.pi * 2) / actionCount
            local actionStart = -math.pi / 2 - (actionAngle / 2)
            
            local a = math.atan2(my - cy, mx - cx)
            if a < actionStart then a = a + math.pi * 2 end
            local relA = (a - actionStart) % (math.pi * 2)
            radial_menu.activeAction = math.floor(relA / actionAngle) + 1
        end

        if radial_menu.lockedGroup == -1 then radial_menu.lockedGroup = 1 end

        -- ŒÚËÒÓ‚Í‡ ‚ÌÛÚÂÌÌÂ„Ó ÍÓÎ¸ˆ‡ („ÛÔÔ˚)
        for i = 1, groupCount do
            local a_start = groupStart + (i - 1) * groupAngle
            local a_end = groupStart + i * groupAngle
            local isHovered = (radial_menu.lockedGroup == i)
            
            local secColor = imgui.ImVec4(sCol[1], sCol[2], sCol[3], baseAlpha * radial_menu.openAnim)
            if isHovered then secColor = imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], (baseAlpha + 0.2) * radial_menu.openAnim) end
            
            DrawDonutSector(dl, cx, cy, midRadius, innerRadius, a_start, a_end, imgui.GetColorU32Vec4(secColor))
            local bordColor = isHovered and imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0 * radial_menu.openAnim)) or imgui.GetColorU32Vec4(imgui.ImVec4(0.2, 0.2, 0.2, 0.8 * radial_menu.openAnim))
            rmath.DrawArcLine(dl, cx, cy, midRadius, a_start, a_end, bordColor, isHovered and 2.5 or 1.5)
            dl:AddLine(imgui.ImVec2(cx + math.cos(a_start)*innerRadius, cy + math.sin(a_start)*innerRadius), imgui.ImVec2(cx + math.cos(a_start)*midRadius, cy + math.sin(a_start)*midRadius), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.3 * radial_menu.openAnim)), 1.5)
            
            local grp = groups[tostring(i)]
            local rawText = grp and u8(grp.name) or u8"√ÛÔÔ‡ "..i
            
            local cleanText = rawText:gsub("{%x%x%x%x%x%x}", "")
            local secText = cleanText:match("^%s*(%S+)") or cleanText
            
            local textX, textY = rmath.GetSectorCenter(cx, cy, innerRadius + (midRadius - innerRadius)/2, a_start, a_end)
            local tSize = imgui.CalcTextSize(secText)
            local textCol = imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, isHovered and 1.0 or 0.5))
            
            if isHovered then
                dl:AddText(imgui.ImVec2(textX - tSize.x/2 + 1, textY - tSize.y/2), textCol, secText)
                dl:AddText(imgui.ImVec2(textX - tSize.x/2, textY - tSize.y/2 + 1), textCol, secText)
            end
            dl:AddText(imgui.ImVec2(textX - tSize.x/2, textY - tSize.y/2), textCol, secText)
        end
        
        -- ŒÚËÒÓ‚Í‡ ‚ÌÂ¯ÌÂ„Ó ÍÓÎ¸ˆ‡ (·ËÌ‰˚)
        dl:AddCircle(imgui.ImVec2(cx, cy), outerRadius + 2, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.3 * radial_menu.openAnim)), 48, 1.5)
        dl:AddCircle(imgui.ImVec2(cx, cy), outerInnerRadius - 2, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.3 * radial_menu.openAnim)), 48, 1.5)

        local grp = groups[tostring(radial_menu.lockedGroup)]
        local actionCount = grp and grp.count or 6
        local actionAngle = (math.pi * 2) / actionCount
        local actionStart = -math.pi / 2 - (actionAngle / 2)
        
        for j = 1, actionCount do
            local a_start = actionStart + (j - 1) * actionAngle
            local a_end = actionStart + j * actionAngle
            local isHoveredOuter = (radial_menu.activeAction == j)
            
            local secColor = imgui.ImVec4(sCol[1], sCol[2], sCol[3], (baseAlpha - 0.1) * radial_menu.openAnim)
            if isHoveredOuter then secColor = imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], (baseAlpha + 0.1) * radial_menu.openAnim) end
            
            DrawDonutSector(dl, cx, cy, outerRadius, outerInnerRadius, a_start, a_end, imgui.GetColorU32Vec4(secColor))
            local bordColor = isHoveredOuter and imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0 * radial_menu.openAnim)) or imgui.GetColorU32Vec4(imgui.ImVec4(0.2, 0.2, 0.2, 0.8 * radial_menu.openAnim))
            rmath.DrawArcLine(dl, cx, cy, outerRadius, a_start, a_end, bordColor, isHoveredOuter and 2.5 or 1.5)
            rmath.DrawArcLine(dl, cx, cy, outerInnerRadius, a_start, a_end, bordColor, isHoveredOuter and 2.5 or 1.5)
            dl:AddLine(imgui.ImVec2(cx + math.cos(a_start)*outerInnerRadius, cy + math.sin(a_start)*outerInnerRadius), imgui.ImVec2(cx + math.cos(a_start)*outerRadius, cy + math.sin(a_start)*outerRadius), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.3 * radial_menu.openAnim)), 1.5)
            
            -- »—œŒÀ‹«”≈Ã  ¿—“ŒÃÕŒ≈ »Ãﬂ
            local actKey = tostring(radial_menu.lockedGroup) .. "_" .. tostring(j)
            local customName = rSet.names and rSet.names[actKey]
            local secText = ""
            if customName and customName ~= "" then
                secText = customName
            else
                local item = nil
                if grp then 
                    local grpBinds = grp.binds or {}
                    item = resolvePath(grpBinds[tostring(j)]) 
                end
                local rawText = item and (item.name and u8(item.name) or u8"¡ËÌ‰") or u8"œÛÒÚÓ"
                local cleanText = rawText:gsub("{%x%x%x%x%x%x}", "")
                secText = cleanText:match("^%s*(%S+)") or cleanText
            end
            
            local textX, textY = rmath.GetSectorCenter(cx, cy, outerInnerRadius + (outerRadius - outerInnerRadius)/2, a_start, a_end)
            local tSize = imgui.CalcTextSize(secText)
            local textCol = imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, isHoveredOuter and 1.0 or 0.6))
            
            if isHoveredOuter then
                dl:AddText(imgui.ImVec2(textX - tSize.x/2 + 1, textY - tSize.y/2), textCol, secText)
                dl:AddText(imgui.ImVec2(textX - tSize.x/2, textY - tSize.y/2 + 1), textCol, secText)
            end
            dl:AddText(imgui.ImVec2(textX - tSize.x/2, textY - tSize.y/2), textCol, secText)
        end
    end

    dl:AddCircleFilled(imgui.ImVec2(cx, cy), innerRadius, imgui.GetColorU32Vec4(imgui.ImVec4(sb_color[1], sb_color[2], sb_color[3], 1.0 * radial_menu.openAnim)), 32)
    dl:AddCircle(imgui.ImVec2(cx, cy), innerRadius, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0 * radial_menu.openAnim)), 32, 2.5)

    local centerText = "-"
    if style == 0 and radial_menu.activeSector ~= -1 then
        centerText = tostring(radial_menu.activeSector)
    elseif style == 1 and radial_menu.lockedGroup ~= -1 then
        centerText = tostring(radial_menu.lockedGroup)
    end
    
    local ctSize = imgui.CalcTextSize(centerText)
    dl:AddText(imgui.ImVec2(cx - ctSize.x/2, cy - ctSize.y/2), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0 * radial_menu.openAnim)), centerText)
    if MFT.fonts.title then imgui.PopFont() end

    imgui.End()
    imgui.PopStyleVar(2)
    imgui.PopStyleColor()
end

return radial_menu