#!/bin/bash

#
# Update local RHEL image
#
sudo yum -y update
sudo yum -y install wget nc unzip
sudo yum -y install vim

#
# Install Java 8
#
filename=jdk-8u112-linux-x64.rpm
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u112-b15/$filename"
if [ ! -s $filename ]; then
  echo "Could not download java, you may need to setup http_proxy and https_proxy environment variables."
  exit -1
fi

# Java install method via RPM looks easiest...
sudo rpm -Uvh $filename
sudo alternatives --install /usr/bin/java java /usr/java/latest/bin/java 2

# Setup JAVA_HOME
export JAVA_HOME=/usr/java/latest
echo export JAVA_HOME=/usr/java/latest >>~/.bash_profile

# Setup JRE_HOME
export JRE_HOME=$JAVA_HOME/jre
export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
echo export PATH=\$PATH:\$JAVA_HOME/bin:\$JRE_HOME/bin >>~/.bash_profile

#
# Setup local user, "lucidworks"
#
sudo adduser lucidworks
sudo su lucidworks -c "mkdir -p ~/.ssh/"
# Uncomment below to add a public key for the lucidworks user...
sudo su lucidworks -c "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFdl6bk6Gq3fM2cdR7yeYGcJGLCKFUtVVA6ms2gVVutzdQ95VKf/nwhglvxBstF/YZBbzSqA/h9ebEdmvk5xkHqrEl20HDt3MbatO+yW57yyTANnQEghA3Wm8BYgjTpRWY6cemk8jXFSDG4GO1eNMSaQCL8TeHkNleEH8rhODRvRLXslSAC6n6hXbrb6OrIU/MpcOdhtgZBTE+LcLf6nXEczlnS38LsDdSuCxd+N1swsbpsRYg5jodmLZ1bgBqyHdKsCjHQoo7lUrFC3jG5B9G7AZ2Wc3xBeKxS+rk1zVtLMF98SOI7Kjv2imfKrnXuxAkT7u0p7eBHosWq4W5ftb9qsEEqeL39n9Zm3DicPUXov5VQTAuRe9+pxneUQBwU55FSyqZM94P0T+FhzXBgZtiErtnFnAdHq7CslHLMM7Z16pzsykD8BS40PEvowIH3IaMTpuuIQIIwS67Qz6Dxthl6XUxKbzIBOPEzJVxH3nFC8Ue7hrJCuKfghcAt/Jav1aNX+/tTuoHwcL8cXAUoJKslRyMjxdct+GmMoRORdnViSc4rjI6ZxhQifN3PT4schugBnd4SGhooTcyvEs5UqxD4NzQFrjB7ImQoR89SmbEBqwTYnKKaLiK8cSfn1ydQbP0MJG7iKT6bv/ibfdTiZMuuB7fOdkZPxIfZ0nK6dGo1w==' >>~/.ssh/authorized_keys"
sudo su lucidworks -c "chmod 600 ~/.ssh/authorized_keys "

#
# TODO: Add ulimit stuff
#
# max file handles
sudo bash -c 'echo "lucidworks           soft    nofile          63536" >>/etc/security/limits.conf'
sudo bash -c 'echo "lucidworks           hard    nofile          63536" >>/etc/security/limits.conf'
# set limits for max processes
sudo bash -c 'echo "lucidworks           soft    nproc          16384" >>/etc/security/limits.conf'
sudo bash -c 'echo "lucidworks           hard    nproc          16384" >>/etc/security/limits.conf'

#
# Setup EBS volume
#
lsblk
# for now, hard code the device name
device=/dev/xvdb
sudo file -s $device
mnt=/opt/lucidworks
sudo mkdir $mnt
sudo mkfs -t ext4 $device && sudo mount $device $mnt 
sudo chown -R lucidworks:lucidworks $mnt

#
# TODO: Add download and setup of Fusion bits
#
sudo -u lucidworks wget -q https://download.lucidworks.com/fusion-2.4.3.tar.gz -O $mnt/fusion-2.4.3.tar.gz
