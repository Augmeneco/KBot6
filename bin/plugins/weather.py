import kb, datetime, requests
import libkbot as libkb

class weather:
	level = 1
	keywords = ['погода','weather']
	def handler(self, msg):
		msg = libkb.fix_names(msg)
		if msg['user_text'] == '':
			msg['user_text'] = 'Санкт-Петербург'
		def format_weather(city):
			weather = requests.get('http://api.openweathermap.org/data/2.5/weather', params={'lang':'ru', 'units': 'metric', 'APPID': 'ef23e5397af13d705cfb244b33d04561', 'q':city}).json()
			try:
				out=""
				out+="Погода в " + str(weather['sys']['country']) + "/" + weather['name'] + ":\n"
				out+='&#8195;•Температура: ' + str(weather['main']['temp']) + '°C\n'
				out+='&#8195;•Скорость ветра: ' + str(weather['wind']['speed']) + ' м/с\n'
				out+='&#8195;•Влажность: ' + str(weather['main']['humidity']) + '%\n'
				out+='&#8195;•Состояние: ' + str(weather['weather'][0]['description']) + "\n"
				out+='&#8195;•Давление: ' + ('%0.2f' % (float(weather['main']['pressure'])/1000*750.06))+"\n"
				out+='Время обновления: ' + datetime.datetime.fromtimestamp(weather["dt"]).strftime('%I:%M%p');
				return out
			except AttributeError:
				return None
		def translit(x):
			symbols = (u"абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ",
				u"abvgdeejzijklmnoprstufhzcss_y_euaABVGDEEJZIJKLMNOPRSTUFHZCSS_Y_EUA")
			tr = {ord(a):ord(b) for a, b in zip(*symbols)}
			return tounicode(x).translate(tr)

		out = format_weather(msg['user_text'])
		if out == None:
			out = format_weather(msg['user_text'])
		if out == None:
			libkb.apisay('Я не нашла населённый пункт '+msg['user_text'],msg['toho'])
			return 0
		libkb.apisay(out,msg['toho'])

kb.reg_command(weather())