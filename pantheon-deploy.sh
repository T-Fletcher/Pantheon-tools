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
        
        read -p "Do these updates require a drush database update on DEV .e.g a Drupal Core update? (Note Pantheon runs update.php by default on TEST and LIVE deployments) (y/n)" response

        if [[ $response = 'y' || $response = 'Y' ]]; then
            UPDB=1;
            echo -e '\nOk, running "drush updb" after importing changes';
        fi
        echo ''

        read -p "Do you want to run only a partial config import ('y' for partial, 'n' for full)? This uses less memory for crummy servers, but leaves deleted entities intact in the database (y/n)" response

        if [[ $response = 'y' || $response = 'Y' ]];then
         
            read -p "Have you enabled or uninstalled all modules affected by this config on "$ENV" with terminus to reduce the chance of memory issues on import? (y/n)" response

            if [[ $response = 'n' || $response = 'N' ]];then
                echo -e "\nIf you're using a crummy server, you may need to do this to avoid memory errors. Let's see what happens...\n";
            fi
         
            read -p "Have you deleted any entities via the UI on "$ENV" that are removed by this config? (y/n)" response

            if [[ $response = 'n' || $response = 'N' ]];then
                echo -e '\nBetter do that first, or you will have orphaned items in the database!\n';
                exit
            fi

            echo -e '\nImporting new and updated configuration to '$ENV
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
        else 

            echo -e '\nSyncing all configuration to '$ENV
            terminus remote:drush $PANTHEON_PROJECT.$ENV -- cim -y
        fi


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
            echo -e '\Error returned. Better look into it ^^^ Exiting...\n'
            exit 1;
        fi;

        # Jump back to wherever we ran the script from
        cd $HERE;
    else
        echo 'ERROR: No environment provided. Usage: pantheon-deploy.sh <dev/test/live>'
        exit 1;
    fi
else 
    echo -e 'ERROR: You must specify a local site location in $SITE (around line 9).\nERROR: '$SITE' does not exist! \nExiting...';
    exit 1;
fi
