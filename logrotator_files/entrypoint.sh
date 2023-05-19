#!/bin/sh

cat >/etc/logrotate.conf <<.
/media/ephemeral0/$EXCHANGE/*bidder*/*Bidder*.log {
    missingok
    dateext
    dateformat rotate-%Y-%m-%d-%s
    rotate 1
    nomail
    nosharedscripts
    nocompress
    copytruncate
    olddir /media/ephemeral0/upload/$EXCHANGE
    lastaction
        /etc/logrotate.sh
    endscript
}
.

# Create directory for rotated logs
mkdir -p /media/ephemeral0/upload/$EXCHANGE

touch crontab.tmp \
&& echo "$CRON_EXPRESSION /usr/sbin/logrotate -v -f --state /tmp/logrotate.status /etc/logrotate.conf > /proc/1/fd/1 2>/proc/1/fd/2" > crontab.tmp \
&& crontab crontab.tmp \
&& rm -rf crontab.tmp

/usr/sbin/crond -f