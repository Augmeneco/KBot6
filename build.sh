if [ -z "$1" ] 
then
	lazbuild kbot6.lpi --build-mode=Release;
else
	lazbuild kbot6.lpi --build-mode=$1;
fi
