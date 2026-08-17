-- Файл: MFTools/core/chatedit.lua
local imgui = require "mimgui"
local ffi = require "ffi"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local engine = require "MFTools.core.engine"

local chatedit = {}

chatedit.warn_font = renderCreateFont("Arial", 11, 5) 
chatedit.menu_font = renderCreateFont("Arial", 10, 5)
chatedit.editBuffer = ffi.new("char[1024]")

chatedit.selectedLineId = -1
chatedit.selectedLineText = ""
chatedit.selectedLinePrefix = ""
chatedit.selectedLineColor = 0
chatedit.selectedLinePColor = 0

chatedit.menuOpen = false
chatedit.menuX = 0
chatedit.menuY = 0

local function getChatMemoryData()
    local chatPtr = sampGetChatInfoPtr()
    if chatPtr == 0 then return nil, nil end
    local sampBase = getModuleHandle("samp.dll")
    local ep = ffi.cast("uint32_t*", sampBase + 0x128)[0]
    local offset = 0x132
    if ep == 0x51E2055 then offset = 0x132     
    elseif ep == 0x5399555 then offset = 0x13E 
    elseif ep == 0x53A7A55 then offset = 0x142 
    elseif ep == 0x53B6A55 then offset = 0x146 
    end
    return chatPtr, offset
end

local function forceChatRedraw()
    local mode = sampGetChatDisplayMode()
    sampSetChatDisplayMode(0) 
    sampSetChatDisplayMode(mode) 
end

function chatedit.saveBackup()
    if not MFT.state.chatBackup then
        local chatPtr, offset = getChatMemoryData()
        if chatPtr then
            local pChat = ffi.cast("uint8_t*", chatPtr + offset)
            MFT.state.chatBackup = ffi.new("uint8_t[25200]")
            ffi.copy(MFT.state.chatBackup, pChat, 25200)
        end
    end
end

function chatedit.restoreBackup()
    if MFT.state.chatBackup then
        local chatPtr, offset = getChatMemoryData()
        if chatPtr then
            local pChat = ffi.cast("uint8_t*", chatPtr + offset)
            ffi.copy(pChat, MFT.state.chatBackup, 25200)
            forceChatRedraw()
        end
        MFT.state.chatBackup = nil
    end
    MFT.state.chatEdited = false
    sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Чат успешно перезагружен. Оригинальные строки восстановлены!", -1)
end

local function editChatLineFFI(id, text, prefix, color, pcolor)
    local chatPtr, offset = getChatMemoryData()
    if not chatPtr then return false end
    
    local entryPtr = chatPtr + offset + (id * 252)
    local pEntry = ffi.cast("uint8_t*", entryPtr)
    
    if text then 
        ffi.fill(pEntry + 32, 144, 0)
        ffi.copy(pEntry + 32, text, math.min(#text, 143))
    end
    
    forceChatRedraw()
    return true
end

local function clearChatLineFFI(id)
    local chatPtr, offset = getChatMemoryData()
    if not chatPtr then return false end
    
    local entryPtr = chatPtr + offset + (id * 252)
    local pEntry = ffi.cast("uint8_t*", entryPtr)
    
    ffi.fill(pEntry + 32, 144, 0) 
    ffi.copy(pEntry + 32, " ", 1) 
    ffi.fill(pEntry + 4, 28, 0)   
    
    ffi.cast("uint32_t*", pEntry + 244)[0] = 0x00000000 
    ffi.cast("uint32_t*", pEntry + 248)[0] = 0x00000000 
    
    forceChatRedraw()
    return true
end

local function deleteChatLineFFI(id)
    local chatPtr, offset = getChatMemoryData()
    if not chatPtr then return false end
    
    for i = id, 1, -1 do
        local pCurrent = ffi.cast("uint8_t*", chatPtr + offset + (i * 252))
        local pPrev = ffi.cast("uint8_t*", chatPtr + offset + ((i - 1) * 252))
        ffi.copy(pCurrent, pPrev, 252)
    end
    
    local pFirst = ffi.cast("uint8_t*", chatPtr + offset)
    ffi.fill(pFirst, 252, 0)
    
    forceChatRedraw()
    return true
end

function chatedit.processDX()
    if MFT.state.chatEdited then
        local sw, sh = getScreenResolution()
        
        local text1 = "Внимание: Сообщение в чате скрыто/изменено!"
        local t2_1 = "Чтобы убрать это сообщение, "
        local t2_2 = "перезагрузите чат"
        local t2_3 = " в настройках."
        
        local len1 = renderGetFontDrawTextLength(chatedit.warn_font, text1)
        local len2_1 = renderGetFontDrawTextLength(chatedit.warn_font, t2_1)
        local len2_2 = renderGetFontDrawTextLength(chatedit.warn_font, t2_2)
        local len2_3 = renderGetFontDrawTextLength(chatedit.warn_font, t2_3)
        local totalLen2 = len2_1 + len2_2 + len2_3
        
        local maxLen = math.max(len1, totalLen2)
        
        local padX = 12
        local padY = 10
        local lineH = 14
        local space = 4
        
        local boxW = maxLen + (padX * 2)
        local boxH = (padY * 2) + (lineH * 2) + space
        
        -- ПОЗИЦИЯ: Самый левый нижний угол
        local boxX = 5 
        local boxY = sh - boxH - 5
        
        renderDrawBox(boxX - 2, boxY - 2, boxW + 4, boxH + 4, 0xAA000000) 
        renderDrawBox(boxX - 1, boxY - 1, boxW + 2, boxH + 2, 0xCCFF3333) 
        renderDrawBox(boxX, boxY, boxW, boxH, 0xEE111111) 
        
        renderFontDrawText(chatedit.warn_font, text1, boxX + padX, boxY + padY, 0xFFFFAAAA)
        
        -- Отрисовка второй строки с красным текстом посередине
        local line2_Y = boxY + padY + lineH + space
        renderFontDrawText(chatedit.warn_font, t2_1, boxX + padX, line2_Y, 0xFFFFFFFF)
        renderFontDrawText(chatedit.warn_font, t2_2, boxX + padX + len2_1, line2_Y, 0xFFFF4444)
        renderFontDrawText(chatedit.warn_font, t2_3, boxX + padX + len2_1 + len2_2, line2_Y, 0xFFFFFFFF)
    end

    local pagesize = MFT.settings.chatPageSize or 10
    local lineSpacing = MFT.settings.chatLineSpacing or 16.0
    local startX = MFT.settings.chatOffsetX or 35.0
    local startY = MFT.settings.chatOffsetY or 35.0
    local width = MFT.settings.chatOverlayWidth or 700.0

    if MFT.state.isCalibratingChat then
        for i = 0, pagesize - 1 do
            local itemY = startY + (i * lineSpacing)
            local color = (i % 2 == 0) and 0x55FF0000 or 0x33FF0000
            renderDrawBox(startX, itemY, width, lineSpacing, color)
            renderDrawBox(startX, itemY, width, 1, 0x55FFFFFF) 
        end
        return 
    end

    if not MFT.settings.chatEditEnabled then return end
    if not isSampAvailable() then return end
    if not sampIsChatInputActive() then
        chatedit.menuOpen = false
        return
    end

    local mx, my = getCursorPos()

    if chatedit.menuOpen then
        local menuW = 240
        local itemH = 26  
        local menuH = itemH * 3

        renderDrawBox(chatedit.menuX - 2, chatedit.menuY - 2, menuW + 4, menuH + 4, 0xAA000000)
        renderDrawBox(chatedit.menuX - 1, chatedit.menuY - 1, menuW + 2, menuH + 2, 0x55FFFFFF)
        renderDrawBox(chatedit.menuX, chatedit.menuY, menuW, menuH, 0xEE111111)
        
        local items = {"Скопировать строку", "Изменить строку", "Удалить строку"}
        local clickedItem = -1

        for i = 1, 3 do
            local ix = chatedit.menuX
            local iy = chatedit.menuY + (i - 1) * itemH
            local isHovered = (mx >= ix and mx <= ix + menuW and my >= iy and my <= iy + itemH)

            if isHovered then
                renderDrawBox(ix, iy, menuW, itemH, 0x55FFFFFF)
                if wasKeyPressed(0x01) then clickedItem = i end
            end
            
            renderFontDrawText(chatedit.menu_font, items[i], ix + 16, iy + 5, 0xFFFFFFFF)
        end

        if wasKeyPressed(0x01) then
            if clickedItem == 1 then
                local fullStr = chatedit.selectedLineText
                if chatedit.selectedLinePrefix and chatedit.selectedLinePrefix ~= "" then
                    fullStr = chatedit.selectedLinePrefix .. ": " .. fullStr
                end
                fullStr = fullStr:gsub("{%x%x%x%x%x%x}", "")
                setClipboardText(fullStr)
                sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Строка скопирована!", -1)
            elseif clickedItem == 2 then
                MFT.state.isEditingChatLine = true
                ffi.copy(chatedit.editBuffer, u8(chatedit.selectedLineText))
            elseif clickedItem == 3 then
                chatedit.saveBackup()
                if MFT.settings.chatDeleteLeaveEmpty then
                    clearChatLineFFI(chatedit.selectedLineId)
                else
                    deleteChatLineFFI(chatedit.selectedLineId)
                end
                MFT.state.chatEdited = true
            end
            chatedit.menuOpen = false
        elseif wasKeyPressed(0x02) then
            chatedit.menuOpen = false
        end
        return
    end

    if MFT.state.isEditingChatLine then return end

    for i = 0, pagesize - 1 do
        local lineId = 99 - pagesize + 1 + i
        local text, prefix, color, pcolor = sampGetChatString(lineId)

        if text and text ~= "" then
            local itemX = startX
            local itemY = startY + (i * lineSpacing)

            if mx >= itemX and mx <= itemX + width and my >= itemY and my <= itemY + lineSpacing then
                renderDrawBox(itemX, itemY, width, lineSpacing, 0x40FFFFFF)

                if wasKeyPressed(0x02) then
                    chatedit.selectedLineId = lineId
                    chatedit.selectedLineText = text
                    chatedit.selectedLinePrefix = prefix
                    chatedit.selectedLineColor = color
                    chatedit.selectedLinePColor = pcolor
                    chatedit.menuOpen = true
                    chatedit.menuX = mx
                    chatedit.menuY = my
                end
                break
            end
        end
    end
end

function chatedit.drawUI()
    local sw, sh = getScreenResolution()
    
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(20, 20))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 8.0)
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.12, 0.98))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.4, 0.3, 0.8, 0.7))
    
    if MFT.state.isEditingChatLine then
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2, sh/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(u8"Редактирование строки чата", nil, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)
        imgui.SetWindowFontScale(1.15) 
        
        imgui.TextColored(imgui.ImVec4(0.8, 0.6, 1.0, 1.0), u8"Новый текст строки:")
        imgui.Spacing()
        
        imgui.PushItemWidth(500)
        imgui.InputText("##chat_edit_input", chatedit.editBuffer, 1024)
        imgui.PopItemWidth()
        
        imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
        
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.3, 0.6, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.4, 0.7, 0.4, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.5, 0.2, 1.0))
        if imgui.Button(u8"СОХРАНИТЬ ИЗМЕНЕНИЯ", imgui.ImVec2(242, 45)) then
            chatedit.saveBackup()
            local newText = u8:decode(ffi.string(chatedit.editBuffer))
            editChatLineFFI(chatedit.selectedLineId, newText, chatedit.selectedLinePrefix, chatedit.selectedLineColor, chatedit.selectedLinePColor)
            MFT.state.chatEdited = true
            MFT.state.isEditingChatLine = false
        end
        imgui.PopStyleColor(3)
        
        imgui.SameLine(0, 15)
        
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.6, 0.2, 0.2, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.7, 0.3, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.5, 0.1, 0.1, 1.0))
        if imgui.Button(u8"ОТМЕНА", imgui.ImVec2(242, 45)) then
            MFT.state.isEditingChatLine = false
        end
        imgui.PopStyleColor(3)
        
        imgui.SetWindowFontScale(1.0) 
        imgui.End()
    end
    
    if MFT.state.isCalibratingChat then
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2, sh/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(u8"Калибровка сетки Chat++", nil, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)
        imgui.SetWindowFontScale(1.15) 
        
        imgui.TextColored(imgui.ImVec4(0.3, 0.9, 0.3, 1.0), u8"ШАГ 1: Откройте чат в игре (кнопка F6, чтобы видеть текст)")
        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1.0), u8"ШАГ 2: Двигайте ползунки, пока красная сетка не покроет текст чата")
        
        imgui.Spacing(); imgui.Separator(); imgui.Spacing(); imgui.Spacing()
        
        imgui.PushItemWidth(450)
        local cPage = ffi.new("int[1]", MFT.settings.chatPageSize or 10)
        if imgui.SliderInt(u8"Кол-во строк (/pagesize)", cPage, 10, 30) then MFT.settings.chatPageSize = tonumber(cPage[0]) end 
        imgui.Spacing()
        
        local cSpace = ffi.new("float[1]", MFT.settings.chatLineSpacing or 16.0)
        if imgui.SliderFloat(u8"Высота строки (зависит от /fontsize)", cSpace, 10.0, 30.0) then MFT.settings.chatLineSpacing = tonumber(cSpace[0]) end 
        imgui.Spacing()
        
        local cOffX = ffi.new("float[1]", MFT.settings.chatOffsetX or 35.0)
        if imgui.SliderFloat(u8"Отступ ВПРАВО / ВЛЕВО", cOffX, 0.0, 200.0) then MFT.settings.chatOffsetX = tonumber(cOffX[0]) end 
        imgui.Spacing()
        
        local cOffY = ffi.new("float[1]", MFT.settings.chatOffsetY or 35.0)
        if imgui.SliderFloat(u8"Отступ ВНИЗ / ВВЕРХ", cOffY, 0.0, 400.0) then MFT.settings.chatOffsetY = tonumber(cOffY[0]) end 
        imgui.Spacing()
        
        local cW = ffi.new("float[1]", MFT.settings.chatOverlayWidth or 700.0)
        if imgui.SliderFloat(u8"Ширина выделения", cW, 300.0, 1500.0) then MFT.settings.chatOverlayWidth = tonumber(cW[0]) end 
        imgui.PopItemWidth()
        
        imgui.Spacing(); imgui.Spacing(); imgui.Separator(); imgui.Spacing(); imgui.Spacing()
        
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.3, 0.6, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.4, 0.7, 0.4, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.5, 0.2, 1.0))
        if imgui.Button(u8"СОХРАНИТЬ НАСТРОЙКИ", imgui.ImVec2(-1, 50)) then
            MFT.state.isCalibratingChat = false
            MFT.state.isMenuOpen = true
            engine.saveData()
            sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Сетка чата успешно откалибрована!", -1)
        end
        imgui.PopStyleColor(3)
        
        imgui.SetWindowFontScale(1.0) 
        imgui.End()
    end
    
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(3)
end

return chatedit