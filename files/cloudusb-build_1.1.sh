#!/bin/bash

#
# WARNING: THIS IS *NOT* A SCRIPT 
#          This is the log of the commands used to create the USB key
#
# WARNING: DANGER! These commands suppose that the USB key is 
#          mounted as /dev/sdb: If you have your hard disk mounted
#          as /dev/sdb YOU WILL LOSE ALL YOUR DATA!!!
#
# WARNING: Do not use these commands if you do not understand
#          the previous point or what these commands do
#
# Author: Gianluca Moro <giangiammy@gmail.com>
# Date: 2010-02-10
# Version 1.0_beta2
# Copyright (C) 2010 Gianluca Moro
#
# this file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# this file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# For more details, write to the Free Software Foundation, 
# 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 
#
#
#echo "Read the source!"
#exit 0

#
# Usage:
# run these commands as root user
#

#
# The script starts from an Ubuntu 9.10 plain installation,
# installs some packages, and configures the system to use 
# and encfs crypted system stored on a Dropbox account.
#
# Here some links to have a persistent USB installation and
# to use encfs with PAM; I used them to have an idea of the 
# procedure:
# https://wiki.edubuntu.org/EncryptedHomeFolder
# https://wiki.ubuntu.com/LiveUsbPendrivePersistent

function debug {
    echo -n "Debug: "
    echo $1
}

debug "Make sure only root can run our script"
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root"
   exit 1
fi

VERSION="1.1"
#
# Look for "Desktop" name in localized systems
#
if [ -f /home/cloudusb/.config/user-dirs.dirs ] ; then
  . /home/cloudusb/.config/user-dirs.dirs
  XDG_ONLY_DESKTOP_DIR=`echo $XDG_DESKTOP_DIR | awk 'BEGIN { FS = "/" } ; { print $3 }'`
  DESKTOP_DIR=/home/cloudusb/$XDG_ONLY_DESKTOP_DIR
else
  DESKTOP_DIR=/home/cloudusb/Desktop
fi

debug "Desktop directory is $DESKTOP_DIR"

#
#
#
debug "update the standard system..."
apt-get update
apt-get upgrade -y

#
#
#
debug "set the needed repositories..."
echo >> /etc/apt/sources.list
echo "# Remastersys repository" >> /etc/apt/sources.list
echo "deb http://www.geekconnection.org/remastersys/repository karmic/" >> /etc/apt/sources.list

echo >> /etc/apt/sources.list
echo "# Dropbox repository" >> /etc/apt/sources.list
echo "deb http://linux.dropbox.com/ubuntu karmic main" >> /etc/apt/sources.list
echo "deb-src http://linux.dropbox.com/ubuntu karmic main" >> /etc/apt/sources.list

echo >> /etc/apt/sources.list
echo "# Skype repository" >> /etc/apt/sources.list
echo "deb http://download.skype.com/linux/repos/debian/ stable non-free" >> /etc/apt/sources.list

# medibuntu repository
wget http://www.medibuntu.org/sources.list.d/lucid.list -O /etc/apt/sources.list.d/medibuntu.list

#
# 
#
debug "Install some tools..."
apt-get update
apt-get install -y emacs
apt-get install -y gimp
apt-get install -y encfs
apt-get install -y libpam-mount
apt-get install -y libpam-encfs
apt-get install -y unetbootin
apt-get install -y --force-yes remastersys 
apt-get install -y --force-yes nautilus-dropbox
apt-get install -y --force-yes skype
apt-get install -y --force-yes ubuntu-restricted-extras

# medibuntu
apt-get install -y --force-yes medibuntu-keyring
apt-get install -y --force-yes mplayer w32codecs vlc

# Wireless tools (iwconfig, iptraf present by default, arping not installed)
apt-get install -y wavemon
apt-get install -y kismet
apt-get install -y dsniff
apt-get install -y iptraf


#
# 
#
if [ x$INSTALL_MATH != "x" ] ; then
debug "install mathematical tools..."
apt-get install -y freemat
apt-get install -y gnuplot
apt-get install -y gretl
apt-get install -y maxima
apt-get install -y maxima-doc
apt-get install -y maxima-emacs
apt-get install -y maxima-share
apt-get install -y maxima-src
apt-get install -y maxima-test
apt-get install -y octave
apt-get install -y r-base
apt-get install -y scilab
apt-get install -y xmaxima
apt-get install -y wxmaxima
fi


#
# children tools
#
if [ x$INSTALL_CHILD != "x" ] ; then
apt-get install -y childsplay
fi


#
# 
#
debug "Set the background..."
wget http://dl.dropbox.com/u/2095818/warty-final-ubuntu-cloudusb1.png
mv -f warty-final-ubuntu-cloudusb1.png /usr/share/backgrounds/warty-final-ubuntu.png

#
# 
#
debug "Set Firefox home page..."
cat > /usr/lib/firefox-3.6.3/defaults/pref/home.js <<EOF 
user_pref("browser.startup.homepage", "http://cloudusb.net/|http://faberlibertatis.org/wiki/Inizio");
EOF

#
# Set Time Zone - NO: find another solution!
#
#cat > /etc/timezone <<EOF
#Europe/Rome
#EOF

#
#
#
debug " Configure PAM to mount an encrypted file system..."
# in file /etc/pam.d/common-auth  we need to add the line
#   auth sufficient pam_encfs.so 
# somewhere before:
#   auth requisite pam_unix.so 
# and append "use_first_pass" to each line following pam_encfs.so.
cp /etc/pam.d/common-auth /etc/pam.d/common-auth.ori
cat > /etc/pam.d/common-auth <<EOF
auth  sufficient                   pam_encfs.so
auth  [success=1 default=ignore]   pam_unix.so nullok_secure use_first_pass
auth  requisite                    pam_deny.so
auth  required                     pam_permit.so
auth  optional                     pam_mount.so 
auth  optional                     pam_ecryptfs.so unwrap
EOF

# file /ect/security/pam_encfs.conf is the configuration file for the 
# pam_encfs.so we just added to common-auth. 
# Change "allow_other" to "nonempty".
cp /etc/security/pam_encfs.conf /etc/security/pam_encfs.conf.ori
cat > /etc/security/pam_encfs.conf <<EOF
#Note that I dont support spaces in params
#So if your for example gonna specify idle time use --idle=X not -i X.

#If this is specified program will attempt to drop permissions before running encfs. (will not work with --public for example)
drop_permissions

#This specifies default encfs options
#encfs_default --idle=1

#Same for fuse, note that allow_root (or allow_other, or --public in encfs) is needed to run gdm/X.
#fuse_default allow_root,nonempty

#- means match all, put any overrides over it.
#if - is in username it will take source path + "/$USER", and mount to $HOME

#USERNAME    	     SOURCE  	  	 TARGET PATH      ENCFS Options		FUSE Options
#user		     			 /home/.enc/user  /home/user		-v,--idle=1,-test,-test2	allow_root
#-	  /home/.enc		-		-v   allow_other
cloudusb  /home/cloudusb/Dropbox/private-data  $DESKTOP_DIR/.private-data   -v   allow_other
EOF

# gconf-editor: apps/nautilus/desktop remove checkbox from volumes_visible

#
# 
#
debug "Generate the script to setup CloudUSB configuration..."
cat > $DESKTOP_DIR/setup.sh <<EOF
#!/bin/bash

# Author: Gianluca Moro <giangiammy@gmail.com>
# Copyright (C) 2010 Gianluca Moro
# part of CloudUSB - http://cloudusb.net

function abort {
  zenity --info --text "Installation aborted.\nBye"
  exit 0
}

zenity --question --title "CloudUSB Setup --- http://cloudusb.net" --text "Setup of CloudUSB secure online storage.\nFor more information see http://cloudusb.net\nThis will downloads the online backup manager (Dropbox):\nContinue?"
if [ \$? -ne 0 ]
then
  abort
fi

dropbox start -i

while [  true ] ; do 
  if [ -d /home/cloudusb/Dropbox ] ; then break ; fi 
  if [ "\$(pidof dropbox)" ] ; then echo "waiting ..." ; else abort ; fi
  (for ((i=0;i<100;i+=3)) ; do echo \$i ; sleep 1; done) | zenity --width 500 --title "Please wait for Dropbox connection completion" --progress --auto-close
done

mkdir -p /home/cloudusb/Dropbox/data
mkdir -p /home/cloudusb/Dropbox/private-data
mkdir -p $DESKTOP_DIR/.private-data
ln -s /home/cloudusb/Dropbox/data data

mkdir -p /home/cloudusb/.scripts
mv $DESKTOP_DIR/setup.sh /home/cloudusb/.scripts

zenity --question --title "Secure data initialization" --text "Do you want to initialize the private-data directory? (Only needed on new Dropbox account)"
if [ \$? -ne 0 ]
then
  zenity --info --title "Complete!" --text "Reboot your system and enjoy CloudUSB!"
  exit 0
fi

PASSWORD=\`zenity --title='Login Password' --hide-text --text='Configuring secure encrypted data.\nPlease enter the SAME PASSWORD OF YOUR LOGIN' --entry\`

if [ "X\${PASSWORD}" = "X" ]; then
  zenity --info --text "Empty password!"
  exit 0
fi

echo "echo \$PASSWORD" > /home/cloudusb/.scripts/pwd.sh
chmod a+x /home/cloudusb/.scripts/pwd.sh

echo "p" | encfs --extpass="/home/cloudusb/.scripts/pwd.sh" /home/cloudusb/Dropbox/private-data/ $DESKTOP_DIR/.private-data/

rm /home/cloudusb/.scripts/pwd.sh

# on login this will be mounted:
# encfs /home/cloudusb/Dropbox/private-data/ $DESKTOP_DIR/.private-data/

zenity --info --text "All done!\nEnjoy http://www.cloudusb.net"

EOF

chown cloudusb:cloudusb $DESKTOP_DIR/setup.sh
chmod a+x $DESKTOP_DIR/setup.sh

mkdir -p /home/cloudusb/.scripts

debug "put CloudUSB link on desktop..."
cat > /home/cloudusb/.scripts/blue-cloudusb300x200.svg <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   width="300pt"
   height="200pt"
   viewBox="0 0 300 200"
   version="1.1"
   id="svg2"
   inkscape:version="0.47 r22583"
   sodipodi:docname="blue-cloudusb300x200-3.svg">
  <metadata
     id="metadata96">
    <rdf:RDF>
      <cc:Work
         rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type
           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title></dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <defs
     id="defs94">
    <inkscape:perspective
       sodipodi:type="inkscape:persp3d"
       inkscape:vp_x="0 : 125 : 1"
       inkscape:vp_y="0 : 1000 : 0"
       inkscape:vp_z="375 : 125 : 1"
       inkscape:persp3d-origin="187.5 : 83.333333 : 1"
       id="perspective98" />
  </defs>
  <sodipodi:namedview
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1"
     objecttolerance="10"
     gridtolerance="10"
     guidetolerance="10"
     inkscape:pageopacity="0"
     inkscape:pageshadow="2"
     inkscape:window-width="640"
     inkscape:window-height="484"
     id="namedview92"
     showgrid="false"
     inkscape:zoom="0.944"
     inkscape:cx="253.30169"
     inkscape:cy="120.95785"
     inkscape:window-x="442"
     inkscape:window-y="210"
     inkscape:window-maximized="0"
     inkscape:current-layer="svg2" />
  <path
     fill="#99c4ed"
     d=" M 0.00 0.00 L 300.00 0.00 L 300.00 200.00 L 0.00 200.00 L 0.00 0.00 Z"
     id="path4" />
  <path
     fill="#050609"
     d=" M 101.42 16.18 C 102.50 16.21 103.58 16.24 104.67 16.28 C 105.00 23.77 104.57 31.30 105.53 38.75 C 101.59 39.09 97.51 40.52 93.59 39.42 C 87.38 36.37 89.43 25.22 96.19 24.26 C 97.65 23.92 99.14 23.70 100.62 23.45 C 100.87 21.02 101.13 18.60 101.42 16.18 Z"
     id="path6" />
  <path
     fill="#050609"
     d=" M 45.80 17.06 C 46.69 17.00 48.49 16.89 49.38 16.83 C 50.13 23.18 49.57 29.58 50.19 35.94 C 50.22 37.50 50.65 39.21 49.82 40.65 C 48.52 40.57 47.23 40.35 45.95 40.17 C 45.33 32.48 45.45 24.76 45.80 17.06 Z"
     id="path8" />
  <path
     fill="#050609"
     d=" M 142.86 17.07 C 143.71 16.97 145.40 16.76 146.25 16.66 C 146.65 19.28 146.99 21.92 147.32 24.56 C 150.19 24.45 153.85 23.46 155.93 26.08 C 158.27 29.42 158.00 34.38 155.56 37.60 C 153.28 40.40 149.24 40.07 146.01 39.77 C 144.53 39.70 142.40 39.11 142.64 37.21 C 142.47 30.50 142.69 23.78 142.86 17.07 Z"
     id="path10" />
  <path
     fill="#050609"
     d=" M 207.02 16.86 C 207.69 16.94 209.02 17.11 209.68 17.19 C 209.90 19.27 210.10 21.36 210.30 23.44 C 211.94 23.87 213.59 24.33 215.23 24.79 C 214.42 26.92 212.14 27.74 210.22 28.55 C 210.06 32.48 209.99 36.41 209.72 40.33 C 208.64 40.03 207.58 39.70 206.54 39.33 C 205.91 36.00 206.36 32.58 205.78 29.26 C 204.82 27.91 203.49 26.90 202.29 25.78 C 205.23 23.65 206.44 20.32 207.02 16.86 Z"
     id="path12" />
  <path
     fill="#050609"
     d="m 253.98,19.9 c 1.36,-1.17 2.73,0.47 3.81,1.23 5.45,4.94 11.02,9.74 16.65,14.48 1.25,1.22 3.48,2.9 2.03,4.81 -4.05,5.24 -9.01,9.71 -13.32,14.73 1.57,4.37 3.31,9.92 -0.09,13.89 -4.12,4.54 -8.85,8.46 -13.33,12.63 -12.85,12.17 -25.9,24.12 -38.67,36.38 -1.01,0.89 -2.07,1.78 -3.33,2.29 -1.39,0.54 -2.57814,2.84085 -4.18,2.82119 -1.20075,0.67183 -0.0833,3.43464 -1.71169,0.83695 7.4178,-10.17221 -0.57547,3.91536 0.89661,0.15339 -5.66,-1.55 -13.34492,-3.91153 -17.38492,-8.48153 -6.62,-6.94 -15.16,-12.91 -18.36,-22.34 -0.33,-3.59 2.8,-6.46 4.6,-9.3 2.12,-2.43 4.54,-4.57 6.99,-6.68 15.74,-13.51 31.13,-27.44 46.78,-41.05 4.09,-3.9 10.01,-1.4 14.94,-2.14 5.22,-4.08 8.31,-10.34 13.68,-14.26 z"
     id="path14"
     sodipodi:nodetypes="ccccccccccccccccccc" />
  <path
     fill="#050609"
     d=" M 33.47 23.42 C 36.34 22.08 39.32 23.74 41.96 24.84 C 41.90 25.68 41.79 27.35 41.74 28.19 C 39.41 27.74 37.09 27.24 34.78 26.75 C 32.66 29.57 32.13 33.00 33.66 36.23 C 36.24 35.76 38.82 35.24 41.43 34.91 C 40.68 36.51 40.55 38.95 38.51 39.49 C 35.75 40.28 32.14 40.32 30.26 37.76 C 26.97 33.36 28.42 25.90 33.47 23.42 Z"
     id="path16" />
  <path
     fill="#050609"
     d=" M 128.98 23.98 C 132.10 21.57 137.96 22.16 138.82 26.61 C 136.27 26.97 133.71 27.25 131.16 27.62 C 133.56 29.00 136.22 29.98 138.36 31.78 C 141.06 34.97 138.03 40.50 133.97 40.43 C 131.23 40.43 129.04 38.52 126.82 37.17 C 126.93 36.34 127.15 34.70 127.26 33.88 C 130.03 34.84 132.81 35.81 135.71 36.30 C 134.32 33.17 130.75 32.53 128.34 30.50 C 127.14 28.52 127.33 25.65 128.98 23.98 Z"
     id="path18" />
  <path
     fill="#050609"
     d=" M 168.27 24.16 C 172.39 24.21 177.46 21.82 180.91 25.02 C 182.26 29.10 181.75 33.56 181.55 37.78 C 181.79 39.64 179.77 41.05 178.23 39.78 C 177.07 35.51 177.64 31.02 177.39 26.64 C 175.68 27.64 172.85 28.00 172.58 30.36 C 172.04 33.64 172.01 36.98 171.67 40.28 C 170.61 39.80 168.74 39.96 168.50 38.49 C 167.80 33.76 168.30 28.93 168.27 24.16 Z"
     id="path20" />
  <path
     fill="#050609"
     d=" M 58.44 24.42 C 62.48 22.44 68.08 25.33 67.87 30.08 C 68.98 35.80 63.56 42.70 57.45 40.59 C 50.78 37.68 52.09 26.99 58.44 24.42 Z"
     id="path22" />
  <path
     fill="#050609"
     d=" M 71.63 23.75 C 72.39 23.91 73.91 24.22 74.67 24.38 C 74.74 28.23 75.01 32.09 75.81 35.86 C 76.67 35.89 78.38 35.94 79.24 35.97 C 80.20 32.65 80.34 29.19 80.88 25.80 C 81.31 24.41 82.89 24.04 84.02 23.44 C 84.69 28.83 85.00 34.26 86.07 39.60 C 82.76 39.41 79.44 39.65 76.13 39.60 C 73.53 39.71 71.77 37.14 71.23 34.87 C 70.53 31.19 71.05 27.41 71.63 23.75 Z"
     id="path24" />
  <path
     fill="#050609"
     d=" M 109.78 24.00 C 110.63 24.06 112.32 24.17 113.16 24.23 C 113.29 28.45 113.13 32.81 114.89 36.77 C 116.04 35.98 117.26 35.27 118.27 34.28 C 119.04 30.84 119.05 27.27 119.69 23.80 C 120.43 23.95 121.91 24.24 122.65 24.38 C 122.59 29.30 123.48 34.12 124.61 38.88 C 121.59 40.04 118.21 39.52 115.05 39.65 C 112.16 39.87 109.98 37.26 109.57 34.61 C 108.99 31.09 109.41 27.51 109.78 24.00 Z"
     id="path26" />
  <path
     fill="#050609"
     d=" M 186.56 36.41 C 184.02 32.00 186.00 25.37 191.23 24.11 C 194.80 22.50 200.57 24.26 200.00 28.94 C 199.15 33.35 193.45 33.62 190.28 35.77 C 193.99 36.13 197.68 35.52 201.37 35.14 C 199.42 41.21 189.42 42.21 186.56 36.41 Z"
     id="path28" />
  <path
     fill="#99c4ed"
     d=" M 255.13 24.99 C 260.71 29.49 266.12 34.21 271.35 39.11 C 267.36 43.86 263.32 48.58 258.94 52.96 C 257.75 53.93 256.15 55.84 254.61 54.39 C 249.33 50.67 244.47 46.35 239.61 42.09 C 244.94 36.53 249.82 30.56 255.13 24.99 Z"
     id="path30" />
  <path
     fill="#99c4ed"
     d=" M 189.13 31.46 C 190.27 29.18 192.47 27.91 194.70 26.89 C 195.17 27.51 196.10 28.76 196.57 29.39 C 194.13 30.22 191.65 30.94 189.13 31.46 Z"
     id="path32" />
  <path
     fill="#99c4ed"
     d=" M 57.18 32.13 C 57.56 29.69 59.94 27.03 62.62 28.04 C 64.70 29.42 64.24 32.40 63.40 34.39 C 62.58 36.66 59.92 36.79 57.97 37.50 C 57.64 35.72 57.10 33.95 57.18 32.13 Z"
     id="path34" />
  <path
     fill="#99c4ed"
     d=" M 94.43 29.60 C 95.90 27.49 98.86 28.07 101.07 27.60 C 100.93 29.85 101.07 32.18 100.39 34.37 C 98.78 35.63 96.70 35.97 94.82 36.62 C 94.30 34.39 92.80 31.73 94.43 29.60 Z"
     id="path36" />
  <path
     fill="#99c4ed"
     d=" M 147.44 30.49 C 148.70 29.12 150.42 28.32 151.98 27.36 C 152.62 29.57 153.93 32.15 152.48 34.34 C 151.32 36.34 148.59 35.77 146.69 36.31 C 146.91 34.39 146.51 32.26 147.44 30.49 Z"
     id="path38" />
  <path
     fill="#050609"
     d=" M 159.63 34.49 C 161.03 35.30 164.11 35.05 164.21 37.09 C 165.02 39.81 161.29 39.54 159.69 40.48 C 159.57 38.48 159.57 36.49 159.63 34.49 Z"
     id="path40" />
  <path
     fill="#99c4ed"
     d=" M 228.21 38.95 C 230.78 38.44 233.37 38.12 235.97 37.78 C 235.43 39.68 234.61 41.53 234.51 43.51 C 239.69 48.70 245.66 53.05 251.23 57.82 C 253.29 59.92 256.32 59.44 258.98 59.39 C 259.69 61.03 260.38 62.67 261.06 64.33 C 257.73 64.09 253.99 64.07 251.36 61.70 C 246.30 57.44 241.75 52.62 236.85 48.18 C 233.72 45.35 230.55 42.50 228.21 38.95 Z"
     id="path42" />
  <path
     fill="#99c4ed"
     d=" M 207.23 58.23 C 213.18 53.18 218.76 47.71 224.87 42.85 C 231.85 50.32 239.78 56.79 247.05 63.96 C 249.67 66.59 253.29 67.69 256.70 68.91 C 241.67 83.48 226.12 97.53 210.93 111.94 C 205.88 116.77 197.54 118.24 191.36 114.79 C 187.28 111.89 184.15 107.89 180.50 104.50 C 178.07 101.96 175.12 99.77 173.42 96.64 C 172.84 93.21 172.80 89.09 175.41 86.43 C 179.42 82.09 184.32 78.70 188.59 74.62 C 194.59 68.91 201.07 63.75 207.23 58.23 Z"
     id="path44" />
  <path
     fill="#050609"
     d=" M 214.55 66.75 C 214.97 61.21 221.02 56.03 226.55 58.26 C 228.63 59.90 229.36 62.76 231.60 64.24 C 233.75 65.74 236.69 67.20 236.55 70.28 C 236.81 75.37 232.06 78.48 228.38 81.05 C 224.18 75.89 220.05 70.61 214.55 66.75 Z"
     id="path46" />
  <path
     fill="#696a6b"
     d="m 96.75,70.91 c 3.27,-4.65 6.32,-10.64 12.42,-11.87 6.55,-1.63 13.2,1.41 17.8,5.99 2.82,2.15 5.14,5.8 8.89,6.18 5.19,-3.08 8.19,-9.43 14.31,-10.97 5.59,-0.51 10.4,3.07 15.16,5.43 5.43,2.67 8.56,8.09 13.25,11.68 -2.45,2.11 -4.87,4.25 -6.99,6.68 -2.75,-8.24 -10.18,-14.48 -18.6,-16.2 -4.49,0.34 -7.32,4.5 -9.49,8.01 -0.29907,2.192012 1.55461,3.638021 -1.78,3.01 -1.08,1.44 -2.33,3.52 -4.47,2.77 -7.83,-2.24 -12.19,-9.85 -18.79,-14.07 -2.69,-1.71 -6.67,-2.95 -9.26,-0.38 -4.18,4.02 -0.28864,7.707627 -5.06847,11.842373 2.00316,4.231236 1.28204,6.540891 -6.73153,2.077627 -3.89,-2.1 -7.54,-5.32 -12.19,-5.37 -5.41,-0.12 -10.82,0.22 -16.2,0.66 -4.9,0.37 -10.07,3.08 -12,7.78 0.06,4.35 7.71,6.43 5.77,11.26 -4.14,3.19 -10.21,3.39 -13.46,7.86 -3.31,4.75 -6,10.38 -6.13,16.25 1.75,1.28 3.961864,2.4778 5.871864,3.4878 -2.61,1.65 -4.891864,3.6522 -6.441864,6.3122 -3.15,-2.54 -8.01,-4.62 -7.97,-9.35 0.69,-11.06 7.1,-21.27 16.2,-27.47 -1.02,-2.48 -2.28,-4.91 -2.71,-7.57 -0.27,-2.11 1.11,-3.94 2.29,-5.54 4.71,-5.84 11.74,-10.52 19.52,-10.11 8.94,0.25 18.13,-1.23 26.8,1.62 z"
     id="path48"
     sodipodi:nodetypes="cccccccccccccccccccccccccccccc" />
  <path
     fill="#99c4ed"
     d=" M 219.46 63.25 C 221.45 62.54 223.45 61.89 225.48 61.31 C 225.64 63.83 224.90 66.24 223.67 68.41 C 222.14 66.79 220.75 65.05 219.46 63.25 Z"
     id="path50" />
  <g
     id="g3063">
    <path
       sodipodi:nodetypes="ccccccccccccccccccccscccccccccccscccc"
       id="path52"
       d="m 109.2,67.17 c 2.59,-2.57 6.57,-1.33 9.26,0.38 6.6,4.22 10.96,11.83 18.79,14.07 2.14,0.75 3.39,-1.33 4.47,-2.77 0.6,-1 1.19,-2 1.78,-3.01 2.17,-3.51 5,-7.67 9.49,-8.01 8.42,1.72 15.85,7.96 18.6,16.2 -1.8,2.84 -4.93,5.71 -4.6,9.3 3.2,9.43 11.74,15.4 18.36,22.34 4.04,4.57 10.03,6.19 15.69,7.74 -2.35,3.36 -6.04,5.15 -9.8,6.46 0.57,2.28 1.18,4.55 1.7,6.84 0.82,3.37 1.27,8.08 -2.53,9.82 -6.63,2.31 -13.68,-0.17 -20.29,-1.39 -2.94,-0.03 -5.59,1.35 -7.27,3.75 -2.33,5.56 -2.82,11.85 -5.96,17.06 -3.48,3.79 -9.5,1.99 -13.17,-0.62 -5.32,-3.9 -10.55,-8.04 -16.67,-10.64 -1.23,-0.41 -2.47,-0.86 -3.77,-0.93 -1.95,0.44 -3.18,2.24 -4.51,3.58 -2.48,2.99 -4.84,6.98 -9.12,7.36 -6.66,0.59 -12.72,-3.61 -16.46,-8.82 -1.51,-2.15 -3.65,-3.78 -6.37,-3.89 -9.12,0.29 -18.46,0.76 -27.41,-1.37 -5.05,-1.85 -10.68,-4.11 -13.71,-8.79 0.18,-5.64 6.67,-8.99 7.06,-14.68 0.07,-2.27 -2.42,-3.22 -3.91,-4.45 -1.91,-1.01 -3.91,-1.89 -5.66,-3.17 0.13,-5.87 2.82,-11.5 6.13,-16.25 3.25,-4.47 9.32,-4.67 13.46,-7.86 1.94,-4.83 -5.71,-6.91 -5.77,-11.26 1.93,-4.7 7.1,-7.41 12,-7.78 2.854977,-0.233493 5.718402,-0.438825 8.585792,-0.562198 2.536001,-0.109116 5.075105,-0.154122 7.614208,-0.0978 4.65,0.05 8.3,3.27 12.19,5.37 1.93,0.75 3.97,1.18 5.99,1.63 1.39,-5.3 1.63,-11.53 5.81,-15.55 z"
       fill="#99c4ed" />
  </g>
  <path
     fill="#99c4ed"
     d=" M 225.81 70.96 C 227.22 69.17 229.80 67.43 232.03 68.96 C 233.96 71.66 230.93 74.01 229.24 75.79 C 228.04 74.22 226.79 72.68 225.81 70.96 Z"
     id="path54" />
  <path
     fill="#050609"
     d=" M 202.20 78.09 C 202.24 73.28 206.90 70.80 210.68 68.99 C 211.18 69.58 212.18 70.77 212.68 71.36 C 209.73 73.81 205.84 75.99 205.74 80.33 C 210.21 79.57 214.56 76.17 219.20 77.72 C 223.54 79.37 223.71 85.66 220.56 88.55 C 217.75 91.56 213.42 91.93 209.57 91.44 C 209.74 90.74 210.08 89.32 210.25 88.61 C 212.65 87.99 215.25 87.66 217.33 86.19 C 219.13 84.97 218.10 82.53 218.17 80.76 C 214.36 81.51 210.86 83.42 207.02 83.95 C 203.90 84.15 201.63 81.03 202.20 78.09 Z"
     id="path56" />
  <path
     fill="#050609"
     d=" M 192.81 81.44 C 193.85 80.99 194.89 80.54 195.93 80.10 C 199.61 84.48 203.84 88.74 205.73 94.27 C 207.38 99.17 202.89 104.38 198.01 104.64 C 194.47 104.63 191.74 101.96 189.41 99.60 C 186.85 96.73 183.93 93.88 182.83 90.08 C 183.77 89.47 185.31 88.66 186.25 89.73 C 189.93 93.04 192.39 97.66 196.69 100.28 C 199.87 101.87 203.24 97.52 201.52 94.62 C 199.21 89.86 195.09 86.25 192.81 81.44 Z"
     id="path62" />
  <path
     fill="#050609"
     d=" M 70.00 112.01 C 72.89 109.70 76.67 107.83 80.46 108.53 C 81.92 109.68 82.99 111.23 84.13 112.68 C 83.61 113.06 82.56 113.82 82.04 114.20 C 80.46 113.61 78.92 112.78 77.23 112.55 C 71.49 113.57 67.76 121.49 72.03 125.96 C 75.64 129.22 79.06 124.20 82.27 122.72 C 84.47 128.96 75.70 132.99 70.90 130.11 C 64.44 126.55 64.55 116.44 70.00 112.01 Z"
     id="path64" />
  <path
     fill="#050609"
     d=" M 86.66 107.99 C 87.71 108.38 88.75 108.78 89.79 109.18 C 89.84 114.98 89.89 120.79 90.17 126.59 C 93.62 127.09 99.00 125.15 100.78 129.05 C 96.65 132.16 90.87 130.25 86.06 130.19 C 86.11 122.79 85.38 115.32 86.66 107.99 Z"
     id="path66" />
  <path
     fill="#050609"
     d=" M 108.45 108.48 C 112.92 106.34 119.19 108.03 121.06 112.87 C 123.08 118.38 121.33 125.06 116.87 128.87 C 112.89 132.34 105.73 131.75 102.88 127.13 C 99.32 120.87 101.68 111.50 108.45 108.48 Z"
     id="path68" />
  <path
     fill="#050609"
     d=" M 125.57 108.38 C 126.81 108.51 128.05 108.65 129.29 108.80 C 129.61 113.82 128.91 118.96 130.08 123.90 C 130.78 127.84 136.84 127.30 137.81 123.79 C 139.19 118.98 138.54 113.88 138.75 108.94 C 139.91 108.60 141.07 108.27 142.23 107.93 C 142.95 113.74 143.26 119.80 141.47 125.45 C 139.72 131.88 129.14 132.53 126.64 126.32 C 124.43 120.62 125.41 114.33 125.57 108.38 Z"
     id="path70" />
  <path
     fill="#050609"
     d=" M 145.54 111.22 C 150.07 107.95 156.57 107.51 161.19 110.83 C 166.49 114.67 166.56 123.43 161.66 127.62 C 158.08 130.82 153.00 130.97 148.46 130.76 C 147.73 124.22 150.00 116.83 145.54 111.22 Z"
     id="path72" />
  <path
     fill="#99c4ed"
     d=" M 110.52 111.53 C 113.74 110.48 117.63 112.67 118.19 116.07 C 118.76 119.79 117.16 123.85 114.17 126.15 C 111.18 128.64 106.10 126.39 105.48 122.69 C 104.73 118.49 106.46 113.40 110.52 111.53 Z"
     id="path74" />
  <path
     fill="#99c4ed"
     d=" M 152.54 112.09 C 154.48 112.50 156.52 112.68 158.29 113.65 C 162.04 116.04 161.91 121.98 158.84 124.86 C 156.96 126.21 154.59 126.54 152.42 127.18 C 152.26 122.15 152.26 117.11 152.54 112.09 Z"
     id="path76" />
  <g
     id="g3060">
    <g
       id="g3131">
      <path
         fill="#696a6b"
         d="m 203.55,121.89 c 1.39,-0.51 2.79,-1.01 4.18,-1.55 -0.05,2.93 0.35,6.01 -0.68,8.83 -1.39,2.45 -3.86,4.03 -5.45,6.33 -1.33,4.99 -0.56,10.8 -4.17,14.98 -2.54,3.65 -7.24,4.5 -11.39,4.27 -5.3,-0.11 -10.55,-0.89 -15.84,-0.97 1.23,-2.8 1.19,-5.86 -0.08,-8.64 6.61,1.22 13.66,3.7 20.29,1.39 3.8,-1.74 3.35,-6.45 2.53,-9.82 0.44695,-2.64458 1.54983,-5.10475 2.92983,-6.80475 2.87,-3.5 0.45305,-3.4805 3.26305,-7.0305 -1.07,-0.72 5.48712,-0.26475 4.41712,-0.98475 z"
         id="path78"
         sodipodi:nodetypes="ccccccccccccc" />
    </g>
  </g>
  <g
     id="g2917">
    <path
       sodipodi:nodetypes="ccccccccccc"
       id="path82"
       d="m 52.76,127.15 c -0.39,5.69 -6.88,9.04 -7.06,14.68 3.03,4.68 8.66,6.94 13.71,8.79 8.95,2.13 18.29,1.66 27.41,1.37 -1.87,2.37 -2.88,5.25 -2.86,8.27 -8.01,-0.48 -16.03,-0.93 -24.04,-1.3 -5.01,-0.05 -8.7,-3.86 -12.87,-6.08 -3.3,-2.19 -7.52,-3.73 -9.43,-7.43 -1.52,-5.93 2.44,-11.14 5,-16.12 2.23,0.91 -5.417288,-5.29237 -3.087288,-7.10237 C 43.720914,121.46375 51.750554,121.9629 52.76,127.15 z"
       fill="#696a6b" />
  </g>
  <g
     id="g3134">
    <path
       sodipodi:nodetypes="cccccccccccccscccc"
       id="path86"
       d="m 156.89,165.95 c 3.14,-5.21 3.63,-11.5 5.96,-17.06 3.72017,-5.71712 7.86407,-4.33678 8.72407,-2.42678 1.59,-0.28 1.90881,5.05441 -1.26814,7.10492 -4.17,5.17 -2.99593,13.08186 -7.82593,17.80186 -3.93,4.06 -10.16,4.17 -15.39,3.4 -7.54,-1.09 -11.92,-8.26 -18.66,-11.04 -1.32,-0.8 -2.55,0.32 -3.63,0.97 -3.79,2.63 -7.32,6.12 -12.08,6.78 -4.8,0.62 -10.12,0.91 -14.4,-1.76 -4.17,-2.48 -8.32,-5.22 -11.3,-9.13 1.54,0.12 -4.537119,-0.64746 -2.987119,-0.55746 -0.867118,-1.67 0.596272,-10.42746 4.072373,-7.22457 3.74,5.21 14.884746,12.48203 21.544746,11.89203 4.28,-0.38 6.64,-4.37 9.12,-7.36 8.34983,-1.19528 1.47071,-3.13275 8.28,-2.65 6.12,2.6 11.35,6.74 16.67,10.64 3.67,2.61 9.69,4.41 13.17,0.62 z"
       fill="#696a6b" />
  </g>
</svg>
EOF
chown cloudusb:cloudusb /home/cloudusb/.scripts/blue-cloudusb300x200.svg

cat > $DESKTOP_DIR/CloudUSB.net.desktop <<EOF
#!/usr/bin/env xdg-open

[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Link
Icon[en_US]=gnome-panel-launcher
Name[en_US]=CloudUSB.net
URL=http://cloudusb.net
Comment[en_US]=CloudUSB
Name=CloudUSB.net
Comment=CloudUSB official site
Icon=/home/cloudusb/.scripts/blue-cloudusb300x200.svg
EOF
chown cloudusb:cloudusb $DESKTOP_DIR/CloudUSB.net.desktop


#
# set permissions
#
chmod a+r /etc/fuse.conf
echo "user_allow_other" >> /etc/fuse.conf

debug "Final system clenaing..."
#
# Remove the final "eject CD" and other operations
#
rm -f /etc/rc0.d/*casper
rm -f /etc/rc6.d/*casper

#
# Remove installation icon on desktop - NO: find another solution!
#
rm -f /usr/share/applications/ubiquity-gtkui.desktop
rm -f $DESKTOP_DIR/ubiquity-gtkui.desktop


#
# put scripts in .scripts
#
mkdir -p /home/cloudusb/.scripts
chown cloudusb:cloudusb /home/cloudusb/.scripts
mv $DESKTOP_DIR/cloudusb-build_$VERSION.sh /home/cloudusb/.scripts
chown cloudusb:cloudusb /home/cloudusb/.scripts/cloudusb-build_$VERSION.sh 


#
# One shot script to be executed just at the first boot
#

cat > /home/cloudusb/.oneshot <<EOF
#!/bin/bash
# Author: Gianluca Moro <giangiammy@gmail.com>
# Copyright (C) 2010 Gianluca Moro
# part of CloudUSB - http://cloudusb.net

killall gvfsd-metadata
rm -f $DESKTOP_DIR/ubiquity-gtkui.desktop
mv /home/cloudusb/.oneshot /home/cloudusb/.oneshot.DONE
EOF

chown cloudusb:cloudusb /home/cloudusb/.oneshot
chmod a+x /home/cloudusb/.oneshot

#
# call .oneshot
#

echo "if [ -x /home/cloudusb/.oneshot ] ; then /home/cloudusb/.oneshot ; fi" >> /home/cloudusb/.bashrc

update-rc.d -f apparmor remove

#
# 
#
debug "Create the ISO..."
remastersys backup

#
# 
#
debug "create USB key..."
echo "WARNING: USB KEY IS SUPPOSED TO BE RECOGNIZED ON /dev/sdb:"
echo "if you are not sure where the USB KEY is mapped"
echo "or you do not understand what this means, ABORT NOW!"
echo "DO NOT USE THIS PROCEDURE until you understand it!"
read -p "press enter to continue - CTRL-C to ABORT..."

umount /dev/sdb1
umount /dev/sdb2

# get partition structure with: sfdisk -d /dev/sdb

sfdisk /dev/sdb << EOF
# partition table of /dev/sdb
unit: sectors

/dev/sdb1 : start=       62, size=  4214512, Id= b, bootable
/dev/sdb2 : start=  4214574, size= 11578500, Id=83
/dev/sdb3 : start=        0, size=        0, Id= 0
/dev/sdb4 : start=        0, size=        0, Id= 0
EOF

mkfs.vfat /dev/sdb1
mkfs.ext2 -b 4096 -L casper-rw /dev/sdb2

mkdir -p /media/usbkey
mount /dev/sdb1 /media/usbkey

# CLI mode
unetbootin method=diskimage isofile="/home/remastersys/remastersys/custombackup.iso" message="CloudUSB from http://www.cloudusb.net" autoinstall=yes

#remastersys clean

debug "Setup boot files..."

sed -i 's/append initrd=\/ubninit file=\/cdrom\/preseed\/custom.seed boot=casper quiet splash --/append initrd=\/ubninit file=\/cdrom\/preseed\/custom.seed boot=casper persistent quiet splash --/g' /media/usbkey/syslinux.cfg 

sed -i 's/UNetbootin/CloudUSB Boot - http:\/\/www.cloudusb.net/g' /media/usbkey/syslinux.cfg 

sed -i 's/Default/CloudUSB/g' /media/usbkey/syslinux.cfg 

sed -i 's/timeout 100/timeout 50/g' /media/usbkey/syslinux.cfg 

#
#
#
debug "Copy image files on USBkey"
mkdir /media/usbkey/cloudusb
cp /home/cloudusb/.scripts/cloudusb-build_$VERSION.sh /media/usbkey/cloudusb/
cp /usr/share/backgrounds/warty-final-ubuntu.png /media/usbkey/cloudusb/
cp /home/remastersys/remastersys/custombackup.iso* /media/usbkey/cloudusb/

