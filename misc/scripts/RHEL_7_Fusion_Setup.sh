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
filename=jdk-8u65-linux-x64.rpm
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.rpm"

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
#sudo su lucidworks -c "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFdl6bk6Gq3fM2cdR7yeYGcJGLCKFUtVVA6ms2gVVutzdQ95VKf/nwhglvxBstF/YZBbzSqA/h9ebEdmvk5xkHqrEl20HDt3MbatO+yW57yyTANnQEghA3Wm8BYgjTpRWY6cemk8jXFSDG4GO1eNMSaQCL8TeHkNleEH8rhODRvRLXslSAC6n6hXbrb6OrIU/MpcOdhtgZBTE+LcLf6nXEczlnS38LsDdSuCxd+N1swsbpsRYg5jodmLZ1bgBqyHdKsCjHQoo7lUrFC3jG5B9G7AZ2Wc3xBeKxS+rk1zVtLMF98SOI7Kjv2imfKrnXuxAkT7u0p7eBHosWq4W5ftb9qsEEqeL39n9Zm3DicPUXov5VQTAuRe9+pxneUQBwU55FSyqZM94P0T+FhzXBgZtiErtnFnAdHq7CslHLMM7Z16pzsykD8BS40PEvowIH3IaMTpuuIQIIwS67Qz6Dxthl6XUxKbzIBOPEzJVxH3nFC8Ue7hrJCuKfghcAt/Jav1aNX+/tTuoHwcL8cXAUoJKslRyMjxdct+GmMoRORdnViSc4rjI6ZxhQifN3PT4schugBnd4SGhooTcyvEs5UqxD4NzQFrjB7ImQoR89SmbEBqwTYnKKaLiK8cSfn1ydQbP0MJG7iKT6bv/ibfdTiZMuuB7fOdkZPxIfZ0nK6dGo1w==' >>~/.ssh/authorized_keys"
sudo su lucidworks -c "chmod 600 ~/.ssh/authorized_keys "

#
# TODO: Add download and setup of Fusion bits
#
