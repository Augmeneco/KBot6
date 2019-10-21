json = require("dkjson")
cmd = {}
cmd['keywords']={'расп'}
cmd['level'] = 1

function cmd.handler(msg) 
    msg = libkb.fix_names(msg)

    config = json.decode(io.open('plugins/rasp/rasp.json','r'):read('*a'))
    zam_data = split(msg.user_text,' ')
    if zam_data[1] == 'сет' and msg.userid == 354255965 then
        day = zam_data[2]
        table.remove(zam_data,1)
        table.remove(zam_data,1)
        text = table.concat(zam_data,' ')
        config.zam[tonumber(day)] = text
        io.popen('echo \''..json.encode(config)..'\'> plugins/rasp/rasp.json'):read('*a')
        libkb.apisay{'Заметка добавлена',msg.toho}
        return 0
    end
    if zam_data[1] == 'дел' and msg.userid == 354255965 then
        day = zam_data[2]
        config.zam[tonumber(day)] = false
        --io.open('plugins/rasp/rasp.json','w'):write(json.encode(config))
        
        io.popen('echo \''..json.encode(config)..'\'> plugins/rasp/rasp.json'):read('*a')
        
        libkb.apisay{'Заметка удалена',msg.toho}
        return 0
    end
    mode = config.mode
    date_now = split(os.date("%A|%d"),'|')
    if config.day ~= date_now[2] and date_now[1] == 'Sunday' then
        if mode == 1 then mode = 2 else mode = 1 end
        config.mode = mode
        config.day = date_now[2]
        io.popen('echo \''..json.encode(config)..'\'> plugins/rasp/rasp.json'):read('*a')
        libkb.apisay{'[LOG] Тип недели изменен на '..mode,msg.toho}
    end
    if mode == 1 then
        mode_text = 'Числитель'
    else
        mode_text = 'Знаменатель'
    end
    rasp = {
        {
            {
                {'МДК 01.01 МИКРОСХЕМОТЕХНИКА',611},
                {'МДК 01.01 МИКРОСХЕМОТЕХНИКА',611},
                {'МДК 01.01 ИСТОЧНИКИ ПИТАНИЯ',505}
            },
            {
                {'ФИЗИЧЕСКАЯ КУЛЬТУРА','С/З'},
                {'ОСНОВЫ ФИЛОСОФИИ',616},
                {'МДК 01.02 КОНСТРУИРОВАНИЕ, ПРОИЗВОДСТВО, ЭКСПЛУАТАЦИЯ СВТ',718},
                {'ИНОСТРАННЫЙ ЯЗЫК',714}
            },
            {
                {false},
                {'МДК 02.01 АРХИТЕКТУРА ЭВМ',712},
                {'ОСНОВЫ ФИЛОСОФИИ',616},
                {'ИНОСТРАННЫЙ ЯЗЫК',515}
            },
            {
                {'МДК 01.02 КОНСТРУИРОВАНИЕ, ПРОИЗВОДСТВО, ЭКСПЛУАТАЦИЯ СВТ',718},
                {'МДК 01.01 ИСТОЧНИКИ ПИТАНИЯ',505}
            },
            {
                {'МДК 03.02 СИСТЕМЫ УПРАВЛЕНИЯ БАЗАМИ ДАННЫХ',308},
                {'МДК 03.02 СИСТЕМЫ УПРАВЛЕНИЯ БАЗАМИ ДАННЫХ',308},
                {'МДК 02.01 ПРОГРАММИРОВАНИЕ МИКРОКОНТРОЛЛЕРОВ',521},
                {'МДК 01.01 МИКРОСХЕМОТЕХНИКА',521}
            },
            {
                {'МДК 02.01 АРХИТЕКТУРА ЭВМ',712},
                {'МДК 01.02 КОНСТРУИРОВАНИЕ, ПРОИЗВОДСТВО, ЭКСПЛУАТАЦИЯ СВТ',718},
                {'МДК 03.02 СИСТЕМЫ УПРАВЛЕНИЯ БАЗАМИ ДАННЫХ',308}
            }
        },
        {
            {
                {'МДК 01.01 МИКРОСХЕМОТЕХНИКА',611},
                {'МДК 01.01 МИКРОСХЕМОТЕХНИКА',611},
                {'МДК 01.01 ИСТОЧНИКИ ПИТАНИЯ',505}
            },
            {
                {'ФИЗИЧЕСКАЯ КУЛЬТУРА','С/З'},
                {'ОСНОВЫ ФИЛОСОФИИ',616},
                {'МДК 01.02 КОНСТРУИРОВАНИЕ, ПРОИЗВОДСТВО, ЭКСПЛУАТАЦИЯ СВТ',718},
                {'ИНОСТРАННЫЙ ЯЗЫК',714}
            },
            {
                {false},
                {'МДК 02.01 АРХИТЕКТУРА ЭВМ',712},
                {'МДК 01.02 КОНСТРУИРОВАНИЕ, ПРОИЗВОДСТВО, ЭКСПЛУАТАЦИЯ СВТ',718},
                {'ИНОСТРАННЫЙ ЯЗЫК',515}
            },
            {
                {'МДК 01.02 КОНСТРУИРОВАНИЕ, ПРОИЗВОДСТВО, ЭКСПЛУАТАЦИЯ СВТ',718},
                {'МДК 01.01 ИСТОЧНИКИ ПИТАНИЯ',505},
                {'МДК 02.01 АРХИТЕКТУРА ЭВМ',712}
            },
            {
                {false},
                {'МДК 03.02 СИСТЕМЫ УПРАВЛЕНИЯ БАЗАМИ ДАННЫХ',308},
                {'МДК 02.01 ПРОГРАММИРОВАНИЕ МИКРОКОНТРОЛЛЕРОВ',521},
                {'МДК 01.01 МИКРОСХЕМОТЕХНИКА',521}
            },
            {
                {'МДК 02.01 АРХИТЕКТУРА ЭВМ',712},
                {'МДК 01.02 КОНСТРУИРОВАНИЕ, ПРОИЗВОДСТВО, ЭКСПЛУАТАЦИЯ СВТ',718},
                {'МДК 03.02 СИСТЕМЫ УПРАВЛЕНИЯ БАЗАМИ ДАННЫХ',308}
            }
        }
    }
    
    day_names_ru = {'Понедельник','Вторник','Среда','Четверг','Пятница','Суббота'}

    if #msg.user_text == 0 then 
        today = tonumber(os.date("%w"))
        if today == 0 then
            libkb.apisay{'Сегодня выходной :(',msg.toho}
            return 0
        end
    else
        today = tonumber(split(msg.user_text,' ')[1])
    end
    out = '[ '..mode_text..' ]<br><br>'..day_names_ru[today]..':<br>'
    for key, value in pairs(rasp[mode][today]) do
        if value[1] ~= false then
            out = out..key..') '..value[1]..' ('..value[2]..')<br>'
        else
        	out = out..key..') Пары нет <br>'
        end
    end

    if config.zam[today] ~= false then
        out = out..'<br>Заметка на этот день:<br>'..config.zam[today]
    end

    libkb.apisay{out,msg.toho}

end
reg_command(cmd)
