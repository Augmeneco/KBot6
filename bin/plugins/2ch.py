import kb, random, requests, re
import libkbot as libkb

class dvach:
	level = 1
	keywords = ['двач','2ch','сосач','харкач']
	def handler(self, msg):
		msg = libkb.fix_names(msg)
		if msg['user_text'] == '': msg['user_text'] = 'b'
		try:
			thread = requests.get('https://2ch.hk/'+msg['user_text']+'/'+str(random.randint(0,9)).replace('0','index')+'.json').json()['threads']
		except:
			libkb.apisay('Такой борды не существует',msg['toho'])
			return 0
		thread = thread[len(thread)-1]
		url = 'https://2ch.hk/'+msg['user_text']+'/res/'+thread['posts'][0]['num']+'.html'
		text = 'Оригинал: '+url+'\n'+re.sub('(\<(/?[^>]+)>)','',thread['posts'][0]['comment'])
		img = 'https://2ch.hk'+thread['posts'][0]['files'][0]['path']
		img = requests.get(img).content
		libkb.apisay(text, msg['toho'],photo=img)

kb.reg_command(dvach())