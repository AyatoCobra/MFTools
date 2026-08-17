-- Файл: MFTools/ui/uistate.lua
local ffi = require "ffi"
local imgui = require "mimgui"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Только чистое хранилище данных, без подгрузки других файлов нашего скрипта!

local state = {
    -- Переменные для создания/редактирования биндов
    newBindName = ffi.new("char[128]"),
    newBindText = ffi.new("char[8192]"),
    newBindDelay = ffi.new("int[1]", 1000),
    newBindOverlay = imgui.new.bool(true),
    newBindHotkey = ffi.new("int[1]", 0),

    -- Переменные для создания кастомной темы
    newThemeName = ffi.new("char[64]"),
    tempColor = ffi.new("float[3]", {0, 0, 0}),

    ctSettings = {
        bg = ffi.new("float[3]", {0.06, 0.06, 0.06}),
        sidebar = ffi.new("float[3]", {0.10, 0.10, 0.10}),
        btn = ffi.new("float[3]", {0.15, 0.15, 0.15}),
        accent = ffi.new("float[3]", {0.35, 0.55, 0.85}),
        text = ffi.new("float[3]", {0.95, 0.95, 0.95})
    },

    -- НАСТРОЙКИ КРУГОВОГО МЕНЮ (RADIAL MENU)
    radial = {
        isConfiguringHotkey = false,
        activeSector = 1, -- Какой сектор сейчас выбран в настройках
        tempSectorCount = ffi.new("int[1]", 6),
        -- Доступные иконки для секторов
        icons = {u8"Без иконки", u8"Звезда", u8"Наручники", u8"Молния", u8"Документ", u8"Авто"}
    },

    -- Пресеты фракций (Добавлены Алькатрас и Сервисный центр)
    factions = {
        {id = 1, name = u8"Полиция"}, {id = 2, name = u8"ФБР"},
        {id = 3, name = u8"Больница"}, {id = 4, name = u8"СМИ"},
        {id = 5, name = u8"Правительство"}, {id = 6, name = u8"Гетто"},
        {id = 7, name = u8"Картели"}, {id = 8, name = u8"Байкеры"}, 
        {id = 9, name = u8"Сухопутные Войска"}, {id = 10, name = u8"Алькатрас"},
        {id = 11, name = u8"Сервисный центр"}
    },

    -- Стандартные мягкие темы
    pThemes = {
        {name = u8"Мягкий Красный", col = {0.85, 0.35, 0.35}},
        {name = u8"Мягкий Оранжевый", col = {0.85, 0.55, 0.25}},
        {name = u8"Мягкий Желтый", col = {0.85, 0.75, 0.25}},
        {name = u8"Мягкий Зеленый", col = {0.35, 0.75, 0.45}},
        {name = u8"Мягкий Голубой", col = {0.25, 0.75, 0.75}},
        {name = u8"Мягкий Синий", col = {0.35, 0.55, 0.85}},
        {name = u8"Мягкий Фиолетовый", col = {0.65, 0.45, 0.85}},
        {name = u8"Мягкий Розовый", col = {0.85, 0.45, 0.65}},
        {name = u8"Нейтральный Серый", col = {0.60, 0.60, 0.60}}
    }
}

return state