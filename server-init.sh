#!/bin/bash
# EHESS 2018 / Server setup script
# David N. Brett - EHESS

#locale-gen "en_US.UTF-8"

locale-gen en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

apt-get update && apt-get upgrade
apt-get autoremove && apt-get autoclean

apt-get install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

apt-get install build-essential

# Time sync
dpkg-reconfigure tzdata
timedatectl set-local-rtc 0
timedatectl set-ntp true
timedatectl status
systemctl status systemd-timesyncd

# Secure Shared Memory
echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab
reboot

adduser xyz
usermod -aG sudo xyz

# Restrict su to admin group
groupadd adminxyz
usermod -a -G adminxyz xyz
dpkg-statoverride --update --add root adminxyz 4750 /bin/su

echo "AllowUsers xyz@IP_ADDRESS" >> /etc/ssh/sshd_config
# Change SSH port to 1122
nano /etc/ssh/sshd_config

###############################
# sshd_config EXAMPLE
###############################
# Logging
# SyslogFacility AUTH
# LogLevel INFO

# Authentication:
# LoginGraceTime 120
# PermitRootLogin no
# UsePrivilegeSeparation yes
# StrictModes yes
# MaxAuthTries 3
# MaxSessions 10

# PubkeyAuthentication yes
# RSAAuthentication yes
# AuthorizedKeysFile %h/.ssh/authorized_keys

# IgnoreRhosts yes
# RhostsRSAAuthentication no
# HostbasedAuthentication no

# PasswordAuthentication no
# PermitEmptyPasswords no

# ChallengeResponseAuthentication no

# UsePAM yes
###############################

sudo systemctl restart sshd

apt-get install fail2ban
nano /etc/fail2ban/jail.local
# add the following contents:

# [sshd]
# enabled = true
# port = ANY_PORT
# filter = sshd
# logpath = /var/log/auth.log
# maxretry = 3

systemctl restart fail2ban

###############################
# Install firewall
apt-get install ufw
sudo ufw allow from IP_ADDRESS to any port ANY_PORT
ufw enable
reboot

###############################
# Disable root account
# To disable the root account, simply use the -l option.
sudo passwd -l root

# If for some valid reason you need to re-enable the account, simply use the -u option.
# sudo passwd -u root

###############################
# Let's check if a SWAP file exists and it's enabled before we create one.
sudo swapon -s

# To create the SWAP file, you will need to use this.
sudo fallocate -l 4G /swapfile	# same as "sudo dd if=/dev/zero of=/swapfile bs=1G count=4"

# Secure swap.
sudo chown root:root /swapfile
sudo chmod 0600 /swapfile

# Prepare the swap file by creating a Linux swap area.
sudo mkswap /swapfile

# Activate the swap file.
sudo swapon /swapfile

# Confirm that the swap partition exists.
sudo swapon -s

# This will last until the server reboots. Let's create the entry in the fstab.
sudo nano /etc/fstab
: /swapfile	none	swap	sw	0 0

# Swappiness in the file should be set to 0. Skipping this step may cause both poor performance,
# whereas setting it to 0 will cause swap to act as an emergency buffer, preventing out-of-memory crashes.
echo 0 | sudo tee /proc/sys/vm/swappiness
echo vm.swappiness = 0 | sudo tee -a /etc/sysctl.conf

###############################
# sysctl.conf
# http://bookofzeus.com/harden-ubuntu/hardening/sysctl-conf/

# These settings can:

# Limit network-transmitted configuration for IPv4
# Limit network-transmitted configuration for IPv6
# Turn on execshield protection
# Prevent against the common 'syn flood attack'
# Turn on source IP address verification
# Prevents a cracker from using a spoofing attack against the IP address of the server.
# Logs several types of suspicious packets, such as spoofed packets, source-routed packets, and redirects.
# "/etc/sysctl.conf" file is used to configure kernel parameters at runtime. Linux reads and applies settings from this file.

sudo nano /etc/sysctl.conf

# IP Spoofing protection
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
# Block SYN attacks
net.ipv4.tcp_syncookies = 1
# Controls IP packet forwarding
net.ipv4.ip_forward = 0
# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
# Log Martians
net.ipv4.conf.all.log_martians = 1
# Block SYN attacks
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
# Log Martians
net.ipv4.icmp_ignore_bogus_error_responses = 1
# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all = 1
kernel.exec-shield = 1
kernel.randomize_va_space = 1
# disable IPv6 if required (IPv6 might caus issues with the Internet connection being slow)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
# Accept Redirects? No, this is not router
net.ipv4.conf.all.secure_redirects = 0
# Log packets with impossible addresses to kernel log? yes
net.ipv4.conf.default.secure_redirects = 0

# [IPv6] Number of Router Solicitations to send until assuming no routers are present.
# This is host and not router.
net.ipv6.conf.default.router_solicitations = 0
# Accept Router Preference in RA?
net.ipv6.conf.default.accept_ra_rtr_pref = 0
# Learn prefix information in router advertisement.
net.ipv6.conf.default.accept_ra_pinfo = 0
# Setting controls whether the system will accept Hop Limit settings from a router advertisement.
net.ipv6.conf.default.accept_ra_defrtr = 0
# Router advertisements can cause the system to assign a global unicast address to an interface.
net.ipv6.conf.default.autoconf = 0
# How many neighbor solicitations to send out per address?
net.ipv6.conf.default.dad_transmits = 0
# How many global unicast IPv6 addresses can be assigned to each interface?
net.ipv6.conf.default.max_addresses = 1

# In rare occasions, it may be beneficial to reboot your server reboot if it runs out of memory.
# This simple solution can avoid you hours of down time. The vm.panic_on_oom=1 line enables panic
# on OOM; the kernel.panic=10 line tells the kernel to reboot ten seconds after panicking.
vm.panic_on_oom = 1
kernel.panic = 10

# Apply new settings
sudo sysctl -p


###############################
# Disable IRQ Balance
# http://bookofzeus.com/harden-ubuntu/server-setup/disable-irqbalance/

# You should turn off IRQ Balance to make sure you do not get hardware interrupts in your threads. Turning off IRQ Balance, will optimize the balance between power savings and performance through distribution of hardware interrupts across multiple processors.

sudo nano /etc/default/irqbalance
: ENABLED="0"


###############################
sudo nano /etc/hostname
# nerthus

sudo nano /etc/hosts
# 127.0.0.1       localhost
# 127.0.1.1       nerthus.allez-savoir.fr nerthus
# EXTERNAL IP ADDRESS    nerthus.allez-savoir.fr nerthus

###############################
# IP Spoofing
# http://hardenubuntu.com/hardening/ip-spoofing/

# IP spoofing is the creation of Internet Protocol (IP) packets with a forged source IP address, with the purpose of concealing the identity of the sender or impersonating another computing system.

sudo nano /etc/host.conf
order bind,hosts
nospoof on


###############################
sudo apt-get install clamav
sudo freshclam
sudo apt-get install clamav-daemon
sudo crontab -e

#PLUS BESOIN DE :
#00 00 * * * clamscan -r /srv/www/htdocs | grep FOUND >> /path/to/save/report/myfile.txt

###############################
# MYSQL
sudo apt-get install gnupg2
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo apt-get update
sudo apt-get install percona-server-server-5.7
mysql_secure_installation

###############################
# APACHE2
sudo apt-get install apache2
sudo ufw allow 'Apache Full'
sudo ufw reload

# Should be Error with the following :
sudo apt-get install libapache2-mod-fastcgi

###############################
# PHP
# apt-cache pkgnames | grep php7.2
# Next, install the packages that your application requires:
sudo apt-get install software-properties-common
#sudo ln -s /etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list
#sudo chmod -R 0644 /etc/apt/sources.list.d/
#sudo -H software-properties-gtk &>/dev/null  
#sudo chmod +x /etc/apt/sources.list.d
# here create a blank sources list file if needed
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install php7.2 -y
sudo apt-get install php7.2-fpm
sudo apt-get install php7.2-{SimpleXML,xml,mysqlnd,jsmin,bcmath,bz2,ctype,curl,dom,gd,gettext,iconv,imagick,json,mbstring,mysqli,newrelic,openssl,PDO,pdo_mysql,pdo_sqlite,zlib,readline,redis,sqlite3,tidy,uploadprogress,xmlreader,xmlrpc,xmlwriter,zip,} -y

sudo nano /etc/php/7.2/apache2/php.ini

# file_uploads = On
# allow_url_fopen = On
# memory_limit = 256M
# upload_max_filesize = 64M
# upload_max_filesize = 100M
# max_execution_time = 360
# date.timezone = America/Chicago

# Next, lookup Apache2 dir.conf file and confirm the line below:

# <IfModule mod_dir.c>
#      DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
# </IfModule>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

# If you don’t see the index.php definition on the line, please add it and save the file.
















