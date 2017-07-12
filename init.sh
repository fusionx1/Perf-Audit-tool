#!/bin/bash
SITENAME=$1

echo "Fetching Organization:"
ORG_UUID=$($HOME/Projects/pantheon/terminus/bin/terminus site:info $SITENAME --format=json| jq .organization)
ORG_UUID="${ORG_UUID%\"}"
ORG_UUID="${ORG_UUID#\"}"
echo "ORG UUID:" $ORG_UUID

echo "Fetching URL"
URL=$($HOME/Projects/pantheon/terminus/bin/terminus env:info $SITENAME.live --format=json| jq .domain)
URL="${URL%\"}"
URL="${URL#\"}"
echo "ENV URL:" $URL

APPSERVER=`curl -sS http://routes.live.getpantheon.com:463/$URL | jq .bindings | grep -E 'host|binding_id' | awk -F\" '{print $4}' | head -2`
APPSERVER_BINDING_ID=`echo $APPSERVER | awk '{print $2}'`
APPSERVER_IP=`echo $APPSERVER | awk '{print $1}'`

gpg2 --card-status > /dev/null

echo "Fetching Files Info:"
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/files; du -h -d 1 .;exit;bash --login';

echo "Collecting Logs:"
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/files; btool collect_logs;exit;bash --login'
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/files; find -maxdepth 1 -type d | while read -r dir; do printf "%s:\t" "$dir"; find "$dir" -type f | wc -l; done ;exit;bash --login'

echo "Running Watchdog Logs:"
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'; btool drush ws --count=500 | grep "Error";exit;bash --login'

echo "Fetching New Relic Data:"
$HOME/Projects/pantheon/terminus/bin/terminus newrelic-data:org $ORG_UUID
$HOME/Projects/pantheon/terminus/bin/terminus newrelic-data:org $ORG_UUID --overview

echo "Fetching Heaviest Tables:"
MYSQL_STRING=$($HOME/Projects/pantheon/terminus/bin/terminus connection:info $SITENAME.live --format=json| jq .mysql_command)
MYSQL_STRING="${MYSQL_STRING%\"}"
MYSQL_STRING="${MYSQL_STRING#\"}"

export PHP_ID=php5_6; export PATH="/Applications/Dev Desktop/$PHP_ID/bin:/Applications/Dev Desktop/mysql/bin:/Applications/Dev Desktop/tools:$PATH"
$MYSQL_STRING -e "SELECT TABLE_NAME, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) 'Size in MB' FROM information_schema.TABLES WHERE table_schema = 'pantheon' and TABLE_TYPE='BASE TABLE' ORDER BY data_length DESC;
#;";

echo "Fetching Biggest Table Blobs:"
$HOME/Projects/pantheon/terminus/bin/terminus blob:columns $SITENAME.live

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

  echo "Fetching Redis Info:"
  REDIS_CLI=$($HOME/Projects/pantheon/terminus/bin/terminus connection:info $SITENAME.live --format=json| jq .redis_command)
  REDIS_CLI="${REDIS_CLI%\"}"
  REDIS_CLI="${REDIS_CLI#\"}"
  $REDIS_CLI info

 
