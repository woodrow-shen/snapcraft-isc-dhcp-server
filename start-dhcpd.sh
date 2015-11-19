#!/bin/sh

set -e
set -x

# create necessary directories
mkdir -p $SNAP_APP_DATA_PATH/etc/apparmor.d/dhcpd.d
mkdir -p $SNAP_APP_DATA_PATH/etc/default/
mkdir -p $SNAP_APP_DATA_PATH/etc/dhcp/
mkdir -p $SNAP_APP_DATA_PATH/var/lib/dhcp
mkdir -p $SNAP_APP_DATA_PATH/var/run
mkdir -p $SNAP_APP_DATA_PATH/var/db/
touch $SNAP_APP_DATA_PATH/var/db/dhcpd.leases

# 
test -f $SNAP_APP_PATH/sbin/dhcpd || exit 0

cp -n $SNAP_APP_PATH/etc/default/isc-dhcp-server $SNAP_APP_DATA_PATH/etc/default/isc-dhcp-server
DHCPD_DEFAULT="${DHCPD_DEFAULT:-$SNAP_APP_DATA_PATH/etc/default/isc-dhcp-server}"

# It is not safe to start if we don't have a default configuration...
if [ ! -f "$DHCPD_DEFAULT" ]; then
        echo "$DHCPD_DEFAULT does not exist! - Aborting..."
        exit 0
fi

. /lib/lsb/init-functions

# Read init script configuration
[ -f "$DHCPD_DEFAULT" ] && . "$DHCPD_DEFAULT"

NAME=dhcpd
DESC="ISC DHCP server"
# fallback to default config file
cp -n $SNAP_APP_PATH/etc/dhcpd.conf $SNAP_APP_DATA_PATH/etc/dhcpd.conf
DHCPD_CONF=${DHCPD_CONF:-$SNAP_APP_PATH/etc/dhcpd.conf}

# try to read pid file name from config file, with fallback to /var/run/dhcpd.pid
if [ -z "$DHCPD_PID" ]; then
        DHCPD_PID=$(sed -n -e 's/^[ \t]*pid-file-name[ \t]*"(.*)"[ \t]*;.*$/\1/p' < "$DHCPD_CONF" 2>/dev/null | head -n 1)
fi
DHCPD_PID="${DHCPD_PID:-$SNAP_APP_DATA_PATH/var/run/dhcpd.pid}"

test_config()
{
        if ! $SNAP_APP_PATH/sbin/dhcpd -t $OPTIONS -q -cf "$DHCPD_CONF" > /dev/null 2>&1; then
                echo "dhcpd self-test failed. Please fix $DHCPD_CONF."
                echo "The error was: "
		$SNAP_APP_PATH/sbin/dhcpd -t $OPTIONS -cf "$DHCPD_CONF"
                exit 1
        fi
}

# single arg is -v for messages, -q for none
check_status()
{
    if [ ! -r "$DHCPD_PID" ]; then
        test "$1" != -v || echo "$NAME is not running."
        return 3
    fi
    if read pid < "$DHCPD_PID" && ps -p "$pid" > /dev/null 2>&1; then
        test "$1" != -v || echo "$NAME is running."
        return 0
    else
        test "$1" != -v || echo "$NAME is not running but $DHCPD_PID exists."
        return 1
    fi
}

# start dhcpd service
test_config
log_daemon_msg "Starting $DESC" "$NAME"
start-stop-daemon --start --quiet --pidfile "$DHCPD_PID" \
	--exec $SNAP_APP_PATH/sbin/dhcpd -- \
	-q $OPTIONS -cf "$DHCPD_CONF" -pf "$DHCPD_PID" $INTERFACES \
	-lf $SNAP_APP_DATA_PATH/var/db/dhcpd.leases
sleep 2

if check_status -q; then
	log_end_msg 0
else
	log_failure_msg "check syslog for diagnostics."
	log_end_msg 1
	exit 1
fi

exit 0
