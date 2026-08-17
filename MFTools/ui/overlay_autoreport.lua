-- Файл: MFTools/ui/overlay_autoreport.lua
local imgui = require "mimgui"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local ovl_ar = {}

function ovl_ar.draw(c_accent)
    if not MFT.settings.autoReport.enabled then return end
    
    -- НОВАЯ ПРОВЕРКА: Если юзер отключил оверлей, мы его не рисуем (кроме режима перемещения)
    if MFT.settings.autoReport.showOverlay == false and not MFT.state.isPlacingAROverlay then return end
    
    if not MFT.state.ar.isRunning and not MFT.state.isPlacingAROverlay and not MFT.state.isMenuOpen then return end

    local sw, sh = getScreenResolution()
    local nx = MFT.settings.autoReport.x or 500
    local ny = MFT.settings.autoReport.y or 100

    if MFT.state.isPlacingAROverlay then
        local mp = imgui.GetMousePos()
        nx = math.floor(tonumber(mp.x))
        ny = math.floor(tonumber(mp.y))
        
        local dl = imgui.GetBackgroundDrawList()
        local hintText = u8"Нажмите ПРОБЕЛ для сохранения позиции автодоклада"
        local boxMin = imgui.ImVec2(nx, ny - 35)
        local boxMax = imgui.ImVec2(nx + imgui.CalcTextSize(hintText).x + 20, ny - 5)
        dl:AddRectFilled(boxMin, boxMax, imgui.GetColorU32Vec4(imgui.ImVec4(0.05, 0.05, 0.05, 0.95)), 6.0)
        dl:AddRect(boxMin, boxMax, imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.8)), 6.0, 0, 1.2)
        dl:AddText(imgui.ImVec2(nx + 10, ny - 28), imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, 1)), hintText)
        
        MFT.settings.autoReport.x = nx
        MFT.settings.autoReport.y = ny
    end

    local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoSavedSettings
    if not MFT.state.isPlacingAROverlay then flags = bit.bor(flags, imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoMove) end

    imgui.SetNextWindowPos(imgui.ImVec2(nx, ny), imgui.Cond.Always)
    
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.04, 0.04, 0.04, 0.95))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.9))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 2.5)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(30, 20))

    if imgui.Begin("AutoReportOverlay", nil, flags) then
        imgui.TextColored(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0), u8"АВТОДОКЛАД")
        imgui.Separator()
        imgui.Spacing()
        
        if MFT.state.ar.isRunning and MFT.state.ar.activeId and MFT.state.ar.activeId ~= -1 then
            local reports = MFT.settings.autoReport.reports or {}
            local currentRep = reports[MFT.state.ar.activeId]
            local rTitle = currentRep and u8(currentRep.title) or u8"Неизвестно"
            
            local remain = math.max(0, MFT.state.ar.nextTime - os.time())
            local m = math.floor(remain / 60)
            local s = remain % 60
            
            imgui.Text(u8"Доклад: " .. rTitle)
            imgui.Spacing()
            imgui.Text(u8"Статус: ")
            imgui.SameLine()
            imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.2, 1.0), u8"АКТИВЕН")
            
            imgui.Text(string.format(u8"Следующая строка через: %02d:%02d", m, s))
            
            local totalLines = currentRep and currentRep.lines and #currentRep.lines or 0
            local dispIndex = MFT.state.ar.currentIndex
            if dispIndex > totalLines then dispIndex = totalLines end
            
            imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.8, 1.0), u8(string.format("Прогресс: Строка %d из %d", dispIndex, totalLines)))
        else
            imgui.Text(u8"Статус: ")
            imgui.SameLine()
            imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), u8"ОЖИДАНИЕ")
            
            if MFT.state.isMenuOpen or MFT.state.isPlacingAROverlay then
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"(Запустите один из докладов)")
            end
        end
        
        imgui.End()
    end
    imgui.PopStyleVar(3)
    imgui.PopStyleColor(2)
end

return ovl_ar