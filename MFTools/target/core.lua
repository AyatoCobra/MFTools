-- Файл: MFTools/target/core.lua
local samp = require "lib.samp.events"
local vk = require "vkeys"
local imgui = require "mimgui"
local engine = require "MFTools.core.engine"
local tradial = require "MFTools.target.radial"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local tcore = {}

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

function tcore.process()
    if not MFT.settings.target.enabled then return end

    local valid, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
    if valid and doesCharExist(ped) then
        local res, id = sampGetPlayerIdByCharHandle(ped)
        if res then
            MFT.state.aimTargetId = id
            MFT.state.aimTargetName = sampGetPlayerNickname(id) or "Player"

            if not MFT.state.isMenuOpen and not sampIsChatInputActive() and not sampIsDialogActive() then
                for i, q in ipairs(MFT.settings.target.quickKeys) do
                    local qBindStr = tostring(q.bind)
                    if q.key ~= 0 and qBindStr ~= "0" and qBindStr ~= "" and wasKeyPressed(q.key) then
                        local item = resolvePath(qBindStr)
                        if item and item.type == "bind" then
                            engine.executeBind(item)
                        end
                    end
                end

                local rk = MFT.settings.target.radialKey or 82
                if wasKeyPressed(rk) then
                    tradial.open()
                end
            end
        end
    else
        if not tradial.isOpen then
            MFT.state.aimTargetId = -1
            MFT.state.aimTargetName = ""
        end
    end

    tradial.process()
end

function tcore.shouldDraw()
    if not MFT.settings.target.enabled then return false end
    return (MFT.state.aimTargetId ~= -1) or tradial.isOpen or tradial.openAnim > 0.01
end

function tcore.isRadialOpen()
    return tradial.isOpen
end

function tcore.drawUI()
    if not MFT.settings.target.enabled then return end

    local dt = imgui.GetIO().DeltaTime
    local showNotif = (MFT.state.aimTargetId ~= -1 and not tradial.isOpen)
    
    tcore.animValue = tcore.animValue or 0.0
    tcore.animValue = tcore.animValue + ((showNotif and 1.0 or 0.0) - tcore.animValue) * math.min(1.0, 15.0 * dt)

    if tcore.animValue > 0.01 then
        local resX, resY = getScreenResolution()
        
        local slideY = -100 + (170 * tcore.animValue)

        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, slideY), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, tcore.animValue)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.04, 0.04, 0.04, 0.95))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.9, 0.15, 0.15, 0.9))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.5)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(40, 25))

        imgui.Begin("TargetLockNotif", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoSavedSettings)
        
        local keyName = vk.id_to_name(MFT.settings.target.radialKey or 82) or "R"
        
        -- ПОЛНЫЙ ФИКС КОДИРОВКИ: Сначала склеиваем всю строку, потом конвертируем u8()
        local text1 = u8("[ЗАХВАТ] ЦЕЛЬ ЗАФИКСИРОВАНА: " .. tostring(MFT.state.aimTargetName) .. " [" .. tostring(MFT.state.aimTargetId) .. "]")
        local text2 = u8("Удерживайте [" .. tostring(keyName) .. "] для взаимодействия")
        
        local tSize1 = imgui.CalcTextSize(text1)
        local tSize2 = imgui.CalcTextSize(text2)
        local maxW = math.max(tSize1.x, tSize2.x)

        imgui.SetCursorPosX(imgui.GetCursorPosX() + (maxW - tSize1.x) / 2)
        imgui.TextColored(imgui.ImVec4(1.0, 1.0, 1.0, 1.0), text1)
        
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        
        imgui.SetCursorPosX(imgui.GetCursorPosX() + (maxW - tSize2.x) / 2)
        imgui.TextColored(imgui.ImVec4(0.9, 0.2, 0.2, 1.0), text2)

        imgui.End()
        
        imgui.PopStyleVar(3)
        imgui.PopStyleColor(2)
        imgui.PopStyleVar()
    end

    tradial.drawUI()
end

return tcore