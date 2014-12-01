#!/bin/bash
# Interface that runs the IPV4 VPN Tunnel
INTERFACE=tun0
PROVIDERIF=eth0
WGET=/usr/bin/wget
REFLECTOR=https://mephis.to/echo.php
GWNAME=gw01
shopt -s nullglob
ffip=$(ip addr | awk '/inet/ && /br-ffm/{sub(/\/.*$/,"",$2); print $2}')
vpnip=$(ip addr | awk '/inet/ && /tun0/{sub(/\/.*$/,"",$2); print $2}')
providerip=$(ip addr | awk '/inet/ && /eth0/{sub(/\/.*$/,"",$2); print $2}')
RESULT=$($WGET -4 -t1 --timeout 10 -qO- --bind-address $ffip $REFLECTOR)
echo -n "ProviderIP: "
echo $providerip
echo -n "External: "
echo $RESULT

# Turn off if Tunnel is inactive
if [ "$providerip" != "$RESULT" ]
then
NEW_STATE=server
else
NEW_STATE=off
fi

# Turn off if V4 Connectivity is broken
if [ "$providerip" = "" ]
then
NEW_STATE=off
fi
echo -n "BatState: "
echo $NEW_STATE

# Enable / Disable Batman Servermode
for MESH in /sys/class/net/*/mesh; do
OLD_STATE="$(cat $MESH/gw_mode)"
[ "$OLD_STATE" == "$NEW_STATE" ] && continue
echo "Statechange!"
echo $NEW_STATE > $MESH/gw_mode
echo 100MBit/100MBit > $MESH/gw_bandwidth
logger "batman gateway mode changed to $NEW_STATE"
echo -e "Somethings wrong the $GWNAME\nCheck immidiately\nNew GW Mode: $NEW_STATE\nProviderInterface IP: $providerip\nTest Result: $RESULT" | mail -s "GW Mode changed on $GWNAME" mephisto@mephis.to,mail@dreessen.de,frnk@bk.ru
done
