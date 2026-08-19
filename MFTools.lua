--[[
    MFTools (Mordor Faction Tools) v1.2 (beta test)
    Главный файл (Ядро + Автоустановщик + Автообновление)
    Разработчик: Bryan Kogfield (Богдан)
]]

script_name("MFTools")
script_author("Bryan Kogfield")
script_version("1.2 (beta test)")

require "lib.moonloader"
local samp = require "lib.samp.events"
local dlstatus = require('moonloader').download_status
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- ==========================================
-- === НАСТРОЙКИ АВТООБНОВЛЕНИЯ И ЗАГРУЗКИ ===
-- ==========================================
local SCRIPT_VERSION = 1.2 
local SCRIPT_VERSION_TEXT = "1.2 (beta test)"
local UPDATE_JSON_URL = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/update.json" 
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools.lua" 

-- Полный список всех файлов (код, данные, интерфейс и иконки) для автоматической загрузки у игроков
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
    { path = "MFTools\\ui\\tab_binds.lua", url = "https://raw.githubusercontent.com/AyatoCobra/MFTools/main/MFTools/ui/tab_binds.lua" },
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
    sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Началась первичная установка компонентов. Пожалуйста, подождите...", -1)
    
    for i, file in ipairs(files_to_download) do
        local dest = getWorkingDirectory() .. "\\" .. file.path
        if not doesFileExist(dest) then
            -- Добавлен обход кэша для первичной установки
            local urlWithNoCache = file.url .. "?t=" .. os.time()
            downloadUrlToFile(urlWithNoCache, dest, function(id, status, p1, p2)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    print("MFTools: Загружен файл " .. file.path)
                end
            end)
        end
    end
    
    local allDownloaded = false
    while not allDownloaded do
        wait(1000)
        allDownloaded = true
        for _, file in ipairs(files_to_download) do
            if not doesFileExist(getWorkingDirectory() .. "\\" .. file.path) then allDownloaded = false end
        end
    end
    
    sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Установка успешно завершена! Скрипт перезагружается...", -1)
    thisScript():reload()
end

local function checkForUpdates()
    local jsonPath = getWorkingDirectory() .. "\\mft_update.json"
    -- Обход кэша для JSON работает отлично
    local urlWithNoCache = UPDATE_JSON_URL .. "?t=" .. os.time()
    
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
                    
                    if tonumber(data.version) > SCRIPT_VERSION then
                        updateAvailable = true
                        updateUrl = data.url
                        updateVersionText = data.version_text
                        sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Доступно обновление: {FFDD00}" .. updateVersionText, -1)
                        sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Напишите команду в чат {FFDD00}/mft_up{FFFFFF}, чтобы установить его.", -1)
                    else
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
        presetsExpanded = false
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
        return dashboard.shouldDraw() or radial_menu.isOpen or radial_menu.openAnim > 0.01 or target_core.shouldDraw() or MFT.state.isEditingChatLine or MFT.state.isCalibratingChat or MFT.state.ar.isRunning or MFT.state.isPlacingAROverlay
    end,
    function(player)
        dashboard.draw()
        radial_menu.drawUI()
        target_core.drawUI()
        chatedit.drawUI()
        ovl_ar.draw(MFT.settings.colorAccent)
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

    sampRegisterChatCommand("mft_up", function() 
        if updateAvailable then
            sampAddChatMessage("{3498DB}[MFTools] {FFFFFF}Начинаем загрузку обновления. Это займет пару секунд...", -1)
            
            lua_thread.create(function()
                -- 1. Скачиваем главный файл с ОБХОДОМ КЭША
                local scriptPath = thisScript().path
                local mainScriptDownloaded = false
                local mainUrlWithNoCache = updateUrl .. "?t=" .. os.time()
                
                downloadUrlToFile(mainUrlWithNoCache, scriptPath, function(id, status)
                    if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                        mainScriptDownloaded = true
                    end
                end)
                
                -- 2. Скачиваем все зависимые файлы с ОБХОДОМ КЭША
                local totalFiles = #files_to_download
                local downloaded = 0
                
                for _, file in ipairs(files_to_download) do
                    local dest = getWorkingDirectory() .. "\\" .. file.path
                    local fileUrlWithNoCache = file.url .. "?t=" .. os.time()
                    
                    downloadUrlToFile(fileUrlWithNoCache, dest, function(id, status)
                        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                            downloaded = downloaded + 1
                        end
                    end)
                end
                
                -- 3. Ждем завершения загрузок
                while downloaded < totalFiles or not mainScriptDownloaded do wait(100) end
                
                -- 4. Перезагрузка
                sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Все файлы успешно обновлены! Скрипт перезагружается...", -1)
                thisScript():reload()
            end)
        else
            sampAddChatMessage("{FF0000}[MFTools] {FFFFFF}Нет доступных обновлений для загрузки.", -1)
        end
    end)
    
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
function onWindowMessage(msg, wparam, lparam) return suggest.onWindowMessage(msg, wparam, lparam) end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        if chatedit and MFT.state.chatEdited then pcall(chatedit.restoreBackup) end
    end
end