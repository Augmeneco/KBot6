import kb
import libkbot as libkb

class help:
	level = 1
	keywords = ['хелп','начать','помощь','help']
	def handler(self, msg):
		msg = libkb.fix_names(msg)
		text = '''[ ОБЫЧНЫЙ ЮЗЕР ]
&#8195;kb_name баш - случайная цитата с баша
&#8195;kb_name цитген - создаёт цитату великих людей с пересланным сообщением
&#8195;kb_name цитата - создаёт изображение с текстом пересланных сообщений, можно даже вложенные
&#8195;kb_name говнокод - берёт рандомный говнокод (как аргумент может принимать название языка на английском)
&#8195;kb_name кек - отзеркаливание картинки
&#8195;kb_name кек лол - отзеркаливание в другую сторону
&#8195;kb_name вьетнам - наложение вьетнамского флешбека на картинку
&#8195;kb_name жмых - сжимает изображение через CAS, так же принимает 2 числовых аргумента, например 50 50
&#8195;kb_name 34 - временно не работает :(
&#8195;kb_name кончи - кончить на картинку
&#8195;kb_name что - определяет что на изображении
&#8195;kb_name двач - рандомный тред из b, либо указанной борды
&#8195;kb_name инфа - вероятность текста
&#8195;kb_name стата - статистика бота
&#8195;kb_name музыка - поиск музыки по запросу
&#8195;kb_name видео - поиск видео по запросу
&#8195;kb_name доки - поиск документов по запросу
&#8195;kb_name когда - когда произойдет событие

Автор плагинов на Python/Lua - [id354255965|Кикер] 
Автор ядра на FreePascal - [id172332816|Михаил] 
Исходный код бота - https://github.com/Augmeneco/KBot6'''
		text = text.replace('kb_name',msg['text_split'][0])
		libkb.apisay(text,msg['toho'])
		

kb.reg_command(help())
