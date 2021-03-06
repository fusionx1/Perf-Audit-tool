#!/bin/bash
ORG_UUID=$1
SITENAME=$2
YUBI_KEY=$3
ds=$(date '+%d/%m/%Y %H:%M:%S');
echo "Perf audit started": . $ds
TERMINUS_PATH='/usr/local/bin/terminus'

echo "==============" > ./output/initial-info.txt
echo "FETCHING URL" >> ./output/initial-info.txt
echo "==============" >> ./output/initial-info.txt

URL=$($TERMINUS_PATH env:info $SITENAME.live --format=json| jq .domain)
URL="${URL%\"}"
URL="${URL#\"}"

ORG_NAME=$($TERMINUS_PATH org:list --format=json | jq .['"'$1'"'].label)

echo "ENV URL:" $URL >> ./output/initial-info.txt
echo "ORGANIZATION NAME:" $ORG_NAME >> ./output/initial-info.txt

FRAMEWORK=$($TERMINUS_PATH site:info $SITENAME --format=json| jq .framework)
FRAMEWORK="${FRAMEWORK%\"}"
FRAMEWORK="${FRAMEWORK#\"}"

echo "FRAMEWORK:" $FRAMEWORK >> ./output/initial-info.txt

APPSERVER=`curl -sS http://routes.live.getpantheon.com:463/$URL | jq .bindings | grep -E 'host|binding_id' | awk -F\" '{print $4}' | head -2`
APPSERVER_BINDING_ID=`echo $APPSERVER | awk '{print $2}'`
APPSERVER_IP=`echo $APPSERVER | awk '{print $1}'`

gpg2 --card-status > /dev/null

echo "======================" > ./output/gist-logs.txt
echo "Collecting Log Gists:" >> ./output/gist-logs.txt
echo "======================" >> ./output/gist-logs.txt

echo "Check most recent 100 lines:" > ./output/logs-first100.txt
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'; ls -la;cd logs;tail -100 nginx-error.log;tail -100 php-error.log;tail -100 php-fpm-error.log;exit;bash --login'  >> ./output/logs-first100.txt

echo "Search for any 500 type status codes:" > ./output/500-status-code.txt
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'; grep " 50[0-9] " nginx-access.log;exit;bash --login'  > ./output/500-status-code.txt

echo "=====================" > ./output/drupal-detailed-info.txt
echo "=====================" > ./output/wordpress-detailed-info.txt

if [[ "$FRAMEWORK" == "drupal" || "$FRAMEWORK" == "drupal8" ]]
then
  echo "FETCHING DRUPAL INFO:" >> ./output/drupal-detailed-info.txt
  echo "=====================" >> ./output/drupal-detailed-info.txt
  echo "Running Watchdog Logs:"
  $TERMINUS_PATH remote:drush $SITENAME.live -- ws --count=500 | grep -i “error” >> ./output/drupal-detailed-info.txt
  echo "Running Drupal Status:"
  $TERMINUS_PATH remote:drush $SITENAME.live -- st  >> ./output/drupal-detailed-info.txt
  echo "List of all enabled non-core modules:"
  $TERMINUS_PATH remote:drush $SITENAME.live -- pm-list --type=module --no-core --status=enabled  >> ./output/drupal-detailed-info.txt
  echo "Drupal Settings.php:"
  ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/code;ls -la;cat sites/default/settings.php;exit;bash --login' >> ./output/drupal-detailed-info.txt

else
  echo "FETCHING WORDPRESS INFO:" >> ./output/wordpress-detailed-info.txt
  echo "=====================" >> ./output/wordpress-detailed-info.txt

  ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/code;ls -la;cat wp-config.php;exit;bash --login'  >> ./output/wordpress-detailed-info.txt
  $TERMINUS_PATH remote:wp $SITENAME.live -- core version >> ./output/wordpress-detailed-info.txt
  $TERMINUS_PATH remote:wp $SITENAME.live -- plugin list >> ./output/wordpress-detailed-info.txt
  $TERMINUS_PATH remote:wp $SITENAME.live -- cron event list >> ./output/wordpress-detailed-info.txt
fi

echo "====================" > ./output/files-info.txt
echo "Fetching Files Info:" >> ./output/files-info.txt
echo "====================" >> ./output/files-info.txt

ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/files; du -h -d 1 .;exit;bash --login'  >> ./output/files-info.txt
ssh $APPSERVER_IP.panth.io -t 'cd /srv/bindings/'$APPSERVER_BINDING_ID'/files; find -maxdepth 1 -type d | while read -r dir; do printf "%s:\t" "$dir"; find "$dir" -type f | wc -l; done ;exit;bash --login'  >> ./output/files-info.txt

echo "========================" > ./output/newrelic-info.txt
echo "Fetching New Relic Data:" >> ./output/newrelic-info.txt
echo "========================" >> ./output/newrelic-info.txt

$TERMINUS_PATH newrelic-data:org $ORG_UUID >>  ./output/newrelic-info.txt
$TERMINUS_PATH newrelic-data:org $ORG_UUID --overview  >> ./output/newrelic-info.txt

echo "=======================" >  ./output/fetching-heaviest-tables.txt
echo "FETCHING DATABASE INFO:" >>  ./output/fetching-heaviest-tables.txt
echo "=======================" >> ./output/fetching-heaviest-tables.txt

echo "Fetching Heaviest Tables:" >>  ./output/fetching-heaviest-tables.txt
MYSQL_STRING=$($HOME/Projects/pantheon/terminus/bin/terminus connection:info $SITENAME.live --format=json| jq .mysql_command)
MYSQL_STRING="${MYSQL_STRING%\"}"
MYSQL_STRING="${MYSQL_STRING#\"}"

export PHP_ID=php5_6; export PATH="/Applications/Dev Desktop/$PHP_ID/bin:/Applications/Dev Desktop/mysql/bin:/Applications/Dev Desktop/tools:$PATH"
$MYSQL_STRING -e "SELECT TABLE_NAME, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) 'Size in MB' FROM information_schema.TABLES WHERE table_schema = 'pantheon' and TABLE_TYPE='BASE TABLE' ORDER BY data_length DESC LIMIT 20;
;" >>  ./output/fetching-heaviest-tables.txt

export PHP_ID=php5_6; export PATH="/Applications/Dev Desktop/$PHP_ID/bin:/Applications/Dev Desktop/mysql/bin:/Applications/Dev Desktop/tools:$PATH"

echo "Fetching Biggest Table Blobs:" >  ./output/fetching-biggest-blobs.txt
$TERMINUS_PATH blob:columns $SITENAME.live  >>  ./output/fetching-biggest-blobs.txt

echo "Analyzing Slow Query Logs:" > ./output/query-log-analysis.txt
  # Get Db server host and binding id.
  echo "Gathering database information ..."
  DB_SERVERS=`ssh $APPSERVER_IP.panth.io -t "cd /srv/bindings/$APPSERVER_BINDING_ID; btool" | grep -i dbserver | awk '{print $4 $2}'`
  # Elites have 2 dbs
  for DB_SERVER in $DB_SERVERS;
  do
    DB_SERVER_IP=`echo $DB_SERVER | cut -d\( -f1 | cut -d\: -f1`
    DB_SERVER_BINDING_ID=`echo $DB_SERVER | cut -d\( -f2 | cut -d\) -f1`
    ssh $DB_SERVER_IP.panth.io -t 'cd /srv/bindings/'$DB_SERVER_BINDING_ID'/logs; pt-query-digest mysqld-slow-query.log;exit;bash --login'  >> ./output/query-log-analysis.txt
  done

  echo "====================" > ./output/redis-analysis.txt
  echo "FETCHING REDIS INFO:" >> ./output/redis-analysis.txt
  echo "====================" >> ./output/redis-analysis.txt

  REDIS_CLI=$($TERMINUS_PATH connection:info $SITENAME.live --format=json| jq .redis_command)
  REDIS_CLI="${REDIS_CLI%\"}"
  REDIS_CLI="${REDIS_CLI#\"}"
  $REDIS_CLI info  >> ./output/redis-analysis.txt

  echo "===========================================" > ./output/custom-domain.txt
  echo "FETCHING CUSTOM DOMAINS, GLOBAL CDN & HSTS:" >> ./output/custom-domain.txt
  echo "===========================================" >> ./output/custom-domain.txt

echo "CUSTOM DOMAINS:" >> ./output/custom-domain.txt

$TERMINUS_PATH domain:list $SITENAME.live --format=json | jq '.[].domain' | while read i; do
  DOMAIN="${i%\"}"
  DOMAIN="${DOMAIN#\"}"
  echo $DOMAIN: >> ./output/custom-domain.txt
  if curl -Is $DOMAIN | grep -i fastly-debug-digest >/dev/null;
  then
    echo " - Has Fastly CDN:" >> ./output/custom-domain.txt
    if dig $DOMAIN | grep 23.185.0. >/dev/null; 
    then     
        echo " - Pantheon GCDN Enabled" >> ./output/custom-domain.txt
    else     
        echo " - Not Pantheon GCDN" >> ./output/custom-domain.txt
    fi
  else
    echo " - No Fastly CDN">> ./output/custom-domain.txt
  fi

  if curl -Is $DOMAIN | grep -i "strict Strict-Transport-Security" >/dev/null;
  then     
    echo " - Its HSTS Enabled" >> ./output/custom-domain.txt
  else     
    echo " - Not HSTS Enabled" >> ./output/custom-domain.txt
  fi
  echo "-------------------------------------------------------------------------------------------------" >> ./output/custom-domain.txt
done

ACCESS_TOKEN="3816526681a4a68f2cc989da4f96565f2f073368"

description="Data analysis for " $SITENAME
public="false"
filename=$SITENAME

desc=$(echo "$description" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
file1=$(cat ./output/initial-info.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file2=$(cat ./output/logs-first100.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file3=$(cat ./output/500-status-code.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file4=$(cat ./output/drupal-detailed-info.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file5=$(cat ./output/wordpress-detailed-info.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file6=$(cat ./output/custom-domain.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file7=$(cat ./output/files-info.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file8=$(cat ./output/newrelic-info.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file9=$(cat ./output/fetching-heaviest-tables.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file10=$(cat ./output/fetching-biggest-blobs.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file11=$(cat ./output/query-log-analysis.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
file12=$(cat ./output/redis-analysis.txt | jq --slurp --raw-input '.' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')


curl -v -H "Content-Type: text/json; charset=utf-8" \
        -H "Authorization: Token $ACCESS_TOKEN" \
        -X POST https://api.github.com/gists -d @- << EOF
{
  "description": "$desc",
  "public": "$public",
  "files": {
       "A.initial-info" : {
          "content": "$file1"
       },
       "B.logs-first100" : {
          "content": "$file2"
       },
       "C.500-status-code" : {
          "content": "$file3"
       },
       "D.drupal-detailed-info" : {
          "content": "$file4"
       },
       "E.wordpress-detailed-info" : {
          "content": "$file5"
       },
       "F.custom-domain" : {
          "content": "$file6"
       },
       "G.files-info" : {
          "content": "$file7"
       },
       "H.newrelic-info" : {
          "content": "$file8"
       },
       "I.fetching-heaviest-tables" : {
          "content": "$file9"
       },
       "J.fetching-biggest-blobs" : {
          "content": "$file10"
       },
       "K.query-log-analysis" : {
          "content": "$file11"
       },
       "L.redis-analysis" : {
          "content": "$file12"
       }
   }
}
EOF

echo "Archiving...."
cd output
for i in *; do cat /dev/null > $i; done
cd ..


cd nr-image-capture
./newrelic_image_capture.sh $SITENAME $YUBI_KEY $FRAMEWORK $ORG_UUID
cd ..

cd ./nr-image-capture/screenshots/
python ../../upload.py
cd ../../
CLEAN_SITENAME="${SITENAME// /.}"
CLEAN_ORGNAME="${ORG_NAME// /.}"
python slide.py $CLEAN_ORGNAME $CLEAN_SITENAME

echo "Performance Audit Completed"
dc=$(date '+%d/%m/%Y %H:%M:%S');
echo "Perf audit completed!": . $dc
