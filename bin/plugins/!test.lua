log_write('Lua version is '.._VERSION)
local inspect = require('plugins.inspect')
local cjson = require('cjson')
function handler(msg)
  print('handler called');
  change_handler(msg.from_id, 'main')
end

reg_handler('first', handler)

--print(net_post('https://httpbin.org/post').text)

--print(inspect(vkapi('groups.getTokenPermissions')))
--log_write('zhozh')

cmd = {}
cmd['keywords']={'ror', 'уку'}
cmd['level'] = 1
function cmd.handler(msg)
  print(inspect(msg))
  print(inspect(vkapi('messages.send', {peer_id=msg.peer_id, message='ИдИ нАхУй!'})))
end

reg_command(cmd)

--print(net_get('http://example.com/').text)