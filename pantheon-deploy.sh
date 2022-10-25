#!/bin/sh

# Uses Pantheon's Terminus interface to import config from deployed changes to DEV, TEST and LIVE environments

# To use, create a .env file containing the following variables and add your details:

# SITE='/path/to/my/local/repo/'
# PANTHEON_PROJECT='my-pantheon-project'

# Usage: bash pantheon-deploy.sh ENV 
# e.g bash pantheon-deploy.sh test

source .env

HERE=$(pwd)
ENV=$1

if [[ $(echo $PANTHEON_PROJECT) == '' ]]; then
    echo -e 'ERROR: No Pantheon project specified in $PANTHEON_PROJECT, around line 12.\nERROR: Exiting...'
    exit 1
fi

if [[ $(echo $SITE) != '' ]] && $(cd $SITE); then
    cd $SITE
    echo -e 'Jumping to site location: '$SITE    
    if [[ $1 == 'dev' ]] || [[ $1 == 'test' ]] || [[ $1 == 'live' ]]; then
        echo -e 'Importing configuration to '$ENV' and rebuilding cache. You may need to run this several times if a memory error appears\n'
        terminus remote:drush $PANTHEON_PROJECT.$ENV -- cim -y && 
        echo -e 'Import complete, rebuilding cache' && 
        terminus remote:drush $PANTHEON_PROJECT.$ENV -- cr && 
        echo -e 'Cache rebuild complete!'
        cd $HERE;
    else
        echo 'ERROR: No environment provided. Usage: pantheon-deploy.sh <dev/test/live>'
        exit 1
    fi
else 
    echo -e 'ERROR: You must specify a local site location in $SITE (around line 9).\nERROR: '$SITE' does not exist! \nExiting...'
    exit 1
fi
