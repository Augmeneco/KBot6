import kb, requests, json, os, time

def fix_names(msg):
    msg['userid'] = msg['from_id']
    msg['toho'] = msg['peer_id']
    msg['text_split'] = msg['text'].split(' ')
    if 'argument' in msg:
        msg['user_text'] = msg['argument']
    else:
        msg['user_text'] = msg['text']
    return msg

def sendmsg(text,toho):
    kb.vkapi('messages.send',{"message":text,"peer_id":toho})
    return True
def chunks(l, n):
    for i in range(0, len(l), n):
        yield l[i:i + n]
        
def getproxy(): 
    if not os.path.exists('/tmp/tmpfs/proxy'):
        open('/tmp/tmpfs/proxy','w').write('{"proxy":"http://84.22.61.46:53281","time":'+str(time.time()-2700)+'}')

    info = json.loads(open('/tmp/tmpfs/proxy','r').read())
    if time.time() - info["time"] >= 2700:
        while True:
            data = requests.get('https://api.getproxylist.com/proxy').json()
            if 'error' in data:
                proxies = {'http':info['proxy'],'https':info['proxy']}
                return proxies
            if data['protocol'] == 'http': break


        proxies = {'http':data['protocol']+'://'+data['ip']+':'+str(data['port']),'https':data['protocol']+'://'+data['ip']+':'+str(data['port'])}
        open('/tmp/tmpfs/proxy','w').write('{"proxy":"'+data['protocol']+'://'+data['ip']+':'+str(data['port'])+'","time":'+str(time.time())+'}')
    else:
        proxies = {'http':info['proxy'],'https':info['proxy']}
    return proxies

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
    for chunk in chunks(text,4096):
        requests.post('https://api.vk.com/method/messages.send',data={'access_token':token,'v':'5.80','peer_id':toho,'message':chunk,'attachment':attachment,'keyboard':json.dumps(keyboard,ensure_ascii=False)}).json()    
    return True
