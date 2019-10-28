#!/usr/bin/python3
import subprocess, time
while True:
    pid = subprocess.getoutput('pgrep kbot6')
    subprocess.call(['kill',pid])
    print('Бот убит')
    time.sleep(3600)
