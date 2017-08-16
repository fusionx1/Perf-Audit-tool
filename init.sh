#!/bin/bash
ORG_UUID=$1
SITENAME=$2

$TERMINUS_PATH=$HOME/Projects/pantheon/terminus/bin/terminus

echo "Fetching URL"
URL=$($TERMINUS_PATH env:info $SITENAME.live --format=json| jq .domain)
URL="${URL%\"}"
URL="${URL#\"}"
echo "ENV URL:" $URL

APPSERVER=`curl -sS http://routes.live.getpantheon.com:463/$URL | jq .bindings | grep -E 'host|binding_id' | awk -F\" '{print $4}' | head -2`
APPSERVER_BINDING_ID=`echo $APPSERVER | awk '{print $2}'`
APPSERVER_IP=`echo $APPSERVER | awk '{print $1}'`

gpg2 --card-status > /dev/null

echo "Collecting Log Gists:"
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/files; btool collect_logs;btool forensics;exit;bash --login'

echo "Running btool info:"
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'; btool;exit;bash --login'

echo "Running Watchdog Logs:"
$TERMINUS_PATH remote:drush $SITENAME.live -- ws --count=500 | grep -i “error”

echo "Running Drupal Status:"
$TERMINUS_PATH remote:drush $SITENAME.live -- st

echo "Fetching Files Info:"
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/files; du -h -d 1 .;exit;bash --login';
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/files; find -maxdepth 1 -type d | while read -r dir; do printf "%s:\t" "$dir"; find "$dir" -type f | wc -l; done ;exit;bash --login'

echo "Fetching New Relic Data:"
$TERMINUS_PATH newrelic-data:org $ORG_UUID
$TERMINUS_PATH newrelic-data:org $ORG_UUID --overview

echo "Fetching Heaviest Tables:"
MYSQL_STRING=$($TERMINUS_PATH connection:info $SITENAME.live --format=json| jq .mysql_command)
MYSQL_STRING="${MYSQL_STRING%\"}"
MYSQL_STRING="${MYSQL_STRING#\"}"

export PHP_ID=php5_6; export PATH="/Applications/Dev Desktop/$PHP_ID/bin:/Applications/Dev Desktop/mysql/bin:/Applications/Dev Desktop/tools:$PATH"
$MYSQL_STRING -e "SELECT TABLE_NAME, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) 'Size in MB' FROM information_schema.TABLES WHERE table_schema = 'pantheon' and TABLE_TYPE='BASE TABLE' ORDER BY data_length DESC;
#;";

echo "Fetching Biggest Table Blobs:"
$TERMINUS_PATH blob:columns $SITENAME.live

echo "Analyzing Slow Query Logs:"
  # Get Db server host and binding id.
  echo "Gathering database information ..."
  DB_SERVERS=`ssh $APPSERVER_IP.panth.io -t "cd /srv/bindings/$APPSERVER_BINDING_ID; btool" | grep -i dbserver | awk '{print $4 $2}'`
  # Elites have 2 dbs
  for DB_SERVER in $DB_SERVERS;
  do
    DB_SERVER_IP=`echo $DB_SERVER | cut -d\( -f1 | cut -d\: -f1`
    DB_SERVER_BINDING_ID=`echo $DB_SERVER | cut -d\( -f2 | cut -d\) -f1`

    ssh $DB_SERVER_IP.panth.io -t 'cd /srv/bindings/'$DB_SERVER_BINDING_ID'/logs; pt-query-digest mysqld-slow-query.log;exit;bash --login'
  done

  echo "Fetching Redis:"
  REDIS_CLI=$($TERMINUS_PATH connection:info $SITENAME.live --format=json| jq .redis_command)
  REDIS_CLI="${REDIS_CLI%\"}"
  REDIS_CLI="${REDIS_CLI#\"}"
  $REDIS_CLI info
