#!/bin/bash

apt-get --yes install vsftpd


useradd --home /home/vsftpd --gid nogroup -m --shell /bin/false vsftpd

service vsftpd restart
