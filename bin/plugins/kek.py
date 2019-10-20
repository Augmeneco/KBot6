import kb, requests
from PIL import Image, ImageDraw, ImageFont
from io import BytesIO
import libkbot as libkb

class kek:
	level = 1
	keywords = ['кек','kek']
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
			image_obj = Image.open(BytesIO(ret))
			imgByteArr = BytesIO()
			if 'лол' in msg['user_text']:
				image2 = image_obj.crop([0,0,int(image_obj.size[0]/2),int(image_obj.size[1])])
				image2 = image2.transpose(Image.FLIP_LEFT_RIGHT)
				image_obj.paste(image2,(int(image_obj.size[0]/2),0))
				image_obj.save(imgByteArr,format='PNG')
				libkb.apisay('',msg['toho'],photo=imgByteArr.getvalue())
			else:
				image2 = image_obj.transpose(Image.FLIP_LEFT_RIGHT)
				image2 = image2.crop([0,0,int(image_obj.size[0]/2),int(image_obj.size[1])])
				image2 = image2.transpose(Image.FLIP_LEFT_RIGHT)
				image_obj = image_obj.transpose(Image.FLIP_LEFT_RIGHT)
				image_obj.paste(image2,(int(image_obj.size[0]/2),0))
				image_obj.save(imgByteArr,format='PNG')
				libkb.apisay('',msg['toho'],photo=imgByteArr.getvalue())
		else:
			libkb.apisay('Картинку забыл сунуть',msg['toho'])
		image_obj.close()
		image2.close()
kb.reg_command(kek())