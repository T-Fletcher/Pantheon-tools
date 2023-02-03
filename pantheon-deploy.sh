#!/bin/sh

# Uses Pantheon's Terminus interface to import config from deployed changes to DEV, TEST and LIVE environments

# To use, create a .env file containing the following variables and add your details:

# SITE='/path/to/my/local/repo/'
# PANTHEON_PROJECT='my-pantheon-project'

# Usage: bash pantheon-deploy.sh ENV 
# e.g bash pantheon-deploy.sh test

if [[ -f .env ]]; then
    source .env
else 
    echo -e 'You must create a .env file to specify your project details, see script comments.'
    exit 0
fi

HERE=$(pwd)
ENV=$1
UPDB=0

if [[ $(echo $PANTHEON_PROJECT) == '' ]]; then
    echo -e 'ERROR: No Pantheon project specified in $PANTHEON_PROJECT, around line 12.\nERROR: Exiting...'
    exit 1
fi

if [[ $(echo $SITE) != '' ]] && $(cd $SITE); then
    cd $SITE
    echo -e 'Jumping to site location: '$SITE    
    if [[ $1 == 'dev' ]] || [[ $1 == 'test' ]] || [[ $1 == 'live' ]]; then
        echo -e 'You may need to run this several times if a memory error appears\n'
        echo -e 'NOTE: If your config changs involve adding/removing modules, enable/uninstall them first with terminus 
to reduce the chance of memory issues before importing config.\n'
        
        read -p "Have you enabled or uninstalled all modules affected by this config on "$ENV"? (y/n)" response

        if [[ $response = 'y' || $response = 'Y' ]];then
            echo -e '\nOk, next question:\n'
            read -p "Have you deleted any entities via the UI on "$ENV" that are removed by this config? (y/n)" response

            if [[ $response = 'y' || $response = 'Y' ]];then
                echo -e '\nOk, next question:\n';
                read -p "Do these updates require a drush database update .e.g a Drupal Core update? (y/n)" response

                if [[ $response = 'y' || $response = 'Y' ]];then
                    UPDB=1 && echo '\nOk, running a drush updb before importing changes\n';
                else
                    echo -e '\nNo worries, importing partial config changes\n';
                fi
            else
                echo 'Better do that first!';
                exit
            fi
        else
            echo 'Better do that first!';
            exit
        fi


echo -e 'Importing new and updated configuration to '$ENV

echo -e '
*** WARNING ***
* 
* cim --partial only imports new and updated config - deleted entities are left intact:
* 
* https://www.drush.org/latest/commands/config_import/
* 
* DO NOT try to delete them programatically, this can WSOD your site!
* Delete these entities via the UI of the target site before importing the config changes.
* 
***************
'
        terminus remote:drush $PANTHEON_PROJECT.$ENV -- cim -y --partial

        if [ $? -eq 0 ]; then
            if [ $UPDB -eq 1 ]; then
                echo -e 'Running database updates, if any'
                terminus remote:drush $PANTHEON_PROJECT.$ENV -- updb
            fi
            echo -e 'Rebuilding cache'
            terminus remote:drush $PANTHEON_PROJECT.$ENV -- cr
            echo -e 'Cache rebuild complete!'
        elif [ $? -eq 255 ]; then
            echo -e '\nMemory error, try again. Exiting...\n'
            exit 1;
        else 
            echo -e '\nSome error, try again. Exiting...\n'
            exit 1;
        fi;

        cd $HERE;
    else
        echo 'ERROR: No environment provided. Usage: pantheon-deploy.sh <dev/test/live>'
        exit 1
    fi
else 
    echo -e 'ERROR: You must specify a local site location in $SITE (around line 9).\nERROR: '$SITE' does not exist! \nExiting...'
    exit 1
fi
