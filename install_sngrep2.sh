#!/bin/bash

set -o errexit
set -o nounset

apt-get install -y build-essential
apt-get install -y autoconf
apt-get install -y libpcap-dev
apt-get install -y libncurses-dev
apt-get install -y libssl-dev
apt-get install -y libncursesw5-dev
apt-get install -y libpcre3-dev

mkdir -p /usr/local/src/git
cd /usr/local/src/git
rm -fr sngrep_with_mrcp_support
git clone https://github.com/MayamaTakeshi/sngrep sngrep_with_mrcp_support
cd sngrep_with_mrcp_support
git checkout mrcp_support
./bootstrap.sh
./configure --enable-unicode --with-pcre --with-openssl --enable-eep
make
cp src/sngrep /usr/local/bin/sngrep2

echo "Installation of sngrep2 successful"
