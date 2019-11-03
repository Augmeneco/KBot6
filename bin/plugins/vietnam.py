import kb, requests, os
from PIL import Image, ImageDraw, ImageFont
from io import BytesIO
import libkbot as libkb

class vietnam:
	level = 1
	keywords = ['вьетнам','vietnam']
	def handler(self,msg):
		msg = libkb.fix_names(msg)
		if 'photo' in msg['attachments'][0]:
			ret = msg['attachments'][0]['photo']['sizes']
			num = 0
			for size in ret:
				if size['width'] > num:
					num = size['width']
					url = size['url']
			ret = requests.get(url).content
			
			if 'vietnam.png' not in os.listdir('/tmp/tmpfs'):
				img = requests.get('https://raw.githubusercontent.com/Cha14ka/kb_python/master/tmp/vietnam.png').content
				open('/tmp/tmpfs/vietnam.png','wb').write(img)
				pic1 = Image.open(BytesIO(img))
			else:
				pic1 = Image.open('/tmp/tmpfs/vietnam.png')
			pic2 = Image.open(BytesIO(ret))
			pic1 = pic1.resize(pic2.size)
			pic2 = pic2.convert('RGBA')
			pic3 = Image.alpha_composite(pic2,pic1)
			imgByteArr = BytesIO()
			pic3.save(imgByteArr,format='PNG')

			libkb.apisay('Готово',msg['toho'],photo=imgByteArr.getvalue())
		else:
			libkb.apisay('Фото забыл сунуть',msg['toho'])
	
kb.reg_command(vietnam())
