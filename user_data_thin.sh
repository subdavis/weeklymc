#!/bin/bash

# Install dependencies
# apt update
# apt install git

# SET SCRIPTDIR = location of this git repo
echo "SCRIPTDIR=/opt/github.com/weeklymc" >> /etc/environment

export SCRIPTDIR=/opt/github.com/weeklymc

# Clone scripts from git
mkdir -p /opt/github.com && cd /opt/github.com

git config --global user.name Brandon
git config --global user.email weeklymc@anon.subdavis.com

if [ ! -d "weeklymc" ]
then
    git clone https://github.com/subdavis/weeklymc
    cd weeklymc
else
    cd weeklymc
    git pull
fi

./user_data_full.sh