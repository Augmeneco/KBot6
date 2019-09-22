import kb, requests
import libkbot as libkb

class cum:
	level = 1
	keywords = ['кончи','кончил','cum']
	def handler(self, msg):
		msg = libkb.fix_names(msg) 

		if 'photo' in msg['attachments'][0]:
			ret = msg['attachments'][0]['photo']['sizes']
			num = 0
			for size in ret:
				if size['width'] > num:
					num = size['width']
					url = size['url']
			pic = requests.get('http://lunach.ru/?cum=&url='+url).content
			libkb.apisay('Готово!',msg['toho'],photo=pic)
		else:
			libkb.apisay('Картинку забыл сунуть',msg['toho'])

kb.reg_command(cum())