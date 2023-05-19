#!/bin/bash

# Author: Sri kumar
# Purpose: Starts a bidder process within a docker container image

inst_folder=/home/ec2-user/ExtendTV/
aws="/usr/local/bin/aws"

# For docker, hostname is equivalent to the 
# docker id
dockerid=`cat /etc/hostname`
echo "My name $dockerid"

mkdir -p $inst_folder
mkdir -p $inst_folder/webserver1 && cd $inst_folder/webserver1

export AWS_PATH=/opt/aws
BIDDER_SECRET_VALUES=$(aws secretsmanager get-secret-value --secret-id $BIDDER_CONFIGURATION_SECRET_NAME --query SecretString --output text)
REGION=$(echo $BIDDER_SECRET_VALUES | jq --raw-output '."Region"' | tr '[:upper:]' '[:lower:]')
ExchangeName=$(echo $BIDDER_SECRET_VALUES | jq --raw-output '."Exchange"')
exchange=$(echo $ExchangeName | tr '[:upper:]' '[:lower:]')

if [ "$exchange" == "spotx2" ]
then
  SpotXORTB="Y"
fi

logfolder="/media/ephemeral0/$exchange/$dockerid/"
echo "Creating my peristence log folder $logfolder"
mkdir -p $logfolder

echo "********* Exchange = $exchange ***********"
echo "********* ExchangeName = $ExchangeName *********"
echo "********* SpotXORTB = $SpotXORTB ***********"

DEPLOYMENT_BUCKET_SUFFIX=$(echo $BIDDER_SECRET_VALUES | jq --raw-output '."spotinst:aws:ec2:group:name"' | tr '[:upper:]' '[:lower:]')

echo "********* DEPLOYMENT_BUCKET_SUFFIX = $DEPLOYMENT_BUCKET_SUFFIX ***********"

BidderURLPostfix="bidder-$REGION.extend.tv"
EventsBidderURLPostfix="eventsbidder-$REGION.extend.tv"

AerospikeBiddingAgent="aerospike-1.databases.zm.private"

# Install helper scripts
mkdir -p $inst_folder/tools
aws s3 cp s3://extendtv-exchange-$DEPLOYMENT_BUCKET_SUFFIX/tools/*.sh $inst_folder/  --force --recursive --no-progress

aws s3 cp s3://extendtv-bidder/geodata-v2/enterprise/GeoIP2-Enterprise.mmdb $inst_folder/webserver1 --no-progress
aws s3 cp s3://extendtv-bidder/geodata-v2/anonymous/GeoIP2-Anonymous-IP.mmdb $inst_folder/webserver1 --no-progress

aws s3 cp s3://extendtv-exchange-$DEPLOYMENT_BUCKET_SUFFIX/GeoCriteriaId3.txt GeoCriteriaId2.txt --force --no-progress
aws s3 cp s3://extendtv-exchange-$DEPLOYMENT_BUCKET_SUFFIX/GeoCriteriaIdCityDMA3.txt GeoCriteriaIdCityDMA2.txt --force --no-progress
aws s3 cp s3://extendtv-exchange-$DEPLOYMENT_BUCKET_SUFFIX/adx_to_iab_category_mapping.txt . --force --no-progress

GeoIPST="MaxMind"

GeoIPDB="Maxmind"
if [ "$GeoIPST" == "SSP" ]
then 
    GeoIPDB="ssp"
fi

WinUrlHost="$ExchangeName$EventsBidderURLPostfix"
if [ "$SpotXORTB" == "Y" ]
then
    WinUrlHost="https:\/\/SpotX2eventsbidder-east.extend.tv\/a.gif"
fi

Port=8000

BidderConfig="<Bidder>
<!-- General Settings //-->
<Name>$ExchangeName</Name>   <!-- Possible Names: GoogleAdx, LiveRail //-->
<Id>Bidder</Id>
<DockerId>${dockerid}</DockerId>
<IP>0.0.0.0</IP>
<Port>${Port}</Port>
<ServerLocation>US${REGION^^}</ServerLocation>
<LogFilePath>${logfolder}/${dockerid}-BidderLog.log</LogFilePath>
<DebugLevel>INFO</DebugLevel>
<BidRequestCollector>FileBidRequestCollector</BidRequestCollector>
<ImpressionCollector>FileImpressionCollector</ImpressionCollector>
<BidRequestBidCollector>FileBidRequestBidCollector</BidRequestBidCollector>
<AdServerEventsCollector>FileAdServerEventsCollector</AdServerEventsCollector>
<CookieEventsCollector>FileCookieEventsCollector</CookieEventsCollector>

<GeoIPDatabase>${GeoIPDB}</GeoIPDatabase>
<Mode>Manual</Mode>           <!-- Manual or Auto //-->
<Bid>1</Bid>                  <!-- 0 for NoBid, 1 for Bid //-->
<!-- <BidVASTTag>http://ad4.liverail.com/?LR_ORDER_ID=65614&LR_ORDER_LINE_ID=58030548&LR_PUBLISHER_ID=20718&LR_SCHEMA=vast2&LR_URL=[URL]&cb=[CACHEBUSTER]</BidVASTTag>      
<BidPrice>1.00</BidPrice> -->

<WinURLHost>${WinUrlHost}</WinURLHost>

<!-- File Collector Settings //-->
<FileBidRequestCollector>
<Filename>BidRequests</Filename>
<Path>${logfolder}</Path>
</FileBidRequestCollector>

<FileImpressionCollector>
<Filename>Impressions</Filename>
<Path>${logfolder}</Path>
</FileImpressionCollector>

<FileBidRequestBidCollector>
<Filename>BidRequestBids</Filename>
<Path>${logfolder}</Path>
</FileBidRequestBidCollector>

<FileAdServerEventsCollector>
<Filename>AdServerEvents</Filename>
<Path>${logfolder}</Path>
</FileAdServerEventsCollector>

<FileCookieEventsCollector>
<Filename>CookieEvents</Filename>
<Path>${logfolder}</Path>
</FileCookieEventsCollector>

<GeoCriteriaIdFilePath>GeoCriteriaId2.txt</GeoCriteriaIdFilePath>
<GeoCriteriaIdCityDMAFilePath>GeoCriteriaIdCityDMA2.txt</GeoCriteriaIdCityDMAFilePath>

<IABCategoryMappingFilePath>adx_to_iab_category_mapping.txt</IABCategoryMappingFilePath>

<RedisConfigFrequency>1800</RedisConfigFrequency>

<Maxmind>
        <DataFilename>GeoIP2-Enterprise.mmdb</DataFilename>
</Maxmind>

<Aerospike>
<AerospikePort>3000</AerospikePort>
<AerospikeUserProfileHost>$AerospikeBiddingAgent</AerospikeUserProfileHost>
<AerospikeBiddingAgentHost>$AerospikeBiddingAgent</AerospikeBiddingAgentHost>
</Aerospike>

<BiddingAgentFrequency>1800</BiddingAgentFrequency> <!-- Seconds -->
<MetricsFrequency>60</MetricsFrequency> <!-- Seconds -->

<!-- Exchanges //-->
<Exchanges>
        <Exchange>
                <Name>$ExchangeName</Name>
                <TestMode>0</TestMode>
                <!-- Bidding Agents //-->
                <BiddingAgents>
                </BiddingAgents>
        </Exchange>
</Exchanges>
</Bidder>"

echo "Generating config"
echo $BidderConfig > $inst_folder/webserver1/BidderConfig.xml
chown ec2-user:ec2-user $inst_folder/webserver1/BidderConfig.xml

aws s3 cp s3://extendtv-exchange-$DEPLOYMENT_BUCKET_SUFFIX/webserver1 $inst_folder/webserver1/webserver --force --no-progress

# TBD - will be removed after testing
aws s3 cp s3://extendtv-bidder-production/releases/tags/EBP-781/webserver $inst_folder/webserver1/webserver --force --no-progress

chmod +x $inst_folder/webserver1/webserver
cd $inst_folder/webserver1/
echo 'Starting webserver'
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH && ./webserver &

# wait forever
echo 'Starting wait loop'
while true
do
  tail -f /dev/null & wait ${!}
done
