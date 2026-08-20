-- Файл: MFTools/core/formatter.lua
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local formatter = {}

-- Авто-форматирование отправляемых команд (/me, /do)
function formatter.onSendCommand(cmd)
    if not MFT.settings.autoRpFormatter then return cmd end
    
    local command, rest = cmd:match("^(%S+)%s+(.+)$")
    if not command then return cmd end
    
    command = command:lower()
    
    if command == "/me" or command == "/do" or command == "/todo" then
        local f_upper = rest:sub(1, 1):upper()
        rest = f_upper .. rest:sub(2)
        
        if not rest:match("[%.%?!]$") then
            rest = rest .. "."
        end
        
        return command .. " " .. rest
    end
    
    return cmd
end

-- Фильтрация входящих сообщений (Режим СС) и Перехват Анти-флуда
function formatter.onServerMessage(color, text)
    -- Очищаем текст от серверных HEX-цветов (формат {XXXXXX}) перед проверками
    local cleanText = text:gsub("{%x%x%x%x%x%x}", "")
    
    -- === УМНЫЙ АНТИ-ФЛУД (ПЕРЕХВАТ) ===
    if cleanText:find("Не флуди") or cleanText:find("прекратите флудить") then
        local engine = require "MFTools.core.engine"
        engine.antiFloodTriggered = true 
        return false 
    end
    -- ===================================

    if MFT.settings.ssMode then
        local f = MFT.settings.ssFilters or {ooc = true, radio = true, vip = true, ads = true, sys = true, pd_alerts = true, afk = true, events = true, thoughts = true, sms = true, payday = true}
        
        -- Фильтр OOC чатов
        if f.ooc and (cleanText:find("^%s*%(%(") or cleanText:find("%(%(.*%)%)$")) then 
            return false 
        end
        
        -- Фильтр раций фракции/департамента
        if f.radio and (cleanText:find("^%[R%]") or cleanText:find("^%[D%]") or cleanText:find("^%[Р%]") or cleanText:find("^%[Д%]") or cleanText:find("%[Рация") or cleanText:find("%[Департамент")) then 
            return false 
        end
        
        -- Фильтр VIP и Семей
        if f.vip and (cleanText:find("^%[VIP%]") or cleanText:find("^%[V%]") or cleanText:find("^%[Семья%]") or cleanText:find("^%[Fam") or cleanText:find("^%[Family%]") or cleanText:find("^%[F%]") or cleanText:find("^%[.-%] %[.-%] [%w_]+%[%d+%]:")) then 
            return false 
        end
        
        -- Фильтр объявлений (СМИ)
        if f.ads and (cleanText:find("^Объявление:") or cleanText:find("Отредактировал.*СМИ") or cleanText:find("^%[VIP Объявление%]")) then 
            return false 
        end
        
        -- Системные и Админ-сообщения (включая репорты, жалобы, пассы, яхты, войсчат)
        if f.sys and (cleanText:find("^%[A%]") or cleanText:find("^Администратор") or cleanText:find("Администратор установил вам временный") or cleanText:find("^%[ЖБ%]") or cleanText:find("^Всего жалоб:") or cleanText:find("^Система %|") or cleanText:find("^Вы не получили зарплату") or cleanText:find("^Mordor Pass %|") or cleanText:find("^%[Яхта%]") or cleanText:find("^%[Mordor VoiceChat%]")) then 
            return false 
        end
        
        -- Фильтр ПД/ФБР (Уведомления о розыске)
        if f.pd_alerts and cleanText:find("^%[Внимание%]") then
            return false
        end
        
        -- Фильтр AFK сообщений
        if f.afk and cleanText:find("^AFK %|") then
            return false
        end
        
        -- Фильтр Серверных ивентов (Новости, МП, Захваты территорий, Корабли)
        if f.events and (cleanText:find("^Новости %|") or cleanText:find("^МП %|") or cleanText:find("^%[Захват%]:") or cleanText:find("^%[Ограбление корабля%]")) then
            return false
        end
        
        -- Фильтр Мыслей персонажа (Голод и т.д.)
        if f.thoughts and cleanText:find("^Мысли %|") then
            return false
        end
        
        -- Фильтр SMS сообщений
        if f.sms and (cleanText:find("мобильный телефон и отправляет СМС") or cleanText:find("отправил СМС")) then
            return false
        end
        
        -- Фильтр Payday (Зарплаты и Уведомления)
        if f.payday and (cleanText:find("^Законопослушность") or cleanText:find("^Зарплата:") or cleanText:find("^Зарплата семьи:") or cleanText:find("^Медицинское отчисление:") or cleanText:find("^Пенсионные отчисления:") or cleanText:find("^Итого зарплата:") or cleanText:find("^Баланс банковского счёта:") or cleanText:find("^Exp %+") or cleanText:find("^Напоминалка:") or cleanText:find("^%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-")) then
            return false
        end
    end
    
    return true
end

return formatter