#!/bin/bash

ROOT=$(dirname $(realpath $0))

cd $ROOT

cp run.sh ~/
sudo cp -r etc/* /etc/
