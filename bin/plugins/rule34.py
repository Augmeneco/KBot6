import kb, random, requests, untangle, traceback, time
import libkbot as libkb

class r34:
	level = 1
	keywords = ['34','р34','r34','rule34','хентай']
	def handler(self, msg):
		msg = libkb.fix_names(msg)
		proxies = libkb.getproxy()
		headers = {'User-agent':'Mozilla/5.0 (X11; Linux x86_64; rv:70.0) Gecko/20100101 Firefox/70.0'}
		blacklist = '-anthro+-fur+-scat*+-darling_in_the_franxx+-furry+-dragon+-guro+-animal_penis+-animal+-wolf+-fox+-webm+-my_little_pony+-monster*+-3d+-animal*+-ant+-insects+-mammal+-horse+-blotch+-deer+-real*+-shit+-everlasting_summer+-copro*+-wtf+'
		timer = time.time()
		try:
			parse = untangle.parse(requests.get('https://rule34.xxx/index.php?page=dapi&s=post&q=index&limit=1000&tags='+blacklist+msg['user_text'].replace(' ','+'),proxies=proxies).text)
		except:
			libkb.apisay('Что-то не так с прокси :(\n\n'+traceback.format_exc(),msg['toho'])
			return 0
		if int(parse.posts['count']) > 0:
			randnum = random.randint(0,len(parse.posts.post))
			mess = 'Дрочевня подкатила ('+str(time.time()-timer)+' sec)\n('+str(randnum)+'/'+str(len(parse.posts.post))+')\n----------\nОстальные теги: '+parse.posts.post[randnum]['tags']
			parse = parse.posts.post[randnum]['file_url']
			pic = requests.get(parse,proxies=proxies).content
			libkb.apisay(mess,msg['toho'],photo=pic)
		else: libkb.apisay('Ничего не найдено :(',msg['toho'])
kb.reg_command(r34())