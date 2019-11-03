import kb, random, requests, untangle, traceback, time
import libkbot as libkb

class r34:
	level = 1
	keywords = ['арт','хентай','art','hentai','бура','booru']
	def handler(self, msg):
		msg = libkb.fix_names(msg)
		proxies = {'http': 'socks5h://localhost:9050','https': 'socks5h://localhost:9050'}
		timer = time.time()
		try:
			parse = untangle.parse(requests.get('http://gelbooru.com/index.php?page=dapi&s=post&q=index&limit=1000&tags='+msg['user_text'].replace(' ','+'),proxies=proxies).text)
		except:
			libkb.apisay('Что-то не так с прокси :(\n\n'+traceback.format_exc(),msg['toho'])
			return 0
		if int(parse.posts['count']) > 0:
			randnum = random.randint(0,len(parse.posts.post))
			mess = 'Бурятские артики ('+str(time.time()-timer)+' sec)\n('+str(randnum)+'/'+str(len(parse.posts.post))+')\n----------\nОстальные теги: '+parse.posts.post[randnum]['tags']
			parse = parse.posts.post[randnum]['file_url']
			pic = requests.get(parse,proxies=proxies).content
			libkb.apisay(mess,msg['toho'],photo=pic)
		else: libkb.apisay('Ничего не найдено :(',msg['toho'])
kb.reg_command(r34())