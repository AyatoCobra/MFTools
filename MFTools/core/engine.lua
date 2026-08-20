-- Файл: MFTools/core/engine.lua
local samp = require "lib.samp.events"
local vk = require "vkeys"
local ffi = require "ffi"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local engine = {}
engine.lastSentLine = ""           -- Запоминаем последнюю отправленную строку
engine.antiFloodTriggered = false  -- Флаг срабатывания анти-флуда

local cfgPath = getWorkingDirectory() .. "\\config\\MFTools_Data.ini"

pcall(ffi.cdef, [[
    typedef unsigned long DWORD;
    typedef unsigned short WORD;
    typedef unsigned char BYTE;
    typedef int BOOL;
    typedef void* HWND;
    typedef void* HDC;
    typedef void* HBITMAP;
    typedef void* HGDIOBJ;
    
    HDC GetDC(HWND hWnd);
    int ReleaseDC(HWND hWnd, HDC hDC);
    HDC CreateCompatibleDC(HDC hdc);
    BOOL DeleteDC(HDC hdc);
    HBITMAP CreateCompatibleBitmap(HDC hdc, int cx, int cy);
    HGDIOBJ SelectObject(HDC hdc, HGDIOBJ h);
    BOOL DeleteObject(HGDIOBJ ho);
    BOOL BitBlt(HDC hdcDest, int xDest, int yDest, int wDest, int hDest, HDC hdcSrc, int xSrc, int ySrc, DWORD rop);
    int MultiByteToWideChar(unsigned int CodePage, DWORD dwFlags, const char* lpMultiByteStr, int cbMultiByte, wchar_t* lpWideCharStr, int cchWideChar);
    
    typedef struct {
        uint32_t GdiplusVersion;
        void* DebugEventCallback;
        BOOL SuppressBackgroundThread;
        BOOL SuppressExternalCodecs;
    } GdiplusStartupInput;

    typedef struct {
        uint32_t Data1;
        uint16_t Data2;
        uint16_t Data3;
        uint8_t  Data4[8];
    } CLSID;

    int GdiplusStartup(void **token, const GdiplusStartupInput *input, void *output);
    void GdiplusShutdown(void *token);
    int GdipCreateBitmapFromHBITMAP(HBITMAP hbm, void* hpal, void **bitmap);
    int GdipSaveImageToFile(void *image, const wchar_t *filename, const CLSID *clsidEncoder, const void *encoderParams);
    int GdipDisposeImage(void *image);
]])

local gdi32, user32, gdiplus, k32
pcall(function()
    gdi32 = ffi.load('gdi32')
    user32 = ffi.load('user32')
    gdiplus = ffi.load('gdiplus')
    k32 = ffi.load('kernel32')
end)

local function loadCustomIni(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local data = {}
    local section = nil
    for line in f:lines() do
        if line:sub(1, 3) == "\xEF\xBB\xBF" then line = line:sub(4) end
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and line:sub(1,1) ~= ";" then
            local s = line:match("^%[(.+)%]$")
            if s then
                section = s
                data[section] = data[section] or {}
            elseif section then
                local k, v = line:match("^([^=]+)=(.*)$")
                if k and v then data[section][k:match("^%s*(.-)%s*$")] = v:match("^%s*(.-)%s*$") end
            end
        end
    end
    f:close()
    return data
end

local function saveCustomIni(data, path)
    local f = io.open(path, "w")
    if not f then return false end
    for sec, kv in pairs(data) do
        if type(kv) == "table" and next(kv) ~= nil then
            f:write("[" .. sec .. "]\n")
            for k, v in pairs(kv) do f:write(tostring(k) .. "=" .. tostring(v) .. "\n") end
        end
    end
    f:close()
    return true
end

local function cleanPlayerName(name)
    if not name then return "" end
    name = name:gsub("%[PC%]", ""):gsub("%[M%]", ""):match("^%s*(.-)%s*$")
    return name:gsub("_", " ")
end

local function getClosestPlayerIdAndName()
    if not doesCharExist(PLAYER_PED) then return -1, "" end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local minDist, closestId = 30.0, -1
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)

    for i = 0, sampGetMaxPlayerId(true) do
        if sampIsPlayerConnected(i) and i ~= myId then
            local result, ped = sampGetCharHandleBySampPlayerId(i)
            if result and doesCharExist(ped) then
                local hx, hy, hz = getCharCoordinates(ped)
                local dist = math.sqrt((px - hx)^2 + (py - hy)^2 + (pz - hz)^2)
                if dist < minDist then minDist = dist; closestId = i end
            end
        end
    end
    local closestName = closestId ~= -1 and cleanPlayerName(sampGetPlayerNickname(closestId)) or ""
    return closestId, closestName
end

local function getLocation()
    local x, y, z = getCharCoordinates(PLAYER_PED)
    if x < -1000 then return "San-Fierro"
    elseif x > 1000 then return "Las-Venturas"
    else return "Los-Santos" end
end

local function getDirection()
    local heading
    if isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        heading = getCarHeading(car)
    else
        heading = getCharHeading(PLAYER_PED)
    end
    
    if heading >= 337.5 or heading < 22.5 then return "север"
    elseif heading >= 22.5 and heading < 67.5 then return "северо-запад"
    elseif heading >= 67.5 and heading < 112.5 then return "запад"
    elseif heading >= 112.5 and heading < 157.5 then return "юго-запад"
    elseif heading >= 157.5 and heading < 202.5 then return "юг"
    elseif heading >= 202.5 and heading < 247.5 then return "юго-восток"
    elseif heading >= 247.5 and heading < 292.5 then return "восток"
    elseif heading >= 292.5 and heading < 337.5 then return "северо-восток"
    end
    return "неизвестно"
end

local function cleanCData(data)
    if type(data) == "table" then
        local cleanTable = {}
        for k, v in pairs(data) do cleanTable[k] = cleanCData(v) end
        return cleanTable
    elseif type(data) == "cdata" then
        if tostring(data):find("bool") then return data[0] == true end
        local ok, num = pcall(tonumber, data)
        if ok and num then return num end
        return tostring(data)
    else return data end
end

local function toBool(v)
    if type(v) == "boolean" then return v end
    if v == "true" then return true end
    if v == "false" then return false end
    return v
end

local function valToStr(v)
    if type(v) == "cdata" then
        if tostring(v):find("bool") then return tostring(v[0] == true) end
        local ok, num = pcall(tonumber, v)
        if ok and num then return tostring(num) end
    end
    if v == nil then return "" end
    return tostring(v)
end

local function initGroups(targetObj)
    if type(targetObj.groups) ~= "table" then targetObj.groups = {} end
    for i=1, 12 do
        if not targetObj.groups[tostring(i)] then
            targetObj.groups[tostring(i)] = { name = "ГРУППА "..i, count = 6, binds = {} }
        end
    end
end

function engine.initDefaults()
    if type(MFT.settings.accordions) ~= "table" then MFT.settings.accordions = {} end
    if not MFT.settings.recentCommands then MFT.settings.recentCommands = {} end
    if not MFT.settings.cmdUsageStats then MFT.settings.cmdUsageStats = {} end
    if MFT.settings.autoRpFormatter == nil then MFT.settings.autoRpFormatter = true end
    if type(MFT.settings.autoScreenModes) ~= "table" then
        MFT.settings.autoScreenModes = { radio = true, su = false, arrest = false, frisk = false, cuff = false, ticket = false, heal = false, lic = false }
    end
    if not MFT.settings.savedThemes then MFT.settings.savedThemes = {} end
    if type(MFT.settings.ssFilters) ~= "table" then
        MFT.settings.ssFilters = {ooc = true, radio = true, vip = true, ads = true, sys = true, pd_alerts = true, afk = true, events = true, thoughts = true}
    end
    
    if type(MFT.settings.radial) ~= "table" then MFT.settings.radial = {} end
    if MFT.settings.radial.menuMode == nil then MFT.settings.radial.menuMode = 0 end
    initGroups(MFT.settings.radial)
    
    if not MFT.settings.target then
        MFT.settings.target = { enabled = true, radialKey = 82, sectorsCount = 6, radius = 150.0, transparency = 0.8, sectorColor = {0.1, 0.1, 0.1}, radialBinds = {}, quickKeys = {{key=0, bind=0}}, menuMode = 0 }
    end
    if MFT.settings.target.menuMode == nil then MFT.settings.target.menuMode = 0 end
    initGroups(MFT.settings.target)

    if not MFT.settings.autoReport then
        MFT.settings.autoReport = { enabled = false, interval = 10, autoScreen = true, showOverlay = true, x = 500, y = 100, reports = {} }
    end
    if MFT.settings.autoReport.autoScreen == nil then MFT.settings.autoReport.autoScreen = true end
    if MFT.settings.autoReport.showOverlay == nil then MFT.settings.autoReport.showOverlay = true end
    if MFT.state.ar.activeId == nil then MFT.state.ar.activeId = -1 end
    if MFT.state.ar.sentCount == nil then MFT.state.ar.sentCount = 0 end

    if not MFT.settings.smartDept then
        MFT.settings.smartDept = { enabled = true, maxItems = 8, tags = {"to [ALL]", "to [LSPD]", "to [SFPD]", "to [LVPD]", "to [FBI]", "to [MZ]", "to [SMI]", "to [SV]"} }
    end
    if MFT.settings.smartDept.maxItems == nil then MFT.settings.smartDept.maxItems = 8 end

    if MFT.settings.cmdSuggestEnabled == nil then MFT.settings.cmdSuggestEnabled = true end
    if MFT.settings.cmdFontSize == nil then MFT.settings.cmdFontSize = 11 end
    if MFT.settings.cmdOffsetY == nil then MFT.settings.cmdOffsetY = 55 end
    if MFT.settings.cmdMaxItems == nil then MFT.settings.cmdMaxItems = 8 end
    if not MFT.settings.cmdColorSel then MFT.settings.cmdColorSel = {0.20, 0.59, 0.85} end
    if not MFT.settings.cmdColorUnsel then MFT.settings.cmdColorUnsel = {0.62, 0.62, 0.62} end

    if not MFT.settings.autoLineBreak then
        MFT.settings.autoLineBreak = { 
            enabled = true, maxLength = 95, suffix = "...", prefix = "...",
            cmds = { normal = true, r = true, rn = true, f = true, fn = true, fr = true, frn = true, a = true, me = true, do_ = true }
        }
    end

    if type(MFT.settings.smartScreen) ~= "table" then
        local old = MFT.settings.smartF8 or {}
        MFT.settings.smartScreen = { 
            enabled = old.enabled or false, 
            hotkey = old.hotkey or 119,
            showNotif = old.showNotif == nil and true or old.showNotif,
            x = old.x or 20, 
            y = old.y or 20, 
            w = old.w or 800, 
            h = old.h or 600 
        }
    end
    
    if type(MFT.settings.seqOverlay) ~= "table" then
        MFT.settings.seqOverlay = { enabled = true, hotkey = 0, alpha = 0.8, x = 300, y = 300 }
    end
    if MFT.settings.seqOverlay.alpha == nil then MFT.settings.seqOverlay.alpha = 0.8 end
    if MFT.state.seq == nil then MFT.state.seq = { activeBind = nil, step = 1 } end
end

local function deserializeBindsTree(prefix, ini)
    local list = {}
    if not ini[prefix] then return list end
    local count = tonumber(ini[prefix].count) or 0
    for i = 1, count do
        local curKey = prefix .. "_" .. i
        local sec = ini[curKey]
        if sec then
            if sec.type == "folder" then
                local folder = { type = "folder", name = valToStr(sec.name), items = deserializeBindsTree(curKey .. "_items", ini) }
                table.insert(list, folder)
            else
                local b = { type = "bind", name = valToStr(sec.name), delay = tonumber(sec.delay) or 1000, hotkey = tonumber(sec.hotkey) or 0, showInOverlay = toBool(sec.showInOverlay), lines = {} }
                for j = 1, tonumber(sec.linesCount) or 0 do table.insert(b.lines, valToStr(sec["line_"..j] or "")) end
                table.insert(list, b)
            end
        end
    end
    return list
end

local function serializeBindsTree(list, prefix, ini)
    ini[prefix] = { count = tostring(#list) }
    for i, item in ipairs(list) do
        local curKey = prefix .. "_" .. i
        if item.type == "folder" then
            ini[curKey] = { type = "folder", name = valToStr(item.name) }
            serializeBindsTree(item.items or {}, curKey .. "_items", ini)
        else
            ini[curKey] = { type = "bind", name = valToStr(item.name), delay = valToStr(item.delay), hotkey = valToStr(item.hotkey), showInOverlay = valToStr(item.showInOverlay), linesCount = tostring(#(item.lines or {})) }
            for j, line in ipairs(item.lines or {}) do
                ini[curKey]["line_"..j] = valToStr(line)
            end
        end
    end
end

local function loadGroups(obj, prefix, ini)
    obj.menuMode = tonumber(ini[prefix] and ini[prefix].menuMode) or 0
    obj.groups = {}
    for i=1, 12 do
        local gSec = ini[prefix.."_Group_"..i]
        if gSec then
            local grp = { name = valToStr(gSec.name), count = tonumber(gSec.count) or 6, binds = {} }
            for j=1, 12 do grp.binds[tostring(j)] = valToStr(gSec["bind_"..j] or "") end
            obj.groups[tostring(i)] = grp
        else
            obj.groups[tostring(i)] = { name = "ГРУППА "..i, count = 6, binds = {} }
        end
    end
end

local function saveGroups(obj, prefix, ini)
    if not ini[prefix] then ini[prefix] = {} end
    ini[prefix].menuMode = valToStr(obj.menuMode)
    for i=1, 12 do
        local grp = obj.groups[tostring(i)]
        if grp then
            local gSecName = prefix.."_Group_"..i
            ini[gSecName] = { name = valToStr(grp.name), count = valToStr(grp.count) }
            for j=1, 12 do ini[gSecName]["bind_"..j] = valToStr(grp.binds[tostring(j)]) end
        end
    end
end

function engine.loadData()
    MFT.state.isLoadingData = true 
    local ini = loadCustomIni(cfgPath)
    if not ini then ini = {} end

    MFT.settings = {}
    MFT.binds = {}
    
    if ini.Settings then
        for k, v in pairs(ini.Settings) do 
            MFT.settings[k] = toBool(v) 
            if tonumber(v) and type(MFT.settings[k]) ~= "boolean" then MFT.settings[k] = tonumber(v) end
        end
    end
    
    MFT.settings.radial = {}
    if ini.Radial then
        for k, v in pairs(ini.Radial) do MFT.settings.radial[k] = toBool(v); if tonumber(v) and type(MFT.settings.radial[k]) ~= "boolean" then MFT.settings.radial[k] = tonumber(v) end end
    end
    MFT.settings.radial.binds = {}
    if ini.RadialBinds then for k, v in pairs(ini.RadialBinds) do MFT.settings.radial.binds[tostring(k)] = tonumber(v) or v end end
    if ini.RadialColors then MFT.settings.radial.sectorColor = {tonumber(ini.RadialColors.r) or 0.08, tonumber(ini.RadialColors.g) or 0.08, tonumber(ini.RadialColors.b) or 0.08} end
    loadGroups(MFT.settings.radial, "Radial", ini)
    
    MFT.settings.ssFilters = {}
    if ini.SSFilters then for k, v in pairs(ini.SSFilters) do MFT.settings.ssFilters[k] = toBool(v) end end
    
    engine.initDefaults()

    if ini.Accordions then
        for k, v in pairs(ini.Accordions) do MFT.settings.accordions[k] = toBool(v) end
    end

    if ini.Settings then
        if ini.Settings.cSelR then MFT.settings.cmdColorSel = {tonumber(ini.Settings.cSelR), tonumber(ini.Settings.cSelG), tonumber(ini.Settings.cSelB)} end
        if ini.Settings.cUnselR then MFT.settings.cmdColorUnsel = {tonumber(ini.Settings.cUnselR), tonumber(ini.Settings.cUnselG), tonumber(ini.Settings.cUnselB)} end
    end

    if ini.Target then
        MFT.settings.target.enabled = toBool(ini.Target.enabled); MFT.settings.target.radialKey = tonumber(ini.Target.radialKey) or 82
        MFT.settings.target.sectorsCount = tonumber(ini.Target.sectorsCount) or 6; MFT.settings.target.radius = tonumber(ini.Target.radius) or 150.0
        MFT.settings.target.transparency = tonumber(ini.Target.transparency) or 0.8
        if ini.Target.r then MFT.settings.target.sectorColor = {tonumber(ini.Target.r) or 0.1, tonumber(ini.Target.g) or 0.1, tonumber(ini.Target.b) or 0.1} end
    end
    MFT.settings.target.radialBinds = {}
    if ini.TargetRadial then for k, v in pairs(ini.TargetRadial) do MFT.settings.target.radialBinds[tostring(k)] = tonumber(v) or v end end
    loadGroups(MFT.settings.target, "Target", ini)
    
    if ini.TargetQuick then
        MFT.settings.target.quickKeys = {}
        for i = 1, tonumber(ini.TargetQuick.count) or 0 do table.insert(MFT.settings.target.quickKeys, { key = tonumber(ini.TargetQuick["key_"..i]) or 0, bind = tonumber(ini.TargetQuick["bind_"..i]) or ini.TargetQuick["bind_"..i] }) end
    end

    if ini.AutoReport then
        MFT.settings.autoReport.enabled = toBool(ini.AutoReport.enabled)
        MFT.settings.autoReport.interval = tonumber(ini.AutoReport.interval) or 10
        if ini.AutoReport.autoScreen ~= nil then MFT.settings.autoReport.autoScreen = toBool(ini.AutoReport.autoScreen) end
        if ini.AutoReport.showOverlay ~= nil then MFT.settings.autoReport.showOverlay = toBool(ini.AutoReport.showOverlay) end
        MFT.settings.autoReport.x = tonumber(ini.AutoReport.x) or 500
        MFT.settings.autoReport.y = tonumber(ini.AutoReport.y) or 100
    end
    
    if ini.AutoReportInfo then
        MFT.settings.autoReport.reports = {}
        for i=1, tonumber(ini.AutoReportInfo.count) or 0 do
            local rSec = ini["AutoReport_"..i]
            if rSec then
                local rep = { title = valToStr(rSec.title), lines = {} }
                for j=1, tonumber(rSec.linesCount) or 0 do table.insert(rep.lines, valToStr(rSec["line_"..j] or "")) end
                table.insert(MFT.settings.autoReport.reports, rep)
            end
        end
    end

    if ini.SmartDept then
        MFT.settings.smartDept.enabled = toBool(ini.SmartDept.enabled)
        MFT.settings.smartDept.maxItems = tonumber(ini.SmartDept.maxItems) or 8
        MFT.settings.smartDept.tags = {}
        for i=1, tonumber(ini.SmartDept.count) or 0 do
            table.insert(MFT.settings.smartDept.tags, valToStr(ini.SmartDept["tag_"..i] or ""))
        end
    end

    if ini.AutoLineBreak then
        MFT.settings.autoLineBreak.enabled = toBool(ini.AutoLineBreak.enabled)
        MFT.settings.autoLineBreak.maxLength = tonumber(ini.AutoLineBreak.maxLength) or 95
        MFT.settings.autoLineBreak.suffix = valToStr(ini.AutoLineBreak.suffix)
        MFT.settings.autoLineBreak.prefix = valToStr(ini.AutoLineBreak.prefix)
    end
    
    if ini.SmartScreen then
        MFT.settings.smartScreen.enabled = toBool(ini.SmartScreen.enabled)
        MFT.settings.smartScreen.hotkey = tonumber(ini.SmartScreen.hotkey) or 119
        if ini.SmartScreen.showNotif ~= nil then MFT.settings.smartScreen.showNotif = toBool(ini.SmartScreen.showNotif) end
        MFT.settings.smartScreen.x = tonumber(ini.SmartScreen.x) or 20
        MFT.settings.smartScreen.y = tonumber(ini.SmartScreen.y) or 20
        MFT.settings.smartScreen.w = tonumber(ini.SmartScreen.w) or 800
        MFT.settings.smartScreen.h = tonumber(ini.SmartScreen.h) or 600
    end
    
    if ini.SeqOverlay then
        MFT.settings.seqOverlay.enabled = toBool(ini.SeqOverlay.enabled)
        MFT.settings.seqOverlay.hotkey = tonumber(ini.SeqOverlay.hotkey) or 0
        MFT.settings.seqOverlay.alpha = tonumber(ini.SeqOverlay.alpha) or 0.8
        MFT.settings.seqOverlay.x = tonumber(ini.SeqOverlay.x) or 300
        MFT.settings.seqOverlay.y = tonumber(ini.SeqOverlay.y) or 300
    end

    MFT.settings.savedThemes = {}
    if ini.ThemesInfo then
        for i = 1, tonumber(ini.ThemesInfo.count) or 0 do
            local tSec = ini["Theme_"..i]
            if tSec then
                table.insert(MFT.settings.savedThemes, {
                    name = tSec.name, bg = {tonumber(tSec.bg1), tonumber(tSec.bg2), tonumber(tSec.bg3)}, sidebar = {tonumber(tSec.sb1), tonumber(tSec.sb2), tonumber(tSec.sb3)},
                    btn = {tonumber(tSec.btn1), tonumber(tSec.btn2), tonumber(tSec.btn3)}, accent = {tonumber(tSec.acc1), tonumber(tSec.acc2), tonumber(tSec.acc3)}, text = {tonumber(tSec.txt1), tonumber(tSec.txt2), tonumber(tSec.txt3)}
                })
            end
        end
    end
    
    if ini.BindsRoot then
        MFT.binds = deserializeBindsTree("BindsRoot", ini)
    elseif ini.BindsInfo then
        for i = 1, tonumber(ini.BindsInfo.count) or 0 do
            local bSec = ini["Bind_"..i]
            if bSec then
                if bSec.type == "folder" then
                    local folder = { type = "folder", name = valToStr(bSec.name), items = {} }
                    for j = 1, tonumber(bSec.itemsCount) or 0 do
                        local iSec = ini["Bind_"..i.."_Item_"..j]
                        if iSec then
                            local b = { type = "bind", name = valToStr(iSec.name), delay = tonumber(iSec.delay) or 1000, hotkey = tonumber(iSec.hotkey) or 0, showInOverlay = toBool(iSec.showInOverlay), lines = {} }
                            for k = 1, tonumber(iSec.linesCount) or 0 do table.insert(b.lines, valToStr(iSec["line_"..k] or "")) end
                            table.insert(folder.items, b)
                        end
                    end
                    table.insert(MFT.binds, folder)
                else
                    local b = { type = "bind", name = valToStr(bSec.name), delay = tonumber(bSec.delay) or 1000, hotkey = tonumber(bSec.hotkey) or 0, showInOverlay = toBool(bSec.showInOverlay), lines = {} }
                    for j = 1, tonumber(bSec.linesCount) or 0 do table.insert(b.lines, valToStr(bSec["line_"..j] or "")) end
                    table.insert(MFT.binds, b)
                end
            end
        end
    end
    
    MFT.state.dataLoaded = true
end

function engine.saveData()
    if not MFT.state.dataLoaded then return end
    MFT.settings = cleanCData(MFT.settings); MFT.binds = cleanCData(MFT.binds)
    
    local ini = { ThemesInfo = { count = tostring(#(MFT.settings.savedThemes or {})) }, Settings = {}, Radial = {}, RadialBinds = {}, RadialColors = {}, SSFilters = {}, Target = {}, TargetRadial = {}, TargetQuick = {}, AutoReport = {}, AutoReportInfo = {}, SmartDept = {}, AutoLineBreak = {}, AutoLineBreakCmds = {}, Accordions = {}, SmartScreen = {}, SeqOverlay = {} }
    
    for k, v in pairs(MFT.settings) do if type(v) ~= "table" then ini.Settings[k] = valToStr(v) end end
    for k, v in pairs(MFT.settings.ssFilters or {}) do ini.SSFilters[k] = valToStr(v) end
    for k, v in pairs(MFT.settings.accordions or {}) do ini.Accordions[k] = valToStr(v) end
    
    ini.Settings.cSelR = valToStr(MFT.settings.cmdColorSel[1])
    ini.Settings.cSelG = valToStr(MFT.settings.cmdColorSel[2])
    ini.Settings.cSelB = valToStr(MFT.settings.cmdColorSel[3])
    ini.Settings.cUnselR = valToStr(MFT.settings.cmdColorUnsel[1])
    ini.Settings.cUnselG = valToStr(MFT.settings.cmdColorUnsel[2])
    ini.Settings.cUnselB = valToStr(MFT.settings.cmdColorUnsel[3])

    if MFT.settings.radial then
        for k, v in pairs(MFT.settings.radial) do if type(v) ~= "table" then ini.Radial[k] = valToStr(v) end end
        for k, v in pairs(MFT.settings.radial.binds or {}) do ini.RadialBinds[tostring(k)] = valToStr(v) end
        if MFT.settings.radial.sectorColor then ini.RadialColors.r = valToStr(MFT.settings.radial.sectorColor[1]); ini.RadialColors.g = valToStr(MFT.settings.radial.sectorColor[2]); ini.RadialColors.b = valToStr(MFT.settings.radial.sectorColor[3]) end
        saveGroups(MFT.settings.radial, "Radial", ini)
    end

    if MFT.settings.target then
        ini.Target.enabled = valToStr(MFT.settings.target.enabled); ini.Target.radialKey = valToStr(MFT.settings.target.radialKey)
        ini.Target.sectorsCount = valToStr(MFT.settings.target.sectorsCount); ini.Target.radius = valToStr(MFT.settings.target.radius); ini.Target.transparency = valToStr(MFT.settings.target.transparency)
        if MFT.settings.target.sectorColor then ini.Target.r = valToStr(MFT.settings.target.sectorColor[1]); ini.Target.g = valToStr(MFT.settings.target.sectorColor[2]); ini.Target.b = valToStr(MFT.settings.target.sectorColor[3]) end
        for k, v in pairs(MFT.settings.target.radialBinds or {}) do ini.TargetRadial[tostring(k)] = valToStr(v) end
        ini.TargetQuick.count = tostring(#MFT.settings.target.quickKeys)
        for i, q in ipairs(MFT.settings.target.quickKeys) do ini.TargetQuick["key_"..i] = valToStr(q.key); ini.TargetQuick["bind_"..i] = valToStr(q.bind) end
        saveGroups(MFT.settings.target, "Target", ini)
    end

    if MFT.settings.autoReport then
        ini.AutoReport.enabled = valToStr(MFT.settings.autoReport.enabled); ini.AutoReport.interval = valToStr(MFT.settings.autoReport.interval)
        ini.AutoReport.autoScreen = valToStr(MFT.settings.autoReport.autoScreen)
        ini.AutoReport.showOverlay = valToStr(MFT.settings.autoReport.showOverlay)
        ini.AutoReport.x = valToStr(MFT.settings.autoReport.x); ini.AutoReport.y = valToStr(MFT.settings.autoReport.y)
        ini.AutoReportInfo.count = tostring(#(MFT.settings.autoReport.reports or {}))
        for i, rep in ipairs(MFT.settings.autoReport.reports or {}) do
            ini["AutoReport_"..i] = { title = valToStr(rep.title), linesCount = tostring(#rep.lines) }
            for j, line in ipairs(rep.lines) do ini["AutoReport_"..i]["line_"..j] = valToStr(line) end
        end
    end

    if MFT.settings.smartDept then
        ini.SmartDept.enabled = valToStr(MFT.settings.smartDept.enabled)
        ini.SmartDept.maxItems = valToStr(MFT.settings.smartDept.maxItems)
        ini.SmartDept.count = tostring(#MFT.settings.smartDept.tags)
        for i, tag in ipairs(MFT.settings.smartDept.tags) do
            ini.SmartDept["tag_"..i] = valToStr(tag)
        end
    end

    if MFT.settings.autoLineBreak then
        ini.AutoLineBreak.enabled = valToStr(MFT.settings.autoLineBreak.enabled)
        ini.AutoLineBreak.maxLength = valToStr(MFT.settings.autoLineBreak.maxLength)
        ini.AutoLineBreak.suffix = valToStr(MFT.settings.autoLineBreak.suffix)
        ini.AutoLineBreak.prefix = valToStr(MFT.settings.autoLineBreak.prefix)
        
        ini.AutoLineBreakCmds.normal = valToStr(MFT.settings.autoLineBreak.cmds.normal)
        ini.AutoLineBreakCmds.r = valToStr(MFT.settings.autoLineBreak.cmds.r)
        ini.AutoLineBreakCmds.rn = valToStr(MFT.settings.autoLineBreak.cmds.rn)
        ini.AutoLineBreakCmds.f = valToStr(MFT.settings.autoLineBreak.cmds.f)
        ini.AutoLineBreakCmds.fn = valToStr(MFT.settings.autoLineBreak.cmds.fn)
        ini.AutoLineBreakCmds.fr = valToStr(MFT.settings.autoLineBreak.cmds.fr)
        ini.AutoLineBreakCmds.frn = valToStr(MFT.settings.autoLineBreak.cmds.frn)
        ini.AutoLineBreakCmds.a = valToStr(MFT.settings.autoLineBreak.cmds.a)
        ini.AutoLineBreakCmds.me = valToStr(MFT.settings.autoLineBreak.cmds.me)
        ini.AutoLineBreakCmds.do_ = valToStr(MFT.settings.autoLineBreak.cmds.do_)
    end

    if MFT.settings.smartScreen then
        ini.SmartScreen.enabled = valToStr(MFT.settings.smartScreen.enabled)
        ini.SmartScreen.hotkey = valToStr(MFT.settings.smartScreen.hotkey)
        ini.SmartScreen.showNotif = valToStr(MFT.settings.smartScreen.showNotif)
        ini.SmartScreen.x = valToStr(MFT.settings.smartScreen.x)
        ini.SmartScreen.y = valToStr(MFT.settings.smartScreen.y)
        ini.SmartScreen.w = valToStr(MFT.settings.smartScreen.w)
        ini.SmartScreen.h = valToStr(MFT.settings.smartScreen.h)
    end
    
    if MFT.settings.seqOverlay then
        ini.SeqOverlay.enabled = valToStr(MFT.settings.seqOverlay.enabled)
        ini.SeqOverlay.hotkey = valToStr(MFT.settings.seqOverlay.hotkey)
        ini.SeqOverlay.alpha = valToStr(MFT.settings.seqOverlay.alpha)
        ini.SeqOverlay.x = valToStr(MFT.settings.seqOverlay.x)
        ini.SeqOverlay.y = valToStr(MFT.settings.seqOverlay.y)
    end
    
    local function addIfNotEmpty(name, t) if next(t) ~= nil then ini[name] = t else ini[name] = nil end end
    addIfNotEmpty("Settings", ini.Settings); addIfNotEmpty("Radial", ini.Radial); addIfNotEmpty("RadialBinds", ini.RadialBinds)
    addIfNotEmpty("RadialColors", ini.RadialColors); addIfNotEmpty("SSFilters", ini.SSFilters)
    addIfNotEmpty("Target", ini.Target); addIfNotEmpty("TargetRadial", ini.TargetRadial); addIfNotEmpty("TargetQuick", ini.TargetQuick); addIfNotEmpty("AutoReport", ini.AutoReport); addIfNotEmpty("AutoReportInfo", ini.AutoReportInfo)
    addIfNotEmpty("SmartDept", ini.SmartDept); addIfNotEmpty("AutoLineBreak", ini.AutoLineBreak); addIfNotEmpty("AutoLineBreakCmds", ini.AutoLineBreakCmds)
    addIfNotEmpty("Accordions", ini.Accordions)
    addIfNotEmpty("SmartScreen", ini.SmartScreen)
    addIfNotEmpty("SeqOverlay", ini.SeqOverlay)
    
    for i, theme in ipairs(MFT.settings.savedThemes or {}) do
        ini["Theme_"..i] = {
            name = valToStr(theme.name), bg1 = valToStr(theme.bg[1]), bg2 = valToStr(theme.bg[2]), bg3 = valToStr(theme.bg[3]),
            sb1 = valToStr(theme.sidebar[1]), sb2 = valToStr(theme.sidebar[2]), sb3 = valToStr(theme.sidebar[3]),
            btn1 = valToStr(theme.btn[1]), btn2 = valToStr(theme.btn[2]), btn3 = valToStr(theme.btn[3]),
            acc1 = valToStr(theme.accent[1]), acc2 = valToStr(theme.accent[2]), acc3 = valToStr(theme.accent[3]), text = valToStr(theme.text[1]), txt2 = valToStr(theme.text[2]), txt3 = valToStr(theme.text[3])
        }
    end
    
    serializeBindsTree(MFT.binds, "BindsRoot", ini)
    saveCustomIni(ini, cfgPath)
end

function engine.parseString(line)
    local parsedLine = line
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local myName = cleanPlayerName(sampGetPlayerNickname(myId) or "Player")
    parsedLine = parsedLine:gsub("{id}", tostring(myId)); parsedLine = parsedLine:gsub("{name}", tostring(myName))
    parsedLine = parsedLine:gsub("{loc}", getLocation()); parsedLine = parsedLine:gsub("{dir}", getDirection())

    if parsedLine:find("{weapon}") then
        local currWeapon = getCurrentCharWeapon(PLAYER_PED); local wName = getWeapontypeName(currWeapon) or "оружие"
        parsedLine = parsedLine:gsub("{weapon}", wName)
    end
    if parsedLine:find("{car}") then
        local carName = "автомобиль"
        if isCharInAnyCar(PLAYER_PED) then carName = getNameOfVehicleModel(getCarModel(storeCarCharIsInNoSave(PLAYER_PED))) end
        parsedLine = parsedLine:gsub("{car}", carName)
    end
    if parsedLine:find("{target}") or parsedLine:find("{namet}") then
        local closestId, closestName = getClosestPlayerIdAndName()
        if closestId ~= -1 then parsedLine = parsedLine:gsub("{target}", tostring(closestId)); parsedLine = parsedLine:gsub("{namet}", tostring(closestName)) end
    end
    if parsedLine:find("{radial}") then
        if MFT.state.aimTargetId and MFT.state.aimTargetId ~= -1 then parsedLine = parsedLine:gsub("{radial}", tostring(MFT.state.aimTargetId)) end
    end
    return parsedLine
end

-- === УМНАЯ ОТПРАВКА СТРОК (АНТИ-ФЛУД) ===
function engine.executeBind(bind)
    if not bind or bind.type == "folder" then return end
    if MFT.bindThreads[1] and MFT.bindThreads[1]:status() ~= "dead" then MFT.bindThreads[1]:terminate() end
    
    MFT.bindThreads[1] = lua_thread.create(function()
        for i, line in ipairs(bind.lines or {}) do
            if #line > 0 then
                local parsedLine = line
                local custom_sleep = parsedLine:match("{sleep:(%d+)}")
                if custom_sleep then parsedLine = parsedLine:gsub("{sleep:%d+}", "") end

                if parsedLine:find("{dialog}") then
                    MFT.state.dialogActive = true; MFT.state.dialogPrompt = u8"Введите данные для продолжения:"
                    while MFT.state.dialogActive do wait(0) end 
                    local user_input = ffi.string(MFT.state.dialogText)
                    parsedLine = parsedLine:gsub("{dialog}", u8:decode(user_input)); ffi.copy(MFT.state.dialogText, "") 
                end

                parsedLine = engine.parseString(parsedLine)

                if parsedLine:match("%S") then
                    engine.lastSentLine = parsedLine
                    sampSendChat(parsedLine)
                    
                    local delay = custom_sleep and tonumber(custom_sleep) or bind.delay
                    local waited = 0
                    
                    -- Проверяем задержку и перехватываем мут от антифлуда
                    if i < #(bind.lines or {}) then
                        while waited < delay do
                            wait(50)
                            waited = waited + 50
                            
                            if engine.antiFloodTriggered then
                                wait(3000) -- Ждем 3 секунды, чтобы сервер успокоился
                                sampSendChat(engine.lastSentLine)
                                engine.antiFloodTriggered = false
                                waited = 0 -- Обнуляем таймер для следующей строки
                            end
                        end
                    else
                        -- Даже после последней строчки ждем долю секунды, чтобы проверить ответ сервера
                        wait(500)
                        if engine.antiFloodTriggered then
                            wait(3000)
                            sampSendChat(engine.lastSentLine)
                            engine.antiFloodTriggered = false
                        end
                    end
                end
            end
        end
    end)
end

function engine.useBind(index)
    if MFT.binds[index] and MFT.binds[index].type ~= "folder" then
        engine.executeBind(MFT.binds[index])
    end
end

function engine.handleAutoLineBreak(text, isCommand)
    if MFT.state.skipLineBreak then return true end
    if not MFT.settings.autoLineBreak then return true end
    if not MFT.settings.autoLineBreak.enabled then return true end

    local lbSet = MFT.settings.autoLineBreak
    local maxLen = tonumber(lbSet.maxLength) or 90
    local suffix = tostring(lbSet.suffix or "")
    local prefix = tostring(lbSet.prefix or "")
    local cmds = lbSet.cmds or {}

    local cmdPart = ""
    local msgPart = text
    
    local isCmdDetect = text:sub(1, 1) == "/"

    if isCmdDetect then
        local c, m = text:match("^(%S+)%s+(.*)")
        if c and m then
            local cl = c:lower()
            if cl == "/r" and cmds.r then cmdPart = c .. " "
            elseif cl == "/rn" and cmds.rn then cmdPart = c .. " "
            elseif cl == "/f" and cmds.f then cmdPart = c .. " "
            elseif cl == "/fn" and cmds.fn then cmdPart = c .. " "
            elseif cl == "/fr" and cmds.fr then cmdPart = c .. " "
            elseif cl == "/frn" and cmds.frn then cmdPart = c .. " "
            elseif cl == "/a" and cmds.a then cmdPart = c .. " "
            elseif cl == "/me" and cmds.me then cmdPart = c .. " "
            elseif cl == "/do" and cmds.do_ then cmdPart = c .. " "
            else return true end
            msgPart = m
        else return true end
    else
        if not cmds.normal then return true end
    end

    if #msgPart <= maxLen then return true end

    local parts = {}
    local currentStr = ""
    local overhead = #cmdPart + #suffix + #prefix
    local limit = maxLen - overhead
    if limit < 10 then limit = 10 end

    for word in msgPart:gmatch("%S+") do
        if #word > limit then
            if currentStr ~= "" then table.insert(parts, currentStr); currentStr = "" end
            local wPtr = 1
            while wPtr <= #word do
                local chunk = word:sub(wPtr, wPtr + limit - 1)
                if wPtr + limit > #word then currentStr = chunk else table.insert(parts, chunk) end
                wPtr = wPtr + limit
            end
        else
            local testStr = currentStr == "" and word or (currentStr .. " " .. word)
            if #testStr > limit and currentStr ~= "" then
                table.insert(parts, currentStr)
                currentStr = word
            else
                currentStr = testStr
            end
        end
    end
    if currentStr ~= "" then table.insert(parts, currentStr) end

    if #parts <= 1 then return true end

    lua_thread.create(function()
        MFT.state.skipLineBreak = true
        for i, part in ipairs(parts) do
            local outStr = ""
            if isCmdDetect then
                if i == 1 then outStr = cmdPart .. part .. suffix
                elseif i == #parts then outStr = cmdPart .. prefix .. part
                else outStr = cmdPart .. prefix .. part .. suffix end
            else
                if i == 1 then outStr = part .. suffix
                elseif i == #parts then outStr = prefix .. part
                else outStr = prefix .. part .. suffix end
            end
            sampProcessChatInput(outStr)
            if i < #parts then wait(1500) end
        end
        MFT.state.skipLineBreak = false
    end)

    return false
end

function engine.processAutoReport()
    if not MFT.state.ar.isRunning or not MFT.state.ar.activeId or MFT.state.ar.activeId == -1 then return end
    
    if os.time() >= MFT.state.ar.nextTime then
        local reports = MFT.settings.autoReport.reports or {}
        local currentRep = reports[MFT.state.ar.activeId]
        
        if currentRep and currentRep.lines and #currentRep.lines > 0 then
            local lIndex = MFT.state.ar.currentIndex
            if lIndex <= #currentRep.lines then
                local lineToSent = currentRep.lines[lIndex]
                lua_thread.create(function()
                    if MFT.state.isMenuOpen then MFT.state.isMenuOpen = false end
                    wait(300) 
                    local parsed = engine.parseString(lineToSent)
                    if #parsed > 0 then
                        -- Встраиваем анти-флуд и сюда тоже!
                        engine.lastSentLine = parsed
                        sampSendChat(parsed)
                        
                        wait(500)
                        if engine.antiFloodTriggered then
                            wait(3000)
                            sampSendChat(engine.lastSentLine)
                            engine.antiFloodTriggered = false
                        end
                        
                        if MFT.settings.autoReport.autoScreen == true then
                            wait(500); setVirtualKeyDown(vk.VK_F8, true); wait(50); setVirtualKeyDown(vk.VK_F8, false)
                        end
                    end
                end)
                MFT.state.ar.currentIndex = MFT.state.ar.currentIndex + 1
                if MFT.state.ar.currentIndex > #currentRep.lines then
                    MFT.state.ar.isRunning = false; MFT.state.ar.activeId = -1
                    sampAddChatMessage("{88FF88}[MFTools] {FFFFFF}Автодоклад полностью завершен!", -1)
                else
                    MFT.state.ar.nextTime = os.time() + (MFT.settings.autoReport.interval * 60)
                end
            end
        else
            MFT.state.ar.isRunning = false; MFT.state.ar.activeId = -1
        end
    end
end

function engine.takeSmartScreenshot()
    if not gdi32 or not gdiplus then 
        if MFT.settings.smartScreen.showNotif then
            MFT.state.f8NotifText = "Ошибка: Библиотеки GDI+ недоступны."
            MFT.state.f8NotifTimer = os.clock() + 5.0
        end
        return 
    end
    
    lua_thread.create(function()
        wait(100)
        local sf8 = MFT.settings.smartScreen
        local x, y, w, h = math.floor(sf8.x), math.floor(sf8.y), math.floor(sf8.w), math.floor(sf8.h)
        
        local success, err = pcall(function()
            local hdcScreen = user32.GetDC(nil)
            local hdcMem = gdi32.CreateCompatibleDC(hdcScreen)
            local hBitmap = gdi32.CreateCompatibleBitmap(hdcScreen, w, h)
            local hOld = gdi32.SelectObject(hdcMem, hBitmap)
            
            gdi32.BitBlt(hdcMem, 0, 0, w, h, hdcScreen, x, y, 0x00CC0020)
            gdi32.SelectObject(hdcMem, hOld)
            
            local token = ffi.new("void*[1]")
            local startupInput = ffi.new("GdiplusStartupInput", {1, nil, 0, 0})
            gdiplus.GdiplusStartup(token, startupInput, nil)
            
            local pBitmap = ffi.new("void*[1]")
            gdiplus.GdipCreateBitmapFromHBITMAP(hBitmap, nil, pBitmap)
            
            local pngClsid = ffi.new("CLSID", {0x557cf406, 0x1a04, 0x11d3, {0x9a, 0x73, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e}})
            
            local lfs = require "lfs"
            local docPath = getWorkingDirectory() .. "\\config\\MFT_Screens\\"
            if not lfs.attributes(docPath) then lfs.mkdir(docPath) end
            
            local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
            local filename = docPath .. "SS_" .. timestamp .. ".png"
            
            local cp_acp = 0
            local wlen = k32.MultiByteToWideChar(cp_acp, 0, filename, -1, nil, 0)
            local wstr = ffi.new("wchar_t[?]", wlen)
            k32.MultiByteToWideChar(cp_acp, 0, filename, -1, wstr, wlen)
            
            gdiplus.GdipSaveImageToFile(pBitmap[0], wstr, pngClsid, nil)
            
            gdiplus.GdipDisposeImage(pBitmap[0])
            gdiplus.GdiplusShutdown(token[0])
            
            gdi32.DeleteObject(hBitmap)
            gdi32.DeleteDC(hdcMem)
            user32.ReleaseDC(nil, hdcScreen)
            
            wait(500) 
            if sf8.showNotif then
                MFT.state.f8NotifText = "Сохранен: SS_" .. timestamp .. ".png"
                MFT.state.f8NotifTimer = os.clock() + 5.0
            end
        end)
        if not success then 
            wait(500)
            if sf8.showNotif then
                MFT.state.f8NotifText = "Ошибка создания скриншота!"
                MFT.state.f8NotifTimer = os.clock() + 5.0
            end
            print("Smart Screen Error: " .. tostring(err)) 
        end
    end)
end

function engine.advanceSequence(bind)
    if not bind or not bind.lines or #bind.lines == 0 then return end
    if MFT.state.seq == nil then MFT.state.seq = { activeBind = nil, step = 1 } end
    
    if MFT.state.seq.activeBind ~= bind then
        MFT.state.seq.activeBind = bind
        MFT.state.seq.step = 1
    end
    
    local currentLine = bind.lines[MFT.state.seq.step]
    if currentLine and currentLine ~= "" then
        lua_thread.create(function()
            local parsedLine = currentLine
            local custom_sleep = parsedLine:match("{sleep:(%d+)}")
            if custom_sleep then parsedLine = parsedLine:gsub("{sleep:%d+}", "") end
            
            if parsedLine:find("{dialog}") then
                MFT.state.dialogActive = true; MFT.state.dialogPrompt = u8"Введите данные для продолжения:"
                while MFT.state.dialogActive do wait(0) end 
                local user_input = ffi.string(MFT.state.dialogText)
                parsedLine = parsedLine:gsub("{dialog}", u8:decode(user_input)); ffi.copy(MFT.state.dialogText, "") 
            end
            
            parsedLine = engine.parseString(parsedLine)
            if parsedLine:match("%S") then
                -- Встраиваем анти-флуд в пошаговые бинды
                engine.lastSentLine = parsedLine
                sampSendChat(parsedLine)
                
                wait(500)
                if engine.antiFloodTriggered then
                    wait(3000)
                    sampSendChat(engine.lastSentLine)
                    engine.antiFloodTriggered = false
                end
            end
        end)
    end
    
    MFT.state.seq.step = MFT.state.seq.step + 1
    
    if MFT.state.seq.step > #bind.lines then
        MFT.state.seq.activeBind = nil 
        engine.saveData()
    end
end

local function checkHotkeysRecursive(list)
    for _, item in ipairs(list) do
        if item.type == "folder" then 
            checkHotkeysRecursive(item.items or {})
        else
            if item.hotkey and item.hotkey ~= 0 and wasKeyPressed(item.hotkey) then
                engine.executeBind(item)
            end
        end
    end
end

function engine.processHotkeys()
    if not MFT.state.isMenuOpen and not MFT.state.dialogActive and not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() and not MFT.state.isPlacingOverlay then
        checkHotkeysRecursive(MFT.binds)
        
        if MFT.settings.smartScreen and MFT.settings.smartScreen.enabled then
            local hk = MFT.settings.smartScreen.hotkey or 119
            if hk ~= 0 and wasKeyPressed(hk) then
                engine.takeSmartScreenshot()
            end
        end
        
        if MFT.settings.seqOverlay then
            local gHk = MFT.settings.seqOverlay.hotkey or 0
            if gHk ~= 0 and wasKeyPressed(gHk) then
                if MFT.state.seq and MFT.state.seq.activeBind then
                    engine.advanceSequence(MFT.state.seq.activeBind)
                end
            end
        end
    end
end

return engine