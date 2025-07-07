#!/bin/sh

FILE1="/etc/init.d/dbus"

# dont edit and remove
sed -i '15i\
    [ -f /var/run/dbus.pid ] && rm -f /var/run/dbus.pid
' "$FILE1"

rm -- "$0"