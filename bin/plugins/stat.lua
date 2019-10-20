cmd = {}
cmd['keywords']={'стата', 'статус', 'стат'}
cmd['level'] = 1

function cmd.handler(msg)
    local status = io.open('/proc/self/status','r'):read('*a')
    local BOT_USE = status:match('VmRSS:%s+(%d+) kB')
    status = [[
        [ Статистика ]
        Процессор:
        &#8195;UPTIME&#8195;Температура: TEMP °С
        ОЗУ:
        &#8195;Всего: RAM_FULL МБ
        &#8195;Использовано: RAM_USE МБ
        &#8195;Свободно: RAM_FREE МБ
        &#8195;Использовано ботом: BOT_USE кБ
        Бот:
        &#8195;Чат: CHAT
        &#8195;Время работы: WORK_TIME
    ]]

    status = status:gsub('BOT_USE',BOT_USE):gsub('UPTIME',io.popen('uptime'):read('*a'))

    local clock = os.time()-(BOT_START_TIME-10800)
    local WORK_TIME = math.floor(clock/(60*60*24))..' дней | '..math.floor((clock/(60*60))%24)..' часов | '..math.floor((clock/60)%60)..' минут | '..math.floor((clock)%60)..' секунд'
    status = status:gsub('WORK_TIME',WORK_TIME):gsub('CHAT',msg.peer_id)

    local RAM = {}
    for i in io.popen('free -m'):read('*a'):gmatch('%d+') do RAM[#RAM+1]=i if #RAM==2 then break end end
    status = status:gsub('RAM_FULL',RAM[1]):gsub('RAM_USE',RAM[2]):gsub('RAM_FREE',RAM[1]-RAM[2])
    status = status:gsub('TEMP',io.open('/sys/class/thermal/thermal_zone0/temp','r'):read('*a')/1000)
    vkapi('messages.send', {message=status, peer_id=msg.peer_id})
end

reg_command(cmd)