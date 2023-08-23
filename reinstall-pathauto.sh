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


if [[ $(echo $PANTHEON_PROJECT) == '' ]]; then
    echo -e 'ERROR: No Pantheon project specified in $PANTHEON_PROJECT, around line 12.\nERROR: Exiting...'
    exit 1
fi

if [[ $(echo $SITE) != '' ]] && $(cd $SITE); then
    if [[ ! $1 ]] || [[ $1 == '' ]]; then
        echo 'ERROR: No environment provided. Usage: pantheon-deploy.sh <dev/test/live/my-multidev-env>'
        exit 1
    else
        cd $SITE
        echo -e 'Jumping to site location: '$SITE
        echo -e 'Reinstalling pathauto on "'$ENV'" environment...\n'
        echo -e 'You may need to run this several times if a memory error appears\n'
        
        envExists=$(terminus remote:drush $PANTHEON_PROJECT.$ENV 2>&1)

        if [[ "$envExists" == " [error]"* ]]; then
            echo -e '\nEnvironment "'$ENV'" cannot be found. Exiting...\n'
            exit 1;
        else 
            terminus remote:drush $PANTHEON_PROJECT.$ENV -- pm:uninstall pathauto -y
            terminus remote:drush $PANTHEON_PROJECT.$ENV -- cr
            terminus remote:drush $PANTHEON_PROJECT.$ENV -- en -y pathauto
            terminus remote:drush $PANTHEON_PROJECT.$ENV -- cim -y --partial
            terminus remote:drush $PANTHEON_PROJECT.$ENV -- cr
            
            if [ $? -eq 255 ]; then
                echo -e '\nMemory error, try again. Exiting...\n'
                exit 1;
            else 
                echo -e '\nPathauto reinstallation complete, now save a page to test it worked!\n'
                exit 1;
            fi;
            cd $HERE;
        fi
    fi
else 
    echo -e 'ERROR: You must specify a local site location in $SITE (around line 9).\nERROR: '$SITE' does not exist! \nExiting...'
    exit 1
fi
