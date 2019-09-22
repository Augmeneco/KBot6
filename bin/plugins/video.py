import kb, random, requests
import libkbot as libkb

class video:
	level = 1
	keywords = ['видео','video']
	def handler(self, msg):
		msg = libkb.fix_names(msg)

		param = {'v':'5.90','q':msg['user_text'],'offset':random.randint(0,100),'count':'10','access_token':kb.config['user_token']}
		items = requests.post('https://api.vk.com/method/video.search', data=param).json()['response']['items']

		attachment = ''
		if len(items) != 0:
			for item in items:
				attachment += 'video'+str(item['owner_id'])+'_'+str(item['id'])+','
			libkb.apisay('Видео по вашему запросу',msg['toho'],attachment=attachment)
		else: libkb.apisay('Видео по запросу не найдены :(',msg['toho'])

kb.reg_command(video())