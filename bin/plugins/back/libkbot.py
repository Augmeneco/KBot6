import kb
def fix_names(msg):
    msg['userid'] = msg['from_id']
    msg['toho'] = msg['peer_id']
    msg['text_split'] = msg['text'].split(' ')
    msg['user_text'] = msg['argument']
    return msg
def apisay(text,toho):
    kb.vkapi('messages.send',{"message":text,"peer_id":toho})
    return true