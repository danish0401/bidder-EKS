#!/bin/sh
FORMAT=`date +%Y-%m-%d`
MONTH=`date +%m`
DAY=`date +%d`
YEAR=`date +%Y`
find /media/ephemeral0/upload/$EXCHANGE/ -name "*logrotate*"  -size  0 -print0 |xargs -0 rm
echo "Uploading to s3://extendtv-logs-test-bucket/$YEAR/$MONTH/$DAY/"
aws s3 sync /media/ephemeral0/upload/$EXCHANGE/ "s3://extendtv-logs-test-bucket/$YEAR/$MONTH/$DAY/" --region $BUCKET_REGION --output text