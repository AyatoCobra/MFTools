-- Файл: MFTools/core/suggest.lua
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local engine = require "MFTools.core.engine"

local suggest = {}

suggest.cmd_font = renderCreateFont("Segoe UI", 11, 5)
suggest.current_font_size = 11

local function ImVecToHex(farray)
    local r = math.floor(farray[1] and farray[1] * 255 or farray[0] * 255)
    local g = math.floor(farray[2] and farray[2] * 255 or farray[1] * 255)
    local b = math.floor(farray[3] and farray[3] * 255 or farray[2] * 255)
    return string.format("{%02X%02X%02X}", r, g, b)
end

function suggest.addToHistory(command)
    if type(command) ~= "string" or command == "" then return end
    local base_cmd = command:match("^(%S+)")
    if base_cmd then
        if not base_cmd:find("^/") then base_cmd = "/" .. base_cmd end
        base_cmd = base_cmd:lower()
        
        if not MFT.settings.recentCommands then MFT.settings.recentCommands = {} end
        
        for i = #MFT.settings.recentCommands, 1, -1 do
            if MFT.settings.recentCommands[i] == base_cmd then
                table.remove(MFT.settings.recentCommands, i)
            end
        end
        
        table.insert(MFT.settings.recentCommands, 1, base_cmd)
        
        while #MFT.settings.recentCommands > 7 do
            table.remove(MFT.settings.recentCommands)
        end
        
        if not MFT.settings.cmdUsageStats then MFT.settings.cmdUsageStats = {} end
        MFT.settings.cmdUsageStats[base_cmd] = (MFT.settings.cmdUsageStats[base_cmd] or 0) + 1
        
        engine.saveData()
    end
end

function suggest.onSendCommand(command) end

local function filter_commands(input)
    local matched_commands = {}
    local added = {}
    local input_lower = input:lower()
    
    local function tryAdd(cmd)
        local c = cmd:lower()
        if not added[c] and c:find(input_lower, 1, true) == 1 then
            table.insert(matched_commands, c)
            added[c] = true
        end
    end

    if MFT.settings.recentCommands then
        for _, cmd in ipairs(MFT.settings.recentCommands) do tryAdd(cmd) end
    end

    tryAdd("/mft")
    tryAdd("/bb")

    if MFT.data and type(MFT.data.command_list) == "table" then
        for _, v in ipairs(MFT.data.command_list) do
            local cName = ""
            if type(v) == "table" then
                cName = type(v.cmd) == "string" and v.cmd or (type(v[1]) == "string" and v[1] or "")
                if cName == "" and type(v.name) == "string" then cName = v.name end
            elseif type(v) == "string" then
                cName = v
            end
            if cName ~= "" then
                if cName:sub(1, 1) ~= "/" then cName = "/" .. cName end
                tryAdd(cName)
            end
        end
    end

    local maxItems = MFT.settings.cmdMaxItems or 8

    if input_lower == "/" then
        local res = {}
        for i = 1, math.min(maxItems, #matched_commands) do
            table.insert(res, matched_commands[i])
        end
        return res
    end

    table.sort(matched_commands, function(a, b)
        local a_recent_idx = 999
        local b_recent_idx = 999
        
        if MFT.settings.recentCommands then
            for i, rcmd in ipairs(MFT.settings.recentCommands) do
                if rcmd == a then a_recent_idx = i end
                if rcmd == b then b_recent_idx = i end
            end
        end
        
        if a_recent_idx ~= b_recent_idx then
            return a_recent_idx < b_recent_idx
        end
        
        local countA = (MFT.settings.cmdUsageStats and MFT.settings.cmdUsageStats[a]) or 0
        local countB = (MFT.settings.cmdUsageStats and MFT.settings.cmdUsageStats[b]) or 0
        
        if countA == countB then
            if #a == #b then return a < b end
            return #a < #b 
        end
        return countA > countB
    end)
    
    local final_result = {}
    for i = 1, math.min(maxItems, #matched_commands) do
        table.insert(final_result, matched_commands[i])
    end
    
    return final_result
end

function suggest.processTick()
    local targetSize = MFT.settings.cmdFontSize or 11
    if suggest.current_font_size ~= targetSize then
        suggest.current_font_size = targetSize
        suggest.cmd_font = renderCreateFont("Segoe UI", suggest.current_font_size, 5)
    end

    if MFT.state.cmdReopenText ~= nil then
        MFT.state.cmdReopenTicks = (MFT.state.cmdReopenTicks or 0) + 1
        if not sampIsChatInputActive() then
            sampSetChatInputEnabled(true)
            sampSetChatInputText(MFT.state.cmdReopenText)
            MFT.state.cmdReopenText = nil
            MFT.state.cmdReopenTicks = 0
        elseif MFT.state.cmdReopenTicks > 10 then
            sampSetChatInputText(MFT.state.cmdReopenText)
            MFT.state.cmdReopenText = nil
            MFT.state.cmdReopenTicks = 0
        end
    end

    if MFT.settings.cmdSuggestEnabled == false then 
        MFT.state.cmdShowSuggestions = false
        return 
    end
    
    if not isSampAvailable() then return end
    
    local chatActive = sampIsChatInputActive()
    if not chatActive then
        MFT.state.cmdShowSuggestions = false
        return
    end
    
    local text = sampGetChatInputText()
    
    if text:sub(1, 1) == "/" then
        if text ~= MFT.state.cmdLastText then
            MFT.state.cmdLastText = text
            
            local isDept = false
            local searchDep = ""
            local depCmd = ""
            
            if text:match("^/d%s+(.*)") then isDept = true; searchDep = text:match("^/d%s+(.*)"); depCmd = "/d "
            elseif text:match("^/dep%s+(.*)") then isDept = true; searchDep = text:match("^/dep%s+(.*)"); depCmd = "/dep "
            elseif text:match("^/d$") then isDept = true; searchDep = ""; depCmd = "/d "
            elseif text:match("^/dep$") then isDept = true; searchDep = ""; depCmd = "/dep "
            end
            
            if isDept and MFT.settings.smartDept and MFT.settings.smartDept.enabled then
                MFT.state.suggestMode = "dept"
                MFT.state.suggestPrefix = depCmd
                searchDep = searchDep:lower()
                
                local matched_dept = {}
                local maxD = MFT.settings.smartDept.maxItems or 8
                
                for _, tag in ipairs(MFT.settings.smartDept.tags or {}) do
                    if #matched_dept >= maxD then break end
                    if u8(tag):lower():find(searchDep, 1, true) or searchDep == "" then
                        table.insert(matched_dept, tag)
                    end
                end
                MFT.state.cmdSuggestions = matched_dept
                MFT.state.cmdSelectedIndex = 1
            else
                MFT.state.suggestMode = "cmd"
                MFT.state.cmdSuggestions = filter_commands(text)
                MFT.state.cmdSelectedIndex = 1
            end
        end
        MFT.state.cmdShowSuggestions = (#MFT.state.cmdSuggestions > 0)
    else
        MFT.state.cmdShowSuggestions = false
        MFT.state.cmdLastText = ""
        MFT.state.suggestMode = "none"
    end
end

function suggest.onWindowMessage(msg, wparam, lparam)
    -- ПЕРЕХВАТ ENTER (Самый надежный способ обойти все другие скрипты)
    if msg == 0x100 and wparam == 0x0D then
        if sampIsChatInputActive() then
            local current_text = sampGetChatInputText()
            
            -- ПРОВЕРКА НА АВТОПЕРЕНОС
            local allow = engine.handleAutoLineBreak(current_text)
            if not allow then
                sampSetChatInputEnabled(false) -- Моментально закрываем чат
                return false -- Блокируем нажатие Enter для SA-MP и других скриптов
            end
            
            if current_text:sub(1, 1) == "/" then
                if MFT.settings.cmdSuggestEnabled ~= false and MFT.state.cmdShowSuggestions then
                    local selected_cmd = MFT.state.cmdSuggestions[MFT.state.cmdSelectedIndex]
                    if selected_cmd then
                        if MFT.state.suggestMode == "dept" then
                            local targetText = MFT.state.suggestPrefix .. u8:decode(u8(selected_cmd)) .. ", "
                            if current_text:lower() ~= targetText:lower() then
                                MFT.state.cmdReopenText = targetText
                                sampSetChatInputText("")
                                return false 
                            end
                        else
                            if current_text:lower() ~= selected_cmd:lower() then
                                MFT.state.cmdReopenText = selected_cmd .. " "
                                sampSetChatInputText("")
                                return false 
                            end
                        end
                    end
                end
                suggest.addToHistory(current_text)
            end
        end
    end

    if MFT.settings.cmdSuggestEnabled == false then return end
    if not MFT.state.cmdShowSuggestions or not sampIsChatInputActive() then return end
    
    if msg == 0x100 then
        if wparam == 0x27 then
            MFT.state.cmdSelectedIndex = MFT.state.cmdSelectedIndex + 1
            if MFT.state.cmdSelectedIndex > #MFT.state.cmdSuggestions then MFT.state.cmdSelectedIndex = 1 end
            return false
        elseif wparam == 0x25 then
            MFT.state.cmdSelectedIndex = MFT.state.cmdSelectedIndex - 1
            if MFT.state.cmdSelectedIndex < 1 then MFT.state.cmdSelectedIndex = #MFT.state.cmdSuggestions end
            return false
        elseif wparam == 0x09 then
            local selected = MFT.state.cmdSuggestions[MFT.state.cmdSelectedIndex]
            if selected then
                if MFT.state.suggestMode == "dept" then
                    sampSetChatInputText(MFT.state.suggestPrefix .. u8:decode(u8(selected)) .. ", ")
                else
                    sampSetChatInputText(selected .. " ")
                end
            end
            return false
        end
    end
end

function suggest.drawUI()
    if MFT.settings.cmdSuggestEnabled == false then return end
    if not MFT.state.cmdShowSuggestions or not MFT.state.cmdSuggestions or #MFT.state.cmdSuggestions == 0 then 
        return 
    end

    if not isSampAvailable() or not sampIsChatInputActive() then 
        MFT.state.cmdShowSuggestions = false
        return 
    end

    local in1 = sampGetInputInfoPtr()
    if in1 ~= 0 then
        in1 = getStructElement(in1, 0x8, 4)
        local in2 = getStructElement(in1, 0x8, 4)
        local in3 = getStructElement(in1, 0xC, 4)
        
        local offsetY = MFT.settings.cmdOffsetY or 55
        local drawX = in2 + 5
        local drawY = in3 + offsetY
        
        local cSel = MFT.settings.cmdColorSel or {0.20, 0.59, 0.85}
        local cUnsel = MFT.settings.cmdColorUnsel or {0.62, 0.62, 0.62}
        
        local color_sel_hex = ImVecToHex(cSel)
        local color_unsel_hex = ImVecToHex(cUnsel)
        
        local render_text = ""
        for i, cmd in ipairs(MFT.state.cmdSuggestions) do
            local dispText = u8:decode(u8(cmd))
            
            if i == MFT.state.cmdSelectedIndex then
                render_text = render_text .. color_sel_hex .. "[" .. dispText .. "]   " 
            else
                render_text = render_text .. color_unsel_hex .. dispText .. "   "   
            end
            
            if i % 10 == 0 and i < #MFT.state.cmdSuggestions then
                render_text = render_text .. "\n"
            end
        end
        
        renderFontDrawText(suggest.cmd_font, render_text, drawX, drawY, 0xFFFFFFFF)
    end
end

return suggest