#!/bin/bash

# Interface that runs the IPV4 VPN Tunnel
INTERFACE=ppp0
WGET=/usr/bin/wget
REFLECTOR=https://mephis.to/echo.php
GWNAME=gw04
shopt -s nullglob

ffip=$(ip addr | awk '/inet/ && /br-ffm/{sub(/\/.*$/,"",$2); print $2}')
vpnip=$(ip addr | awk '/inet/ && /ppp0/{sub(/\/.*$/,"",$2); print $2}')

RESULT=$($WGET -4 -t1 --timeout 10 -qO- --bind-address $ffip $REFLECTOR)

echo -n "Expected: "
echo $vpnip

echo -n "External: "
echo $RESULT

if [ "$vpnip" = "$RESULT" ]
then
        NEW_STATE=server
else
        NEW_STATE=off
fi


if [ "$vpnip" = "" ]
then
        NEW_STATE=off
fi

echo -n "BatState: "
echo $NEW_STATE

for MESH in /sys/class/net/*/mesh; do
OLD_STATE="$(cat $MESH/gw_mode)"
[ "$OLD_STATE" == "$NEW_STATE" ] && continue
         echo "Statechange!"
         echo $NEW_STATE > $MESH/gw_mode
         echo 100MBit/100MBit > $MESH/gw_bandwidth
         logger "batman gateway mode changed to $NEW_STATE"
         echo -e "Somethings wrong the $GWNAME\nCheck immidiately\nNew GW Mode: $NEW_STATE\nInterface IP: $vpnip\nTest Result: $RE
SULT" | mail -s "GW Mode changed on $GWNAME" mephisto@mephis.to,mail@dreessen.de,frnk@bk.ru
done
