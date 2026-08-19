-- Файл: MFTools/ui/tab_about.lua
local imgui = require "mimgui"
local ffi = require "ffi"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local tab_about = {}

local function drawTextWrapped(text, color)
    if color then imgui.PushStyleColor(imgui.Col.Text, color) end
    imgui.TextWrapped(text)
    if color then imgui.PopStyleColor() end
end

local function drawSectionHeader(title, c_accent)
    imgui.Spacing(); imgui.Spacing()
    if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
    imgui.TextColored(c_accent, title)
    if MFT.fonts.title then imgui.PopFont() end
    imgui.Separator()
    imgui.Spacing()
end

function tab_about.draw(dash, dt, c_accent, sb_color, c_text, availWidth)
    local tAlpha = dash.anims.tabSwitch
    local slideX = (1.0 - tAlpha) * 30.0
    imgui.SetCursorPosX(imgui.GetCursorPosX() + slideX)
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, tAlpha)

    imgui.BeginChild("AboutScroll", imgui.ImVec2(0, 0), false, imgui.WindowFlags.AlwaysVerticalScrollbar)
    
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 6))

    -- ЗАГОЛОВОК
    if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
    local mainTitle = u8"ПОЛНОЕ РУКОВОДСТВО ПОЛЬЗОВАТЕЛЯ: MFTools"
    local titleW = imgui.CalcTextSize(mainTitle).x
    imgui.SetCursorPosX((availWidth - titleW) / 2)
    imgui.TextColored(c_accent, mainTitle)
    if MFT.fonts.title then imgui.PopFont() end
    
    imgui.Spacing(); imgui.Spacing()
    drawTextWrapped(u8"Добро пожаловать в подробную инструкцию по использованию тулса. Если вы никогда раньше не пользовались подобными скриптами - не переживайте, после прочтения этого текста вы станете настоящим профессионалом.", imgui.ImVec4(0.8, 0.8, 0.8, 1.0))

    -- РАЗДЕЛ 1
    drawSectionHeader(u8"[1] ОСНОВНОЙ ИНТЕРФЕЙС И КАК ИМ ПОЛЬЗОВАТЬСЯ", c_accent)
    drawTextWrapped(u8"Ваш главный инструмент - это меню скрипта. Это ваша панель управления, где вы настраиваете всё под себя.")
    imgui.BulletText(u8"Открытие меню: Вы вводите команду /mft, и перед вами появляется это окно.")
    imgui.BulletText(u8"Навигация: В меню сверху есть вкладки, по которым вы кликаете левой кнопкой мыши.")
    imgui.BulletText(u8"Сохранение: Любое изменение нужно сохранять. Нашли кнопку 'Сохранить' -> нажали -> готово.")

    -- РАЗДЕЛ 2
    drawSectionHeader(u8"[2] СИСТЕМА БИНДОВ", c_accent)
    drawTextWrapped(u8"Бинд - это когда вы нажимаете всего одну кнопку на клавиатуре, а ваш персонаж в игре делает целое действие (отыгрывает РП, достает оружие и т.д.).")
    imgui.Spacing()
    imgui.TextColored(imgui.ImVec4(1, 1, 1, 1), u8"Как создать свой первый бинд:")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" 1. Зайдите во вкладку 'База биндов' и создайте папку (или используйте корень).")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" 2. Нажмите 'Добавить пресет' или создайте бинд с нуля.")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" 3. В настройках бинда назначьте клавишу и впишите нужные строки.")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" 4. Нажмите 'СОХРАНИТЬ'. Готово!")

    -- РАЗДЕЛ 3
    drawSectionHeader(u8"[3] СИСТЕМА ТАРГЕТА (ПРИЦЕЛИВАНИЕ)", c_accent)
    drawTextWrapped(u8"Таргет - это захват цели. Он позволяет скрипту понять, с каким именно игроком вы сейчас взаимодействуете, чтобы автоматически подставить его ID или Имя в отыгровки.")
    imgui.Spacing()
    imgui.TextColored(imgui.ImVec4(1, 1, 1, 1), u8"Как правильно взять игрока в таргет:")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" - Подойдите к нужному игроку.")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" - Нажмите и удерживайте Правую Кнопку Мыши (ПКМ), целясь на него.")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" - Над игроком появится зеленый треугольник.")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" - Не отпуская прицел, нажмите кнопку вашего бинда.")

    -- РАЗДЕЛ 4
    drawSectionHeader(u8"[4] УМНЫЕ ТЕГИ (SMART TAGS)", c_accent)
    drawTextWrapped(u8"Это специальные слова в фигурных скобках. Скрипт видит их и автоматически заменяет на нужную информацию в игре. Ниже представлен полный список:")
    
    imgui.Spacing()
    
    imgui.TextColored(c_accent, u8" {target}")
    imgui.SameLine(); drawTextWrapped(u8"- Вписывает ID игрока, на которого вы смотрите (в таргете).", imgui.ImVec4(0.8,0.8,0.8,1))
    
    imgui.TextColored(c_accent, u8" {namet}")
    imgui.SameLine(); drawTextWrapped(u8"- Вписывает Имя_Фамилию игрока, которого вы взяли в таргет.", imgui.ImVec4(0.8,0.8,0.8,1))
    
    imgui.TextColored(c_accent, u8" {id}")
    imgui.SameLine(); drawTextWrapped(u8"- Вписывает ваш собственный ID.", imgui.ImVec4(0.8,0.8,0.8,1))
    
    imgui.TextColored(c_accent, u8" {name}")
    imgui.SameLine(); drawTextWrapped(u8"- Вписывает ваше собственное Имя_Фамилию.", imgui.ImVec4(0.8,0.8,0.8,1))

    imgui.TextColored(c_accent, u8" {weapon}")
    imgui.SameLine(); drawTextWrapped(u8"- Вписывает название оружия, которое у вас сейчас в руках.", imgui.ImVec4(0.8,0.8,0.8,1))
    
    imgui.TextColored(c_accent, u8" {car}")
    imgui.SameLine(); drawTextWrapped(u8"- Вписывает название автомобиля, в котором вы сидите.", imgui.ImVec4(0.8,0.8,0.8,1))

    imgui.TextColored(c_accent, u8" {loc}")
    imgui.SameLine(); drawTextWrapped(u8"- Вписывает ваше текущее местоположение (город/район).", imgui.ImVec4(0.8,0.8,0.8,1))

    imgui.TextColored(c_accent, u8" {dir}")
    imgui.SameLine(); drawTextWrapped(u8"- Вписывает направление, куда вы смотрите (север, юг, запад...).", imgui.ImVec4(0.8,0.8,0.8,1))
    
    imgui.TextColored(c_accent, u8" {radial}")
    imgui.SameLine(); drawTextWrapped(u8"- Используется для Радиального меню, вставляет ID цели.", imgui.ImVec4(0.8,0.8,0.8,1))

    -- РАЗДЕЛ 5
    drawSectionHeader(u8"[5] ПОШАГОВЫЕ БИНДЫ (СОБЕСЕДОВАНИЯ)", c_accent)
    drawTextWrapped(u8"Эта система позволяет отправлять огромные тексты (например, лекции или правила) не сразу, а по одной строке, чтобы игроки успевали их читать.")
    imgui.Spacing()
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" - В 'Базе биндов' нажмите кнопку 'Пошагово' рядом с нужным биндом.")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" - Появится удобный оверлей на экране (можно отключить в настройках).")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" - Нажимайте глобальную клавишу (настраивается во вкладке 'Настройки') для отправки следующей строки.")

    -- РАЗДЕЛ 6
    drawSectionHeader(u8"[6] РЕДАКТОР ЧАТА (CHAT++)", c_accent)
    drawTextWrapped(u8"Позволяет взаимодействовать со строками прямо в чате игры. Наведите курсор на любую строку чата и нажмите Правую Кнопку Мыши (ПКМ).")
    imgui.Spacing()
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" - Вы можете скопировать строку, удалить её или полностью переписать.")
    imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), u8" - Если вы скрыли строку, в настройках появится красная кнопка сброса.")

    -- РАЗДЕЛ 7
    drawSectionHeader(u8"[7] УМНЫЙ АВТОПЕРЕНОС", c_accent)
    drawTextWrapped(u8"Скрипт автоматически разобьет ваше длинное сообщение на несколько частей, чтобы оно не обрезалось сервером. Можно настроить символы префиксов (например, троеточие в конце).")

    -- РАЗДЕЛ 8
    drawSectionHeader(u8"[8] РЕЖИМ СС (ОЧИСТКА ЧАТА)", c_accent)
    drawTextWrapped(u8"Идеально для создания Скриншот-Ситуаций (СС). Включая этот режим, вы скрываете весь OOC-мусор из чата (VIP чат, объявления СМИ, системные уведомления). Вы сами выбираете, что именно скрывать в настройках.")

    -- РАЗДЕЛ 9
    drawSectionHeader(u8"[9] АВТОДОКЛАДЫ", c_accent)
    drawTextWrapped(u8"Устали писать доклады каждые 10 минут? Создайте автодоклад, задайте интервал, и скрипт сам будет выводить строки в чат (а при необходимости еще и делать скриншоты).")

    -- РАЗДЕЛ 10
    drawSectionHeader(u8"[10] ПОДСКАЗКИ КОМАНД И ДЕПАРТАМЕНТ", c_accent)
    drawTextWrapped(u8"Скрипт выводит на экран удобный список существующих команд при вводе слэша (/). Также, при вводе команды /d (департамент), скрипт предложит быстро вставить нужный тег (например, to [LSPD]).")

    -- РАЗДЕЛ 11
    drawSectionHeader(u8"[11] УМНЫЙ СКРИНШОТ", c_accent)
    drawTextWrapped(u8"Скрипт позволяет откалибровать рамку на экране. При нажатии назначенной клавиши, сохранится скриншот только выделенной области (идеально для вырезания чата без фона).")

    -- ИНФОРМАЦИЯ О РАЗРАБОТЧИКЕ
    imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
    
    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.04, 0.04, 0.04, 0.8))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(c_accent.x, c_accent.y, c_accent.z, 0.5))
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, 12.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildBorderSize, 1.5)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(20, 15))
    
    imgui.BeginChild("AuthorBlock", imgui.ImVec2(-1, 140), true)
    if MFT.fonts.title then imgui.PushFont(MFT.fonts.title) end
    imgui.TextColored(c_accent, u8"О РАЗРАБОТЧИКЕ")
    if MFT.fonts.title then imgui.PopFont() end
    imgui.Separator(); imgui.Spacing()
    
    imgui.TextColored(imgui.ImVec4(1,1,1,1), u8"Создатель и разработчик MFTools:")
    imgui.SameLine()
    imgui.TextColored(c_accent, u8"Bryan Kogfield (Богдан)")
    
    imgui.Spacing()
    drawTextWrapped(u8"Скрипт создан для максимального упрощения отыгровок и автоматизации рутины на RolePlay серверах. Все системы написаны с упором на стабильность и удобство.", imgui.ImVec4(0.7, 0.7, 0.7, 1.0))
    
    imgui.Spacing()
    imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.8, 1.0), u8"Связь с разработчиком (Discord):")
    imgui.SameLine()
    if imgui.Button(u8"Скопировать Discord", imgui.ImVec2(180, 24)) then
        imgui.SetClipboardText("твой_discord_здесь")
    end
    
    imgui.EndChild()
    imgui.PopStyleVar(3)
    imgui.PopStyleColor(2)

    imgui.PopStyleVar()
    imgui.EndChild()
    imgui.PopStyleVar() 
end

return tab_about