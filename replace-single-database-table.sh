#!/bin/bash

PANTHEON_ENV=$1
TABLE=$2
FILE=$3
USAGE="bash node_access-replace.sh <pantheon-environment-suffix> <table-to-replace> <single-table-to-import.sql>"

if [ ! -f ".env" ]; then
    echo "Error: .env file not found. Please create a .env file with your Terminus credentials 'TERMINUS_EMAIL' and 'TERMINUS_MACHINE_TOKEN'."
    exit 1
fi

source .env
echo -e "Replacing the contents of the '$TABLE' table in '$PANTHEON_PROJECT.$PANTHEON_ENV'\n";
echo -e "HAVE YOU TAKEN A FULL DATABASE BACKUP? (y/n)\n";
read -r confirmation
if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo "Do that first!!!! This script runs destructive operations!"
    exit 1
fi

if [ -z "$PANTHEON_ENV" ]; then
    echo "Error: No environment specified as arg 1. Use 'dev', 'test', 'live' etc."
    echo -e "\nUsage: \n\n$USAGE\n";
    exit 1
fi

if [ -z "$PANTHEON_PROJECT" ]; then
    echo "Error: No Pantheon site specified in .env. Add one under 'PANTHEON_PROJECT'"
    exit 1
fi

if [[ -z "$TABLE" || -z "$FILE" ]]; then
    echo "Error: Missing arguments. "
    echo -e "\nUsage: \n\n$USAGE\n";
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: SQL file '$FILE' not found."
    echo -e "\nUsage: \n\n$USAGE\n";
    exit 1
fi

terminus auth:login --email=$TERMINUS_EMAIL --machine-token=$TERMINUS_MACHINE_TOKEN

echo -e "Showing the contents of '$TABLE' before emptying:"
terminus remote:drush $PANTHEON_PROJECT.$PANTHEON_ENV -- sql:query "SELECT * FROM $TABLE;";

# Ask for user confirmation to proceed with the truncation
echo -e "\n\nThis will empty the '$TABLE' table. Are you sure you want to continue? (y/n)"
read -r confirmation
if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo "Operation cancelled, bye."
    exit 1
fi

echo -e "\n\nProceeding with the truncation of the '$TABLE' table and rebuilding the cache...\n"
terminus remote:drush $PANTHEON_PROJECT.$PANTHEON_ENV -- sql:query "TRUNCATE TABLE $TABLE;";
terminus remote:drush $PANTHEON_PROJECT.$PANTHEON_ENV -- cr;

echo -e "Showing the contents of '$TABLE' after emptying. There should be no results:"
terminus remote:drush $PANTHEON_PROJECT.$PANTHEON_ENV -- sql:query "SELECT * FROM $TABLE;";

echo -e "\n\nThe Nodeaccess grants are now gone. Check the grants are correctly emptied in the site before proceeding!!. Press Y when you've done this to import the new Grants (y/n)"
read -r confirmation2
if [[ "$confirmation2" != "y" && "$confirmation2" != "Y" ]]; then
    echo "Operation cancelled, you should now  pull down the PROD database to restore the previous Grant records!!!!."
    exit 2
fi

echo -e "Importing SQL file '$FILE' to the '$TABLE' table...\n"
terminus remote:drush $PANTHEON_PROJECT.$PANTHEON_ENV -- sql:cli < "$FILE";

echo "The '$TABLE' table has been emptied and repopulated successfully."

echo -e "Rebuilding the cache...";
terminus remote:drush $PANTHEON_PROJECT.$PANTHEON_ENV -- cr;
exit 0
