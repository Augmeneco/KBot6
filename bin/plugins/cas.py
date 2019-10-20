import kb, random, requests, os
import libkbot as libkb
from io import BytesIO
from PIL import Image, ImageDraw, ImageFont

class cas:
    level = 1
    keywords = ['cas','жмых']
    def handler(self, msg):
        msg = libkb.fix_names(msg)
        if len(msg['attachments']) == 0:
            libkb.apisay('Картинку сунуть забыл',msg['toho'])
            return 0
        if 'photo' in msg['attachments'][0]:
            ret = msg['attachments'][0]['photo']['sizes']
            num = 0
            for size in ret:
                if size['width'] > num:
                    num = size['width']
                    url = size['url']
            ret = requests.get(url).content
            img_size = Image.open(BytesIO(ret))
            size = img_size.size
            img_size.close()
            
            if len(msg['user_text'].split(' ')) == 2:
                rescale = msg['user_text'].split(' ')
                
                if not rescale[0].isdigit() and not rescale[1].isdigit():
                    libkb.apisay('Аргументы должны быть числами',msg['toho'])
                    return 0
                if int(rescale[0]) > 100 and int(rescale[1]) > 100:
                    libkb.apisay('Нельзя больше 100',msg['toho'])
                    return 0
                if int(rescale[0]) <= 0 and int(rescale[1]) <= 0:
                    libkb.apisay('Нельзя меньше 0',msg['toho'])
                    return 0
                rescale = rescale[0]+'x'+rescale[1]+'%\!'
            else:
                rescale = '50x50%\!'
            libkb.apisay('Жмыхаю картинку... создание шок контента может занять до 20 секунд',msg['toho'])
            open('/tmp/tmpfs/'+str(msg['userid'])+'.jpg','wb').write(ret)
            os.system('convert /tmp/tmpfs/'+str(msg['userid'])+'.jpg  -liquid-rescale 50x50%\!  /tmp/tmpfs/'+str(msg['userid'])+'_out.jpg')
            image_obj = Image.open('/tmp/tmpfs/'+str(msg['userid'])+'_out.jpg')
            imgByteArr = BytesIO()
            image_obj = image_obj.resize(size)
            image_obj.save(imgByteArr,format='PNG')
            libkb.apisay('Готово',msg['toho'],photo=imgByteArr.getvalue())
            os.system('rm /tmp/tmpfs/'+str(msg['userid'])+'_out.jpg')
            os.system('rm /tmp/tmpfs/'+str(msg['userid'])+'.jpg')
            image_obj.close()

kb.reg_command(cas())