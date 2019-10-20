cmd = {}
cmd['keywords']={'зв','звон','звонки','звонк'}
cmd['level'] = 1

function cmd.handler(msg) 
	msg = libkb.fix_names(msg)
	if msg.user_text == 'укр' then
		out = [[
1) 9:00 - 10:00
2) 10:10 - 11:10
Обед: 11:10 - 11:40
3) 11:40 - 12:40]]
		libkb.apisay{out,msg.toho}
		return 0
	end
    out = [[
1) 
&#8195;9:00-9:45
&#8195;9:50-10:35
2) 
&#8195;10:45-11:30
&#8195;11:35-12:20
Обед 
&#8195;12:20-12:55 
3)
&#8195;12:55-13:40
&#8195;13:45-14:30
4)
&#8195;14:40-15:25
&#8195;15:30-16:15]]

    libkb.apisay{out,msg.toho}
end
reg_command(cmd)
