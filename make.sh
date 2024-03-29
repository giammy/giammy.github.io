#!/bin/bash

#$git commit -am "..."
#$ git push
#Username for 'https://github.com': giammy
#Password for 'https://giammy@github.com':

function makeBase {
    cat header.html.tmpl > $1
    cat $1.tmpl >> $1
    cat footer1.html.tmpl >> $1
    fn="footer-statcounter-"$1".tmpl"
    # echo $fn
    if [ -f $fn ]; then
        cat $fn >> $1
    else
        cat footer-statcounter-default.html.tmpl >> $1
    fi
    cat footer3.html.tmpl >> $1
}

for i in index hsk art art-africa riflessioni nsa psn cloudusb misc about bci gadgets energiaescienza cars ciclozingarate mappe ; do 
    makeBase $i.html  
done

cp art.html arte.html
cp art-africa.html arte-africa.html

git commit -am "..." 
git push

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

