import kb, random, requests
import libkbot as libkb

class rip:
	level = 1
	keywords = ['rip','рип']
	def handler(self, msg):
		msg = libkb.fix_names(msg) 

		if msg['user_text'] == '':
			libkb.apisay('Текст то напиши',msg['toho'])
			exit()
		out = ''
		if len(msg['user_text'].split(' ')) > 70:
			libkb.apisay('Сообщение слишком больше, я не хочу чтобы яндекс наказали меня :(',msg['toho'])
			exit()
		for word in msg['user_text'].split(' '):
			result = requests.get('https://dictionary.yandex.net/api/v1/dicservice.json/lookup?key='+kb.config['yandex_key']+'&lang=ru-ru&text='+word).json()
			if len(result['def']) != 0:
				out += result['def'][0]['tr'][random.randint(0,len(result['def'][0]['tr'])-1)]['text']+' '
			else:
				out += word+' '
		libkb.apisay(out,msg['toho'])

kb.reg_command(rip())