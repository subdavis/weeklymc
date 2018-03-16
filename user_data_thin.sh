#!/bin/bash

# Install dependencies
apt install git

# SET SCRIPTDIR = location of this git repo
echo "SCRIPTDIR=/opt/github.com/weeklymc" >> /etc/environment
export SCRIPTDIR=/opt/github.com/weeklymc

# Clone scripts from git
mkdir -p /opt/github.com && cd /opt/github.com

if [ ! -d "weeklymc" ]
then
    git clone git@github.com:subdavis/weeklymc.git
    cd weeklymc
else
    cd weeklymc
    git pull
fi

./user_data_full.sh