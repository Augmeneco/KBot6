#!/bin/bash
fpc -MObjFPC -Schi -Cg -O3 -k-R -k./ -l -vewnhibq -Fulib/python4delphi\;lib/flre -FUcompunits -Ficompunits -Fusrc -Fu. -FEbin -k-lgcc_s -k-lpython3.7m -obin/kbot6 -B main.pas
