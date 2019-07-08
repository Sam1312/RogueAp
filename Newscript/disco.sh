pkill hostapd
pkill airbase-ng &> /dev/null
pkill dnsmasq
airmon-ng stop wlan0mon &>> /dev/null
