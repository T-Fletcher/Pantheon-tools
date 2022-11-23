#!/bin/sh

# Uses Pantheon's Terminus interface to clear orphaned schema data from uninstalled modules on  DEV, TEST and LIVE environments

# WARNING: DO NOT USE ON INSTALLED MODULES!

# To use, create a .env file containing the following variables and add your details:

# SITE='/path/to/my/local/repo/'
# PANTHEON_PROJECT='my-pantheon-project'

# Usage: bash pantheon-deploy.sh ENV MODULENAME
# e.g bash pantheon-deploy.sh test rules

source .env

HERE=$(pwd)
ENV=$1
MODULE=$2
USAGE='Usage: pantheon-deploy.sh <dev/test/live> <module_name_1> <module_name_2> ...'

if [[ $(echo $PANTHEON_PROJECT) == '' ]]; then
    echo -e 'ERROR: No Pantheon project specified in $PANTHEON_PROJECT, around line 12.'
    exit 1
fi

if [[ $(echo $SITE) != '' ]] && $(cd $SITE); then
   if [[ $(echo $MODULE) != '' ]]; then 
        cd $SITE
        echo -e 'Jumping to site location: '$SITE    
        
        if [[ $1 == 'dev' ]] || [[ $1 == 'test' ]] || [[ $1 == 'live' ]]; then            
            # @TODO: Add check to see if module is enabled before scrubbing any data
            echo -e "Removing orphaned schema data for module '"$MODULE"' on '"$ENV"' environment. Note this appears to be successful even if no data is found!"
            terminus remote:drush $PANTHEON_PROJECT.$ENV -- php-eval "\Drupal::keyValue('system.schema')->delete('{"$MODULE"}');"
        else
            echo 'ERROR: No environment provided. '$USAGE
            exit 1
        fi
    else
        echo -e 'ERROR: no module name provided. '$USAGE
        exit 1
    fi
else 
    echo -e 'ERROR: You must specify a local site location in $SITE (around line 9).\nERROR: '$SITE' does not exist!'
    exit 1
fi
