import kb
#import requests, json
import json

def fix_names(msg):
    msg['userid'] = msg['from_id']
    msg['toho'] = msg['peer_id']
    msg['text_split'] = msg['text'].split(' ')
    msg['user_text'] = msg['argument']
    return msg

def sendmsg(text,toho):
    kb.vkapi('messages.send',{"message":text,"peer_id":toho})
    return True

def apisay(text,toho,attachment=None,keyboard={"buttons":[],"one_time":True},photo=None):
    token = kb.config['group_token']
    if photo != None:
        ret = requests.get('https://api.vk.com/method/photos.getMessagesUploadServer?access_token={access_token}&v=5.68'.format(access_token=token)).json()
        try:
            with open(photo, 'rb') as f:
                ret = requests.post(ret['response']['upload_url'],files={'file1': f}).json()
        except:
            ret = requests.post(ret['response']['upload_url'],files={'photo':('photo.png',photo,'image/png')}).json()
        ret = requests.get('https://api.vk.com/method/photos.saveMessagesPhoto?v=5.68&album_id=-3&server='+str(ret['server'])+'&photo='+ret['photo']+'&hash='+str(ret['hash'])+'&access_token='+token).json()
        return requests.post('https://api.vk.com/method/messages.send',data={'attachment':'photo'+str(ret['response'][0]['owner_id'])+'_'+str(ret['response'][0]['id']),'message':text,'v':'5.80','peer_id':str(toho),'access_token':str(token),'keyboard':json.dumps(keyboard)}).json()
        
    return requests.post('https://api.vk.com/method/messages.send',data={'access_token':token,'v':'5.80','peer_id':toho,'message':text,'attachment':attachment,'keyboard':json.dumps(keyboard,ensure_ascii=False)}).json()
