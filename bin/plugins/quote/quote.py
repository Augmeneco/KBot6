#######
#
# Augmeneco 2019. VkQuotesModule v1.3 by Cha14ka, Lanode
#
#######
import re, requests, json, sys, re, os
from PIL import Image, ImageDraw, ImageFont
from io import BytesIO

for font in ['Roboto-Regular.ttf','Roboto-Medium.ttf']:
	if font not in os.listdir('/tmp/tmpfs'):
		ret = requests.get('https://github.com/Augmeneco/KBot5/blob/master/data/'+font+'?raw=true').content
		open('/tmp/tmpfs/'+font,'wb').write(ret)

def recursive_render(offset_x, fwd_messages):
	def wrapper(s, length):
		lines = list()
		for line in s.split('\n'):
			lines.append(str())
			for token in re.split(r'(\s*)(\S+)', line):
				if len(token)+len(lines[-1]) > length:
					if re.match(r'\s*', token).span()[1] == len(token):
						lines[-1] += token[:length-len(lines[-1])-1]
						token = token[length-len(lines[-1])-1:]
					lines.extend([token[i:i+length] for i in range(0, len(token), length)])				
				else:
					lines[-1] += token
		return lines
	global img
	last_id = 0
	line_y = 0
	global offset_y
	global x_size
	global recursive_render
	global max_textbox
	global max_fwd_deep
	max_textbox_iter = 0
	x_size += 70
	for message in fwd_messages:
		if message['from_id'] < 0:
			user_info = requests.post('https://api.vk.com/method/groups.getById',data={'access_token':config['group_token'],'v':'5.90','group_ids':message['from_id']*-1}).json()['response'][0]
			name = user_info['name']
		else:
			user_info = requests.post('https://api.vk.com/method/users.get',data={'access_token':config['group_token'],'v':'5.90','fields':'photo_50','user_ids':message['from_id']}).json()['response'][0]
			name = user_info['first_name']+' '+user_info['last_name']
		
		text = message['text']	

		font_regular = ImageFont.truetype('/tmp/tmpfs/Roboto-Regular.ttf', 17)
		font_medium = ImageFont.truetype('/tmp/tmpfs/Roboto-Medium.ttf', 18)
		draw = ImageDraw.Draw(img)

		if last_id != message['from_id']:
			ava = user_info['photo_50']
			ava = requests.get(ava,stream=True).raw
			ava = Image.open(ava)
			ava = ava.resize([50,50])
			img.paste(ava,[10+offset_x,10+offset_y,60+offset_x,60+offset_y])
			draw.text([70+offset_x,14+offset_y],name,font=font_medium,fill=(66,100,139))

			if max_textbox_iter < 60+draw.textsize(name,font=font_medium)[0]:
				max_textbox_iter = 40+draw.textsize(name,font=font_medium)[0]
		
		#offset_y += 50	
		#textnew = textwrap.wrap(text, 50)
		textnew = wrapper(text,50)
		y = 35
		text_size = 0 
		if last_id == message['from_id']:
			offset_y -= 20
			line_y = 20
		for wrap in textnew:
			draw.text([70+offset_x,y+offset_y],wrap,font=font_regular,fill=(0,0,0))
			text_size += draw.textsize(wrap,font=font_regular)[1]
			y += 19

			if max_textbox_iter < draw.textsize(wrap,font=font_regular)[0]:
				max_textbox_iter = draw.textsize(wrap,font=font_regular)[0]

		for i in range(int(offset_x/70)):
			draw.line((((offset_x+1)-(i*70), offset_y+10+line_y), ((offset_x+1)-(i*70), 50+offset_y+text_size)), width=3, fill=(200, 211, 223))
		line_y = 0
		
		offset_y += text_size+40
		last_id = message['from_id']
		
		#draw.line(((offset_x+70, offset_y+10), (offset_x+70, offset_x*(offset_y+30))), width=3, fill=(200, 211, 223))
		if 'fwd_messages' in message:
			recursive_render(offset_x+70, message['fwd_messages'])
		if 'reply_message' in message:
			recursive_render(offset_x+70, [message['reply_message']])
		else:
			if max_fwd_deep <= offset_x*70:
				max_fwd_deep = offset_x*70
				max_textbox = max_textbox_iter
			#print(max_fwd_deep)

msg = json.loads(sys.argv[1])
config = msg['config']

if 'reply_message' in msg:
	message = msg['reply_message']['text']
	fwd_messages = []
	fwd_messages.append(msg['reply_message'])
else:
	if len(msg['fwd_messages']) == 0: 
		os.exit()
	fwd_messages = msg['fwd_messages']


img = Image.new('RGB', (10000,10000), color = (255,255,255))
imgByteArr = BytesIO()
offset_y = 0
last_id = 0
x_size = 0
y_size = 0
max_textbox = 0
max_fwd_deep = 0

recursive_render(0, fwd_messages)
x_size += max_textbox

img = img.crop([0,0,x_size+10,offset_y+10])
img.save(imgByteArr,format='PNG')

ret = requests.get('https://api.vk.com/method/photos.getMessagesUploadServer?access_token={access_token}&v=5.68'.format(access_token=config['group_token'])).json()
ret = requests.post(ret['response']['upload_url'],files={'photo':('photo.png',imgByteArr.getvalue(),'image/png')}).json()
ret = requests.get('https://api.vk.com/method/photos.saveMessagesPhoto?v=5.68&album_id=-3&server='+str(ret['server'])+'&photo='+ret['photo']+'&hash='+str(ret['hash'])+'&access_token='+config['group_token']).json()
requests.post('https://api.vk.com/method/messages.send',data={'attachment':'photo'+str(ret['response'][0]['owner_id'])+'_'+str(ret['response'][0]['id']),'message':'Готово!','v':'5.80','peer_id':msg['toho'],'access_token':config['group_token']})