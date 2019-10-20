import kb, re, requests, urllib.parse
import libkbot as libkb

class music:
    level = 1
    keywords = ['девойс']
    def handler(self, msg):
        msg = libkb.fix_names(msg)
        if len(msg['user_text'].split(' ')) > 26:
            libkb.apisay('Нельзя больше 26 слов :(',msg['toho'])
            return 0
        libkb.apisay('Создаю гифку... Это может занять до 20 секунд',msg['toho'])
        index = requests.get('https://photocentra.ru/GIF/txt.php?lang=ru&txtstring='+urllib.parse.quote(msg['user_text'])).text
        gif = requests.get(re.findall('href=(.*) style="font',index)[0]).content
        params = {'access_token':kb.config['group_token'],'type':'doc','peer_id':msg['toho'],'v':'5.101'}
        ret = requests.post('https://api.vk.com/method/docs.getMessagesUploadServer',data=params).json()['response']
        ret = requests.post(ret['upload_url'],files={'file':('devoice.gif',gif,'multipart/form-data')}).json()
        params = {'title':'kbot','file':ret['file'],'access_token':kb.config['group_token'],'v':'5.101'}
        ret = requests.post('https://api.vk.com/method/docs.save',data=params).json()['response']['doc']
        attachment = 'doc'+str(ret['owner_id'])+'_'+str(ret['id'])
        libkb.apisay('Готово! Войсеры сосать)',msg['toho'],attachment=attachment)

kb.reg_command(music())