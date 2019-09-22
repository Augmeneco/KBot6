import kb
import libkbot as libkb

class punto:
	level = 1
	keywords = ['pun','пун']
	def handler(self, msg):

		if 'reply_message' in msg:
			message = msg['reply_message']['text']
		else:
			if len(msg['fwd_messages']) == 0: 
				libkb.apisay('Ты забыл переслать сообщение :(',msg['toho'])
				return 0
			message = msg['fwd_messages'][0]['text']



		msg = libkb.fix_names(msg)
		pun = {
			'rus':'йцукенгшщзхъфывапролджэячсмитьбюё',
        	'eng':"qwertyuiop[]asdfghjkl;'zxcvbnm,.`",
        	'rus_table':{},
        	'rus_num':{},
        	'eng_table':{},
        	'eng_num':{}
		}
		key = 0
		for sym in pun['rus']:
			pun['rus_table'][sym] = key
			pun['rus_num'][key] = sym
			key += 1
		key = 0
		for sym in pun['eng']:
			pun['eng_table'][sym] = key
			pun['eng_num'][key] = sym
			key += 1

		out = ''
		for sym in message:
			if sym in pun['rus']:
				out += pun['eng_num'][pun['rus_table'][sym]]
			if sym in pun['eng']:
				out += pun['rus_num'][pun['eng_table'][sym]]
			if sym not in pun['eng'] and sym not in pun['rus']:
				out += sym
		libkb.apisay(out,msg['toho'])
kb.reg_command(punto())
