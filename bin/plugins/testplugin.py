import kb



def f():
	pass
kb.reg_handler('first1', f)

class SuperCmd:
	level = 1
	keywords = ['йцй']
	def handler(self, msg):
		#print(msg)
		print(kb.vkapi('messages.send',{"message":'test',"peer_id":msg['peer_id']}))

kb.reg_command(SuperCmd())

#kb.log_write('sos')

#print(kb.vkapi('groups.getTokenPermissions'))

#print(config)