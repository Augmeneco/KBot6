#if [ -z "$1" ] 
#then
#	lazbuild kbot6.lpi --build-mode=Release;
#else
#	lazbuild kbot6.lpi --build-mode=$1;
#fi
fpc -MObjFPC -Schi -Cg -O3 -k-R -k./ -l -vewnhibq -Ficompunits/x86_64-linux -Fusrc -Fu. -FUcompunits/x86_64-linux -FEbin -obin/kbot6 -B main.pas 
