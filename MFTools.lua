--[[
    MFTools (Mordor Faction Tools) v1.5 (beta test)
    Главный файл (Ядро + Автоустановщик + Автообновление)
    Разработчик: Bryan Kogfield (Богдан)
]]

script_name("MFTools")
script_author("Bryan Kogfield")
script_version("1.5 (beta test)")

require "lib.moonloader"
local samp = require "lib.samp.events"
local dlstatus = require('moonloader').download_status
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local vk = require "vkeys"

-- ==========================================
-- === НАСТРОЙКИ АВТООБНОВЛЕНИЯ И ЗАГРУЗКИ ===
-- ==========================================
local SCRIPT_VERSION = 1.5 
local SCRIPT_VERSION_TEXT = "1.5 (beta test)"

-- JSON проверяем через githack для моментальной реакции
local UPDATE_JSON_URL = "https://raw.githack.com/AyatoCobra/MFTools/main/update.json" 
-- Основные файлы качаем с официального github для стабильности
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools.lua" 

-- Полный список всех файлов
local files_to_download = {
    -- Ядро
    { path = "MFTools\\core\\engine.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/core/engine.lua" },
    { path = "MFTools\\core\\chatedit.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/core/chatedit.lua" },
    { path = "MFTools\\core\\formatter.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/core/formatter.lua" },
    { path = "MFTools\\core\\suggest.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/core/suggest.lua" },
    
    -- Данные
    { path = "MFTools\\data\\commands.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/data/commands.lua" },
    { path = "MFTools\\data\\presets.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/data/presets.lua" },
    
    -- Интерфейс (UI)
    { path = "MFTools\\ui\\dashboard.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/dashboard.lua" },
    { path = "MFTools\\ui\\tab_settings.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/tab_settings.lua" },
    { path = "MFTools\\ui\\tab_binds.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/tab_about.lua" },
    { path = "MFTools\\ui\\tab_about.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/tab_about.lua" },
    { path = "MFTools\\ui\\tab_create.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/tab_create.lua" },
    { path = "MFTools\\ui\\tab_interactions.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/tab_interactions.lua" },
    { path = "MFTools\\ui\\tab_radial.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/tab_radial.lua" },
    { path = "MFTools\\ui\\theme.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/theme.lua" },
    { path = "MFTools\\ui\\utils.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/utils.lua" },
    { path = "MFTools\\ui\\uistate.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/uistate.lua" },
    { path = "MFTools\\ui\\tabs.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/tabs.lua" },
    { path = "MFTools\\ui\\overlay_autoreport.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/overlay_autoreport.lua" },
    
    -- Радиальное меню и цели
    { path = "MFTools\\radial\\radial_menu.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/radial/radial_menu.lua" },
    { path = "MFTools\\radial\\radial_math.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/radial/radial_math.lua" },
    { path = "MFTools\\target\\core.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/target/core.lua" },
    { path = "MFTools\\target\\radial.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/target/radial.lua" },

    -- Иконки и ассеты (папка assets)
    { path = "MFTools\\assets\\ALCATRAZ.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/ALCATRAZ.png" },
    { path = "MFTools\\assets\\FBI.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/FBI.png" },
    { path = "MFTools\\assets\\KB.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/KB.png" },
    { path = "MFTools\\assets\\MZ.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/MZ.png" },
    { path = "MFTools\\assets\\POLICE.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/POLICE.png" },
    { path = "MFTools\\assets\\PRAVO.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/PRAVO.png" },
    { path = "MFTools\\assets\\SMI.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/SMI.png" },
    { path = "MFTools\\assets\\SV.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/SV.png" },
    { path = "MFTools\\assets\\biker.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/biker.png" },
    { path = "MFTools\\assets\\ghetto.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/ghetto.png" },
    { path = "MFTools\\assets\\grid.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/grid.png" },
    { path = "MFTools\\assets\\list.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/list.png" },
    { path = "MFTools\\assets\\sc.png", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/assets/sc.png" }
}

local isInstalled = true
local updateAvailable = false
local updateUrl = ""
local updateVersionText = ""

local function createDirectories()
    local dirs = {
        getWorkingDirectory() .. "\\MFTools",
        getWorkingDirectory() .. "\\MFTools\\core",
        getWorkingDirectory() .. "\\MFTools\\data",
        getWorkingDirectory() .. "\\MFTools\\ui",
        getWorkingDirectory() .. "\\MFTools\\radial",
        getWorkingDirectory() .. "\\MFTools\\target",
        getWorkingDirectory() .. "\\MFTools\\assets",
        getWorkingDirectory() .. "\\config",
        getWorkingDirectory() .. "\\config\\MFT_Screens"
    }
    for _, dir in ipairs(dirs) do
        if not doesDirectoryExist(dir) then createDirectory(dir) end
    end
end

for _, file in ipairs(files_to_download) do
    if not doesFileExist(getWorkingDirectory() .. "\\" .. file.path) then
        isInstalled = false
        break
    end
end

local function downloadDependencies()
    createDirectories()
    local total_files = #files_to_download
    sampAddChatMessage(string.format("{3498DB}[MFTools] {FFFFFF}Началась установка компонентов (всего файлов: {FFDD00}%d{FFFFFF}). Пожалуйста, подождите...", total_files), -1)
    
    for i, file in ipairs(files_to_download) do
        local dest = getWorkingDirectory() .. "\\" .. file.path
        if not doesFileExist(dest) then
            local isDone = false
            local fileUrlWithNoCache = file.url .. "?nocache=" .. os.time() .. "&rnd=" .. math.random(10000, 99999)
            
            downloadUrlToFile(fileUrlWithNoCache, dest, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then isDone = true end
            end)
            
            local timeout = os.clock() + 15.0 
            while not isDone and os.clock() < timeout do wait(50) end
        end
    end
    
    sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Установка успешно завершена! Скрипт перезагружается...", -1)
    thisScript():reload()
end

local function checkForUpdates()
    local jsonPath = getWorkingDirectory() .. "\\mft_update.json"
    
    local urlWithNoCache = UPDATE_JSON_URL .. "?nocache=" .. os.time() .. "&rnd=" .. math.random(10000, 99999)
    
    downloadUrlToFile(urlWithNoCache, jsonPath, function(id, status, p1, p2)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            local f = io.open(jsonPath, "r")
            if f then
                local content = f:read("*a")
                f:close()
                os.remove(jsonPath)
                
                local decode = require("cjson").decode
                local success, data = pcall(decode, content)
                
                if success and data and tonumber(data.version) then
                    sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Текущая версия скрипта: {FFDD00}" .. SCRIPT_VERSION_TEXT, -1)
                    
                    if tonumber(data.version) ~= SCRIPT_VERSION then
                        updateAvailable = true
                        updateUrl = data.url
                        updateVersionText = data.version_text
                        sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Доступно обновление: {FFDD00}" .. updateVersionText, -1)
                        sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Напишите команду в чат {FFDD00}/mft_up{FFFFFF}, чтобы установить его.", -1)
                    else
                        updateAvailable = false
                        sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Проверка обновлений прошла успешно, обновлений не обнаружено.", -1)
                    end
                else
                    sampAddChatMessage("{FF0000}[MFTools] Ошибка чтения update.json. Проверьте синтаксис файла на GitHub!", -1)
                end
            end
        end
    end)
end

if not isInstalled then
    function main()
        while not isSampAvailable() do wait(100) end
        downloadDependencies()
        wait(-1)
    end
    return 
end

local imgui = require "mimgui"

_G.MFT = {
    version = SCRIPT_VERSION_TEXT,
    paths = {
        config = getWorkingDirectory() .. "\\config\\",
        binds  = getWorkingDirectory() .. "\\config\\mftools_binds.json",
        settings = getWorkingDirectory() .. "\\config\\mftools_settings.json",
        assets = getWorkingDirectory() .. "\\MFTools\\assets\\"
    },
    state = {
        isMenuOpen = false,
        mainWindowState = imgui.new.bool(false),
        overlayWindowState = imgui.new.bool(true),
        currentTab = 1,
        dataLoaded = false,
        isPlacingOverlay = false,
        placingTimer = 0.0,
        editingBindIndex = -1,
        expandedBindIndex = -1,
        capturingHotkeyFor = -1,
        
        aimTargetId = -1,
        aimTargetName = "",
        capturingTargetRadial = false,
        capturingTargetQuick = 0,
        
        dialogActive = false,
        dialogPrompt = "",
        dialogText = imgui.new.char[256](""),
        
        cmdShowSuggestions = false,
        cmdSuggestions = {},
        cmdSelectedIndex = 1,
        cmdLastText = "",
        cmdReopenText = nil,
        cmdReopenTicks = 0,
        
        chatEdited = false,
        isEditingChatLine = false,
        chatBackup = nil,
        isCalibratingChat = false,

        isPlacingAROverlay = false,
        openArModal = false,
        editingArIndex = -1,
        ar = { isRunning = false, currentIndex = 1, nextTime = 0 },

        previewPresetId = -1,
        editingModalIndex = -1,
        colorPickerActive = false,
        colorPickerTarget = "",
        showTargetVis = false,
        presetsExpanded = false,
        
        -- === ПЕРЕМЕННЫЕ ДЛЯ КРАСИВОГО ОКНА ОБНОВЛЕНИЯ ===
        isUpdating = false,
        updateCurrent = 0,
        updateTotal = 0,
        updateFileName = "",
        updateAnim = 0.0,
        smoothProgress = 0.0
    },
    settings = {}, binds = {}, bindThreads = {}, data = {}, fonts = {}
}

local commands_data = require "MFTools.data.commands"
local engine        = require "MFTools.core.engine"
local formatter     = require "MFTools.core.formatter"
local suggest       = require "MFTools.core.suggest"
local chatedit      = require "MFTools.core.chatedit"
local theme         = require "MFTools.ui.theme"
local dashboard     = require "MFTools.ui.dashboard"
local radial_menu   = require "MFTools.radial.radial_menu"
local target_core   = require "MFTools.target.core"
local ovl_ar        = require "MFTools.ui.overlay_autoreport"

MFT.data.command_list = commands_data
engine.loadData()

imgui.OnInitialize(function() theme.initFonts() end)

local uiFrame = imgui.OnFrame(
    function() 
        return dashboard.shouldDraw() or radial_menu.isOpen or radial_menu.openAnim > 0.01 or target_core.shouldDraw() or MFT.state.isEditingChatLine or MFT.state.isCalibratingChat or MFT.state.ar.isRunning or MFT.state.isPlacingAROverlay or (MFT.state.updateAnim and MFT.state.updateAnim > 0.005)
    end,
    function(player)
        dashboard.draw()
        radial_menu.drawUI()
        target_core.drawUI()
        chatedit.drawUI()
        ovl_ar.draw(MFT.settings.colorAccent)

        -- === КРАСИВОЕ ОКНО ПРОГРЕССА ОБНОВЛЕНИЯ ===
        MFT.state.updateAnim = MFT.state.updateAnim or 0.0
        local dt = imgui.GetIO().DeltaTime
        local targetAlpha = MFT.state.isUpdating and 1.0 or 0.0
        
        -- Плавная анимация: замедлили в 3 раза для отчетливого выплывания
        if MFT.state.isUpdating then
            MFT.state.updateAnim = MFT.state.updateAnim + (targetAlpha - MFT.state.updateAnim) * math.min(1.0, 4.0 * dt)
        else
            MFT.state.updateAnim = MFT.state.updateAnim + (targetAlpha - MFT.state.updateAnim) * math.min(1.0, 4.0 * dt)
        end

        if MFT.state.updateAnim > 0.005 then
            local sw, sh = getScreenResolution()
            local winW, winH = 420, 115
            local marginY = 50
            
            -- Выплывает прямо из-за нижнего края экрана
            local startY = sh + 20 
            local endY = sh - winH - marginY
            -- Мягкое торможение в конце
            local easeAnim = 1.0 - math.pow(1.0 - MFT.state.updateAnim, 4.0) 
            local currentY = startY + (endY - startY) * easeAnim
            local currentX = sw / 2 - winW / 2
            
            imgui.SetNextWindowPos(imgui.ImVec2(currentX, currentY), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.Always)
            
            local c_accent = MFT.settings.colorAccent or {0.35, 0.55, 0.85}
            
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, MFT.state.updateAnim)
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.07, 0.07, 0.08, 0.98))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.6 * MFT.state.updateAnim))
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12.0)
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 1.5)
            
            imgui.Begin("##ModernUpdatePopup", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoFocusOnAppearing + imgui.WindowFlags.NoInputs)
            
            local dl = imgui.GetWindowDrawList()
            local p = imgui.GetCursorScreenPos()
            
            -- Заголовок
            if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
            imgui.SetCursorPos(imgui.ImVec2(20, 15))
            imgui.TextColored(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0), u8"MFTools | Обновление компонентов")
            if MFT.fonts.title then imgui.PopFont() end
            
            -- Имя файла
            imgui.SetCursorPos(imgui.ImVec2(20, 45))
            imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8"Файл: " .. u8(MFT.state.updateFileName))
            
            -- Текст прогресса (справа)
            local progText = string.format("%d / %d", MFT.state.updateCurrent, MFT.state.updateTotal)
            local tW = imgui.CalcTextSize(progText).x
            imgui.SetCursorPos(imgui.ImVec2(winW - tW - 20, 45))
            imgui.TextColored(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0), progText)
            
            -- Кастомный красивый Progress Bar
            local barX, barY = p.x + 20, p.y + 70
            local barW, barH = winW - 40, 6
            local progress = MFT.state.updateTotal > 0 and (MFT.state.updateCurrent / MFT.state.updateTotal) or 0
            
            -- Плавное заполнение полосы
            MFT.state.smoothProgress = MFT.state.smoothProgress or 0.0
            MFT.state.smoothProgress = MFT.state.smoothProgress + (progress - MFT.state.smoothProgress) * math.min(1.0, 15.0 * dt)
            
            -- Фон полосы
            dl:AddRectFilled(imgui.ImVec2(barX, barY), imgui.ImVec2(barX + barW, barY + barH), imgui.GetColorU32Vec4(imgui.ImVec4(0.15, 0.15, 0.15, 1.0)), 3.0)
            
            -- Заполненная часть с фейковым свечением (glow)
            if MFT.state.smoothProgress > 0.01 then
                local fillW = barW * MFT.state.smoothProgress
                dl:AddRectFilled(imgui.ImVec2(barX, barY - 1), imgui.ImVec2(barX + fillW, barY + barH + 1), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 0.3)), 4.0)
                dl:AddRectFilled(imgui.ImVec2(barX, barY), imgui.ImVec2(barX + fillW, barY + barH), imgui.GetColorU32Vec4(imgui.ImVec4(c_accent[1], c_accent[2], c_accent[3], 1.0)), 3.0)
            end
            
            -- Статус/предупреждение
            imgui.SetCursorPos(imgui.ImVec2(20, 88))
            imgui.TextColored(imgui.ImVec4(0.4, 0.4, 0.4, 1.0), u8"Пожалуйста, не закрывайте игру до окончания загрузки...")
            
            imgui.End()
            imgui.PopStyleVar(3)
            imgui.PopStyleColor(2)
        end
        -- ==================================
    end
)

function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{3498DB}[MFTools v" .. SCRIPT_VERSION_TEXT .. "] {FFFFFF}Скрипт успешно загружен! Меню: {FFDD00}/mft", -1)
    
    lua_thread.create(function()
        wait(2000)
        checkForUpdates()
    end)

    sampRegisterChatCommand("mft", function() 
        MFT.state.isMenuOpen = not MFT.state.isMenuOpen 
    end)

    sampRegisterChatCommand("mft_check", function()
        sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Проверяем наличие обновлений на сервере...", -1)
        checkForUpdates()
    end)

    -- === ОБНОВЛЕННАЯ БРОНЕБОЙНАЯ СИСТЕМА С КРАСИВОЙ АНИМАЦИЕЙ ===
    sampRegisterChatCommand("mft_up", function() 
        if updateAvailable then
            local total_files = #files_to_download + 1 
            local current_file = 0
            
            sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Начинаем загрузку обновления... Пожалуйста, подождите.", -1)
            
            -- Включаем отображение стильного окна прогресса
            MFT.state.isUpdating = true
            MFT.state.updateTotal = total_files
            MFT.state.updateCurrent = 0
            MFT.state.updateFileName = "Подготовка..."
            MFT.state.smoothProgress = 0.0

            lua_thread.create(function()
                -- 1. СКАЧИВАЕМ ЗАВИСИМОСТИ
                for _, file in ipairs(files_to_download) do
                    local dest = getWorkingDirectory() .. "\\" .. file.path
                    if doesFileExist(dest) then os.remove(dest) end
                    
                    current_file = current_file + 1
                    MFT.state.updateCurrent = current_file
                    MFT.state.updateFileName = file.path:match("([^%\\]+)$")
                    
                    local fileDone = false
                    local fileUrlWithNoCache = file.url .. "?nocache=" .. os.time() .. "&rnd=" .. math.random(10000, 99999)
                    
                    downloadUrlToFile(fileUrlWithNoCache, dest, function(id, status)
                        if status == dlstatus.STATUS_ENDDOWNLOADDATA then fileDone = true end
                    end)
                    
                    local fileTimeout = os.clock() + 15.0 
                    while not fileDone and os.clock() < fileTimeout do wait(50) end
                end
                
                -- 2. СКАЧИВАЕМ ГЛАВНЫЙ ФАЙЛ
                local scriptPath = thisScript().path
                local mainDone = false
                
                current_file = current_file + 1
                MFT.state.updateCurrent = current_file
                MFT.state.updateFileName = "MFTools.lua (Завершение)"
                
                downloadUrlToFile(updateUrl .. "?nocache=" .. os.time() .. "&rnd=" .. math.random(10000, 99999), scriptPath, function(id, status)
                    if status == dlstatus.STATUS_ENDDOWNLOADDATA then mainDone = true end
                end)
                
                local timeout = os.clock() + 15.0
                while not mainDone and os.clock() < timeout do wait(50) end
                
                -- Ждем 1 секунду, чтобы игрок успел увидеть 100% загрузки
                wait(1000)
                
                -- Запускаем плавное исчезновение
                MFT.state.isUpdating = false
                
                -- Даем полторы секунды на то, чтобы окно красиво уплыло вниз
                wait(1500) 
                
                sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Все файлы успешно обновлены! Скрипт перезагружается...", -1)
                thisScript():reload()
            end)
        else
            sampAddChatMessage("{FF0000}[MFTools] {FFFFFF}Нет доступных обновлений. Введите {FFDD00}/mft_check{FFFFFF} для проверки сервера.", -1)
        end
    end)
    -- =========================================================
    
    sampRegisterChatCommand("bb", function(arg) engine.cmdRunBind(arg) end)

    while true do
        wait(0)
        suggest.processTick()
        dashboard.processOverlayPlacement()
        engine.processHotkeys()
        engine.processAutoReport()
        radial_menu.process()
        target_core.process()
        
        dashboard.updateState(uiFrame)
        if radial_menu.isOpen or target_core.isRadialOpen() or MFT.state.isCalibratingChat then uiFrame.HideCursor = false end
        
        suggest.drawUI()
        chatedit.processDX()
    end
end

function samp.onSendCommand(cmd)
    suggest.onSendCommand(cmd)
    return formatter.onSendCommand(cmd)
end

function samp.onSendChat(text) return text end
function samp.onServerMessage(color, text) return formatter.onServerMessage(color, text) end

-- === ИНТЕЛЛЕКТУАЛЬНАЯ ОБРАБОТКА НАЖАТИЙ КЛАВИШ (ЗАКРЫТИЕ НА ESCAPE) ===
function onWindowMessage(msg, wparam, lparam) 
    if wparam == vk.VK_ESCAPE and MFT.state.isMenuOpen then
        if msg == 0x0100 or msg == 0x0101 then 
            consumeWindowMessage(true, false) 
            
            if msg == 0x0101 then 
                local isCapturing = MFT.state.capturingSmartScreenKey or MFT.state.capturingSeqKey or 
                                    MFT.state.capturingRadialHotkey or MFT.state.capturingTargetRadial or 
                                    (MFT.state.capturingTargetQuick and MFT.state.capturingTargetQuick > 0) or 
                                    (MFT.state.capturingHotkeyFor and MFT.state.capturingHotkeyFor ~= -1)
                
                if isCapturing then
                elseif MFT.state.colorPickerActive then
                    MFT.state.colorPickerActive = false
                elseif MFT.state.isCustomThemeOpen then
                    MFT.state.isCustomThemeOpen = false
                elseif MFT.state.editingModalIndex and MFT.state.editingModalIndex ~= -1 then
                    MFT.state.editingModalIndex = -1
                elseif MFT.state.previewPresetId and MFT.state.previewPresetId ~= -1 then
                    MFT.state.previewPresetId = -1
                elseif MFT.state.dialogActive then
                    MFT.state.dialogActive = false
                else
                    MFT.state.isMenuOpen = false
                end
            end
        end
    end
    
    return suggest.onWindowMessage(msg, wparam, lparam) 
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        if chatedit and MFT.state.chatEdited then pcall(chatedit.restoreBackup) end
    end
end