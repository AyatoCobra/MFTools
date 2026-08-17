-- Файл: MFTools/ui/tab_create.lua
local imgui = require "mimgui"
local ffi = require "ffi"
local vk = require "vkeys"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local engine = require "MFTools.core.engine"
local utils = require "MFTools.ui.utils"
local uistate = require "MFTools.ui.uistate"

local tab_create = {}

local function insertToTextBox(str)
    local current = ffi.string(uistate.newBindText)
    ffi.copy(uistate.newBindText, current .. str)
end

local function getFolderPaths(list, prefix, depth, names, paths)
    for i, item in ipairs(list) do
        if item.type == "folder" then
            local curPath = prefix == "" and tostring(i) or (prefix .. "_" .. i)
            local indent = string.rep("- ", depth)
            local cleanName = item.name and u8(item.name) or u8"Папка"
            table.insert(names, indent .. "> " .. cleanName)
            table.insert(paths, curPath)
            getFolderPaths(item.items or {}, curPath, depth + 1, names, paths)
        end
    end
end

function tab_create.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    utils.BeginCard(dash, dt, "CreateBind", -1, u8"Создание нового бинда", c_accent, sb_color)
    imgui.BeginChild("CreateBindScroll", imgui.ImVec2(0, 0), false, imgui.WindowFlags.AlwaysVerticalScrollbar)
    
    imgui.Columns(2, "cb_name_hk_cols", false)
    imgui.SetColumnWidth(0, (availWidth - 50) * 0.65)
    
    imgui.Text(u8"Название:")
    imgui.PushItemWidth(-1)
    imgui.InputText("##cb_Name", uistate.newBindName, ffi.sizeof(uistate.newBindName))
    imgui.PopItemWidth()
    
    imgui.NextColumn()
    imgui.Text(u8"Горячая клавиша:")
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
    if dash.anims.capturingHotkeyCreate then
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.5, 0.2, 0.6))
        if imgui.Button(u8"Ожидание...##cb_hk", imgui.ImVec2(-1, 30)) then dash.anims.capturingHotkeyCreate = false end
        imgui.PopStyleColor()
        for k = 8, 255 do
            if imgui.IsKeyPressed(k) then
                if k == vk.VK_BACK or k == vk.VK_ESCAPE then uistate.newBindHotkey[0] = 0
                else uistate.newBindHotkey[0] = k end
                dash.anims.capturingHotkeyCreate = false
                break
            end
        end
    else
        local kn = (uistate.newBindHotkey[0] == 0) and u8"Не назначена" or vk.id_to_name(uistate.newBindHotkey[0])
        if imgui.Button(kn.."##cb_hk", imgui.ImVec2(-1, 30)) then dash.anims.capturingHotkeyCreate = true end
    end
    imgui.PopStyleVar()
    imgui.Columns(1)
    
    imgui.Spacing(); imgui.Spacing()
    
    local fNames = { u8"Корень" }
    local fPaths = { "" }
    getFolderPaths(MFT.binds, "", 1, fNames, fPaths)
    
    local comboItems = ffi.new("const char*[?]", #fNames)
    for i=1, #fNames do comboItems[i-1] = fNames[i] end
    
    if not uistate.createTargetFolderIdx then uistate.createTargetFolderIdx = ffi.new("int[1]", 0) end
    if uistate.createTargetFolderIdx[0] >= #fNames then uistate.createTargetFolderIdx[0] = 0 end
    
    imgui.Text(u8"Куда сохранить:")
    imgui.PushItemWidth(-1)
    imgui.Combo("##targetFolder", uistate.createTargetFolderIdx, comboItems, #fNames)
    imgui.PopItemWidth()

    imgui.Spacing(); imgui.Spacing()
    
    imgui.Text(u8"Текст бинда (Enter = новая строка):")
    imgui.InputTextMultiline("##cb_Text", uistate.newBindText, ffi.sizeof(uistate.newBindText), imgui.ImVec2(-1, 180))
    
    imgui.Spacing(); imgui.TextColored(c_accent, u8"Умные теги (Нажмите для вставки):")
    
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.2))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.6))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
    
    if imgui.Button("{target}", imgui.ImVec2(80, 30)) then insertToTextBox("{target}") end
    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Ближайший игрок (ID)") end
    imgui.SameLine()
    
    if imgui.Button("{namet}", imgui.ImVec2(80, 30)) then insertToTextBox("{namet}") end
    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Имя ближайшего игрока") end
    imgui.SameLine()
    
    if imgui.Button("{radial}", imgui.ImVec2(80, 30)) then insertToTextBox("{radial}") end
    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Вставит ID игрока, на которого вы целитесь (ПКМ)") end
    imgui.SameLine()
    
    if imgui.Button("{weapon}", imgui.ImVec2(80, 30)) then insertToTextBox("{weapon}") end
    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Оружие в руках") end
    imgui.SameLine()
    
    if imgui.Button("{dialog}", imgui.ImVec2(80, 30)) then insertToTextBox("{dialog}") end
    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Запросить ввод текста при активации") end
    
    imgui.PopStyleVar(); imgui.PopStyleColor(2)
    
    imgui.Spacing(); imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    
    imgui.Columns(2, "cb_delay_ovl_cols", false)
    imgui.SetColumnWidth(0, (availWidth - 50) * 0.65)
    
    imgui.Text(u8"Задержка (мс):")
    imgui.PushItemWidth(-1)
    imgui.SliderInt("##cb_Delay", uistate.newBindDelay, 100, 5000)
    imgui.PopItemWidth()
    
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 20)
    imgui.Checkbox(u8"Отображать в оверлее", uistate.newBindOverlay)
    imgui.Columns(1)
    
    imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
    
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0))
    if imgui.Button(u8"Сохранить бинд", imgui.ImVec2(-1, 45)) then
        local nameStr = ffi.string(uistate.newBindName)
        local textStr = ffi.string(uistate.newBindText)
        
        if #nameStr > 0 and #textStr > 0 then
            local lines = {}
            for line in textStr:gmatch("[^\r\n]+") do table.insert(lines, u8:decode(line)) end
            
            local newBindObj = {
                type = "bind",
                name = u8:decode(nameStr),
                lines = lines,
                delay = tonumber(uistate.newBindDelay[0]),
                showInOverlay = (uistate.newBindOverlay[0] == true),
                hotkey = tonumber(uistate.newBindHotkey[0])
            }
            
            local selectedPath = fPaths[uistate.createTargetFolderIdx[0] + 1]
            local targetList = MFT.binds
            
            if selectedPath ~= "" then
                local parts = {}
                for p in string.gmatch(selectedPath, "[^_]+") do table.insert(parts, tonumber(p)) end
                local cur = MFT.binds
                local lastFolder = nil
                for _, p in ipairs(parts) do
                    if not cur[p] then break end
                    lastFolder = cur[p]
                    cur = cur[p].items or {}
                end
                if lastFolder and lastFolder.type == "folder" then
                    if not lastFolder.items then lastFolder.items = {} end
                    targetList = lastFolder.items
                end
            end
            
            table.insert(targetList, newBindObj)
            
            ffi.fill(uistate.newBindName, 256)
            ffi.fill(uistate.newBindText, 4096)
            uistate.newBindHotkey[0] = 0
            
            engine.saveData()
            sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Бинд успешно создан!", -1)
        else
            sampAddChatMessage("{FF0000}[MFTools] {FFFFFF}Ошибка: Заполните название и текст бинда!", -1)
        end
    end
    imgui.PopStyleColor(); imgui.PopStyleVar()
    
    imgui.EndChild()
    utils.EndCard()
end

return tab_create