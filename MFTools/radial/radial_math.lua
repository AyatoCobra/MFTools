-- Файл: MFTools/radial/radial_math.lua
local imgui = require "mimgui"
local math = require "math"

local radial_math = {}

-- Нормализация угла (от 0 до 2*PI)
function radial_math.NormalizeAngle(angle)
    local PI2 = math.pi * 2
    angle = angle % PI2
    if angle < 0 then angle = angle + PI2 end
    return angle
end

-- Проверка, находится ли курсор внутри конкретного сектора
function radial_math.IsMouseInSector(mx, my, cx, cy, r_inner, r_outer, a_start, a_end)
    local dx = mx - cx
    local dy = my - cy
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist < r_inner or dist > r_outer then return false end
    
    local angle = radial_math.NormalizeAngle(math.atan2(dy, dx))
    local nStart = radial_math.NormalizeAngle(a_start)
    local nEnd = radial_math.NormalizeAngle(a_end)
    
    if nStart < nEnd then
        return angle >= nStart and angle <= nEnd
    else
        return angle >= nStart or angle <= nEnd
    end
end

-- Вычисление центра сектора (чтобы ровно ставить туда текст)
function radial_math.GetSectorCenter(cx, cy, radius, a_start, a_end)
    local mid = a_start + (a_end - a_start) / 2
    return cx + math.cos(mid) * radius, cy + math.sin(mid) * radius
end

-- Отрисовка залитого сектора
function radial_math.DrawPieSector(dl, cx, cy, radius, a_start, a_end, colorU32)
    dl:PathClear()
    dl:PathLineTo(imgui.ImVec2(cx, cy))
    dl:PathArcTo(imgui.ImVec2(cx, cy), radius, a_start, a_end, 32)
    dl:PathFillConvex(colorU32)
end

-- Отрисовка дуги (внешняя граница сектора)
function radial_math.DrawArcLine(dl, cx, cy, radius, a_start, a_end, colorU32, thickness)
    dl:PathClear()
    dl:PathArcTo(imgui.ImVec2(cx, cy), radius, a_start, a_end, 32)
    dl:PathStroke(colorU32, false, thickness)
end

return radial_math