import kb, requests, os
import libkbot as libkb
from bs4 import BeautifulSoup
#from lxml import html
#from lxml import etree

class findimg:
	level = 1
	keywords = ['что','чтоэто']
	def handler(self, msg):
		#os.system('sudo service tor restart')
		proxies = {'http': 'socks5h://localhost:9050','https': 'socks5h://localhost:9050'}
		msg = libkb.fix_names(msg)
		if 'photo' in msg['attachments'][0]:
			ret = msg['attachments'][0]['photo']['sizes']
			num = 0
			for size in ret:
				if size['width'] > num:
					num = size['width']
					url = size['url']
			index = requests.get('https://yandex.ru/images/search?url='+url+'&rpt=imageview',proxies=proxies).text
			soup = BeautifulSoup(index, 'html.parser')
			#index = html.fromstring(index)
			#tags = index.xpath('//div[@class="tags__wrapper"]/a')
			out = ''
			for tag in soup.find_all(class_='tags__tag'):
				out += '• '+tag.text+'\n'
			
			libkb.apisay('Я думаю на изображении что-то из этого: \n'+out,msg['toho'])
		else:
			libkb.apisay('Картинку сунуть забыл',msg['toho'])

kb.reg_command(findimg())