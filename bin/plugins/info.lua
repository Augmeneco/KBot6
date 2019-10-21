cmd = {}
cmd['keywords']={'инфа'}
cmd['level'] = 1

function cmd.handler(msg)
    msg = libkb.fix_names(msg)
    math.randomseed(os.clock())
    libkb.apisay{"Вероятность того, что "..msg.user_text..", равна "..math.random(1,146)..'%',msg.toho}
end

reg_command(cmd)