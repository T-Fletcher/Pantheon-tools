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
        echo -e 'You may need to run this several times if a memory error appears, particularly when enabling modules\n'
        
        echo -e 'Importing new and updated configuration to '$ENV
        terminus remote:drush $PANTHEON_PROJECT.$ENV -- cim -y --partial && 

        echo -e '\n*** WARNING *** \ncim --partial only imports new and updated config - deleted entities are left inact:\n\nhttps://www.drush.org/latest/commands/config_import/\n\nDelete these entities via the UI of the target site, where possible!\n'
        
        echo -e 'Rebuilding cache' && 
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
