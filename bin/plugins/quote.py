import kb, json, os
import libkbot as libkb

class quote:
	level = 1
	keywords = ['цитата','цит']
	def handler(self,msg):
		msg = libkb.fix_names(msg)
		
		msg['config'] = kb.config
		arg = json.dumps(msg)
		os.system("python3 plugins/quote/quote.py '"+arg+"'")


kb.reg_command(quote())