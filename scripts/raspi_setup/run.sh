#!/bin/bash

set -e
set -u
set -x

CONFIG=/home/zeppelin/zeppelin.yaml

if [[ "$( ls -1 /boot/*.yaml | wc -l )" -eq 1 ]] ; then
	
	FILENAME=$(ls -1 /boot/*.yaml | rev | cut -f1 -d/ | cut -c6- | rev)

	mkdir -p ~/projects/$FILENAME
	cp /boot/$FILENAME* ~/projects/$FILENAME/

	if [[ ! -d /boot/web_root ]] ; then
		rm -rf ~/projects/$FILENAME/web_root
		sudo ln -s /home/zeppelin/zeppelin_prod/LEDZeppelin/web_root ~/projects/$FILENAME/
	else 
		cp -r /boot/web_root ~/projects/$FILENAME/
	fi

	CONFIG=~/projects/$FILENAME/$FILENAME.yaml
fi

if [[ -f /boot/hostapd.conf ]] ; then
	if [[ "$(md5sum /boot/hostapd.conf | cut -f1 -d' ')" != "$(md5sum /etc/hostapd/hostapd.conf | cut -f1 -d' ')" ]] ; then
		sudo cp /boot/hostapd.conf /etc/hostapd/hostapd.conf
		sudo reboot
	fi
fi

{
while true; do 
	if [[ ! -f /home/zeppelin/zeppelin_prod/LEDZeppelin/led_controller ]] ; then
		echo "No executable"
		sleep 10
	else

		sudo setcap CAP_NET_BIND_SERVICE=+eip /home/zeppelin/zeppelin_prod/LEDZeppelin/led_controller 
		sudo cp /home/zeppelin/zeppelin_prod/LEDZeppelin/*spdlog* /usr/lib/
		/home/zeppelin/zeppelin_prod/LEDZeppelin/led_controller --config $CONFIG --disable 3d_renderer || true
	fi

done;
} &> /home/zeppelin/zeppelin.log &


while ! ping -c 1 -W 1 10.10.10.10 ; do sleep 1 ; done

sudo systemctl restart dnsmasq

while ! ping -c 1 -W 10 8.8.8.8 ; do sleep 1 ; done

git clone --depth 1 https://github.com/UrielGuy/ZeppelinReleases /home/zeppelin/releases || true

cd /home/zeppelin/releases
git pull

if [[ "$(md5sum zeppelin_linux_arm6.zip | cut -f1 -d' ')" != "$(md5sum /home/zeppelin/zeppelin_latest.zip | cut -f1 -d' ')" ]] ; then
	cp zeppelin_linux_arm6.zip /home/zeppelin/zeppelin_latest.zip
	cd ~
	unzip -o zeppelin_latest.zip
	if [[ -d zeppelin_old ]] ; then
		rm -rf zeppelin_old
	fi
	if [[ -d zeppelin_prod ]] ; then
		mv zeppelin_prod zeppelin_old
	fi
	mv zeppelin_linux_arm6 zeppelin_prod
	cp -r /home/zeppelin/zeppelin_prod/LEDZeppelin/web_root .

	if [[ ! -f /home/zeppelin/zeppelin.yaml ]] ; then
		ln -s /home/zeppelin/zeppelin_prod/LEDZeppelin/LedZeppelin.yaml ./zeppelin.yaml
		ln -s /home/zeppelin/zeppelin_prod/LEDZeppelin/LedZeppelin.yaml.config ./zeppelin.yaml.config
	fi


	pkill -f led_controller
fi


