#!/bin/bash

apt-get --yes install vsftpd


useradd --home /home/vsftpd --gid nogroup -m --shell /bin/false vsftpd

sed -i -e 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf
sed -i -e 's/local_enable=NO/local_enable=YES/' /etc/vsftpd.conf
sed -i -e 's/#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf
sed -i -e 's/#local_umask=022/local_umask=022/' /etc/vsftpd.conf

echo "pasv_enable=YES" >> /etc/vsftpd.conf
echo "pasv_min_port=64000" >> /etc/vsftpd.conf
echo "pasv_max_port=64321" >> /etc/vsftpd.conf
echo "port_enable=YES" >> /etc/vsftpd.conf
    
service vsftpd restart
