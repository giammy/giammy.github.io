#!/bin/bash

function makeBase {
    cat header.html.tmpl > $1
    cat $1.tmpl >> $1
    cat footer.html.tmpl >> $1
}

for i in index hsk art riflessioni nsa cloudusb misc about bci gadgets ; do 
    makeBase $i.html  
done

#
#( pushd . ; cd .. ; rsync -av --delete giammy.github.io/* ~/Dropbox/Public/giammy/ ;  popd )
#
#echo https://dl.dropboxusercontent.com/u/2092071/giammy/index.html
#
#function makeDirs {
#    cat headerdirs.html.tmpl > $1
#    cat $1.tmpl >> $1
#    cat footer.html.tmpl >> $1
#}
#for i in xxx ; do 
#    makeDirs $i/index.html  
#done
#
#
# mkdir -p ~/Desktop/tmp
# zip ~/Desktop/tmp/home.zip * ; for i in abstractart css files fonts hsk img js ; do zip -r ~/Desktop/tmp/$i.zip $i ; done
#

