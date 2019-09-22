import kb, random, requests
import libkbot as libkb

class music:
	level = 1
	keywords = ['аудио','audio','музыка','music']
	def handler(self, msg):
		msg = libkb.fix_names(msg)
		param = {'v':'5.90','q':msg['user_text'],'count':'0','sort':2,'access_token':kb.config['user_token']}
		count = requests.post('https://api.vk.com/method/audio.search', data=param).json()['response']['count']
		if count > 10: count = count-10
		if count < 11: count = 0
		param = {'v':'5.90','q':msg['user_text'],'offset':random.randint(0,count),'count':'10','sort':2,'access_token':kb.config['user_token']}
		items = requests.post('https://api.vk.com/method/audio.search', data=param).json()['response']['items']

		attachment = ''
		if len(items) != 0:
			for item in items:
				attachment += 'audio'+str(item['owner_id'])+'_'+str(item['id'])+','
			libkb.apisay('Музыка по вашему запросу',msg['toho'],attachment=attachment)
		else: libkb.apisay('Музыка по запросу не найдена :(',msg['toho'])

kb.reg_command(music())