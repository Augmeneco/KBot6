import kb
import libkbot as libkb

class punto:
	level = 1
	keywords = ['pun']
	def handler(self, msg):
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
		for sym in msg['text']:
			if sym in pun['rus']:
				out += pun['eng_num'][pun['rus_table'][sym]]
			if sym in pun['eng']:
				out += pun['rus_num'][pun['eng_table'][sym]]
			if sym not in pun['eng'] and sym not in pun['rus']:
				out += sym
		libkb.apisay(out,msg['toho'])
kb.reg_command(punto())