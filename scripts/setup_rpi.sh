#!/bin/bash

set -e
set -u
set -x

USER=zeppelin
IP=$1

ROOT=$(dirname $(realpath $0))

ssh-copy-id $USER@$IP

ssh $USER@$IP sudo apt-get update
ssh $USER@$IP sudo apt-get upgrade
ssh $USER@$IP sudo apt-get install -y vim tmux liburiparser1 libfreeimage3 libglfw3 libassimp5 dnsmasq hostapd

ssh $USER@$IP sudo chmod -x /usr/sbin/resolvconf
ssh $USER@$IP sudo systemctl unmask hostapd
ssh $USER@$IP sudo systemctl enable hostapd

scp -r $ROOT/raspi_setup $USER@$IP:~/

ssh $USER@$IP /home/$USER/raspi_setup/place_files.sh

scp ~/opt/x-tools/armv6-rpi-linux-gnueabihf/armv6-rpi-linux-gnueabihf/sysroot/lib/libstdc++.so.6.0.31 $USER@$IP:~
ssh $USER@$IP bash << 'EOF'
    sudo mkdir -p /usr/local/lib/arm-linux-gnueabihf
    sudo mv libstdc++.so.6.0.31 $_
    sudo ldconfig
EOF


