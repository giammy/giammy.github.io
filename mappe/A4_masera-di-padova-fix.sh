#!/bin/bash

SRC=A4_masera-di-padova

cd work
../misc/cpdf/OSX-Intel/cpdf -split  ../$SRC-ori.pdf -o out%%%.pdf
../misc/cpdf/OSX-Intel/cpdf -add-text "v. G. Marconi"  -font "Helvetica" -font-size 6 out013.pdf -o out013.pdf -pos-center "220 320"
../misc/cpdf/OSX-Intel/cpdf -merge -idir . -o ../$SRC.pdf
rm out???.pdf

