#!/bin/bash

ifconfig wlan1mon down &>>/dev/null
iwconfig wlan1mon mode monitor &>>/dev/null

ifconfig wlan1mon up &>>/dev/null

airmon-ng stop wlan1mon &>>/dev/null


ifconfig wlan2mon down &>>/dev/null

iwconfig wlan2mon mode monitor &>>/dev/null

ifconfig wlan2mon up &>>/dev/null

airmon-ng stop wlan2mon &>>/dev/null


ifconfig wlan1 up &>>/dev/null

ifconfig wlan2 up &>>/dev/null
