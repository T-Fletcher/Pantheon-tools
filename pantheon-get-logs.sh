#!/bin/bash

source .env

# Site UUID is REQUIRED: Site UUID from Dashboard URL, e.g. 12345678-1234-1234-abcd-0123456789ab
SITE_UUID=$PANTHEON_PROJECT_UUID

# Environment is REQUIRED: dev/test/live/or a Multidev
ENV=$1

# Get location to nest per-site logs under corresponding directory
LOC=$(pwd)

#  Default to PROD site logs
if [[ ! $ENV ]]; then
    ENV='live'
    echo -e 'Usage: bash pantheon-get-logs.sh <env>.\n\nNo environment given, defaulting to '$ENV'\n'
fi

# Define where logs are saved
LOGS_LOC=$LOC'/logs'
LOGS_LOC_ENV=$LOGS_LOC'/'$ENV

########### Additional settings you don't have to change unless you want to ###########
# OPTIONAL: Set AGGREGATE_NGINX to true if you want to aggregate nginx logs.
#  WARNING: If set to true, this will potentially create a large file
AGGREGATE_NGINX=false
# if you just want to aggregate the files already collected, set COLLECT_LOGS to FALSE
COLLECT_LOGS=true
# CLEANUP_AGGREGATE_DIR removes all logs except combined.logs from aggregate-logs directory.
CLEANUP_AGGREGATE_DIR=false

echo -e 'For documentation on Pantheon Logs, see https://pantheon.io/docs/logs\n\n'

if [[ ! -d $LOGS_LOC ]]; then
    echo 'No logs directory found, creating one now...\n'
    mkdir logs
fi
if [[ ! -d $LOGS_LOC_ENV ]]; then
    echo -e 'No logs directory found for '$ENV', creating one now...\n'
    mkdir $LOGS_LOC_ENV
fi

cd $LOGS_LOC_ENV

if [ $COLLECT_LOGS == true ]; then
    echo -e "COLLECT_LOGS set to $COLLECT_LOGS. Beginning the process..."
    for app_server in $(dig +short -4 appserver.$ENV.$SITE_UUID.drush.in); do
        echo "get -R logs \"app_server_$app_server\"" | sftp -o Port=2222 "$ENV.$SITE_UUID@$app_server"
    done
    
    # Include MySQL logs
    for db_server in $(dig +short -4 dbserver.$ENV.$SITE_UUID.drush.in); do
        echo "get -R logs \"db_server_$db_server\"" | sftp -o Port=2222 "$ENV.$SITE_UUID@$db_server"
    done
else
    echo 'skipping the collection of logs..'
fi

if [ $AGGREGATE_NGINX == true ]; then
    echo -e "AGGREGATE_NGINX set to $AGGREGATE_NGINX. Starting the process of combining nginx-access logs..."
    mkdir aggregate-logs
    
    for d in $(ls -d app*/nginx); do
        for f in $(ls -f "$d"); do
            if [[ $f == "nginx-access.log" ]]; then
                cat "$d/$f" >> aggregate-logs/nginx-access.log
                cat "" >> aggregate-logs/nginx-access.log
            fi
            if [[ $f =~ \.gz ]]; then
                cp -v "$d/$f" aggregate-logs/
            fi
        done
    done
    
    echo "unzipping nginx-access logs in aggregate-logs directory..."
    for f in $(ls -f aggregate-logs); do
        if [[ $f =~ \.gz ]]; then
            gunzip aggregate-logs/"$f"
        fi
    done
    
    echo "combining all nginx access logs..."
    
    for f in $(ls -f aggregate-logs); do
        cat aggregate-logs/"$f" >> aggregate-logs/combined.logs
    done
    echo 'the combined logs file can be found in aggregate-logs/combined.logs'
else
    echo "AGGREGATE_NGINX set to $AGGREGATE_NGINX. So we're done."
fi

if [ $CLEANUP_AGGREGATE_DIR == true ]; then
    echo 'CLEANUP_AGGREGATE_DIR set to $CLEANUP_AGGREGATE_DIR. Cleaning up the aggregate-logs directory'
    find ./aggregate-logs/ -name 'nginx-access*' -print -exec rm {} \;
fi

# Back to the start
cd $LOC

echo -e '\n\nDone, logs saved in '$LOGS_LOC_ENV'\n\n'
