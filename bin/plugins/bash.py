import kb, random, requests, re
import libkbot as libkb
from lxml import html 
from lxml import etree 

class bash:
	level = 1
	keywords = ['баш','bash']
	def handler(self, msg):
		msg = libkb.fix_names(msg) 
		max = int(re.findall('"index" value="(\d*)" auto',requests.get('https://bash.im/').text)[0])
		randnum = str(random.randint(1,max)) 
		index = requests.get('https://bash.im/index/'+randnum).text 
		index = html.fromstring(index) 
		index = index.xpath('//div[@class="quote__body"]') 
		index = random.choice(index) 
		text = etree.tostring(index).decode().replace('<br/>','\n') 
		for clear in ['&lt;','&gt;','<div class="quote__body">','</div>']:
			text = text.replace(clear,'')
		libkb.apisay(text,msg['toho'])

kb.reg_command(bash())
