-- главное
script_name("Foxi Tools")
script_version("0.0.5")

local enable_autoupdate = true -- false to disable auto-update + disable sending initial telemetry (server, moonloader version, script version, samp nickname, virtual volume serial number)
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/chokopaykin/FoxiTools/refs/heads/main/updater.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/chokopaykin/FoxiTools/"
        end
    end
end

local ffi = require 'ffi'
local imgui = require 'mimgui'
local pie = require('imgui_piemenu')
local memory = require('memory')
require "lib.moonloader"
local fa = require 'fAwesome6_solid'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local new = imgui.new
local vkeys = require 'vkeys'
local ffi = require 'ffi'
local d3dx9_43 = ffi.load("d3dx9_43.dll")
local faicons = require('fAwesome6')
local sampev = require 'lib.samp.events'
local sf = require('sampfuncs')
require "strings"


-- inicfg
local inicfg = require 'inicfg'
local ini = inicfg.load({
    mainIni = {
        name = '',
        org = '',
        rank = '',
        checkinfo = false,
        purID=0,
        zap = false,
        zapd = false,
        posit = false,
        await = 1000,
        actien = false,
        text_act = ''
    },
    Themes = {
        number = 0,
        alpha = 1
    },
    Pasw = {
        password = ''
    }
},'LawHelper/lawini.ini')
inicfg.save(ini, 'LawHelper/lawini.ini')
-- темы

local decorList = {u8'Black Theme', u8'White Theme', u8'Blue Theme', u8'Orange Theme', u8'Gray Theme', u8'Green Theme'}
local decorListBuffer = imgui.new['const char*'][#decorList](decorList)
local decorListNumber = new.int(ini.Themes.number)
local styler = imgui.GetStyle()

-- мимгуи основное
local WinState = new.bool()
local tab = 1
local box = new.bool()
local pip = new.bool()
local window_two = new.bool()
local password_screen = new.bool()
local name = new.char[256](u8(ini.mainIni.name))
local org = new.char[256](u8(ini.mainIni.org))
local rank = new.char[256](u8(ini.mainIni.rank))
local checkinfo = new.bool(ini.mainIni.checkinfo)
local text_act = new.char[256](u8(ini.mainIni.text_act))
local tag = '{7172EE}« Foxi Tools »{FFFFFF} '
local pass = new.char[256](u8(ini.Pasw.password))
local alpha = new.float(ini.Themes.alpha)
local pos = nil
local pos2 = nil
local flags = imgui.WindowFlags.NoMove + imgui.WindowFlags.NoDecoration + imgui.WindowFlags.AlwaysAutoResize
local json = require 'cjson'  -- Библиотека для работы с JSON (убедитесь, что она доступна)
local buttonWidth = 120
local buttonHeight = 28
local numButtons = 6
local windowWidth = 795
local spacing = (windowWidth - (buttonWidth * numButtons)) / (numButtons + 1)



-- Инициализация массивов для хранения биндера
local binders = {}  -- Массив для хранения всех биндера
local new_binder = {text = '', command = '', delay = 1000, title = '', power = false} 
local block = {}  -- Массив для хранения всех биндера
local new_block = {text = '', title = ''}  -- Структура для хранения нового биндера
local editing_index = nil  -- Индекс редактируемого биндера
local window_edit_binder = new.bool(false) 
texter = new.char[10000]()
commander = new.char[256]()
delay = new.int(1000)
title = new.char[256]()
power = new.bool()
-- умный розыск
local ssu = new.bool()
local stik = new.bool()
local zap = new.bool(ini.mainIni.zap)
local zapd = new.bool(ini.mainIni.zapd)
local search_active = false
local search = new.char[256]()
local powerBool = new.bool(false)
local lower, sub, char, upper = string.lower, string.sub, string.char, string.upper
local concat = table.concat
local selectedBinderIndex = 1
local checkbox1 = new.bool()
local checkbox2 = new.bool()
local blocknote = new.char[10000]()
local actien = new.bool(ini.mainIni.actien)
local renderWindow = imgui.new.bool(true)
local showPieMenu = imgui.new.bool(false)
local menuItems = {
    { label = '/dealing', action = function() sampSendChat("/b /dealing") end },
    {
        label = 'cost', items = {
            { label = '100$', action = function() showPieMenu[0] = not showPieMenu[0] end },
            { label = '200$', action = function() showPieMenu[0] = not showPieMenu[0] end },
            { label = u8'Себе', action = function() sampSendChat("/inscar") end }
        }
    },
    {
        label = 'user', items = {
            { label = u8'Реклама', action = function() sampSendChat("Работает автодилер") end },
            { label = u8'Скилл', action = function() sampSendChat("/carskill") end }
        }
    }
}

-- initialization table
local lu_rus, ul_rus = {}, {}
for i = 192, 223 do
    local A, a = char(i), char(i + 32)
    ul_rus[A] = a
    lu_rus[a] = A
end
local E, e = char(168), char(184)
ul_rus[E] = e
lu_rus[e] = E

function string.nlower(s)
    s = lower(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = sub(s, i, i)
        res[i] = ul_rus[ch] or ch
    end
    return concat(res)
end

function get_first_last_name(nickname)
    local parts = {}
    for part in string.gmatch(nickname, "([^_]+)") do
        table.insert(parts, part)
    end
    return parts[1], parts[2]  -- Возвращаем имя и фамилию
end

function countLinesInBinder(binder)
    if binder and binder.text then  -- Проверка на наличие биндера и его текста
        local count = 1
        for _ in binder.text:gmatch("[\n]+") do
            count = count + 1  -- Увеличиваем счетчик для каждой строки
        end
        return count
    else
        return 0  -- Возвращаем 0, если биндер или текст не существует
    end
end

local function saveSettings()
    ini.mainIni.name = u8:decode(ffi.string(name))
    ini.mainIni.org = u8:decode(ffi.string(org))
    ini.mainIni.rank = u8:decode(ffi.string(rank))
    ini.mainIni.checkinfo = checkinfo[0]
    inicfg.save(ini, 'LawHelper/lawini.ini')  -- Сохраняем все настройки в LawHelper/lawini.ini

    sampAddChatMessage(tag .. "Настройки {7172EE}сохранены{FFFFFF}!", -1)
end

function mysplit(inputstr, sep)
    if sep == nil then
      sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
    end
    return t
  end

function saveBinders()
    local json_data = json.encode(binders)
    local file, err = io.open('moonloader/LawHelper/binders.json', 'w')
    if not file then
        sampAddChatMessage(tag .. "Ошибка при сохранении биндеров: " .. err, -1)
        return
    end
    file:write(json_data)
    file:close() 
end

function saveBlock()
    local json_data = json.encode(block)
    local file, err = io.open('moonloader/LawHelper/blocknotes.json', 'w')
    if not file then
        sampAddChatMessage(tag .. "Ошибка при сохранении записей: " .. err, -1)
        return
    end
    file:write(json_data)
    file:close() 
end

function loadBlock()
    local file, err = io.open('moonloader/LawHelper/blocknotes.json', 'r')
    if not file then
        sampAddChatMessage(tag .. "Файл 'blocknotes.json' не найден. Создаем новый.", -1)
        saveBlock() -- сохранение пустого массива в файл с помощью saveBinders
        return
    end

    local json_data = file:read('*a')
    if json_data then
        blockData = json.decode(json_data)
        -- Проверка на существование данных
        if blockData then
            block = blockData
        else
            block = {}
        end
    end
    file:close()
end

function loadBinders()
    local file, err = io.open('moonloader/LawHelper/binders.json', 'r')
    if not file then
        sampAddChatMessage(tag .. "Файл 'binders.json' не найден. Создаем новый.", -1)
        saveBinders() -- сохранение пустого массива в файл с помощью saveBinders
        return
    end

    local json_data = file:read('*a')
    if json_data then
        binderData = json.decode(json_data)
        -- Проверка на существование данных
        if binderData then
            binders = binderData
        else
            binders = {}
        end
    end
    file:close()
end

local function copyBinder(selectedIndex)
    -- Получаем выбранный биндера
    local binderToCopy = binders[selectedIndex]  
    
    if binderToCopy then
        for i = 1, #binders do 
        -- Создаем новый биндер с копированными данными
            newBinder = {
                title = ffi.string("Копия " .. binderToCopy.title .. " " .. tostring(i)),
                text = ffi.string(binderToCopy.text),  -- Копируем заголовок биндера
                command = ffi.string(binderToCopy.command),  -- Копируем команду
                delay = binderToCopy.delay,  -- Копируем задержку
                power = false  -- Устанавливаем значение power на false для новой копии
            }
        end
        
        -- Отладочное сообщение
        print("Копирование биндера: " .. newBinder.title)

        -- Добавляем новый биндер в массив
        table.insert(binders, newBinder)  
        
        -- Проверка на успешное добавление
        if #binders > 0 then
            print("Общий биндеров после копирования: " .. #binders)
        else
            print("Ошибка: Биндеры не добавлены.")
        end
        
        saveBinders()  -- Сохраняем обновленный список биндеров
        
        sampAddChatMessage("Бинд " .. newBinder.title .. " успешно скопирован!", -1)  -- Уведомление об успешном копировании
    else
        sampAddChatMessage("Не удалось скопировать выбранный бинд!", -1)  -- Уведомление об ошибке
    end
end

local konstitution = {
    ["Статья 2"] = {
        {"Раздел 1.", "Исполнительная власть возглавляется и формируется Президентом Queen Creek. Он занимает свою должность в течение сорока пяти дней и избирается в порядке, установленным настоящей Конституции.\nВ случае отстранения Президента от должности или его смерти, отставки либо неспособности осуществлять полномочия и обязанности по названной должности таковые переходят к \nпервому Вице-Президенту, и Верховный совет посредством своего решения может установить, какое должностное лицо в случае отстранения, смерти, \nотставки либо неспособности Президента и первого Вице-Президента будет действовать как президент, и такое должностное лицо должно \nдействовать соответствующим образом, пока не будет устранена причина неспособности либо новый Президент не будет избран \nПрезидент в установленные сроки получает за свою службу вознаграждение, которое не может быть увеличено либо уменьшено в течение того срока, на который он избран. \nПеред вступлением в должность Президента приносит присягу либо делает заявление в следующей форме, положа руку на конституцию: \n«Я торжественно клянусь что буду добросовестно исполнять \nОбязанности Президента Республики Queen Creek и по мере всех своих сил \nподдерживать, охранять и защищать суверенитет Queen Creek». \nПолномочия Президента могут быть пролонгированы Верховным советом Республики. \nНовоизбранный Президент вступает в должность и дает присягу в день сложения полномочий ранее избранного Президента."},
        {"Раздел 2.", "Президент является главнокомандующим вооруженных сил и правоохранительных органов Queen Creek;"},
        {"Раздел 3.", "Президент Queen Creek обладает следующими полномочиями:\na. Формировать и устанавливать структуру департаментов и правительства в целом указом, издавать отдельные указы по вопросам, устанавливающим, изменяющим, отменяющим права, обязанности, правоотношения органов государственной власти и иных лиц, устанавливать главам департаментов полномочия, непротиворечащие настоящей конституции и законам Queen Creek.\nb. Заключать договора с внешними государствами.\nc. Назначать и отзывать послов и консулов.\nd. Назначать вице-президентов по делам администрации президента и делам дисциплинарной комиссии Queen Creek.\nf. Назначать судей Республики.\ng. Назначать и отстранять от должности следующие должности: мэры городов, советники Президента, главу службы безопасности президента и иных лиц, предусмотренных законодательством Республики.\nh. Осуществлять, посредством помилования частичное или полное освобождение от уголовной и административной ответственности, по всем видам дел, за исключением дел, которые законом отнесены к делам, по которым осуществление помилования не возможно.\ni. Награждать государственными наградами.\nj. Присваивать очередные и внеочередные звания военнослужащим.\nk. Даровать гражданство Queen Creek.\nl. Иные полномочия, установленные законом.\nm. вводить военное и чрезвычайное положение.\nn. Применять вооруженные силы Queen Creek, на территории и вне территории Queen Creek."},
        {"Раздел 4.", "Президент Queen Creek может быть отстранены от должности по импичменту за государственную измену, взяточничество либо за другие серьезные преступления и правонарушения. Процедура импичмента может быть инициирована любым объединением 3-х руководителей государственных органов или 3-х членов кабинета Президента и рассматривается пленумом руководителей государственных органов. Если за импичмент проголосовало 3/4 действующих руководителей государственных органов, то президент считается отрешенным от должности. Президент обладает пожизненной неприкосновенностью. Временно снять неприкосновенность, в случае совершенного преступления президентом может Директор ФБР."},
        {"Раздел 5.", "На территории Республики действуют 5 постоянных департаментов.\n\nПостоянными департаментами являются:\n\nДепартамент внутренней политики - департамент состоящее из Государственного центра лицензирования и Средств Массовой информации.\nНадзор за деятельностью министерства внутренней политики осуществлет советник Президента в социальной сфере\n\nДепартамент юстиции – департамент, состоящее из Федерального бюро расследований и Полицейского Департамента Куин Крика. \nНадзор за деятельностью министерства юстиции осуществляют советники по делам Юстиции и по делам Национальной безопасности в соответствии с постановлениями Верховного совета.\n\nДепартамент здравоохранения - департамент, осуществляющее выработку политики в области здравоохранения. \nНадзор за деятельностью Министрества здравоохранения осуществляет советник Президента в социальной сфере.\n\nДепартамент обороны – департамент, обеспечивающее безопасность государства, контроль вооруженных сил. \nНадзор за деятельностью министерства обороны осуществляют советники по делам Юстиции и по делам Национальной безопасности, в соответствии с постановлениями Верхвовного совета."},
        {"Раздел 6.", "Все департаменты не зависимы между собой. Ни один департамент не может вмешиваться во внутренние дела другого министерства. Под внутренними делами департамента предполагается внутренние нормативно-правовые акты, дисциплинарные наказания сотрудников. Исключительным правом привлекать к дисциплинарной ответственности сотрудников 1-4 порядковой должности без участия третьих органов обладает ФБР и 5-10 должности с рассмотрением дела дисциплинарной комиссией."},
        {"Раздел 7.", "Правительство в плане своей деятельности отвечает за благосостояние народа. Вправе распоряжаться государственной собственностью и иные полномочия в соответствии с законами Республики."},
        {"Раздел 9.", "Кабинет Президента имеет право издавать акты в пределах следующей компетенции: \nа. Общие требования по поведению в государственных структурах\nб. Взаимоотношения и правила применения отдельных положений законов, регулирующих правоотношения государственных органов\nв. Распределять денежные средства из резервного фонда бюджета.\nг. Акты от имени кабинета президента входящие в компетенцию одного отдельного департамента."}
    },
    ["Статья 3"] = {
        {"Раздел 1.", "Судебная власть Queen Creek предоставляется судебному аппарату из 5-ти судей. Суд Республики Квин-Крик имеет право в лице судьи суда Республики при рассмотрении уголовного дела назначить лицу, совершившему уголовное правонарушение или преступление низкой тяжести впервые, предупреждение, вопреки мерам наказания предусмотренным уголовным законом Республики. В случае, если такое лицо привлекается к уголовной ответственности в течение десяти дней с момента вступления в законную силу приговора суда по уголовному делу, то такое предупреждение недопустимо, равно как и не допустимо вынесение предупреждения, если повторное привлечение к уголовной ответственности лица было произведено до вынесения приговора. Судья занимает свои должности, пока поведение их безупречно, и в установленное время получают за свою службу вознаграждение, которое не может быть уменьшено во время нахождения их в должности. Пленум судебного аппарата - единовременное заседание всех действующих судей Республики. Решение Пленума принимается голосом большенства."},
        {"Раздел 2.", "В компетенцию Суда входит следующие:\n\na. Толкования конституции, законов Республики Queen Creek и иных нижестоящих нормативно-правовых актов по запросу Президента Республики. Толкование постоянно и не подлежит обжалованию, оно может быть дано только пленумом судебного аппарата.\n\nb. Проверка на соответствие Конституции законов и иных Нормативно правовых актов Республики Queen Creek. Суд вправе отменить закон или иной нормативный правовой акт органов государственной власти Республики Queen Creek, в случае признания его неконституционным или противоречащим акту, имеющим высшую юридическую силу, или же вступившим в силу раньше, или же по причине создания коллизионных ситуаций. Иные полномочия суда в сфере конституционного контроля устанавливаются законом. Рассмотрения дел Конституционного контроля происходит Пленумом судебного аппарата.\n\nd. Решением спорных вопросов между государственных органов Queen Creek.\n\ne. Иные полномочия, установленные законом.\n\nf. Выдавать ордера на обыск, задержания, арест, отстранения, прослушивание.\n\ni. Создаёт и обобщает судебную практику Республики посредством Пленума судебного аппарата.\n\nj. В случае если какое то общественно опасное деяние не имеет меры наказания, пленум судебного аппарата вправе определить меру наказания самостоятельно.\n\nk. Создает судебные прецеденты по конкретным юридическим делам, которые применяются в рамках рассмотрения аналогичных юридических дел судами Республики Queen Creek. Исполнение судебных прецедентов является обязательным для исполнения на всей территории Республики Queen Creek. Судебный прецедент является источником права."},
        {"Раздел 3.", "Государственной изменой Республики Queen Creek считается только ведение войны против него или присоединение к их врагам и оказание им помощи и содействия. Ни одно лицо не может быть осуждено за государственную измену иначе как на основании показаний двух свидетелей об одном и том же очевидном деянии либо собственного признания на открытом заседании суда, либо наличие фото/видео материалов, которые могут доказать вину. Генеральная Ассамблея имеет право устанавливать наказание за государственную измену, но признание виновным в измене не влечет лишения всех прав и состояния либо конфискации имущества иначе как при жизни виновного лица."},
        {"Раздел 7.", "Судебный аппарат выступает судом первой инстанции по любым делам, пересмотр решений суда происходит в Верховном совете Республики."},
        {"Раздел 8.", "Государственное обвинение по уголовным делам может выдвигать директор фбр и его заместители, советник юстиции, советник национальной безопасности, члены дисциплинарной комиссии."}
    },
    ["Статья 4"] = {
        {"Раздел 1.", "Граждане Республики имеют следующие права:\na. Право на жизнь\nb. Право на своевременное получение медицинской помощи\nc. Право на неприкосновенность частной и личной жизни. Гражданинне может быть обыскан, досмотрен, без решения суда или иного способа,предусмотренным законом.\nd. Право на личную неприкосновенность. Гражданин не может быть задержан,арестован без решения суда. Гражданин, может быть, задержан правоохранительнымиорганами на срок 24 часа при подозрении на преступление. При задержание человекудолжны быть разъяснены его следующие права: на 1 телефонный звонок, на адвоката, хранить молчание. Государственные слушающие, работающие в ФБР, полиции, администрации президента, включая руководителей этих структур, трудоустраиваясь добровольно отказываются от права хранить молчания. В случае, если граждане будут желать хранить молчание, они автоматически соглашаются на увольнение с места работы, без право на восстановления в должности.\ne. Право на жилье. У гражданина не может быть изъято жилье, если оно у него является единственным.\nf. Право на свободу слова.\ng. Право на свободное получение и распространение информации.\nh. Право на защиту в суде.\ni. Право на государственного правозащитника при задержание.\nj. Право на свободное передвижение по территории государства.\nk. Право на свободные трудовые отношения.\nl. Право на Избирать и быть избранным.\nm. Право на пенсию, которая регулируется законом.\nn. Право на владение и ношения оружия, которое регулируется законом.\no. Иные права, предусмотренные, законами Республики, международными конвенциями, международными договорами."}
    },
}


local lawsData = {
    ["Статья 1. Преступления против жизни и здоровья"] = {
        {"3.1.1 КК", "Убийство человека", 5},
        {"3.1.2 КК", "Причинение легкого вреда здоровью", 2},
        {"3.1.3 КК", "Причинение тяжкого вреда здоровью", 3},
        {"3.1.4 КК", "Угроза убийством", 2},
        {"3.1.5 КК", "Воспрепятствование медработникам", 3},
    },
    ["Статья 2. Преступления против свободы, чести и достоинства личности"] = {
        {"3.2.1 КК", "Похищение", 4},
        {"3.2.2 КК", "Похищение группой лиц", 6},
        {"3.2.3 КК", "Клевета", 1},
        {"3.2.4 КК", "Клевета сотруднику полиции", 3},
        {"3.2.5 КК", "Причинение страданий", 4},
        {"3.2.6 КК", "Побои", 2},
    },
    ["Статья 3. Преступление против собственности"] = {
        {"3.3.1 КК", "Кража", 2},
        {"3.3.2 КК", "Грабеж", 3},
        {"3.3.3 КК", "Вымогательство", 3},
        {"3.3.4 КК", "Угон автомобиля", 3},
        {"3.3.5 КК", "Угон воздушного транспорта", 4},
        {"3.3.6 КК", "Порча частного имущества", 1},
    },
    ["Статья 4. Преступления против общества"] = {
        {"3.4.1 КК", "Теракт", 6},
        {"3.4.2 КК", "Склонение к теракту", 3},
        {"3.4.3 КК", "Пособничество террористам", 3},
        {"3.4.4 КК", "Публичный призыв к теракту", 2},
        {"3.4.5 КК", "Захват заложников", 6},
        {"3.4.6 КК", "Незаконное приобретение, хранение оружия", 2},
        {"3.4.7 КК", "Незаконная продажа или попытка продажи оружия", 4},
        {"3.4.8 КК", "Ношение оружия в открытом виде", 1},
        {"3.4.9 КК", "Изготовление взрывчатки", 4},
        {"3.4.10 КК", "Пиратство", 3},
        {"3.4.11 КК", "Создание, сбыт, дубликатов ключей от ТСР или ТС", 2},
        {"3.4.12 КК", "Хранение наркотиков, более 20 грамм", 2},
        {"3.4.13 КК", "Создание, сбыт наркотиков", 4},
        {"3.4.14 КК", "Дискриминация", 2},
        {"3.4.15 КК", "Распространение заведомо ложных сведений", 2},
        {"3.4.16 КК", "Призывы к войне", 2},
        {"3.4.17 КК", "Заведомо ложный донос", 1},
        {"3.4.18 КК", "Принуждения лица к даче показаний", 3},
    },
    ["Статья 5. Должностные преступления"] = {
        {"3.5.1 КК", "Злоупотребление полномочиями", 3},
        {"3.5.2 КК", "Превышение полномочий", 4},
        {"3.5.3 КК", "Получение взятки", 6},
        {"3.5.4 КК", "Служебный подлог", 3},
        {"3.5.5 КК", "Халатность", 2},
    },
    ["Статья 6. Преступление против государственной власти"] = {
        {"3.6.1 КК", "Вооруженный мятеж", 6},
        {"3.6.2 КК", "Неподчинение", 2},
        {"3.6.3 КК", "Неисполнения решения прокуратуры", 1},
        {"3.6.4 КК", "Дача взятки", 2},
        {"3.6.5 КК", "Покушение на жизнь судьи, сотрудника полиции, правительства", 6},
        {"3.6.6 КК", "Угроза жизни судьи, сотрудника полиции, правительства", 3},
        {"3.6.7 КК", "Убийство судьи, сотрудника полиции, правительства", 6},
        {"3.6.8 КК", "Побег из тюрьмы", 6},
        {"3.6.9 КК", "Помощь в побеге из тюрьмы", 3},
        {"3.6.10 КК", "Дача ложных показаний", 2},
        {"3.6.11 КК", "Неисполнение приговора суда", 2},
        {"3.6.12 КК", "Отказ от уплаты штрафа", 2},
        {"3.6.13 КК", "Помеха сотрудникам полиции", 1},
        {"3.6.14 КК", "Неподчинение прокуратуре", 1},
        {"3.6.15 КК", "Уклонение от службы", 3},
        {"3.6.16 КК", "Самоуправство", 1},
        {"3.6.17 КК", "Неоднократное оскорбление сотрудника полиции", 2},
        {"3.6.18 КК", "Незаконное использование рации департамента", 1},
        {"3.6.19 КК", "Порча государственного имущества", 1},
        {"3.6.20 КК", "Препятствие правосудию", 1},
        {"3.6.21 КК", "Подделка документов", 2},
        {"3.6.22 КК", "Проникновение на режимный объект", 2},
        {"3.6.23 КК", "Нарушение правил РО", 1},
        {"3.6.24 КК", "Раскрытие государственной тайны", 5},
        {"3.6.25 КК", "Организация незаконного митинга", 3},
        {"3.6.26 КК", "Неоднократный ложный вызов", 1},
        {"3.6.28 КК", "Дезертирство", 3},
        {"3.6.29 КК", "Надругательство над гербом или флагом республики", 1},
    },
    ["Статья 7. Экономические преступления"] = {
        {"3.7.1 КК", "Ограничение торговли", 6},
        {"3.7.2 КК", "Создание монополии", 6},
        {"3.7.3 КК", "Кража государственных средств на нецелевые расходы", 6},
    }
}

local pddData = {
    ["Статья 2.1. Скоростной режим"] = {
        {"2.1.2 ДК", "Нарушение скоростного режима установленного Дорожным Кодексом", 320000},
    },
    ["Статья 2.2. Езда в нетрезвом виде"] = {
        {"2.2.1 ДК", "Управление наземным или водным транспортным средством в нетрезвом виде с показателем 0.5‰ промилле и выше.", 350000},
        {"2.2.2 ДК", "Управление воздушным транспортным средством в нетрезвом виде с показателем 0.3‰ промилле и выше", 300000},
    },
    ["Статья 2.3. Парковка в неположенном месте"] = {
        {"2.3.1 ДК", "Парковка транспортного средства по левой стороне дороги, на автомагистралях и железнодорожных путях", 120000},
        {"2.3.2 ДК", "Парковка транспортного средства в местах проведения специальных операций или ближе чем на 15 метров от ограждений, которые установлены сотрудниками полицейских департаментов, ФБР, а также спец. подразделением OSO", 175000},
        {"2.3.4 ДК", "Парковка воздушного транспортного средства на дорогах или парковках для наземных транспортных средств", 150000},
    },
    ["Статья 2.4. Езда по встречной полосе или в неположенном месте"] = {
        {"2.4.1 ДК", "Езда по встречной полосе на транспортном средстве", 23000},
        {"2.4.2 ДК", "Езда по тротуарам, обочинам, газонам, железнодорожным путям", 40000},
    },
    ["Статья 2.5. Дорожно-транспортное происшествие"] = {
        {"2.5.2 ДК", "Дорожно-транспортное происшествие, повлекшее за собой смерть пешехода или другого водителя", 300000},
        {"2.5.3 ДК", "Дорожно-транспортное происшествие, совершенное в нетрезвом состоянии и повлекшее за собой смерть пешехода или другого водителя", 300000},
        {"2.5.4 ДК", "Дорожно-транспортное происшествие, повлекшее за собой вред здоровью перехода или другого водителя", 250000},
        {"2.5.5 ДК", "Дорожно-транспортное происшествие, совершенное в нетрезвом состоянии и повлекшее за собой вред здоровью пешехода или другого водителя", 225000},
    },
    ["Статья 2.6. Уход водителей-участников ДТП с места его происшествия"] = {
        {"2.6.1 ДК", "Уход водителей-участников ДТП с места его происшествия", 200000},
    },
    ["Статья 2.7. Игнорирования спец. сигналов"] = {
        {"2.7.2 ДК", "Игнорирование водителем специальных сигналов, которые установлены на транспортных средствах", 150000},
    },
    ["Статья 2.8. Повторные нарушения правил дорожного движения"] = {
        {"2.8.2 ДК", "Нарушение более трёх правил дорожного движения за день", 250000},
        {"2.8.3 ДК", "Намеренное повторное нарушение правил дорожного движения", 500000},
    }
}
-- main()
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
    if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
    save_command()
    loadBinders()
    saveBinders()
    sampAddChatMessage(tag .. "Скрипт {7172EE}запущен", -1)
    sampAddChatMessage(tag .. "Команда открытия меню - {7172EE}/fox.", -1)
    sampRegisterChatCommand('fox', function() WinState[0] = not WinState[0] end)
    sampRegisterChatCommand('ssu', cmd_ssu)
    sampRegisterChatCommand('sticket', cmd_stik)
    sampRegisterChatCommand('mimgui', function()
        renderWindow[0] = not renderWindow[0]
    end)
    thread = lua_thread.create_suspended(thread_function)


    if checkinfo[0] == true then
        window_two[0] = not window_two[0]
        imgui.showCursor = false
    end

    while true do
		wait(0)
		x,y,z = getCharCoordinates(PLAYER_PED)
        hp = getCharHealth(PLAYER_PED)
	end
end

function imgui.CText(text)
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX((imgui.GetWindowWidth() - calc.x) / 2)
    imgui.Text(text)
   end

-- окно информации
imgui.OnFrame(function() return window_two[0] end, function(player)
    if bit.band(flags, imgui.WindowFlags.NoMove) == 0 then
        local x, y = getCursorPos()
        imgui.SetNextWindowPos(imgui.ImVec2(x, y), nil, imgui.ImVec2(0.5, 0.5))
        if imgui.IsMouseClicked(0) then
            flags = flags + imgui.WindowFlags.NoMove
            sampAddChatMessage(tag .. ' Положение окна изменено!', -1)
        end
    end
    imgui.SetNextWindowBgAlpha(0.3)
    imgui.SetNextWindowSize(imgui.ImVec2(230,126), imgui.Cond.Always)
    imgui.Begin("##yourinfo", window_two, flags + imgui.WindowFlags.NoScrollbar)
    local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local nickname = sampGetPlayerNickname(id)
    local fps = math.floor(memory.getfloat(12045136, true))
    local ping = sampGetPlayerPing(id)
    imgui.CText("FPS: " .. fps .. " | ".. ffi.string(nickname) .. '[' .. id .. '] | Ping: ' .. ping)
    imgui.Separator()
    imgui.TextWrapped(u8"Город: " .. calccity(x, y, z))
    imgui.TextWrapped(u8"Район: " .. calculateZone(x, y, z))
    imgui.Separator()
    imgui.CText(os.date("%d.%m.%Y", os.time()) .. " " .. os.date('%H:%M:%S'))
    imgui.End()
end).HideCursor = true

local searchQuery = new.char[256]()

-- умный розыск
imgui.OnFrame(function() return ssu[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500,500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(830,630), imgui.Cond.Always)
    imgui.Begin(fa.GAVEL .. u8" Умный розыск", ssu, imgui.AlwaysAutoResize)
    imgui.InputText(u8"Поиск", searchQuery, 256)
    imgui.SameLine()
    if imgui.Checkbox(u8'Запрос', zap) then
        if zap[0] == true then
            ini.mainIni.zap = true
            inicfg.save(ini, 'LawHelper/lawini.ini')
        elseif zap[0] == false then
            ini.mainIni.zap = false
            inicfg.save(ini, 'LawHelper/lawini.ini')
        end
    end
    imgui.SameLine()
    if imgui.Checkbox(u8'Запрос /d', zapd) then
        if zapd[0] == true then
            ini.mainIni.zapd = true
            inicfg.save(ini, 'LawHelper/lawini.ini')
        elseif zapd[0] == false then
            ini.mainIni.zapd = false
            inicfg.save(ini, 'LawHelper/lawini.ini')
        end
    end

    local filteredData = {}

    -- Перебираем данные для поиска
    for article, offenses in pairs(lawsData) do
        if string.find(article:lower(), u8:decode(ffi.string(searchQuery)):lower()) or u8:decode(ffi.string(searchQuery)) == "" then
            filteredData[article] = offenses
        else
            for _, offense in ipairs(offenses) do
                -- Проверяем, совпадает ли любой из элементов правонарушение с введенным запросом
                local code, description = offense[1], offense[2]
                if string.find(code:lower(), u8:decode(ffi.string(searchQuery)):lower()) or string.find(description:lower(), u8:decode(ffi.string(searchQuery)):lower()) then
                    if not filteredData[article] then
                        filteredData[article] = {}
                    end
                    table.insert(filteredData[article], offense)
                end
            end
        end
    end

    local sortedKeys = {
        "Статья 1. Преступления против жизни и здоровья",
        "Статья 2. Преступления против свободы, чести и достоинства личности",
        "Статья 3. Преступления против собственности",
        "Статья 4. Преступления против общества",
        "Статья 5. Должностные преступления",
        "Статья 6. Преступление против государственной власти",
        "Статья 7. Экономические преступления"
    }
    
    for _, article in ipairs(sortedKeys) do
        local offenses = filteredData[article]
        if offenses then  -- Если есть совпадения
            if imgui.CollapsingHeader(u8(article)) then  -- Создаем коллапсируемый заголовок
                for _, offense in ipairs(offenses) do
                    local code = offense[1]
                    local description = offense[2]
                    local penalty = offense[3]
                    imgui.Text(u8(string.format("%s | %s | %d*", code, description, penalty)))  -- Форматируем текст
                    local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                    local nickname = sampGetPlayerNickname(id)
                    if imgui.IsItemClicked() then
                        lua_thread.create(function()
                            if zap[0] == true then
                                sampSendChat('/b ' .. nickname .. ' на CONTROL. Запрашиваю объявление в розыск дела ' .. suspect_id)
                                wait(2100)
                                sampSendChat('/b Причина: ' .. code .. ' ' .. description)
                            elseif zapd[0] == true then
                                sampSendChat('/b [to MJ] Запрашиваю объявление в розыск дела ' .. suspect_id)
                                wait(2100)
                                sampSendChat('/b [to MJ] Причина: ' .. code .. ' ' .. description)
                            else
                                sampSendChat('/todo Объявите в розыск дело ' .. suspect_id .. '*разговаривая с диспетчером')
                                wait(1700)
                                sampAddChatMessage('/su ' .. suspect_id .. ' ' .. penalty .. ' ' .. code, -1)
                            end
                        end)
                    end
                end
            end
        end
    end
    imgui.End()
end)

local searchQuery_1 = new.char[256]()

imgui.OnFrame(function() return stik[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500,500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(830,630), imgui.Cond.Always)
    imgui.Begin(fa.GAVEL .. u8" Умный штраф", stik, imgui.AlwaysAutoResize)
    imgui.InputText(u8"Поиск", searchQuery_1, 256)

    local filteredData = {}

    -- Перебираем данные для поиска
    for article, offenses in pairs(pddData) do
        if string.find(article:lower(), u8:decode(ffi.string(searchQuery_1)):lower()) or u8:decode(ffi.string(searchQuery_1)) == "" then
            filteredData[article] = offenses
        else
            for _, offense in ipairs(offenses) do
                -- Проверяем, совпадает ли любой из элементов правонарушение с введенным запросом
                local code, description = offense[1], offense[2]
                if string.find(code:lower(), u8:decode(ffi.string(searchQuery_1)):lower()) or string.find(description:lower(), u8:decode(ffi.string(searchQuery_1)):lower()) then
                    if not filteredData[article] then
                        filteredData[article] = {}
                    end
                    table.insert(filteredData[article], offense)
                end
            end
        end
    end

    local sortedKeys_2 = {
        "Статья 2.1. Скоростной режим",
        "Статья 2.2. Езда в нетрезвом виде",
        "Статья 2.3. Парковка в неположенном месте",
        "Статья 2.4. Езда по встречной полосе или в неположенном месте",
        "Статья 2.5. Дорожно-транспортное происшествие",
        "Статья 2.6. Уход водителей-участников ДТП с места его происшествия",
        "Статья 2.7. Игнорирования спец. сигналов",
        "Статья 2.8. Повторные нарушения правил дорожного движения"
    }
    
    for _, article in ipairs(sortedKeys_2) do
        local offenses = filteredData[article]
        if offenses then  -- Если есть совпадения
            if imgui.CollapsingHeader(u8(article)) then  -- Создаем коллапсируемый заголовок
                for _, offense in ipairs(offenses) do
                    local code_1 = offense[1]
                    local description_2 = offense[2]
                    local penalty_3 = offense[3]
                    imgui.Text(u8(string.format("%s | %s | %d$", code_1, description_2, penalty_3)))  -- Форматируем текст
                    local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                    local nickname = sampGetPlayerNickname(id)
                    if imgui.IsItemClicked() then
                        lua_thread.create(function()
                            sampSendChat('Извините, но я вынужден выписать Вам штраф в размере ' .. penalty_3 .. '$')
                            wait(1700)
                            sampSendChat('/me достал из подсумка бланк и ручку, начал заполнять бланк')
                            wait(1700)
                            sampSendChat('/me закончив заполнять бланк, передал ручку и бланк водителю')
                            wait(1700)
                            sampSendChat('/todo Подпишите вот здесь*указывае пальцем на окошко подписи')
                            wait(1700)
                            sampAddChatMessage('/ticket ' .. ticket_id .. " " .. penalty_3 .. " " .. code_1, -1)
                        end)
                    end
                end
            end
        end
    end
    imgui.End()
end)


-- сохранение темы
function save_themes()
    ini.Themes.number = decorListNumber[0]
    inicfg.save(ini, 'LawHelper/lawini.ini')
    imgui.SetNextWindowBgAlpha(alpha[0])
end

-- умный розыск рег. команды
function cmd_ssu(arg)
    suspect_id = arg
    if arg == '' then
        sampAddChatMessage(tag .. 'Вы не указали id саспeкта!', -1)
    else
        ssu[0] = not ssu[0]
    end
    ini.mainIni.purID = arg
    inicfg.save(ini, 'LawHelper/lawini.ini')
end

function cmd_stik(arg)
    ticket_id = arg
    if arg == '' then
        sampAddChatMessage(tag .. 'Вы не указали id саспeкта!', -1)
    else
        stik[0] = not stik[0]
    end
end



local binder = {}

function sampev.onSendCommand(arguments)
    local command, par, par_2, par_3, par_4, par_5 = arguments:match("/(%S+)%s*(%S*)%s*(%S*)%s*(%S*)%s*(%S*)%s*(%S*)")
    if binder[command] then
        lua_thread.create(function()
            for i, v in ipairs(binder[command]) do
                local input_all = v

                -- Получаем имя и ID игрока
                local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
                local playerNick = sampGetPlayerNickname(playerId)
                local first_name, last_name = get_first_last_name(playerNick)
                local hp = getCharHealth(PLAYER_PED)
                local arm = sampGetPlayerArmor(playerId)
                
                -- Заменяем теги на соответствующие значения, если они есть в строке
                input_all = input_all:gsub('{my_nick}', playerNick)
                input_all = input_all:gsub('{my_id}', playerId)
                input_all = input_all:gsub('{my_name}', first_name)
                input_all = input_all:gsub('{my_surname}', last_name)
                input_all = input_all:gsub('{my_rpnick}', first_name .. " " .. last_name)
                input_all = input_all:gsub('{my_hp}', hp)
                input_all = input_all:gsub('{my_armour}', arm)
                input_all = input_all:gsub('{arg_1}', par)
                input_all = input_all:gsub('{arg_2}', par_2)
                input_all = input_all:gsub('{arg_3}', par_3)
                input_all = input_all:gsub('{arg_4}', par_4)
                input_all = input_all:gsub('{arg_5}', par_5)

                -- Отправляем сообщение в чат
                sampSendChat(input_all)
                wait(delay[0])
            end
        end)
        return false
    end
end

function save_command() -- очистка и перезаполнение таблицы
    if powerBool[0] == false then
        binder = {}
        for i, v in ipairs(binders) do
            binder[v.command] = {}
            for line in v.text:gmatch("[^\n]+") do
                table.insert(binder[v.command], line)
            end
        end
    elseif powerBool[0] == true then
        sampAddChatMessage(tag .. ' Бинд выключен! Моежет включить его в меню.')
    end
end



local window_new_binder = new.bool(false)
imgui.OnFrame(function() return window_new_binder[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(600, 600), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(600, 350), imgui.Cond.Always)
    imgui.Begin(fa.PEN .. u8" Создать бинд", window_new_binder, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoFocusOnAppearing)
    imgui.InputTextWithHint(u8'##Название биндера', u8'Введите название бинда', title, 256)
    imgui.InputTextMultiline(u8'##Текст', texter, 10000)
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 42))
    if imgui.Button(u8'Сохранить', imgui.ImVec2(177, 30)) then
        table.insert(binders, {
            text = u8:decode(ffi.string(texter)),
            command = ffi.string(commander),
            delay = delay[0],
            title = u8:decode(ffi.string(title)),
            power = false
        })
        save_command()
        saveBinders()
        window_new_binder[0] = false
        WinState[0] = true
    end
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 80))
    if imgui.Button(u8'Отмена', imgui.ImVec2(177, 30)) then
        window_new_binder[0] = false
        WinState[0] = true
    end
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 141))
    imgui.PushItemWidth(177)
    imgui.SliderInt(u8'Задержка (мс)', delay, 1000, 5000)
    imgui.PopItemWidth()
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 111))
    imgui.Text(u8'Задержка (мс):')
    imgui.SetCursorPos(imgui.ImVec2(15, 211))
    imgui.InputTextWithHint(u8'##Введите команду (без /)', u8'Введите команду (без /)', commander, 256)
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 170))
    imgui.Text(fa.CIRCLE_INFO .. u8' Теги')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Теги:\n{my_nick} - выведет ваш ник в формате Nick_Name\n{my_id} - выведет ваш ID\n{my_name} - Выведет имя\n{my_surname} - выведет фамилию\n{my_rpnick} - выведет ник в РП формате (без "_")\n{my_hp} - выведет ваше здоровье (HP)\n{my_armour} - выведет вашу броню\n{arg_1} - первый аргумент к команде\n{arg_2} - второй аргумент к команде\n{arg_3} - третий аргумент к команде\n{arg_4} - четвертый аргумент к команде\n{arg_5} - первый аргумент к команде\n')
        imgui.EndTooltip()
    end
    imgui.End()
    imgui.End()
end)


local window_edit_binder = new.bool(false)
imgui.OnFrame(function() return window_edit_binder[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(600, 600), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(600, 350), imgui.Cond.Always)
    imgui.Begin(fa.PEN .. u8" Редактировать бинд", window_edit_binder, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoFocusOnAppearing)
    imgui.InputTextWithHint(u8'##Название биндера', u8'Введите название бинда', title, 256)
    imgui.InputTextMultiline(u8'##Текст', texter, 10000)
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 42))
    if imgui.Button(u8'Сохранить', imgui.ImVec2(177, 30)) then
        if selectedBinderIndex then
            binders[selectedBinderIndex] = {
                text = u8:decode(ffi.string(texter)),
                command = ffi.string(commander),
                delay = delay[0],
                title = u8:decode(ffi.string(title)),
                power = false
            }
            save_command()
            saveBinders()
        end
        window_edit_binder[0] = false
        WinState[0] = true
    end
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 80))
    if imgui.Button(u8'Отмена', imgui.ImVec2(177, 30)) then
        WinState[0] = true
        window_edit_binder[0] = false
    end
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 141))
    imgui.PushItemWidth(177)
    imgui.SliderInt(u8'Задержка (мс)', delay, 1000, 5000)
    imgui.PopItemWidth()
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 111))
    imgui.Text(u8'Задержка (мс):')
    imgui.SetCursorPos(imgui.ImVec2(15, 211))
    imgui.InputTextWithHint(u8'##Введите команду (без /)', u8'Введите команду (без /)', commander, 256)
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(413, 170))
    imgui.Text(fa.CIRCLE_INFO .. u8' Теги')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Теги:\n{my_nick} - выведет ваш ник в формате Nick_Name\n{my_id} - выведет ваш ID\n{my_name} - Выведет имя\n{my_surname} - выведет фамилию\n{my_rpnick} - выведет ник в РП формате (без "_")\n{my_hp} - выведет ваше здоровье (HP)\n{my_armour} - выведет вашу броню\n{arg_1} - первый аргумент к команде\n{arg_2} - второй аргумент к команде\n{arg_3} - третий аргумент к команде\n{arg_4} - четвертый аргумент к команде\n{arg_5} - первый аргумент к команде\n')        imgui.EndTooltip()
    end
    imgui.End()
    imgui.End()
end)

local about_us = new.bool(false)
imgui.OnFrame(function() return about_us[0] end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(600, 600), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(180, 155), imgui.Cond.Always)
    imgui.Begin(fa.CIRCLE_INFO .. u8" Информация", about_us, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoFocusOnAppearing)
    imgui.Text(u8'Имя скрипта: Foxi Tools')
    imgui.Text(u8'Версия: v0.0.4 pre-alpha')
    imgui.Text(u8'Автор: Choko Pay')
    if imgui.Button(u8'Закрыть', imgui.ImVec2(150, 30)) then
        about_us[0] = false
    end
end)

imgui.OnInitialize(function()
    if doesFileExist(getWorkingDirectory()..'\\resource\\example.png') then -- находим необходимую картинку с названием example.png в папке moonloader/resource/
        imhandle = imgui.CreateTextureFromFile(getWorkingDirectory() .. '\\resource\\example.png') -- если найдена, то записываем в переменную хендл картинки
    end
end)
-- главное окно
imgui.OnFrame(function() return WinState[0] and not isGamePaused() end, function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(500,500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(1000,530), imgui.Cond.Always)
    imgui.Begin('Foxi Tools', WinState, imgui.WindowFlags.AlwaysAutoResize)
    if imgui.BeginChild('Main', imgui.ImVec2(170, 470), true) then
        local style = imgui.GetStyle()
        style.FramePadding = imgui.ImVec2(8, 7)
        ---imgui.SetCursorPos(imgui.ImVec2(35, 5))
        --imgui.Image(imhandle, imgui.ImVec2(100, 100)) 
        if imgui.Button(fa.GEAR .. u8' Основное', imgui.ImVec2(140, 40)) then tab = 1 end
        if imgui.Button(fa.GAVEL .. u8' Законодательство', imgui.ImVec2(140, 40)) then tab = 2 end
        if imgui.Button(fa.NEWSPAPER .. u8' Уставы', imgui.ImVec2(140, 40)) then tab = 3 end
        if imgui.Button(fa.KEYBOARD .. u8' Биндер', imgui.ImVec2(140, 40)) then tab = 4 end
        if imgui.Button(fa.BOOK .. u8' Блокнот', imgui.ImVec2(140, 40)) then tab = 5 end
        if imgui.Button(fa.CHART_PIE .. u8' Круговое меню', imgui.ImVec2(140, 40)) then tab = 6 end
        if imgui.Button(fa.CLIPBOARD_QUESTION .. u8' Собеседование', imgui.ImVec2(140, 40)) then tab = 7 end
        imgui.SetCursorPos(imgui.ImVec2(14, 388))
        if imgui.Button(faicons.CIRCLE_INFO) then
            about_us[0] = not about_us[0]
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Информация о скрипте')
            imgui.EndTooltip()
        end
        imgui.SameLine()
        if imgui.Button(fa.HEADSET) then 
            os.execute("start https://vk.com/imclownreal")
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Техническая поддержка')
            imgui.EndTooltip()
        end
        imgui.SameLine()
        if imgui.Button(fa.FLOPPY_DISK) then
            saveSettings()
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Сохранить настройки')
            imgui.EndTooltip()
        end
        imgui.SameLine()
        if imgui.Button(fa.ROTATE) then
            sampAddChatMessage(tag .. "Скрипт перезагружается.", -1)
            thisScript():reload()
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Перезагрузить скрипт')
            imgui.EndTooltip()
        end
        if imgui.Button(fa.POWER_OFF .. u8" Выключить", imgui.ImVec2(143, 30)) then
            sampAddChatMessage(tag .. "Происходит {7172EE}выключение{FFFFFF} скрпита!", -1)
            sampAddChatMessage(tag .. "Скрипт {7172EE}выключен{FFFFFF}!", -1)
            exit()
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
           imgui.Text(u8'Выключить скрипт')
            imgui.EndTooltip()
        end
        imgui.EndChild()
    end

    if tab == 6 then
        imgui.SetCursorPos(imgui.ImVec2(190, 43))
        if imgui.BeginChild('Pie', imgui.ImVec2(795, 470), true) then
        end
        imgui.EndChild()
    end

    if tab == 5 then
        imgui.SetCursorPos(imgui.ImVec2(190, 43))
        if imgui.BeginChild('Shpora', imgui.ImVec2(795, 470), true) then
            imgui.Button(u8'Блокнот', imgui.ImVec2(765, 30))
            if imgui.BeginChild('Block List', imgui.ImVec2(150, 400), true) then
                imgui.Columns(1)
                imgui.CText(u8'Меню блокнотов')
                imgui.Columns(1)
                imgui.Separator()
                imgui.Columns(1)
                imgui.Text(u8'Тест')
                imgui.Columns(1)
                imgui.Separator()
            end
            imgui.EndChild()
            imgui.SameLine()
            if imgui.BeginChild('Block Edit', imgui.ImVec2(607, 400), true) then
                imgui.CText(u8'Редактор блонкота')
                imgui.Separator()
                imgui.InputTextMultiline('##blocknote', blocknote, 10000, imgui.ImVec2(575, 200))
            end
            imgui.EndChild()
        end
    end

    if tab == 7 then
        imgui.SetCursorPos(imgui.ImVec2(190, 43))
        if imgui.BeginChild('Sobes', imgui.ImVec2(795, 470), true) then
            imgui.Text('Coming soon, Sobes')
        end
    end

    if tab == 2 then
        imgui.SetCursorPos(imgui.ImVec2(190, 43))
        if imgui.BeginChild('Law', imgui.ImVec2(795, 470), true) then
            if imgui.CollapsingHeader(u8'Конституция') then
                if imgui.BeginChild(u8'Конституция', imgui.ImVec2(765, 365), true) then
                    local filteredData = {}
                    if imgui.CollapsingHeader(u8'Главное') then
                        -- Перебираем данные для поиска
                        for article, offenses in pairs(konstitution) do
                            if string.find(article:lower(), u8:decode(ffi.string(searchQuery_1)):lower()) or u8:decode(ffi.string(searchQuery_1)) == "" then
                                filteredData[article] = offenses
                            else
                                for _, offense in ipairs(offenses) do
                                    -- Проверяем, совпадает ли любой из элементов правонарушение с введенным запросом
                                    local code, description = offense[1], offense[2]
                                    if string.find(code:lower(), u8:decode(ffi.string(searchQuery_1)):lower()) or string.find(description:lower(), u8:decode(ffi.string(searchQuery_1)):lower()) then
                                        if not filteredData[article] then
                                            filteredData[article] = {}
                                        end
                                        table.insert(filteredData[article], offense)
                                    end
                                end
                            end
                        end
                    
                        local sortedKeys_2 = {
                            "Статья 2",
                            "Статья 3",
                            "Статья 4"
                        }
                        
                        for _, article in ipairs(sortedKeys_2) do
                            local offenses = filteredData[article]
                            if offenses then  -- Если есть совпадения
                                if imgui.CollapsingHeader(u8(article)) then  -- Создаем коллапсируемый заголовок
                                    for _, offense in ipairs(offenses) do
                                        local code_1 = offense[1]
                                        local description_2 = offense[2]
                                        imgui.TextWrapped(u8(string.format("%s %s ", code_1, description_2)))  -- Форматируем текст
                                        local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                                        local nickname = sampGetPlayerNickname(id)
                                    end
                                end
                            end
                        end
                    end
                    imgui.EndChild()
                end
                imgui.EndChild()
            end
        end

    elseif tab == 3 then
        imgui.SetCursorPos(imgui.ImVec2(190, 43))
        if imgui.BeginChild('Ustav', imgui.ImVec2(795, 470), true) then
            imgui.Text(u8'Coming soon, charters')
            imgui.EndChild()
        end
    
    elseif tab == 4 then
        imgui.SetCursorPos(imgui.ImVec2(190, 43))
        if imgui.BeginChild('Binder', imgui.ImVec2(795, 470), true) then
            imgui.Button(u8'Список биндов', imgui.ImVec2(765, 30))
            if imgui.BeginChild('Binder List', imgui.ImVec2(765, 365), true) then
                imgui.Columns(5)
                imgui.Text(fa.LIST_OL) imgui.SetColumnWidth(-1, 35)
                imgui.NextColumn()
                
                imgui.Text(fa.SIGNATURE .. u8' Название бинда:') imgui.SetColumnWidth(-1, 370) -- Первый столбик
                imgui.NextColumn()
                
                imgui.Text(fa.TERMINAL .. u8' Команда:') imgui.SetColumnWidth(-1, 170) -- Второй столбик
                imgui.NextColumn()
                imgui.Text(fa.BARS .. u8' Строки:') imgui.SetColumnWidth(-1, 75) -- Второй столбик
                imgui.NextColumn()
                imgui.Text(fa.CLOCK .. u8' Задержка:') imgui.SetColumnWidth(-1, 100) -- Второй столбик
                imgui.Columns(1)
                imgui.Separator()
                
                for i = 1, #binders do 
                    local binder = binders[i]
                    imgui.Columns(5)
                    
                    
                    imgui.Text(tostring(i)) imgui.SetColumnWidth(-1, 35)
                    imgui.NextColumn()
        
                    
                    if imgui.Selectable(u8(binder.title), selectedBinderIndex == i) then
                        selectedBinderIndex = i
                    end

                    imgui.SetColumnWidth(-1, 370)
                    imgui.NextColumn()
        
                    imgui.Text('/' .. u8(binder.command)) imgui.SetColumnWidth(-1, 170) -- Команда биндера
                    imgui.NextColumn()
                    local lineCount = countLinesInBinder(binder)
                    imgui.Text(tostring(lineCount)) imgui.SetColumnWidth(-1, 75)
                    imgui.NextColumn()
                    imgui.Text(u8(tostring(binder.delay / 1000) .. " сек." )) imgui.SetColumnWidth(-1, 100) -- Второй столбик
                    imgui.Columns(1)
                    imgui.Separator()
                end
            end
            imgui.EndChild()
        end
        imgui.SetCursorPos(imgui.ImVec2(15, 425))
        if imgui.Button(faicons('PLUS'), imgui.ImVec2(120, 28)) then
            new_binder.text = ''
            new_binder.command = ''
            new_binder.delay = 1000
            new_binder.title = ''
            new_binder.power = false  -- Начальное значение power
            window_new_binder[0] = true
            texter = new.char[10000](new_binder.text)
            commander = new.char[256](new_binder.command)
            delay = new.int(new_binder.delay)
            title = new.char[256](new_binder.title)
            power = false
            WinState[0] = false
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Добавить бинд')
            imgui.EndTooltip()
        end

        imgui.SameLine()
        imgui.SetCursorPos(imgui.ImVec2(144, 425))
        if imgui.Button(fa.PEN_TO_SQUARE, imgui.ImVec2(120, 28)) then
            if selectedBinderIndex then  -- Проверяем, выбрана ли строка
                -- Инициализация редактирования выбранного биндера
                local selectedBinder = binders[selectedBinderIndex]
                
                -- Обязательно используйте ffi.string(), чтобы избежать nil значений и гарантировать корректное присвоение
                texter = new.char[10000](u8(selectedBinder.text))
                commander = new.char[256](u8(selectedBinder.command))
                delay = new.int(selectedBinder.delay)  -- Используйте значение по умолчанию для delay
                title = new.char[256](u8(selectedBinder.title))
                power = false
                  -- Сохраняем индекс редактируемого биндера
                window_edit_binder[0] = true  -- Открываем окно редактирования
                WinState[0] = false  -- Обновляем состояние окна
            else
                sampAddChatMessage(tag .. "Выберите бинд для редактирования", -1)  -- Уведомление, если не выбрано
            end
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Редактировать бинд')
            imgui.EndTooltip()
        end

        imgui.SameLine()
        imgui.SetCursorPos(imgui.ImVec2(273, 425))
        if imgui.Button(fa.CLONE, imgui.ImVec2(120, 28)) then
            if selectedBinderIndex then
                copyBinder(selectedBinderIndex)  -- Копируем биндер
            else
                sampAddChatMessage(tag .. "Выберите бинд для копирования", -1)  -- Уведомление, если не выбрано
            end
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Копировать бинд')
            imgui.EndTooltip()
        end

        imgui.SameLine()
        imgui.SetCursorPos(imgui.ImVec2(402, 425))
        if imgui.Button(fa.TRASH, imgui.ImVec2(120, 28)) then
            if selectedBinderIndex then
                local binderToDelete = binders[selectedBinderIndex]
                table.remove(binders, selectedBinderIndex)  -- Удаляем выбранного биндера из массива
                saveBinders()  -- Сохраняем обновленный список биндеров
                sampAddChatMessage(tag .. "Бинд " .. ffi.string(binderToDelete.title) .. " успешно удалён!", -1)  -- Уведомление об удалении
                selectedBinderIndex = nil  -- Сброс выбранного индекса после удаления
            else
                sampAddChatMessage(tag .. "Выберите бинд для удаления", -1)  -- Уведомление, если не выбрано
            end
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Удалить бинд')
            imgui.EndTooltip()
        end

        imgui.SameLine()
        imgui.SetCursorPos(imgui.ImVec2(531, 425))
        if imgui.Button(fa.CIRCLE_UP, imgui.ImVec2(120, 28)) then
            if selectedBinderIndex and selectedBinderIndex > 1 then
                selectedBinderIndex = selectedBinderIndex - 1  -- Переход к предыдущему биндера
            end
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Вверх')
            imgui.EndTooltip()
        end

        imgui.SameLine()
        imgui.SetCursorPos(imgui.ImVec2(660, 425))
        if imgui.Button(fa.CIRCLE_DOWN, imgui.ImVec2(120, 28)) then
            if selectedBinderIndex and selectedBinderIndex < #binders then
                selectedBinderIndex = selectedBinderIndex + 1  -- Переход к следующему биндера
            end
        end
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Вниз')
            imgui.EndTooltip()
        end
        
        imgui.EndChild()



    elseif tab == 1 then
        imgui.SetCursorPos(imgui.ImVec2(190, 43))
        if imgui.BeginChild('Settings', imgui.ImVec2(795, 470), true) then
            imgui.Text(u8'Личные настройки:')
            imgui.PushItemWidth(200)
            imgui.InputTextWithHint(u8'Введите Никнейм', u8'Nick Name', name, 256)
            imgui.PopItemWidth()
            imgui.PushItemWidth(200)
            imgui.InputTextWithHint(u8'Введите тег организации', u8'FBI, GOV и т.д.', org, 256)
            imgui.PopItemWidth()
            imgui.PushItemWidth(200)
            imgui.InputTextWithHint(u8'Введите название должности', u8'Сержант, Ст. Агент и т.д.', rank, 256)
            imgui.PopItemWidth()
            imgui.SetCursorPos(imgui.ImVec2(450, 15))
            imgui.Text(u8'Найстроки Хелпера:')
            imgui.SetCursorPos(imgui.ImVec2(450, 37))
            imgui.PushItemWidth(200)
            if imgui.Combo(u8'Выберите тему', decorListNumber, decorListBuffer, #decorList) then
                save_themes()
                theme[decorListNumber[0]+1].change()
            end
            imgui.PopItemWidth()
            imgui.SetCursorPos(imgui.ImVec2(450, 75))
            if imgui.Checkbox(u8'Вывод информации', checkinfo) then
                if checkinfo[0] == true then
                    window_two[0] = true
                    ini.mainIni.checkinfo = checkinfo[0]
                    inicfg.save(ini, 'LawHelper/lawini.ini')
                else
                    window_two[0] = false
                    ini.mainIni.checkinfo = checkinfo[0]
                    inicfg.save(ini, 'LawHelper/lawini.ini')
                end
            end
            imgui.SameLine()
            imgui.SetCursorPos(imgui.ImVec2(620, 75))
            if imgui.Button(fa.UP_DOWN_LEFT_RIGHT) then
                flags = (bit.band(flags, imgui.WindowFlags.NoMove) == 1) and (flags - imgui.WindowFlags.NoMove) or (flags + imgui.WindowFlags.NoMove)
            end
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(u8'Переместить окно информации')
                imgui.EndTooltip()
            end
            imgui.SetCursorPos(imgui.ImVec2(450, 115))
            imgui.PushItemWidth(200)
            if imgui.SliderFloat(u8'Прозрачность фона', alpha, 0, 1) then
                ini.Themes.alpha = alpha[0]
                inicfg.save(ini, 'LawHelper/lawini.ini')
                theme[decorListNumber[0]+1].change()
            end
            imgui.PopItemWidth()
            imgui.Separator()
            if imgui.BeginChild('Commands', imgui.ImVec2(200, 90), true) then
                imgui.Text(u8'Команды Foxi Tools:\n/fox - открыть главное меню\n/ssu - умный розыск\n/sticket - умный штраф')
            end
            imgui.EndChild()
            if imgui.BeginChild('Noup', imgui.ImVec2(200, 80), true) then
                imgui.Text(u8'')
            end
            imgui.EndChild()
            imgui.SameLine()
            imgui.SetCursorPos(imgui.ImVec2(223, 160))
            if imgui.BeginChild('mainmenu', imgui.ImVec2(350, 178), true) then
                imgui.CText(u8'Foxi Helper')
                imgui.Text(u8'Возможности хелпера:\n1. Удобные настройки\n2. Биндер без ограничения в кол-ве биндов\n3. Меню шпоргалок\n4. Радиальное (круговое) меню\n5. Законодательство и уставы 21-го сервера в хелпере\n6. Помощник собеседований\n7. Техническая поддержка\nИ многое многое другое')
            end
            imgui.EndChild()
            imgui.SameLine()
            if imgui.BeginChild('Commands2', imgui.ImVec2(200, 90), true) then
                imgui.CText(u8'Информация')
                imgui.CText(u8'Foxi Helper')
                imgui.CText(u8'pre-alpha v0.0.4')
            end
            imgui.EndChild()
            imgui.SetCursorPos(imgui.ImVec2(581, 258))
            if imgui.BeginChild('Noup2', imgui.ImVec2(200, 80), true) then
                imgui.Text(u8'')
            end
            imgui.EndChild()
            imgui.SetCursorPos(imgui.ImVec2(15, 345))
            if imgui.BeginChild('Thanks', imgui.ImVec2(766, 110), true) then
                imgui.CText(u8'Спасибо, за всё, Илья Ситников!')
            end
            imgui.EndChild()
        end
    end
end)




-- Загрузка биндеров при старте
loadBinders()

-- список тем

theme = {
    {
        change = function()
            imgui.SwitchContext()
            local style = imgui.GetStyle()
        
            style.WindowPadding = imgui.ImVec2(15, 15)
            style.WindowRounding = 10.0
            style.ChildRounding = 6.0
            style.FramePadding = imgui.ImVec2(8, 7)
            style.FrameRounding = 8.0
            style.ItemSpacing = imgui.ImVec2(8, 8)
            style.ItemInnerSpacing = imgui.ImVec2(10, 6)
            style.IndentSpacing = 25.0
            style.ScrollbarSize = 13.0
            style.ScrollbarRounding = 12.0
            style.GrabMinSize = 10.0
            style.GrabRounding = 6.0
            style.PopupRounding = 8
            style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
            style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

            style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.90, 0.90, 0.80, 1.00)
            style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.60, 0.50, 0.50, 1.00)
            style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.10, 0.10, 0.10, alpha[0])
            style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.12, 0.12, 0.12, alpha[0])
            style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
            style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
            style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
            style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
            style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
            style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
            style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
            style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
            style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
            style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
            style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.66, 0.66, 0.66, 1.00)
            style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.66, 0.66, 0.66, 1.00)
            style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
            style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
            style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
            style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
            style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
            style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
            style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
            style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
            style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
            style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
            style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.95, 0.95, 0.70, 1.00)
            style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
            style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.95, 0.95, 0.70, 1.00)
            style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.25, 0.25, 0.15, 1.00)
            style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.10, 0.10, 0.10, 0.80)
            style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
            style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
        end
    },
    {
        change = function()
            imgui.SwitchContext()
            local style = imgui.GetStyle()
        
            style.WindowPadding = imgui.ImVec2(15, 15)
            style.WindowRounding = 10.0
            style.ChildRounding = 6.0
            style.FramePadding = imgui.ImVec2(8, 7)
            style.FrameRounding = 8.0
            style.ItemSpacing = imgui.ImVec2(8, 8)
            style.ItemInnerSpacing = imgui.ImVec2(10, 6)
            style.IndentSpacing = 25.0
            style.ScrollbarSize = 13.0
            style.ScrollbarRounding = 12.0
            style.GrabMinSize = 10.0
            style.GrabRounding = 6.0
            style.PopupRounding = 8
            style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
            style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
        
            style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
            style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.60, 0.60, 0.60, 1.00)
            style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.95, 0.95, 0.95, alpha[0])
            style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.90, 0.90, 0.90, alpha[0])
            style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.95, 0.95, 0.95, 1.00)
            style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.80, 0.80, 0.80, 1.00)
            style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
            style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
            style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
            style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
            style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.80, 0.80, 0.80, 1.00)
            style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.70, 0.70, 0.70, 1.00)
            style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
            style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
            style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.90, 0.90, 0.90, 1.00)
            style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.55, 0.55, 0.55, 1.00)
            style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.35, 0.35, 0.35, 1.00)
            style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.45, 0.45, 0.45, 1.00)
            style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.55, 0.55, 0.55, 1.00)
            style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.80, 0.80, 0.80, 1.00)
            style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.70, 0.70, 0.70, 1.00)
            style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.60, 0.60, 0.60, 1.00)
            style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
            style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
            style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
            style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.80, 0.80, 0.80, 1.00)
            style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.70, 0.70, 0.70, 1.00)
            style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.60, 0.60, 0.60, 1.00)
            style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
            style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
            style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
            style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
            style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
            style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
            style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
            style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.85, 0.85, 0.85, 0.80)
            style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.85, 0.85, 0.85, 1.00)
            style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.75, 0.75, 0.75, 1.00)
            style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.65, 0.65, 0.65, 1.00)
        end
    },
    {
        change = function()
            imgui.SwitchContext()
            local style = imgui.GetStyle()
          
            style.WindowPadding = imgui.ImVec2(15, 15)
            style.WindowRounding = 10.0
            style.ChildRounding = 6.0
            style.FramePadding = imgui.ImVec2(8, 7)
            style.FrameRounding = 8.0
            style.ItemSpacing = imgui.ImVec2(8, 8)
            style.ItemInnerSpacing = imgui.ImVec2(10, 6)
            style.IndentSpacing = 25.0
            style.ScrollbarSize = 13.0
            style.ScrollbarRounding = 12.0
            style.GrabMinSize = 10.0
            style.GrabRounding = 6.0
            style.PopupRounding = 8
            style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
            style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
        
            style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.90, 0.90, 0.93, 1.00)
            style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
            style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.12, 0.12, 0.14, alpha[0])
            style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.18, 0.20, 0.22, alpha[0])
            style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.13, 0.13, 0.15, 1.00)
            style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
            style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
            style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
            style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
            style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
            style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
            style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.10, 0.10, 0.12, 1.00)
            style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
            style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
            style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
            style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
            style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.70, 0.70, 0.90, 1.00)
            style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.70, 0.70, 0.90, 1.00)
            style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.80, 0.80, 0.90, 1.00)
            style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
            style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.60, 0.60, 0.90, 1.00)
            style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.28, 0.56, 0.96, 1.00)
            style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
            style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
            style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
            style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
            style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
            style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.60, 0.60, 0.65, 1.00)
            style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
            style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
            style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
            style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.64, 1.00)
            style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.70, 0.70, 0.75, 1.00)
            style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.61, 0.61, 0.64, 1.00)
            style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.70, 0.70, 0.75, 1.00)
            style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
            style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.10, 0.10, 0.12, 0.80)
            style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.18, 0.20, 0.22, 1.00)
            style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.60, 0.60, 0.90, 1.00)
            style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.28, 0.56, 0.96, 1.00)
        end
    },
    {
        change = function()
            imgui.SwitchContext()
            local style = imgui.GetStyle()

            style.WindowPadding = imgui.ImVec2(15, 15)
            style.WindowRounding = 10.0
            style.ChildRounding = 6.0
            style.FramePadding = imgui.ImVec2(8, 7)
            style.FrameRounding = 8.0
            style.ItemSpacing = imgui.ImVec2(8, 8)
            style.ItemInnerSpacing = imgui.ImVec2(10, 6)
            style.IndentSpacing = 25.0
            style.ScrollbarSize = 13.0
            style.ScrollbarRounding = 12.0
            style.GrabMinSize = 10.0
            style.GrabRounding = 6.0
            style.PopupRounding = 8
            style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
            style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

            style.Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 0.90, 0.85, 1.00)
            style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.75, 0.60, 0.55, alpha[0])
            style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.25, 0.15, 0.10, alpha[0])
            style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.30, 0.20, 0.15, 0.30)
            style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
            style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.80, 0.35, 0.20, 1.00)
            style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
            style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
            style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.45, 0.25, 0.20, 1.00)
            style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.55, 0.35, 0.25, 1.00)
            style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.25, 0.15, 0.10, 1.00)
            style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.20, 0.10, 0.05, 1.00)
            style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
            style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.25, 0.15, 0.10, 1.00)
            style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.25, 0.15, 0.10, 1.00)
            style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.80, 0.35, 0.20, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(1.00, 0.65, 0.50, 1.00)
            style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 0.65, 0.50, 1.00)
            style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(1.00, 0.65, 0.50, 1.00)
            style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(1.00, 0.70, 0.55, 1.00)
            style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
            style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
            style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(1.00, 0.55, 0.40, 1.00)
            style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.45, 0.25, 0.20, 1.00)
            style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.55, 0.30, 0.25, 1.00)
            style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.65, 0.40, 0.30, 1.00)
            style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.80, 0.35, 0.20, 1.00)
            style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
            style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(1.00, 0.65, 0.50, 1.00)
            style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.45, 0.25, 0.20, 1.00)
            style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.55, 0.30, 0.25, 1.00)
            style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.65, 0.40, 0.30, 1.00)
            style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
            style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.55, 0.40, 1.00)
            style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
            style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.55, 0.40, 1.00)
            style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.55, 0.30, 0.25, 1.00)
            style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.25, 0.15, 0.10, 0.80)
            style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.30, 0.20, 0.15, 1.00)
            style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.90, 0.50, 0.35, 1.00)
            style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(1.00, 0.55, 0.40, 1.00)
        end
    },
    {
        change = function()
            imgui.SwitchContext()
            local style = imgui.GetStyle()
        
            style.WindowPadding = imgui.ImVec2(15, 15)
            style.WindowRounding = 10.0
            style.ChildRounding = 6.0
            style.FramePadding = imgui.ImVec2(8, 7)
            style.FrameRounding = 8.0
            style.ItemSpacing = imgui.ImVec2(8, 8)
            style.ItemInnerSpacing = imgui.ImVec2(10, 6)
            style.IndentSpacing = 25.0
            style.ScrollbarSize = 13.0
            style.ScrollbarRounding = 12.0
            style.GrabMinSize = 10.0
            style.GrabRounding = 6.0
            style.PopupRounding = 8
            style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
            style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
        
            style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.80, 0.80, 0.83, 1.00)
            style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
            style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.16, 0.16, 0.17, alpha[0])
            style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.20, 0.20, 0.22, alpha[0])
            style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.18, 0.18, 0.19, 1.00)
            style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.31, 0.31, 0.35, 1.00)
            style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
            style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
            style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.35, 0.35, 0.37, 1.00)
            style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.45, 0.45, 0.47, 1.00)
            style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.20, 0.20, 0.22, 1.00)
            style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.20, 0.20, 0.22, 1.00)
            style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
            style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.20, 0.20, 0.22, 1.00)
            style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.20, 0.20, 0.22, 1.00)
            style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.30, 0.30, 0.33, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.40, 0.40, 0.43, 1.00)
            style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
            style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.60, 0.60, 0.63, 1.00)
            style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.70, 0.70, 0.73, 1.00)
            style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
            style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
            style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.45, 0.45, 0.47, 1.00)
            style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
            style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.40, 0.40, 0.43, 1.00)
            style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.45, 0.45, 0.48, 1.00)
            style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.30, 0.30, 0.33, 1.00)
            style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
            style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.40, 0.40, 0.43, 1.00)
            style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
            style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.30, 0.30, 0.33, 1.00)
            style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
            style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.65, 0.65, 0.68, 1.00)
            style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.75, 0.75, 0.78, 1.00)
            style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.65, 0.65, 0.68, 1.00)
            style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.75, 0.75, 0.78, 1.00)
            style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
            style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.20, 0.20, 0.22, 0.80)
            style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.25, 0.25, 0.27, 1.00)
            style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.35, 0.35, 0.38, 1.00)
            style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.40, 0.40, 0.43, 1.00)
        end  
    },
    {
        change = function()
            imgui.SwitchContext()
            local style = imgui.GetStyle()
        
            style.WindowPadding = imgui.ImVec2(15, 15)
            style.WindowRounding = 10.0
            style.ChildRounding = 6.0
            style.FramePadding = imgui.ImVec2(8, 7)
            style.FrameRounding = 8.0
            style.ItemSpacing = imgui.ImVec2(8, 8)
            style.ItemInnerSpacing = imgui.ImVec2(10, 6)
            style.IndentSpacing = 25.0
            style.ScrollbarSize = 13.0
            style.ScrollbarRounding = 12.0
            style.GrabMinSize = 10.0
            style.GrabRounding = 6.0
            style.PopupRounding = 8
            style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
            style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

            style.Colors[imgui.Col.Text]                   = imgui.ImVec4(0.85, 0.93, 0.85, 1.00)
            style.Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.55, 0.65, 0.55, 1.00)
            style.Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.13, 0.22, 0.13, alpha[0])
            style.Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.17, 0.27, 0.17, alpha[0])
            style.Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.15, 0.24, 0.15, 1.00)
            style.Colors[imgui.Col.Border]                 = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
            style.Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
            style.Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.19, 0.29, 0.19, 1.00)
            style.Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
            style.Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
            style.Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.15, 0.25, 0.15, 1.00)
            style.Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.15, 0.25, 0.15, 1.00)
            style.Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.18, 0.28, 0.18, 1.00)
            style.Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.15, 0.25, 0.15, 1.00)
            style.Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.15, 0.25, 0.15, 1.00)
            style.Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.30, 0.40, 0.30, 1.00)
            style.Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.35, 0.45, 0.35, 1.00)
            style.Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.50, 0.70, 0.50, 1.00)
            style.Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.50, 0.70, 0.50, 1.00)
            style.Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.55, 0.75, 0.55, 1.00)
            style.Colors[imgui.Col.Button]                 = imgui.ImVec4(0.19, 0.29, 0.19, 1.00)
            style.Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
            style.Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
            style.Colors[imgui.Col.Header]                 = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
            style.Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.28, 0.38, 0.28, 1.00)
            style.Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.30, 0.40, 0.30, 1.00)
            style.Colors[imgui.Col.Separator]              = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
            style.Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.30, 0.40, 0.30, 1.00)
            style.Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.35, 0.45, 0.35, 1.00)
            style.Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.19, 0.29, 0.19, 1.00)
            style.Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
            style.Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
            style.Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.60, 0.70, 0.60, 1.00)
            style.Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(0.65, 0.75, 0.65, 1.00)
            style.Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.60, 0.70, 0.60, 1.00)
            style.Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(0.65, 0.75, 0.65, 1.00)
            style.Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
            style.Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.15, 0.25, 0.15, 0.80)
            style.Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.19, 0.29, 0.19, 1.00)
            style.Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.23, 0.33, 0.23, 1.00)
            style.Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.25, 0.35, 0.25, 1.00)
        end  
    },
    
}


-- названия районов

function calculateZone(x, y, z)
    local streets = {{"Avispa Country Club", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
    {"Easter Bay Airport", -1315.420, -405.388, 15.406, -1264.400, -209.543, 25.406},
    {"Avispa Country Club", -2550.040, -355.493, 0.000, -2470.040, -318.493, 39.700},
    {"Easter Bay Airport", -1490.330, -209.543, 15.406, -1264.400, -148.388, 25.406},
    {"Garcia", -2395.140, -222.589, -5.3, -2354.090, -204.792, 200.000},
    {"Shady Cabin", -1632.830, -2263.440, -3.0, -1601.330, -2231.790, 200.000},
    {"East Los Santos", 2381.680, -1494.030, -89.084, 2421.030, -1454.350, 110.916},
    {"LVA Freight Depot", 1236.630, 1163.410, -89.084, 1277.050, 1203.280, 110.916},
    {"Blackfield Intersection", 1277.050, 1044.690, -89.084, 1315.350, 1087.630, 110.916},
    {"Avispa Country Club", -2470.040, -355.493, 0.000, -2270.040, -318.493, 46.100},
    {"Temple", 1252.330, -926.999, -89.084, 1357.000, -910.170, 110.916},
    {"Unity Station", 1692.620, -1971.800, -20.492, 1812.620, -1932.800, 79.508},
    {"LVA Freight Depot", 1315.350, 1044.690, -89.084, 1375.600, 1087.630, 110.916},
    {"Los Flores", 2581.730, -1454.350, -89.084, 2632.830, -1393.420, 110.916},
    {"Starfish Casino", 2437.390, 1858.100, -39.084, 2495.090, 1970.850, 60.916},
    {"Easter Bay Chemicals", -1132.820, -787.391, 0.000, -956.476, -768.027, 200.000},
    {"Downtown Los Santos", 1370.850, -1170.870, -89.084, 1463.900, -1130.850, 110.916},
    {"Esplanade East", -1620.300, 1176.520, -4.5, -1580.010, 1274.260, 200.000},
    {"Market Station", 787.461, -1410.930, -34.126, 866.009, -1310.210, 65.874},
    {"Linden Station", 2811.250, 1229.590, -39.594, 2861.250, 1407.590, 60.406},
    {"Montgomery Intersection", 1582.440, 347.457, 0.000, 1664.620, 401.750, 200.000},
    {"Frederick Bridge", 2759.250, 296.501, 0.000, 2774.250, 594.757, 200.000},
    {"Yellow Bell Station", 1377.480, 2600.430, -21.926, 1492.450, 2687.360, 78.074},
    {"Downtown Los Santos", 1507.510, -1385.210, 110.916, 1582.550, -1325.310, 335.916},
    {"Jefferson", 2185.330, -1210.740, -89.084, 2281.450, -1154.590, 110.916},
    {"Mulholland", 1318.130, -910.170, -89.084, 1357.000, -768.027, 110.916},
    {"Avispa Country Club", -2361.510, -417.199, 0.000, -2270.040, -355.493, 200.000},
    {"Jefferson", 1996.910, -1449.670, -89.084, 2056.860, -1350.720, 110.916},
    {"Julius Thruway West", 1236.630, 2142.860, -89.084, 1297.470, 2243.230, 110.916},
    {"Jefferson", 2124.660, -1494.030, -89.084, 2266.210, -1449.670, 110.916},
    {"Julius Thruway North", 1848.400, 2478.490, -89.084, 1938.800, 2553.490, 110.916},
    {"Rodeo", 422.680, -1570.200, -89.084, 466.223, -1406.050, 110.916},
    {"Cranberry Station", -2007.830, 56.306, 0.000, -1922.000, 224.782, 100.000},
    {"Downtown Los Santos", 1391.050, -1026.330, -89.084, 1463.900, -926.999, 110.916},
    {"Redsands West", 1704.590, 2243.230, -89.084, 1777.390, 2342.830, 110.916},
    {"Little Mexico", 1758.900, -1722.260, -89.084, 1812.620, -1577.590, 110.916},
    {"Blackfield Intersection", 1375.600, 823.228, -89.084, 1457.390, 919.447, 110.916},
    {"Los Santos International", 1974.630, -2394.330, -39.084, 2089.000, -2256.590, 60.916},
    {"Beacon Hill", -399.633, -1075.520, -1.489, -319.033, -977.516, 198.511},
    {"Rodeo", 334.503, -1501.950, -89.084, 422.680, -1406.050, 110.916},
    {"Richman", 225.165, -1369.620, -89.084, 334.503, -1292.070, 110.916},
    {"Downtown Los Santos", 1724.760, -1250.900, -89.084, 1812.620, -1150.870, 110.916},
    {"The Strip", 2027.400, 1703.230, -89.084, 2137.400, 1783.230, 110.916},
    {"Downtown Los Santos", 1378.330, -1130.850, -89.084, 1463.900, -1026.330, 110.916},
    {"Blackfield Intersection", 1197.390, 1044.690, -89.084, 1277.050, 1163.390, 110.916},
    {"Conference Center", 1073.220, -1842.270, -89.084, 1323.900, -1804.210, 110.916},
    {"Montgomery", 1451.400, 347.457, -6.1, 1582.440, 420.802, 200.000},
    {"Foster Valley", -2270.040, -430.276, -1.2, -2178.690, -324.114, 200.000},
    {"Blackfield Chapel", 1325.600, 596.349, -89.084, 1375.600, 795.010, 110.916},
    {"Los Santos International", 2051.630, -2597.260, -39.084, 2152.450, -2394.330, 60.916},
    {"Mulholland", 1096.470, -910.170, -89.084, 1169.130, -768.027, 110.916},
    {"Yellow Bell Gol Course", 1457.460, 2723.230, -89.084, 1534.560, 2863.230, 110.916},
    {"The Strip", 2027.400, 1783.230, -89.084, 2162.390, 1863.230, 110.916},
    {"Jefferson", 2056.860, -1210.740, -89.084, 2185.330, -1126.320, 110.916},
    {"Mulholland", 952.604, -937.184, -89.084, 1096.470, -860.619, 110.916},
    {"Aldea Malvada", -1372.140, 2498.520, 0.000, -1277.590, 2615.350, 200.000},
    {"Las Colinas", 2126.860, -1126.320, -89.084, 2185.330, -934.489, 110.916},
    {"Las Colinas", 1994.330, -1100.820, -89.084, 2056.860, -920.815, 110.916},
    {"Richman", 647.557, -954.662, -89.084, 768.694, -860.619, 110.916},
    {"LVA Freight Depot", 1277.050, 1087.630, -89.084, 1375.600, 1203.280, 110.916},
    {"Julius Thruway North", 1377.390, 2433.230, -89.084, 1534.560, 2507.230, 110.916},
    {"Willowfield", 2201.820, -2095.000, -89.084, 2324.000, -1989.900, 110.916},
    {"Julius Thruway North", 1704.590, 2342.830, -89.084, 1848.400, 2433.230, 110.916},
    {"Temple", 1252.330, -1130.850, -89.084, 1378.330, -1026.330, 110.916},
    {"Little Mexico", 1701.900, -1842.270, -89.084, 1812.620, -1722.260, 110.916},
    {"Queens", -2411.220, 373.539, 0.000, -2253.540, 458.411, 200.000},
    {"Las Venturas Airport", 1515.810, 1586.400, -12.500, 1729.950, 1714.560, 87.500},
    {"Richman", 225.165, -1292.070, -89.084, 466.223, -1235.070, 110.916},
    {"Temple", 1252.330, -1026.330, -89.084, 1391.050, -926.999, 110.916},
    {"East Los Santos", 2266.260, -1494.030, -89.084, 2381.680, -1372.040, 110.916},
    {"Julius Thruway East", 2623.180, 943.235, -89.084, 2749.900, 1055.960, 110.916},
    {"Willowfield", 2541.700, -1941.400, -89.084, 2703.580, -1852.870, 110.916},
    {"Las Colinas", 2056.860, -1126.320, -89.084, 2126.860, -920.815, 110.916},
    {"Julius Thruway East", 2625.160, 2202.760, -89.084, 2685.160, 2442.550, 110.916},
    {"Rodeo", 225.165, -1501.950, -89.084, 334.503, -1369.620, 110.916},
    {"Las Brujas", -365.167, 2123.010, -3.0, -208.570, 2217.680, 200.000},
    {"Julius Thruway East", 2536.430, 2442.550, -89.084, 2685.160, 2542.550, 110.916},
    {"Rodeo", 334.503, -1406.050, -89.084, 466.223, -1292.070, 110.916},
    {"Vinewood", 647.557, -1227.280, -89.084, 787.461, -1118.280, 110.916},
    {"Rodeo", 422.680, -1684.650, -89.084, 558.099, -1570.200, 110.916},
    {"Julius Thruway North", 2498.210, 2542.550, -89.084, 2685.160, 2626.550, 110.916},
    {"Downtown Los Santos", 1724.760, -1430.870, -89.084, 1812.620, -1250.900, 110.916},
    {"Rodeo", 225.165, -1684.650, -89.084, 312.803, -1501.950, 110.916},
    {"Jefferson", 2056.860, -1449.670, -89.084, 2266.210, -1372.040, 110.916},
    {"Hampton Barns", 603.035, 264.312, 0.000, 761.994, 366.572, 200.000},
    {"Temple", 1096.470, -1130.840, -89.084, 1252.330, -1026.330, 110.916},
    {"Kincaid Bridge", -1087.930, 855.370, -89.084, -961.950, 986.281, 110.916},
    {"Verona Beach", 1046.150, -1722.260, -89.084, 1161.520, -1577.590, 110.916},
    {"Commerce", 1323.900, -1722.260, -89.084, 1440.900, -1577.590, 110.916},
    {"Mulholland", 1357.000, -926.999, -89.084, 1463.900, -768.027, 110.916},
    {"Rodeo", 466.223, -1570.200, -89.084, 558.099, -1385.070, 110.916},
    {"Mulholland", 911.802, -860.619, -89.084, 1096.470, -768.027, 110.916},
    {"Mulholland", 768.694, -954.662, -89.084, 952.604, -860.619, 110.916},
    {"Julius Thruway South", 2377.390, 788.894, -89.084, 2537.390, 897.901, 110.916},
    {"Idlewood", 1812.620, -1852.870, -89.084, 1971.660, -1742.310, 110.916},
    {"Ocean Docks", 2089.000, -2394.330, -89.084, 2201.820, -2235.840, 110.916},
    {"Commerce", 1370.850, -1577.590, -89.084, 1463.900, -1384.950, 110.916},
    {"Julius Thruway North", 2121.400, 2508.230, -89.084, 2237.400, 2663.170, 110.916},
    {"Temple", 1096.470, -1026.330, -89.084, 1252.330, -910.170, 110.916},
    {"Glen Park", 1812.620, -1449.670, -89.084, 1996.910, -1350.720, 110.916},
    {"Easter Bay Airport", -1242.980, -50.096, 0.000, -1213.910, 578.396, 200.000},
    {"Martin Bridge", -222.179, 293.324, 0.000, -122.126, 476.465, 200.000},
    {"The Strip", 2106.700, 1863.230, -89.084, 2162.390, 2202.760, 110.916},
    {"Willowfield", 2541.700, -2059.230, -89.084, 2703.580, -1941.400, 110.916},
    {"Marina", 807.922, -1577.590, -89.084, 926.922, -1416.250, 110.916},
    {"Las Venturas Airport", 1457.370, 1143.210, -89.084, 1777.400, 1203.280, 110.916},
    {"Idlewood", 1812.620, -1742.310, -89.084, 1951.660, -1602.310, 110.916},
    {"Esplanade East", -1580.010, 1025.980, -6.1, -1499.890, 1274.260, 200.000},
    {"Downtown Los Santos", 1370.850, -1384.950, -89.084, 1463.900, -1170.870, 110.916},
    {"The Mako Span", 1664.620, 401.750, 0.000, 1785.140, 567.203, 200.000},
    {"Rodeo", 312.803, -1684.650, -89.084, 422.680, -1501.950, 110.916},
    {"Pershing Square", 1440.900, -1722.260, -89.084, 1583.500, -1577.590, 110.916},
    {"Mulholland", 687.802, -860.619, -89.084, 911.802, -768.027, 110.916},
    {"Gant Bridge", -2741.070, 1490.470, -6.1, -2616.400, 1659.680, 200.000},
    {"Las Colinas", 2185.330, -1154.590, -89.084, 2281.450, -934.489, 110.916},
    {"Mulholland", 1169.130, -910.170, -89.084, 1318.130, -768.027, 110.916},
    {"Julius Thruway North", 1938.800, 2508.230, -89.084, 2121.400, 2624.230, 110.916},
    {"Commerce", 1667.960, -1577.590, -89.084, 1812.620, -1430.870, 110.916},
    {"Rodeo", 72.648, -1544.170, -89.084, 225.165, -1404.970, 110.916},
    {"Roca Escalante", 2536.430, 2202.760, -89.084, 2625.160, 2442.550, 110.916},
    {"Rodeo", 72.648, -1684.650, -89.084, 225.165, -1544.170, 110.916},
    {"Market", 952.663, -1310.210, -89.084, 1072.660, -1130.850, 110.916},
    {"Las Colinas", 2632.740, -1135.040, -89.084, 2747.740, -945.035, 110.916},
    {"Mulholland", 861.085, -674.885, -89.084, 1156.550, -600.896, 110.916},
    {"King's", -2253.540, 373.539, -9.1, -1993.280, 458.411, 200.000},
    {"Redsands East", 1848.400, 2342.830, -89.084, 2011.940, 2478.490, 110.916},
    {"Downtown", -1580.010, 744.267, -6.1, -1499.890, 1025.980, 200.000},
    {"Conference Center", 1046.150, -1804.210, -89.084, 1323.900, -1722.260, 110.916},
    {"Richman", 647.557, -1118.280, -89.084, 787.461, -954.662, 110.916},
    {"Ocean Flats", -2994.490, 277.411, -9.1, -2867.850, 458.411, 200.000},
    {"Greenglass College", 964.391, 930.890, -89.084, 1166.530, 1044.690, 110.916},
    {"Glen Park", 1812.620, -1100.820, -89.084, 1994.330, -973.380, 110.916},
    {"LVA Freight Depot", 1375.600, 919.447, -89.084, 1457.370, 1203.280, 110.916},
    {"Regular Tom", -405.770, 1712.860, -3.0, -276.719, 1892.750, 200.000},
    {"Verona Beach", 1161.520, -1722.260, -89.084, 1323.900, -1577.590, 110.916},
    {"East Los Santos", 2281.450, -1372.040, -89.084, 2381.680, -1135.040, 110.916},
    {"Caligula's Palace", 2137.400, 1703.230, -89.084, 2437.390, 1783.230, 110.916},
    {"Idlewood", 1951.660, -1742.310, -89.084, 2124.660, -1602.310, 110.916},
    {"Pilgrim", 2624.400, 1383.230, -89.084, 2685.160, 1783.230, 110.916},
    {"Idlewood", 2124.660, -1742.310, -89.084, 2222.560, -1494.030, 110.916},
    {"Queens", -2533.040, 458.411, 0.000, -2329.310, 578.396, 200.000},
    {"Downtown", -1871.720, 1176.420, -4.5, -1620.300, 1274.260, 200.000},
    {"Commerce", 1583.500, -1722.260, -89.084, 1758.900, -1577.590, 110.916},
    {"East Los Santos", 2381.680, -1454.350, -89.084, 2462.130, -1135.040, 110.916},
    {"Marina", 647.712, -1577.590, -89.084, 807.922, -1416.250, 110.916},
    {"Richman", 72.648, -1404.970, -89.084, 225.165, -1235.070, 110.916},
    {"Vinewood", 647.712, -1416.250, -89.084, 787.461, -1227.280, 110.916},
    {"East Los Santos", 2222.560, -1628.530, -89.084, 2421.030, -1494.030, 110.916},
    {"Rodeo", 558.099, -1684.650, -89.084, 647.522, -1384.930, 110.916},
    {"Easter Tunnel", -1709.710, -833.034, -1.5, -1446.010, -730.118, 200.000},
    {"Rodeo", 466.223, -1385.070, -89.084, 647.522, -1235.070, 110.916},
    {"Redsands East", 1817.390, 2202.760, -89.084, 2011.940, 2342.830, 110.916},
    {"The Clown's Pocket", 2162.390, 1783.230, -89.084, 2437.390, 1883.230, 110.916},
    {"Idlewood", 1971.660, -1852.870, -89.084, 2222.560, -1742.310, 110.916},
    {"Montgomery Intersection", 1546.650, 208.164, 0.000, 1745.830, 347.457, 200.000},
    {"Willowfield", 2089.000, -2235.840, -89.084, 2201.820, -1989.900, 110.916},
    {"Temple", 952.663, -1130.840, -89.084, 1096.470, -937.184, 110.916},
    {"Prickle Pine", 1848.400, 2553.490, -89.084, 1938.800, 2863.230, 110.916},
    {"Los Santos International", 1400.970, -2669.260, -39.084, 2189.820, -2597.260, 60.916},
    {"Garver Bridge", -1213.910, 950.022, -89.084, -1087.930, 1178.930, 110.916},
    {"Garver Bridge", -1339.890, 828.129, -89.084, -1213.910, 1057.040, 110.916},
    {"Kincaid Bridge", -1339.890, 599.218, -89.084, -1213.910, 828.129, 110.916},
    {"Kincaid Bridge", -1213.910, 721.111, -89.084, -1087.930, 950.022, 110.916},
    {"Verona Beach", 930.221, -2006.780, -89.084, 1073.220, -1804.210, 110.916},
    {"Verdant Bluffs", 1073.220, -2006.780, -89.084, 1249.620, -1842.270, 110.916},
    {"Vinewood", 787.461, -1130.840, -89.084, 952.604, -954.662, 110.916},
    {"Vinewood", 787.461, -1310.210, -89.084, 952.663, -1130.840, 110.916},
    {"Commerce", 1463.900, -1577.590, -89.084, 1667.960, -1430.870, 110.916},
    {"Market", 787.461, -1416.250, -89.084, 1072.660, -1310.210, 110.916},
    {"Rockshore West", 2377.390, 596.349, -89.084, 2537.390, 788.894, 110.916},
    {"Julius Thruway North", 2237.400, 2542.550, -89.084, 2498.210, 2663.170, 110.916},
    {"East Beach", 2632.830, -1668.130, -89.084, 2747.740, -1393.420, 110.916},
    {"Fallow Bridge", 434.341, 366.572, 0.000, 603.035, 555.680, 200.000},
    {"Willowfield", 2089.000, -1989.900, -89.084, 2324.000, -1852.870, 110.916},
    {"Chinatown", -2274.170, 578.396, -7.6, -2078.670, 744.170, 200.000},
    {"El Castillo del Diablo", -208.570, 2337.180, 0.000, 8.430, 2487.180, 200.000},
    {"Ocean Docks", 2324.000, -2145.100, -89.084, 2703.580, -2059.230, 110.916},
    {"Easter Bay Chemicals", -1132.820, -768.027, 0.000, -956.476, -578.118, 200.000},
    {"The Visage", 1817.390, 1703.230, -89.084, 2027.400, 1863.230, 110.916},
    {"Ocean Flats", -2994.490, -430.276, -1.2, -2831.890, -222.589, 200.000},
    {"Richman", 321.356, -860.619, -89.084, 687.802, -768.027, 110.916},
    {"Green Palms", 176.581, 1305.450, -3.0, 338.658, 1520.720, 200.000},
    {"Richman", 321.356, -768.027, -89.084, 700.794, -674.885, 110.916},
    {"Starfish Casino", 2162.390, 1883.230, -89.084, 2437.390, 2012.180, 110.916},
    {"East Beach", 2747.740, -1668.130, -89.084, 2959.350, -1498.620, 110.916},
    {"Jefferson", 2056.860, -1372.040, -89.084, 2281.450, -1210.740, 110.916},
    {"Downtown Los Santos", 1463.900, -1290.870, -89.084, 1724.760, -1150.870, 110.916},
    {"Downtown Los Santos", 1463.900, -1430.870, -89.084, 1724.760, -1290.870, 110.916},
    {"Garver Bridge", -1499.890, 696.442, -179.615, -1339.890, 925.353, 20.385},
    {"Julius Thruway South", 1457.390, 823.228, -89.084, 2377.390, 863.229, 110.916},
    {"East Los Santos", 2421.030, -1628.530, -89.084, 2632.830, -1454.350, 110.916},
    {"Greenglass College", 964.391, 1044.690, -89.084, 1197.390, 1203.220, 110.916},
    {"Las Colinas", 2747.740, -1120.040, -89.084, 2959.350, -945.035, 110.916},
    {"Mulholland", 737.573, -768.027, -89.084, 1142.290, -674.885, 110.916},
    {"Ocean Docks", 2201.820, -2730.880, -89.084, 2324.000, -2418.330, 110.916},
    {"East Los Santos", 2462.130, -1454.350, -89.084, 2581.730, -1135.040, 110.916},
    {"Ganton", 2222.560, -1722.330, -89.084, 2632.830, -1628.530, 110.916},
    {"Avispa Country Club", -2831.890, -430.276, -6.1, -2646.400, -222.589, 200.000},
    {"Willowfield", 1970.620, -2179.250, -89.084, 2089.000, -1852.870, 110.916},
    {"Esplanade North", -1982.320, 1274.260, -4.5, -1524.240, 1358.900, 200.000},
    {"The High Roller", 1817.390, 1283.230, -89.084, 2027.390, 1469.230, 110.916},
    {"Ocean Docks", 2201.820, -2418.330, -89.084, 2324.000, -2095.000, 110.916},
    {"Last Dime Motel", 1823.080, 596.349, -89.084, 1997.220, 823.228, 110.916},
    {"Bayside Marina", -2353.170, 2275.790, 0.000, -2153.170, 2475.790, 200.000},
    {"King's", -2329.310, 458.411, -7.6, -1993.280, 578.396, 200.000},
    {"El Corona", 1692.620, -2179.250, -89.084, 1812.620, -1842.270, 110.916},
    {"Blackfield Chapel", 1375.600, 596.349, -89.084, 1558.090, 823.228, 110.916},
    {"The Pink Swan", 1817.390, 1083.230, -89.084, 2027.390, 1283.230, 110.916},
    {"Julius Thruway West", 1197.390, 1163.390, -89.084, 1236.630, 2243.230, 110.916},
    {"Los Flores", 2581.730, -1393.420, -89.084, 2747.740, -1135.040, 110.916},
    {"The Visage", 1817.390, 1863.230, -89.084, 2106.700, 2011.830, 110.916},
    {"Prickle Pine", 1938.800, 2624.230, -89.084, 2121.400, 2861.550, 110.916},
    {"Verona Beach", 851.449, -1804.210, -89.084, 1046.150, -1577.590, 110.916},
    {"Robada Intersection", -1119.010, 1178.930, -89.084, -862.025, 1351.450, 110.916},
    {"Linden Side", 2749.900, 943.235, -89.084, 2923.390, 1198.990, 110.916},
    {"Ocean Docks", 2703.580, -2302.330, -89.084, 2959.350, -2126.900, 110.916},
    {"Willowfield", 2324.000, -2059.230, -89.084, 2541.700, -1852.870, 110.916},
    {"King's", -2411.220, 265.243, -9.1, -1993.280, 373.539, 200.000},
    {"Commerce", 1323.900, -1842.270, -89.084, 1701.900, -1722.260, 110.916},
    {"Mulholland", 1269.130, -768.027, -89.084, 1414.070, -452.425, 110.916},
    {"Marina", 647.712, -1804.210, -89.084, 851.449, -1577.590, 110.916},
    {"Battery Point", -2741.070, 1268.410, -4.5, -2533.040, 1490.470, 200.000},
    {"The Four Dragons Casino", 1817.390, 863.232, -89.084, 2027.390, 1083.230, 110.916},
    {"Blackfield", 964.391, 1203.220, -89.084, 1197.390, 1403.220, 110.916},
    {"Julius Thruway North", 1534.560, 2433.230, -89.084, 1848.400, 2583.230, 110.916},
    {"Yellow Bell Gol Course", 1117.400, 2723.230, -89.084, 1457.460, 2863.230, 110.916},
    {"Idlewood", 1812.620, -1602.310, -89.084, 2124.660, -1449.670, 110.916},
    {"Redsands West", 1297.470, 2142.860, -89.084, 1777.390, 2243.230, 110.916},
    {"Doherty", -2270.040, -324.114, -1.2, -1794.920, -222.589, 200.000},
    {"Hilltop Farm", 967.383, -450.390, -3.0, 1176.780, -217.900, 200.000},
    {"Las Barrancas", -926.130, 1398.730, -3.0, -719.234, 1634.690, 200.000},
    {"Pirates in Men's Pants", 1817.390, 1469.230, -89.084, 2027.400, 1703.230, 110.916},
    {"City Hall", -2867.850, 277.411, -9.1, -2593.440, 458.411, 200.000},
    {"Avispa Country Club", -2646.400, -355.493, 0.000, -2270.040, -222.589, 200.000},
    {"The Strip", 2027.400, 863.229, -89.084, 2087.390, 1703.230, 110.916},
    {"Hashbury", -2593.440, -222.589, -1.0, -2411.220, 54.722, 200.000},
    {"Los Santos International", 1852.000, -2394.330, -89.084, 2089.000, -2179.250, 110.916},
    {"Whitewood Estates", 1098.310, 1726.220, -89.084, 1197.390, 2243.230, 110.916},
    {"Sherman Reservoir", -789.737, 1659.680, -89.084, -599.505, 1929.410, 110.916},
    {"El Corona", 1812.620, -2179.250, -89.084, 1970.620, -1852.870, 110.916},
    {"Downtown", -1700.010, 744.267, -6.1, -1580.010, 1176.520, 200.000},
    {"Foster Valley", -2178.690, -1250.970, 0.000, -1794.920, -1115.580, 200.000},
    {"Las Payasadas", -354.332, 2580.360, 2.0, -133.625, 2816.820, 200.000},
    {"Valle Ocultado", -936.668, 2611.440, 2.0, -715.961, 2847.900, 200.000},
    {"Blackfield Intersection", 1166.530, 795.010, -89.084, 1375.600, 1044.690, 110.916},
    {"Ganton", 2222.560, -1852.870, -89.084, 2632.830, -1722.330, 110.916},
    {"Easter Bay Airport", -1213.910, -730.118, 0.000, -1132.820, -50.096, 200.000},
    {"Redsands East", 1817.390, 2011.830, -89.084, 2106.700, 2202.760, 110.916},
    {"Esplanade East", -1499.890, 578.396, -79.615, -1339.890, 1274.260, 20.385},
    {"Caligula's Palace", 2087.390, 1543.230, -89.084, 2437.390, 1703.230, 110.916},
    {"Royal Casino", 2087.390, 1383.230, -89.084, 2437.390, 1543.230, 110.916},
    {"Richman", 72.648, -1235.070, -89.084, 321.356, -1008.150, 110.916},
    {"Starfish Casino", 2437.390, 1783.230, -89.084, 2685.160, 2012.180, 110.916},
    {"Mulholland", 1281.130, -452.425, -89.084, 1641.130, -290.913, 110.916},
    {"Downtown", -1982.320, 744.170, -6.1, -1871.720, 1274.260, 200.000},
    {"Hankypanky Point", 2576.920, 62.158, 0.000, 2759.250, 385.503, 200.000},
    {"K.A.C.C. Military Fuels", 2498.210, 2626.550, -89.084, 2749.900, 2861.550, 110.916},
    {"Harry Gold Parkway", 1777.390, 863.232, -89.084, 1817.390, 2342.830, 110.916},
    {"Bayside Tunnel", -2290.190, 2548.290, -89.084, -1950.190, 2723.290, 110.916},
    {"Ocean Docks", 2324.000, -2302.330, -89.084, 2703.580, -2145.100, 110.916},
    {"Richman", 321.356, -1044.070, -89.084, 647.557, -860.619, 110.916},
    {"Randolph Industrial Estate", 1558.090, 596.349, -89.084, 1823.080, 823.235, 110.916},
    {"East Beach", 2632.830, -1852.870, -89.084, 2959.350, -1668.130, 110.916},
    {"Flint Water", -314.426, -753.874, -89.084, -106.339, -463.073, 110.916},
    {"Blueberry", 19.607, -404.136, 3.8, 349.607, -220.137, 200.000},
    {"Linden Station", 2749.900, 1198.990, -89.084, 2923.390, 1548.990, 110.916},
    {"Glen Park", 1812.620, -1350.720, -89.084, 2056.860, -1100.820, 110.916},
    {"Downtown", -1993.280, 265.243, -9.1, -1794.920, 578.396, 200.000},
    {"Redsands West", 1377.390, 2243.230, -89.084, 1704.590, 2433.230, 110.916},
    {"Richman", 321.356, -1235.070, -89.084, 647.522, -1044.070, 110.916},
    {"Gant Bridge", -2741.450, 1659.680, -6.1, -2616.400, 2175.150, 200.000},
    {"Lil' Probe Inn", -90.218, 1286.850, -3.0, 153.859, 1554.120, 200.000},
    {"Flint Intersection", -187.700, -1596.760, -89.084, 17.063, -1276.600, 110.916},
    {"Las Colinas", 2281.450, -1135.040, -89.084, 2632.740, -945.035, 110.916},
    {"Sobell Rail Yards", 2749.900, 1548.990, -89.084, 2923.390, 1937.250, 110.916},
    {"The Emerald Isle", 2011.940, 2202.760, -89.084, 2237.400, 2508.230, 110.916},
    {"El Castillo del Diablo", -208.570, 2123.010, -7.6, 114.033, 2337.180, 200.000},
    {"Santa Flora", -2741.070, 458.411, -7.6, -2533.040, 793.411, 200.000},
    {"Playa del Seville", 2703.580, -2126.900, -89.084, 2959.350, -1852.870, 110.916},
    {"Market", 926.922, -1577.590, -89.084, 1370.850, -1416.250, 110.916},
    {"Queens", -2593.440, 54.722, 0.000, -2411.220, 458.411, 200.000},
    {"Pilson Intersection", 1098.390, 2243.230, -89.084, 1377.390, 2507.230, 110.916},
    {"Spinybed", 2121.400, 2663.170, -89.084, 2498.210, 2861.550, 110.916},
    {"Pilgrim", 2437.390, 1383.230, -89.084, 2624.400, 1783.230, 110.916},
    {"Blackfield", 964.391, 1403.220, -89.084, 1197.390, 1726.220, 110.916},
    {"'The Big Ear'", -410.020, 1403.340, -3.0, -137.969, 1681.230, 200.000},
    {"Dillimore", 580.794, -674.885, -9.5, 861.085, -404.790, 200.000},
    {"El Quebrados", -1645.230, 2498.520, 0.000, -1372.140, 2777.850, 200.000},
    {"Esplanade North", -2533.040, 1358.900, -4.5, -1996.660, 1501.210, 200.000},
    {"Easter Bay Airport", -1499.890, -50.096, -1.0, -1242.980, 249.904, 200.000},
    {"Fisher's Lagoon", 1916.990, -233.323, -100.000, 2131.720, 13.800, 200.000},
    {"Mulholland", 1414.070, -768.027, -89.084, 1667.610, -452.425, 110.916},
    {"East Beach", 2747.740, -1498.620, -89.084, 2959.350, -1120.040, 110.916},
    {"San Andreas Sound", 2450.390, 385.503, -100.000, 2759.250, 562.349, 200.000},
    {"Shady Creeks", -2030.120, -2174.890, -6.1, -1820.640, -1771.660, 200.000},
    {"Market", 1072.660, -1416.250, -89.084, 1370.850, -1130.850, 110.916},
    {"Rockshore West", 1997.220, 596.349, -89.084, 2377.390, 823.228, 110.916},
    {"Prickle Pine", 1534.560, 2583.230, -89.084, 1848.400, 2863.230, 110.916},
    {"Easter Basin", -1794.920, -50.096, -1.04, -1499.890, 249.904, 200.000},
    {"Leafy Hollow", -1166.970, -1856.030, 0.000, -815.624, -1602.070, 200.000},
    {"LVA Freight Depot", 1457.390, 863.229, -89.084, 1777.400, 1143.210, 110.916},
    {"Prickle Pine", 1117.400, 2507.230, -89.084, 1534.560, 2723.230, 110.916},
    {"Blueberry", 104.534, -220.137, 2.3, 349.607, 152.236, 200.000},
    {"El Castillo del Diablo", -464.515, 2217.680, 0.000, -208.570, 2580.360, 200.000},
    {"Downtown", -2078.670, 578.396, -7.6, -1499.890, 744.267, 200.000},
    {"Rockshore East", 2537.390, 676.549, -89.084, 2902.350, 943.235, 110.916},
    {"San Fierro Bay", -2616.400, 1501.210, -3.0, -1996.660, 1659.680, 200.000},
    {"Paradiso", -2741.070, 793.411, -6.1, -2533.040, 1268.410, 200.000},
    {"The Camel's Toe", 2087.390, 1203.230, -89.084, 2640.400, 1383.230, 110.916},
    {"Old Venturas Strip", 2162.390, 2012.180, -89.084, 2685.160, 2202.760, 110.916},
    {"Juniper Hill", -2533.040, 578.396, -7.6, -2274.170, 968.369, 200.000},
    {"Juniper Hollow", -2533.040, 968.369, -6.1, -2274.170, 1358.900, 200.000},
    {"Roca Escalante", 2237.400, 2202.760, -89.084, 2536.430, 2542.550, 110.916},
    {"Julius Thruway East", 2685.160, 1055.960, -89.084, 2749.900, 2626.550, 110.916},
    {"Verona Beach", 647.712, -2173.290, -89.084, 930.221, -1804.210, 110.916},
    {"Foster Valley", -2178.690, -599.884, -1.2, -1794.920, -324.114, 200.000},
    {"Arco del Oeste", -901.129, 2221.860, 0.000, -592.090, 2571.970, 200.000},
    {"Fallen Tree", -792.254, -698.555, -5.3, -452.404, -380.043, 200.000},
    {"The Farm", -1209.670, -1317.100, 114.981, -908.161, -787.391, 251.981},
    {"The Sherman Dam", -968.772, 1929.410, -3.0, -481.126, 2155.260, 200.000},
    {"Esplanade North", -1996.660, 1358.900, -4.5, -1524.240, 1592.510, 200.000},
    {"Financial", -1871.720, 744.170, -6.1, -1701.300, 1176.420, 300.000},
    {"Garcia", -2411.220, -222.589, -1.14, -2173.040, 265.243, 200.000},
    {"Montgomery", 1119.510, 119.526, -3.0, 1451.400, 493.323, 200.000},
    {"Creek", 2749.900, 1937.250, -89.084, 2921.620, 2669.790, 110.916},
    {"Los Santos International", 1249.620, -2394.330, -89.084, 1852.000, -2179.250, 110.916},
    {"Santa Maria Beach", 72.648, -2173.290, -89.084, 342.648, -1684.650, 110.916},
    {"Mulholland Intersection", 1463.900, -1150.870, -89.084, 1812.620, -768.027, 110.916},
    {"Angel Pine", -2324.940, -2584.290, -6.1, -1964.220, -2212.110, 200.000},
    {"Verdant Meadows", 37.032, 2337.180, -3.0, 435.988, 2677.900, 200.000},
    {"Octane Springs", 338.658, 1228.510, 0.000, 664.308, 1655.050, 200.000},
    {"Come-A-Lot", 2087.390, 943.235, -89.084, 2623.180, 1203.230, 110.916},
    {"Redsands West", 1236.630, 1883.110, -89.084, 1777.390, 2142.860, 110.916},
    {"Santa Maria Beach", 342.648, -2173.290, -89.084, 647.712, -1684.650, 110.916},
    {"Verdant Bluffs", 1249.620, -2179.250, -89.084, 1692.620, -1842.270, 110.916},
    {"Las Venturas Airport", 1236.630, 1203.280, -89.084, 1457.370, 1883.110, 110.916},
    {"Flint Range", -594.191, -1648.550, 0.000, -187.700, -1276.600, 200.000},
    {"Verdant Bluffs", 930.221, -2488.420, -89.084, 1249.620, -2006.780, 110.916},
    {"Palomino Creek", 2160.220, -149.004, 0.000, 2576.920, 228.322, 200.000},
    {"Ocean Docks", 2373.770, -2697.090, -89.084, 2809.220, -2330.460, 110.916},
    {"Easter Bay Airport", -1213.910, -50.096, -4.5, -947.980, 578.396, 200.000},
    {"Whitewood Estates", 883.308, 1726.220, -89.084, 1098.310, 2507.230, 110.916},
    {"Calton Heights", -2274.170, 744.170, -6.1, -1982.320, 1358.900, 200.000},
    {"Easter Basin", -1794.920, 249.904, -9.1, -1242.980, 578.396, 200.000},
    {"Los Santos Inlet", -321.744, -2224.430, -89.084, 44.615, -1724.430, 110.916},
    {"Doherty", -2173.040, -222.589, -1.0, -1794.920, 265.243, 200.000},
    {"Mount Chiliad", -2178.690, -2189.910, -47.917, -2030.120, -1771.660, 576.083},
    {"Fort Carson", -376.233, 826.326, -3.0, 123.717, 1220.440, 200.000},
    {"Foster Valley", -2178.690, -1115.580, 0.000, -1794.920, -599.884, 200.000},
    {"Ocean Flats", -2994.490, -222.589, -1.0, -2593.440, 277.411, 200.000},
    {"Fern Ridge", 508.189, -139.259, 0.000, 1306.660, 119.526, 200.000},
    {"Bayside", -2741.070, 2175.150, 0.000, -2353.170, 2722.790, 200.000},
    {"Las Venturas Airport", 1457.370, 1203.280, -89.084, 1777.390, 1883.110, 110.916},
    {"Blueberry Acres", -319.676, -220.137, 0.000, 104.534, 293.324, 200.000},
    {"Palisades", -2994.490, 458.411, -6.1, -2741.070, 1339.610, 200.000},
    {"North Rock", 2285.370, -768.027, 0.000, 2770.590, -269.740, 200.000},
    {"Hunter Quarry", 337.244, 710.840, -115.239, 860.554, 1031.710, 203.761},
    {"Los Santos International", 1382.730, -2730.880, -89.084, 2201.820, -2394.330, 110.916},
    {"Missionary Hill", -2994.490, -811.276, 0.000, -2178.690, -430.276, 200.000},
    {"San Fierro Bay", -2616.400, 1659.680, -3.0, -1996.660, 2175.150, 200.000},
    {"Restricted Area", -91.586, 1655.050, -50.000, 421.234, 2123.010, 250.000},
    {"Mount Chiliad", -2997.470, -1115.580, -47.917, -2178.690, -971.913, 576.083},
    {"Mount Chiliad", -2178.690, -1771.660, -47.917, -1936.120, -1250.970, 576.083},
    {"Easter Bay Airport", -1794.920, -730.118, -3.0, -1213.910, -50.096, 200.000},
    {"The Panopticon", -947.980, -304.320, -1.1, -319.676, 327.071, 200.000},
    {"Shady Creeks", -1820.640, -2643.680, -8.0, -1226.780, -1771.660, 200.000},
    {"Back o Beyond", -1166.970, -2641.190, 0.000, -321.744, -1856.030, 200.000},
    {"Mount Chiliad", -2994.490, -2189.910, -47.917, -2178.690, -1115.580, 576.083}}
    for i, v in ipairs(streets) do
        if (x >= v[2]) and (y >= v[3]) and (z >= v[4]) and (x <= v[5]) and (y <= v[6]) and (z <= v[7]) then
            return v[1]
        end
    end
    return "Unknown"
end

-- название городов


function calccity(x, y, z)
    local city =  {{"Tierra Robada", -1213.910, 596.349, -242.990, -480.539, 1659.680, 900.000},
    {"Flint County", -1213.910, -2892.970, -242.990, 44.615, -768.027, 900.000},
    {"Whetstone", -2997.470, -2892.970, -242.990, -1213.910, -1115.580, 900.000},
    {"Bone County", -480.539, 596.349, -242.990, 869.461, 2993.870, 900.000},
    {"Tierra Robada", -2997.470, 1659.680, -242.990, -480.539, 2993.870, 900.000},
    {"San Fierro", -2997.470, -1115.580, -242.990, -1213.910, 1659.680, 900.000},
    {"Las Venturas", 869.461, 596.349, -242.990, 2997.060, 2993.870, 900.000},
    {"Red County", -1213.910, -768.027, -242.990, 2997.060, 596.349, 900.000},
    {"Los Santos", 44.615, -2892.970, -242.990, 2997.060, -768.027, 900.000}}
    for i, v in ipairs(city) do
        if (x >= v[2]) and (y >= v[3]) and (z >= v[4]) and (x <= v[5]) and (y <= v[6]) and (z <= v[7]) then
            return v[1]
        end
    end
    return "Unknown"
end

-- статьи умного розыска


-- инициализация темы

imgui.OnInitialize(function()
    fa.Init()
    theme[decorListNumber[0]+1].change()
end)
