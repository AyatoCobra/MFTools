-- Файл: MFTools/ui/tab_binds.lua
local imgui = require "mimgui"
local ffi = require "ffi"
local vk = require "vkeys"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local engine = require "MFTools.core.engine"
local utils = require "MFTools.ui.utils"
local uistate = require "MFTools.ui.uistate"

local tab_binds = {}

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
    else 
        copy = orig
    end
    return copy
end

local function drawFolderTreeForMove(list, bindToMove, parentListToMoveFrom, indexToMove)
    for fi, f in ipairs(list) do
        if f.type == "folder" then
            if imgui.Selectable(u8(f.name)) then
                local b = table.remove(parentListToMoveFrom, indexToMove)
                if not f.items then f.items = {} end
                table.insert(f.items, b)
                engine.saveData()
            end
        end
    end
end

function tab_binds.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    if not uistate.newFolderName then uistate.newFolderName = ffi.new("char[256]", "") end
    if type(MFT.state.folderPath) ~= "table" then MFT.state.folderPath = {} end
    if not MFT.state.deleteConfirmIndex then MFT.state.deleteConfirmIndex = -1 end

    local currentList = MFT.binds
    local parentList = nil
    local currentFolderName = "Корень"

    for _, idx in ipairs(MFT.state.folderPath) do
        if currentList[idx] then
            currentFolderName = currentList[idx].name
            parentList = currentList
            currentList = currentList[idx].items
        else
            MFT.state.folderPath = {}
            currentList = MFT.binds
            break
        end
    end

    utils.BeginCard(dash, dt, "ControlPanel", 85, nil, c_accent, sb_color)
    local startY = imgui.GetCursorPos().y
    
    imgui.SetCursorPos(imgui.ImVec2(20, startY + 4))
    local cpos = imgui.GetCursorScreenPos()
    local sW, sH = 120, 45
    local bW = 56
    
    local viewMode = tonumber(MFT.settings.bindsViewMode) or 0
    local targetToggle = (viewMode == 1) and 1.0 or 0.0
    dash.anims.viewToggle = dash.anims.viewToggle or targetToggle
    dash.anims.viewToggle = dash.anims.viewToggle + (targetToggle - dash.anims.viewToggle) * math.min(1.0, 15.0 * dt)
    
    local dl = imgui.GetWindowDrawList()
    dl:AddRectFilled(cpos, imgui.ImVec2(cpos.x + sW, cpos.y + sH), imgui.GetColorU32Vec4(imgui.ImVec4(sb_color[1], sb_color[2], sb_color[3], 0.9)), 12.0)
    local slideOffset = dash.anims.viewToggle * (sW - bW - 6)
    local slideX = cpos.x + 3 + slideOffset
    dl:AddRectFilled(imgui.ImVec2(slideX, cpos.y + 3), imgui.ImVec2(slideX + bW, cpos.y + sH - 3), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.6)), 10.0)
    dl:AddRect(imgui.ImVec2(slideX, cpos.y + 3), imgui.ImVec2(slideX + bW, cpos.y + sH - 3), imgui.GetColorU32Vec4(c_accent), 10.0, 0, 2.0)
    
    local iconSize = 26
    if dash.icons and dash.icons.list then
        local tintL = 1.0 - (0.5 * dash.anims.viewToggle)
        dl:AddImage(dash.icons.list, imgui.ImVec2(cpos.x + 18, cpos.y + 9), imgui.ImVec2(cpos.x + 18 + iconSize, cpos.y + 9 + iconSize), imgui.ImVec2(0,0), imgui.ImVec2(1,1), imgui.GetColorU32Vec4(imgui.ImVec4(tintL, tintL, tintL, 1)))
    end
    if dash.icons and dash.icons.grid then
        local tintG = 0.5 + (0.5 * dash.anims.viewToggle)
        dl:AddImage(dash.icons.grid, imgui.ImVec2(cpos.x + sW - 18 - iconSize, cpos.y + 9), imgui.ImVec2(cpos.x + sW - 18, cpos.y + 9 + iconSize), imgui.ImVec2(0,0), imgui.ImVec2(1,1), imgui.GetColorU32Vec4(imgui.ImVec4(tintG, tintG, tintG, 1)))
    end
    
    imgui.SetCursorScreenPos(cpos)
    if imgui.InvisibleButton("##view_list", imgui.ImVec2(sW/2, sH)) then MFT.settings.bindsViewMode = 0; engine.saveData() end
    imgui.SameLine(0, 0)
    if imgui.InvisibleButton("##view_grid", imgui.ImVec2(sW/2, sH)) then MFT.settings.bindsViewMode = 1; engine.saveData() end
    
    if #MFT.state.folderPath > 0 then
        local fNameShort = currentFolderName
        if #fNameShort > 15 then fNameShort = fNameShort:sub(1, 15) .. ".." end
        
        local prText = MFT.state.presetsExpanded and u8"Скрыть пресеты" or (u8"Добавить пресет в: " .. u8(fNameShort))
        
        local bw_preset = imgui.CalcTextSize(prText).x + 40
        local bw_new = 150
        local bw_back = 100
        local bw_del = 45
        local totalBtns = bw_preset + bw_new + bw_back + bw_del + 30
        
        imgui.SetCursorPos(imgui.ImVec2(availWidth - totalBtns - 20, startY + 4))
        
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.15))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        if imgui.Button(prText, imgui.ImVec2(bw_preset, 45)) then MFT.state.presetsExpanded = not MFT.state.presetsExpanded end
        imgui.SameLine(0, 10)
        
        if imgui.Button(u8"Создать папку", imgui.ImVec2(bw_new, 45)) then
            ffi.fill(uistate.newFolderName, 256) 
            imgui.OpenPopup(u8"Создание папки")
        end
        imgui.SameLine(0, 10)
        
        if imgui.Button(u8"Назад", imgui.ImVec2(bw_back, 45)) then table.remove(MFT.state.folderPath) end
        imgui.PopStyleColor(2); imgui.PopStyleVar()
        imgui.SameLine(0, 10)
        
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.2))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.9, 0.2, 0.2, 0.5))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.9, 0.2, 0.2, 0.8))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.5)
        
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
        if imgui.Button("X", imgui.ImVec2(bw_del, 45)) then
            MFT.state.deleteConfirmIndex = MFT.state.folderPath[#MFT.state.folderPath]
            MFT.state.deleteConfirmList = parentList
            MFT.state.deleteConfirmIsFolderActive = true
            imgui.OpenPopup("DeleteConfirmPopup")
        end
        if MFT.fonts.title then imgui.PopFont() end
        if imgui.IsItemHovered() then imgui.SetTooltip(u8"Удалить текущую папку") end
        
        imgui.PopStyleColor(3); imgui.PopStyleVar()
    else
        local prTextRoot = MFT.state.presetsExpanded and u8"Скрыть базу пресетов" or u8"Добавить пресет из базы"
        local bw_presetRoot = imgui.CalcTextSize(prTextRoot).x + 40
        local bw_newRoot = 150
        local totalBtnsRoot = bw_presetRoot + bw_newRoot + 10
        
        imgui.SetCursorPos(imgui.ImVec2(availWidth - totalBtnsRoot - 20, startY + 4))
        
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.15))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        
        if imgui.Button(prTextRoot, imgui.ImVec2(bw_presetRoot, 45)) then
            MFT.state.presetsExpanded = not MFT.state.presetsExpanded
        end
        imgui.SameLine(0, 10)
        
        if imgui.Button(u8"Создать папку", imgui.ImVec2(bw_newRoot, 45)) then
            ffi.fill(uistate.newFolderName, 256) 
            imgui.OpenPopup(u8"Создание папки")
        end
        
        imgui.PopStyleColor(2); imgui.PopStyleVar()
    end

    imgui.SetNextWindowSize(imgui.ImVec2(400, 180), imgui.Cond.Always)
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.08, 1.0))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
    if imgui.BeginPopupModal(u8"Создание папки", nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
        imgui.Spacing()
        imgui.Text(u8"Название новой папки:")
        imgui.Spacing()
        imgui.PushItemWidth(-1)
        imgui.InputText("##fname", uistate.newFolderName, 256)
        imgui.PopItemWidth()
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0))
        local btnW = (imgui.GetContentRegionAvail().x - 10) / 2
        if imgui.Button(u8"Создать", imgui.ImVec2(btnW, 40)) then
            table.insert(currentList, { type = "folder", name = u8:decode(ffi.string(uistate.newFolderName)), items = {} })
            engine.saveData()
            imgui.CloseCurrentPopup()
        end
        imgui.PopStyleColor()
        
        imgui.SameLine(0, 10)
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.4))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
        if imgui.Button(u8"Отмена", imgui.ImVec2(btnW, 40)) then imgui.CloseCurrentPopup() end
        imgui.PopStyleColor(2); imgui.PopStyleVar()
        imgui.EndPopup()
    end
    imgui.PopStyleVar(2); imgui.PopStyleColor(2)

    utils.EndCard()
    
    if #MFT.state.folderPath > 0 then
        imgui.Spacing(); imgui.Spacing()
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
        
        local b_parts = { {text = u8"Корень", col = nil} }
        local tempPathList = MFT.binds
        for i, idx in ipairs(MFT.state.folderPath) do
            if tempPathList[idx] then
                table.insert(b_parts, {text = " - ", col = nil})
                if i == #MFT.state.folderPath then
                    table.insert(b_parts, {text = u8(tempPathList[idx].name), col = c_accent})
                else
                    table.insert(b_parts, {text = u8(tempPathList[idx].name), col = nil})
                end
                tempPathList = tempPathList[idx].items or {}
            end
        end
        
        local total_w = 0
        for _, p in ipairs(b_parts) do total_w = total_w + imgui.CalcTextSize(p.text).x end
        
        imgui.SetCursorPosX((availWidth - total_w) / 2)
        for i, p in ipairs(b_parts) do
            if p.col then
                imgui.TextColored(p.col, p.text)
            else
                imgui.Text(p.text)
            end
            if i < #b_parts then imgui.SameLine(0, 0) end
        end
        
        if MFT.fonts.title then imgui.PopFont() end
        imgui.Spacing()
    else
        imgui.Spacing(); imgui.Spacing()
    end
    
    local presetH = 90.0 * dash.anims.presetsExpanded
    if presetH > 2.0 then
        utils.BeginCard(dash, dt, "PresetsPanel", presetH, nil, c_accent, sb_color)
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, dash.anims.presetsExpanded)
        
        local pSize = 44
        local pSpace = 6
        local totalPresetsW = (#uistate.factions * pSize) + ((#uistate.factions - 1) * pSpace)
        local startX = (availWidth - totalPresetsW) / 2
        if startX < 10 then startX = 10 end
        
        imgui.SetCursorPos(imgui.ImVec2(startX, 23))
        
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.5)
        for i, f in ipairs(uistate.factions) do
            local curP = imgui.GetCursorPos()
            local isHov = imgui.IsMouseHoveringRect(imgui.GetCursorScreenPos(), imgui.ImVec2(imgui.GetCursorScreenPos().x + pSize, imgui.GetCursorScreenPos().y + pSize))
            local hPr = utils.getHover(dash, "pr_"..i, isHov, 15.0)
            
            local baseR = math.min(1.0, sb_color[1] + 0.15)
            local baseG = math.min(1.0, sb_color[2] + 0.15)
            local baseB = math.min(1.0, sb_color[3] + 0.15)
            
            local bg_col = imgui.ImVec4(baseR, baseG, baseB, 0.95)
            local bord_col = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.3)
            
            if hPr > 0.01 then
                bg_col = imgui.ImVec4(
                    baseR + (c_accent.x - baseR) * hPr * 0.4, 
                    baseG + (c_accent.y - baseG) * hPr * 0.4, 
                    baseB + (c_accent.z - baseB) * hPr * 0.4, 
                    1.0
                )
                bord_col = imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.3 + (0.7 * hPr))
            end
            
            imgui.PushStyleColor(imgui.Col.Button, bg_col)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, bg_col)
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
            imgui.PushStyleColor(imgui.Col.Border, bord_col)
            
            if dash.icons and dash.icons.presets[i] then
                if imgui.ImageButton(dash.icons.presets[i], imgui.ImVec2(pSize, pSize), imgui.ImVec2(0,0), imgui.ImVec2(1,1), 4, bg_col, imgui.ImVec4(1,1,1,1)) then
                    MFT.state.previewPresetId = f.id
                end
            else
                if imgui.Button(tostring(f.id).."##pr"..i, imgui.ImVec2(pSize, pSize)) then MFT.state.previewPresetId = f.id end
            end
            if imgui.IsItemHovered() then imgui.SetTooltip(f.name) end
            
            imgui.PopStyleColor(4)
            imgui.SameLine(0, pSpace)
            imgui.SetCursorPosY(curP.y)
        end
        imgui.PopStyleVar()
        imgui.PopStyleVar()
        utils.EndCard()
        imgui.Spacing(); imgui.Spacing()
    end

    if type(currentList) ~= "table" or #currentList == 0 then
        utils.CenterText(u8"Здесь пусто.", imgui.ImVec4(0.6, 0.6, 0.6, 1.0))
    else
        local toDelete = -1
        
        if viewMode == 0 then
            for i, bind in ipairs(currentList) do
                local isFolder = (bind.type == "folder")
                local bg_color_row = sb_color
                if isFolder then
                    bg_color_row = {sb_color[1] + 0.05, sb_color[2] + 0.05, sb_color[3] + 0.05}
                end
                
                local baseName = bind.name or (isFolder and "Папка" or "Без названия")
                if isFolder then baseName = "[ПАПКА] " .. baseName end
                local displayName = u8(baseName)
                if #displayName > 50 then displayName = displayName:sub(1, 47) .. "..." end
                
                utils.BeginCard(dash, dt, "list_row_"..i, 75, nil, c_accent, bg_color_row)
                
                imgui.SetCursorPos(imgui.ImVec2(15, 22))
                local dragP = imgui.GetCursorScreenPos()
                imgui.InvisibleButton("##drag"..i, imgui.ImVec2(30, 30))
                local hovDrag = imgui.IsItemHovered()
                local colDrag = hovDrag and imgui.GetColorU32Vec4(c_accent) or imgui.GetColorU32Vec4(imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
                
                local dl = imgui.GetWindowDrawList()
                dl:AddLine(imgui.ImVec2(dragP.x + 5, dragP.y + 8), imgui.ImVec2(dragP.x + 25, dragP.y + 8), colDrag, 2.0)
                dl:AddLine(imgui.ImVec2(dragP.x + 5, dragP.y + 15), imgui.ImVec2(dragP.x + 25, dragP.y + 15), colDrag, 2.0)
                dl:AddLine(imgui.ImVec2(dragP.x + 5, dragP.y + 22), imgui.ImVec2(dragP.x + 25, dragP.y + 22), colDrag, 2.0)
                
                if hovDrag then imgui.SetTooltip(u8"Зажмите ЛКМ и тяните для изменения порядка") end
                
                if imgui.BeginDragDropSource(imgui.DragDropFlags.SourceAllowNullID) then
                    imgui.SetDragDropPayload("BIND_ROW", ffi.new("int[1]", i), ffi.sizeof("int"))
                    
                    imgui.PushStyleColor(imgui.Col.PopupBg, imgui.ImVec4(0.05, 0.05, 0.05, 0.95))
                    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
                    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8.0)
                    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
                    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 15))
                    
                    if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
                    imgui.TextColored(c_accent, u8"Перемещение:")
                    imgui.Text(displayName)
                    if MFT.fonts.title then imgui.PopFont() end
                    
                    imgui.PopStyleVar(3); imgui.PopStyleColor(2)
                    imgui.EndDragDropSource()
                end
                
                if imgui.BeginDragDropTarget() then
                    local payload = imgui.AcceptDragDropPayload("BIND_ROW")
                    if payload ~= nil then
                        local srcIdx = ffi.cast("int*", payload.Data)[0]
                        if srcIdx ~= i then
                            local item = table.remove(currentList, srcIdx)
                            local insertIdx = i
                            if srcIdx < i then insertIdx = i end
                            table.insert(currentList, insertIdx, item)
                            engine.saveData()
                        end
                    end
                    imgui.EndDragDropTarget()
                end
                
                if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
                imgui.SetCursorPos(imgui.ImVec2(55, 24))
                imgui.TextColored(c_accent, tostring(i) .. ".")
                
                imgui.SetCursorPos(imgui.ImVec2(85, 24))
                if isFolder then
                    imgui.TextColored(c_accent, displayName)
                else
                    imgui.Text(displayName)
                end
                if MFT.fonts.title then imgui.PopFont() end
                
                if not isFolder then
                    imgui.SetCursorPos(imgui.ImVec2(85, 24))
                    imgui.InvisibleButton("##ctx_"..i, imgui.ImVec2(imgui.CalcTextSize(displayName).x, 30))
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Правая кнопка мыши для перемещения в папку") end
                    if imgui.BeginPopupContextItem("MoveContext_"..i) then
                        if #MFT.state.folderPath == 0 then
                            imgui.TextColored(c_accent, u8"Переместить в:")
                            imgui.Separator()
                            local foundFolders = false
                            for fi, f in ipairs(MFT.binds) do
                                if f.type == "folder" then
                                    foundFolders = true
                                    if imgui.Selectable(u8(f.name)) then
                                        local b = table.remove(currentList, i)
                                        if not MFT.binds[fi].items then MFT.binds[fi].items = {} end
                                        table.insert(MFT.binds[fi].items, b)
                                        engine.saveData()
                                    end
                                end
                            end
                            if not foundFolders then imgui.TextDisabled(u8"Нет папок") end
                        else
                            if imgui.Selectable(u8"В корень (Главное меню)") then
                                local b = table.remove(currentList, i)
                                table.insert(MFT.binds, b)
                                engine.saveData()
                            end
                        end
                        imgui.EndPopup()
                    end
                end

                imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
                
                local rightPad = 15
                local btnRunW = 60
                local btnStepW = 85
                local btnStopW = 160
                local btnDelW = 80
                local btnEditW = 85
                local btnHkW = 110
                local cbOvlW = 90
                
                local isActiveSeq = false
                if MFT.state.seq and MFT.state.seq.activeBind then
                    if MFT.state.seq.activeBind == bind or (bind.name and MFT.state.seq.activeBind.name == bind.name) then
                        isActiveSeq = true
                    end
                end
                
                local xRun = availWidth - rightPad - btnRunW
                local xStep = xRun - 5 - btnStepW
                local xStop = availWidth - rightPad - btnStopW
                
                local currentX = (not isFolder) and (isActiveSeq and xStop or xStep) or xRun
                
                local xDel = currentX - 10 - btnDelW
                local xEdit = xDel - 5 - btnEditW
                local xHk = xEdit - 15 - btnHkW
                local xOvl = xHk - 15 - cbOvlW
                
                imgui.SetCursorPos(imgui.ImVec2(xEdit, 18))
                if not isFolder then
                    if imgui.Button(u8"Изменить##ed_"..i, imgui.ImVec2(btnEditW, 38)) then 
                        MFT.state.editingModalIndex = i
                        uistate.editBindCopy = deepcopy(bind)
                        imgui.OpenPopup("EditBindPopup")
                    end
                else
                    if imgui.Button(u8"Изменить##edf_"..i, imgui.ImVec2(btnEditW, 38)) then
                        ffi.fill(uistate.newFolderName, 256) 
                        ffi.copy(uistate.newFolderName, u8(bind.name or ""))
                        imgui.OpenPopup("RenameFolder_"..i)
                    end
                    imgui.SetNextWindowSize(imgui.ImVec2(400, 170), imgui.Cond.Always)
                    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.08, 1.0))
                    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
                    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(20, 20))
                    if imgui.BeginPopupModal("RenameFolder_"..i, nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar) then
                        imgui.TextColored(c_accent, u8"ИЗМЕНЕНИЕ НАЗВАНИЯ")
                        imgui.Separator(); imgui.Spacing()
                        imgui.Text(u8"Новое имя папки:")
                        imgui.Spacing()
                        imgui.PushItemWidth(-1)
                        imgui.InputText("##rname", uistate.newFolderName, 256)
                        imgui.PopItemWidth()
                        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
                        
                        local rBtn = (imgui.GetContentRegionAvail().x - 10) / 2
                        if imgui.Button(u8"Сохранить", imgui.ImVec2(rBtn, 35)) then
                            bind.name = u8:decode(ffi.string(uistate.newFolderName))
                            engine.saveData()
                            imgui.CloseCurrentPopup()
                        end
                        imgui.SameLine(0, 10)
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.4))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
                        if imgui.Button(u8"Отмена", imgui.ImVec2(rBtn, 35)) then imgui.CloseCurrentPopup() end
                        imgui.PopStyleColor(2); imgui.EndPopup()
                    end
                    imgui.PopStyleVar(2); imgui.PopStyleColor()
                end
                
                imgui.SetCursorPos(imgui.ImVec2(xDel, 18))
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.6))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.9, 0.3, 0.3, 0.9))
                imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
                if imgui.Button(u8"Удалить##del_"..i, imgui.ImVec2(btnDelW, 38)) then
                    MFT.state.deleteConfirmIndex = i
                    MFT.state.deleteConfirmList = currentList
                    imgui.OpenPopup("DeleteConfirmPopup")
                end
                imgui.PopStyleColor(3)
                
                if isFolder then
                    imgui.SetCursorPos(imgui.ImVec2(xRun, 18))
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.6, 0.8, 0.5))
                    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.2, 0.6, 0.8, 1.0))
                    if imgui.Button(u8"Вход##op_"..i, imgui.ImVec2(btnRunW, 38)) then 
                        table.insert(MFT.state.folderPath, i)
                    end
                    imgui.PopStyleColor(2)
                else
                    if isActiveSeq then
                        imgui.SetCursorPos(imgui.ImVec2(xStop, 18))
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.5))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.8, 0.2, 0.2, 1.0))
                        if imgui.Button(u8"Убрать из пошаговых##ust_"..i, imgui.ImVec2(btnStopW, 38)) then
                            MFT.state.seq.activeBind = nil
                            engine.saveData()
                        end
                        imgui.PopStyleColor(2)
                    else
                        imgui.SetCursorPos(imgui.ImVec2(xStep, 18))
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.8, 0.2, 0.5))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.2, 0.8, 0.2, 1.0))
                        if imgui.Button(u8"Пошагово##st_"..i, imgui.ImVec2(btnStepW, 38)) then
                            if not MFT.state.seq then MFT.state.seq = { step = 1 } end
                            MFT.state.seq.activeBind = bind
                            MFT.state.seq.step = 1
                            engine.saveData()
                        end
                        imgui.PopStyleColor(2)
                        
                        imgui.SetCursorPos(imgui.ImVec2(xRun, 18))
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.5))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0))
                        if imgui.Button(u8"Пуск##run_"..i, imgui.ImVec2(btnRunW, 38)) then
                            engine.executeBind(bind)
                        end
                        imgui.PopStyleColor(2)
                    end
                    
                    imgui.SetCursorPos(imgui.ImVec2(xHk, 18))
                    if dash.anims.capturingHotkeyBase == i then
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.5, 0.2, 0.6))
                        if imgui.Button(u8"Нажмите..##hk_"..i, imgui.ImVec2(btnHkW, 38)) then dash.anims.capturingHotkeyBase = -1 end
                        imgui.PopStyleColor()
                        for k = 8, 255 do
                            if imgui.IsKeyPressed(k) then
                                if k == vk.VK_BACK or k == vk.VK_ESCAPE then bind.hotkey = 0
                                else bind.hotkey = k end
                                dash.anims.capturingHotkeyBase = -1
                                engine.saveData()
                                break
                            end
                        end
                    else
                        local hkText = (bind.hotkey and bind.hotkey ~= 0) and vk.id_to_name(bind.hotkey) or u8"Кнопка"
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0,0,0,0))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.5, 0.5, 0.5, 0.6))
                        if imgui.Button(hkText.."##hk_"..i, imgui.ImVec2(btnHkW, 38)) then dash.anims.capturingHotkeyBase = i end
                        imgui.PopStyleColor(2)
                    end
                    
                    imgui.SetCursorPos(imgui.ImVec2(xOvl, 22))
                    local ovlBool = ffi.new("bool[1]", bind.showInOverlay ~= false)
                    if imgui.Checkbox(u8"Оверлей##cb_"..i, ovlBool) then bind.showInOverlay = (ovlBool[0] == true); engine.saveData() end
                end
                
                if isFolder then
                    imgui.SetCursorPos(imgui.ImVec2(xEdit - 150, 28))
                    imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), u8("Биндов: " .. #(bind.items or {})))
                end
                
                imgui.PopStyleVar()
                utils.EndCard()
                imgui.Spacing()
            end
        else
            local columns = math.max(1, math.floor(availWidth / 260))
            imgui.Columns(columns, "binds_grid", false)
            for i, bind in ipairs(currentList) do
                local isFolder = (bind.type == "folder")
                local bg_color_row = sb_color
                if isFolder then bg_color_row = {sb_color[1] + 0.05, sb_color[2] + 0.05, sb_color[3] + 0.05} end
                
                local baseName = bind.name or (isFolder and "Папка" or "Без названия")
                if isFolder then baseName = "[ПАПКА] " .. baseName end
                local rawName = u8(baseName)
                
                utils.BeginCard(dash, dt, "grid_card_"..i, 200, nil, c_accent, bg_color_row)
                if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
                if isFolder then
                    utils.CenterText(tostring(i) .. ". " .. rawName, c_accent)
                else
                    utils.CenterText(tostring(i) .. ". " .. rawName, imgui.ImVec4(1,1,1,1))
                end
                if MFT.fonts.title then imgui.PopFont() end
                
                if not isFolder then
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Правая кнопка мыши для перемещения") end
                    if imgui.BeginPopupContextItem("GridMoveContext_"..i) then
                        if #MFT.state.folderPath == 0 then
                            imgui.TextColored(c_accent, u8"Переместить в:")
                            imgui.Separator()
                            drawFolderTreeForMove(MFT.binds, bind, currentList, i)
                        else
                            if imgui.Selectable(u8"В корень (Главное меню)") then
                                local b = table.remove(currentList, i)
                                table.insert(MFT.binds, b)
                                engine.saveData()
                            end
                        end
                        imgui.EndPopup()
                    end
                end
                
                imgui.Separator(); imgui.Spacing(); imgui.Spacing()
                
                if not isFolder then
                    local ovlBool = ffi.new("bool[1]", bind.showInOverlay ~= false)
                    local cposCB = (imgui.GetWindowWidth() - imgui.CalcTextSize(u8"В оверлее").x - 30) / 2
                    imgui.SetCursorPosX(cposCB)
                    if imgui.Checkbox(u8"В оверлее##gcb_"..i, ovlBool) then bind.showInOverlay = (ovlBool[0] == true); engine.saveData() end
                else
                    imgui.Spacing(); imgui.Spacing()
                end
                
                imgui.Spacing(); imgui.Spacing()
                imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
                
                if isFolder then
                    utils.CenterText(u8("Биндов: " .. #(bind.items or {})), imgui.ImVec4(0.6, 0.6, 0.6, 1.0))
                    imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
                else
                    local isActiveSeq = false
                    if MFT.state.seq and MFT.state.seq.activeBind then
                        if MFT.state.seq.activeBind == bind or (bind.name and MFT.state.seq.activeBind.name == bind.name) then
                            isActiveSeq = true
                        end
                    end
                    
                    if isActiveSeq then
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.5))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.8, 0.2, 0.2, 1.0))
                        if imgui.Button(u8"Убрать из пошаговых##gust_"..i, imgui.ImVec2(-1, 28)) then 
                            MFT.state.seq.activeBind = nil
                            engine.saveData()
                        end
                        imgui.PopStyleColor(2)
                    else
                        if dash.anims.capturingHotkeyBase == i then
                            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.5, 0.2, 0.6))
                            if imgui.Button(u8"Нажмите..##ghk_"..i, imgui.ImVec2(-1, 28)) then dash.anims.capturingHotkeyBase = -1 end
                            imgui.PopStyleColor()
                            for k = 8, 255 do
                                if imgui.IsKeyPressed(k) then
                                    if k == vk.VK_BACK or k == vk.VK_ESCAPE then bind.hotkey = 0
                                    else bind.hotkey = k end
                                    dash.anims.capturingHotkeyBase = -1
                                    engine.saveData()
                                    break
                                end
                            end
                        else
                            local hkText = (bind.hotkey and bind.hotkey ~= 0) and vk.id_to_name(bind.hotkey) or u8"Кнопка"
                            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0,0,0,0))
                            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.5, 0.5, 0.5, 0.6))
                            if imgui.Button(hkText.."##ghk_"..i, imgui.ImVec2(-1, 28)) then dash.anims.capturingHotkeyBase = i end
                            imgui.PopStyleColor(2)
                        end
                    end
                end
                
                imgui.Spacing()
                
                if isFolder then
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.6, 0.8, 0.5))
                    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.2, 0.6, 0.8, 1.0))
                    if imgui.Button(u8"Открыть##gop_"..i, imgui.ImVec2(-1, 35)) then 
                        table.insert(MFT.state.folderPath, i)
                    end
                    imgui.PopStyleColor(2)
                else
                    local halfBtn = (imgui.GetContentRegionAvail().x - 10) / 2
                    local isActiveSeq = false
                    if MFT.state.seq and MFT.state.seq.activeBind then
                        if MFT.state.seq.activeBind == bind or (bind.name and MFT.state.seq.activeBind.name == bind.name) then
                            isActiveSeq = true
                        end
                    end
                    
                    if not isActiveSeq then
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.8, 0.2, 0.5))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.2, 0.8, 0.2, 1.0))
                        if imgui.Button(u8"Пошагово##gst_"..i, imgui.ImVec2(halfBtn, 35)) then
                            if not MFT.state.seq then MFT.state.seq = { step = 1 } end
                            MFT.state.seq.activeBind = bind
                            MFT.state.seq.step = 1
                            MFT.settings.seqOverlay.enabled = true
                            engine.saveData()
                        end
                        imgui.PopStyleColor(2)
                        
                        imgui.SameLine(0, 10)
                        
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.5))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0))
                        if imgui.Button(u8"Пуск", imgui.ImVec2(halfBtn, 35)) then 
                            engine.executeBind(bind)
                        end
                        imgui.PopStyleColor(2)
                    else
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.5))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 1.0))
                        if imgui.Button(u8"Пуск (Вне очереди)##grun_"..i, imgui.ImVec2(-1, 35)) then 
                            engine.executeBind(bind)
                        end
                        imgui.PopStyleColor(2)
                    end
                end
                
                imgui.Spacing()
                local halfBtn = (imgui.GetContentRegionAvail().x - 10) / 2
                
                if not isFolder then
                    if imgui.Button(u8"Изменить##ged_"..i, imgui.ImVec2(halfBtn, 30)) then 
                        MFT.state.editingModalIndex = i
                        uistate.editBindCopy = deepcopy(bind)
                        imgui.OpenPopup("EditBindPopup")
                    end
                else
                    if imgui.Button(u8"Изменить##grn_"..i, imgui.ImVec2(halfBtn, 30)) then
                        ffi.fill(uistate.newFolderName, 256)
                        ffi.copy(uistate.newFolderName, u8(bind.name or ""))
                        imgui.OpenPopup(u8"Изменение названия##grid_" .. i)
                    end
                    
                    imgui.SetNextWindowSize(imgui.ImVec2(400, 170), imgui.Cond.Always)
                    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.08, 1.0))
                    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
                    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
                    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
                    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(20, 20))
                    if imgui.BeginPopupModal(u8"Изменение названия##grid_" .. i, nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar) then
                        imgui.TextColored(c_accent, u8"ИЗМЕНЕНИЕ НАЗВАНИЯ")
                        imgui.Separator(); imgui.Spacing()
                        imgui.Text(u8"Новое имя папки:")
                        imgui.Spacing()
                        imgui.PushItemWidth(-1)
                        imgui.InputText("##grname", uistate.newFolderName, 256)
                        imgui.PopItemWidth()
                        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
                        
                        local rBtn = (imgui.GetContentRegionAvail().x - 10) / 2
                        if imgui.Button(u8"Сохранить", imgui.ImVec2(rBtn, 35)) then
                            bind.name = u8:decode(ffi.string(uistate.newFolderName))
                            engine.saveData()
                            imgui.CloseCurrentPopup()
                        end
                        imgui.SameLine()
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.4))
                        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
                        if imgui.Button(u8"Отмена", imgui.ImVec2(rBtn, 35)) then imgui.CloseCurrentPopup() end
                        imgui.PopStyleColor(2)
                        imgui.EndPopup()
                    end
                    imgui.PopStyleVar(3); imgui.PopStyleColor(2)
                end
                
                imgui.SameLine(0, 10)
                
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.6))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.9, 0.3, 0.3, 0.9))
                imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.9, 0.3, 0.3, 1.0))
                if imgui.Button(u8"Удалить##gdel_"..i, imgui.ImVec2(halfBtn, 30)) then
                    MFT.state.deleteConfirmIndex = i
                    MFT.state.deleteConfirmList = currentList
                    imgui.OpenPopup("DeleteConfirmPopup")
                end
                imgui.PopStyleColor(3)
                
                imgui.PopStyleVar()
                utils.EndCard()
                imgui.NextColumn()
            end
            imgui.Columns(1)
        end
    end

    -- === ВСТРОЕННЫЙ РЕДАКТОР БИНДА ===
    imgui.SetNextWindowSize(imgui.ImVec2(750, 500), imgui.Cond.Appearing)
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.98))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
    
    if imgui.BeginPopupModal("EditBindPopup", nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar) then
        local eb = uistate.editBindCopy
        if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
        imgui.TextColored(c_accent, u8"РЕДАКТОР БИНДА: " .. u8(eb.name or ""))
        if MFT.fonts.title then imgui.PopFont() end
        imgui.Separator(); imgui.Spacing()
        
        local bName = ffi.new("char[256]", u8(eb.name or ""))
        imgui.PushItemWidth(300)
        if imgui.InputText(u8"Название", bName, 256) then eb.name = u8:decode(ffi.string(bName)) end
        
        imgui.Spacing()
        
        local bDel = ffi.new("int[1]", eb.delay or 1000)
        if imgui.InputInt(u8"Задержка между строками (мс)", bDel) then eb.delay = tonumber(bDel[0]) end
        if imgui.IsItemHovered() then imgui.SetTooltip(u8"Установите паузу перед отправкой следующей строки (1000 мс = 1 секунда)") end
        imgui.PopItemWidth()
        
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()
        imgui.TextColored(c_accent, u8"СТРОКИ:"); imgui.Spacing()
        
        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0, 0, 0, 0.3))
        imgui.BeginChild("EditLinesScroll", imgui.ImVec2(0, 310), true)
        
        local lineToDel = -1
        
        for j, line in ipairs(eb.lines) do
            local ldragP = imgui.GetCursorScreenPos()
            imgui.InvisibleButton("##ldrag"..j, imgui.ImVec2(30, 24))
            local hovLDrag = imgui.IsItemHovered()
            local colLDrag = hovLDrag and imgui.GetColorU32Vec4(c_accent) or imgui.GetColorU32Vec4(imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
            
            local lineDl = imgui.GetWindowDrawList()
            lineDl:AddLine(imgui.ImVec2(ldragP.x + 5, ldragP.y + 6), imgui.ImVec2(ldragP.x + 25, ldragP.y + 6), colLDrag, 2.0)
            lineDl:AddLine(imgui.ImVec2(ldragP.x + 5, ldragP.y + 12), imgui.ImVec2(ldragP.x + 25, ldragP.y + 12), colLDrag, 2.0)
            lineDl:AddLine(imgui.ImVec2(ldragP.x + 5, ldragP.y + 18), imgui.ImVec2(ldragP.x + 25, ldragP.y + 18), colLDrag, 2.0)
            
            if hovLDrag then imgui.SetTooltip(u8"Зажмите ЛКМ и тяните для перемещения строки") end
            
            if imgui.BeginDragDropSource(imgui.DragDropFlags.SourceAllowNullID) then
                imgui.SetDragDropPayload("LINE_ROW", ffi.new("int[1]", j), ffi.sizeof("int"))
                
                imgui.PushStyleColor(imgui.Col.PopupBg, imgui.ImVec4(0.05, 0.05, 0.05, 0.95))
                imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
                imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8.0)
                imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
                imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(10, 10))
                
                imgui.TextColored(c_accent, u8"Перемещение строки...")
                
                imgui.PopStyleVar(3); imgui.PopStyleColor(2)
                imgui.EndDragDropSource()
            end
            
            if imgui.BeginDragDropTarget() then
                local payload = imgui.AcceptDragDropPayload("LINE_ROW")
                if payload ~= nil then
                    local srcIdx = ffi.cast("int*", payload.Data)[0]
                    if srcIdx ~= j then
                        local l = table.remove(eb.lines, srcIdx)
                        local insertIdx = j
                        if srcIdx < j then insertIdx = j end
                        table.insert(eb.lines, insertIdx, l)
                    end
                end
                imgui.EndDragDropTarget()
            end
            
            imgui.SameLine(0, 5)
            local lData = ffi.new("char[1024]", u8(line))
            imgui.PushItemWidth(620)
            if imgui.InputText("##l_"..j, lData, 1024) then eb.lines[j] = u8:decode(ffi.string(lData)) end
            imgui.PopItemWidth()
            
            imgui.SameLine(0, 15)
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.6))
            if imgui.Button("X##del"..j, imgui.ImVec2(30, 24)) then lineToDel = j end
            imgui.PopStyleColor()
        end
        
        if lineToDel ~= -1 then
            table.remove(eb.lines, lineToDel)
        end
        
        imgui.Spacing()
        if imgui.Button(u8"+ ДОБАВИТЬ СТРОКУ", imgui.ImVec2(-1, 30)) then table.insert(eb.lines, "") end
        imgui.EndChild()
        imgui.PopStyleColor()
        
        imgui.Spacing(); imgui.Spacing()
        
        local btnW = (imgui.GetContentRegionAvail().x - 10) / 2
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.7, 0.2, 0.5))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.2, 0.8, 0.2, 0.8))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        if imgui.Button(u8"СОХРАНИТЬ", imgui.ImVec2(btnW, 40)) then
            currentList[MFT.state.editingModalIndex] = eb
            engine.saveData()
            MFT.state.editingModalIndex = -1
            uistate.editBindCopy = nil
            imgui.CloseCurrentPopup()
        end
        imgui.PopStyleColor(2)
        
        imgui.SameLine()
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.5))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.8, 0.2, 0.2, 0.8))
        if imgui.Button(u8"ОТМЕНА", imgui.ImVec2(btnW, 40)) then
            MFT.state.editingModalIndex = -1
            uistate.editBindCopy = nil
            imgui.CloseCurrentPopup()
        end
        imgui.PopStyleColor(2); imgui.PopStyleVar()
        
        imgui.EndPopup()
    end
    imgui.PopStyleVar(2); imgui.PopStyleColor()

    -- ПОПАП ПОДТВЕРЖДЕНИЯ УДАЛЕНИЯ БИНДА ИЛИ ПАПКИ
    if MFT.state.deleteConfirmIndex ~= -1 then
        imgui.OpenPopup("DeleteConfirmPopup")
    end
    
    imgui.SetNextWindowSize(imgui.ImVec2(400, 150), imgui.Cond.Always)
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.08, 0.98))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.8))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.0)
    
    if imgui.BeginPopupModal("DeleteConfirmPopup", nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar) then
        imgui.TextColored(c_accent, u8"ПОДТВЕРЖДЕНИЕ УДАЛЕНИЯ")
        imgui.Separator(); imgui.Spacing()
        
        local delItem = MFT.state.deleteConfirmList and MFT.state.deleteConfirmList[MFT.state.deleteConfirmIndex]
        if delItem then
            local dName = delItem.name or u8"Без названия"
            if #dName > 35 then dName = dName:sub(1, 32) .. "..." end
            imgui.Text(u8"Вы действительно хотите удалить:")
            imgui.TextColored(imgui.ImVec4(1,1,1,1), u8(dName) .. " ?")
        end
        
        imgui.Spacing(); imgui.Spacing()
        local btnW = (imgui.GetContentRegionAvail().x - 10) / 2
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.5))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.8, 0.2, 0.2, 1.0))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1.0)
        
        if imgui.Button(u8"Да, удалить", imgui.ImVec2(btnW, 35)) then
            if MFT.state.seq and MFT.state.seq.activeBind == delItem then
                MFT.state.seq.activeBind = nil 
            end
            table.remove(MFT.state.deleteConfirmList, MFT.state.deleteConfirmIndex)
            if MFT.state.deleteConfirmIsFolderActive then
                table.remove(MFT.state.folderPath)
                MFT.state.deleteConfirmIsFolderActive = false
            end
            engine.saveData()
            imgui.CloseCurrentPopup()
            MFT.state.deleteConfirmIndex = -1
        end
        imgui.PopStyleColor(2)
        
        imgui.SameLine()
        
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.2, 0.5))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
        if imgui.Button(u8"Отмена", imgui.ImVec2(btnW, 35)) then
            MFT.state.deleteConfirmIsFolderActive = false
            imgui.CloseCurrentPopup()
            MFT.state.deleteConfirmIndex = -1
        end
        imgui.PopStyleColor(2); imgui.PopStyleVar()
        
        imgui.EndPopup()
    end
    imgui.PopStyleVar(2); imgui.PopStyleColor(2)
end

return tab_binds