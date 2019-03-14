#!/bin/bash

# Get Asset DB from Tenable.io
# This writes to /var/log/tenable
# v1.0 Zach Christensen

## Usage ########################
# ./getAssets.sh

# Update keys (if needed)
ACCESSKEY='<YOUR ACCESS KEY>';
SECRETKEY='<YOUR SECRETKEY>';
SLEEP="30s";


############################################################################
######                                                                ######
######     DO NOT MODIFY BELOW (Unless you know what you are doing)   ######
######                                                                ######
############################################################################

# Global Variables
OUTPUTDIR="/var/log/tenable";
DATE=$(date +%Y_%m_%d);

# Check for root
if [[ $EUID -ne 0 ]]; then
  echo -e "\nPlease Run as root!\n"
  exit
fi

# Verify Directory Structure is correct
if [[ ! -d ${OUTPUTDIR}/db ]]; then
        mkdir -p ${OUTPUTDIR}/db
fi
echo -e "Preliminary checks passed. Initializing..\n"

# Prompt if setup is complete
echo -e "Access Key: ${ACCESSKEY}\nSecret Key: ${SECRETKEY}";
echo -e "\nIs the above configuration correct? [Y/n]";
read answer
while true; do
        case $answer in
                [yY]* ) echo -e "\nWell done good sir! Starting\n";
                       break;;
                [nN]* ) echo -e "\nPlease update script with correct information\n";
                        exit;;
                * ) echo 'Please press "Y" for yes or "N" for no';
                        exit;;
        esac
done;

# Generate Assets API Call
generate_assets() {
  curl -X POST -H "Content-Type: application/json" --data '{"chunk_size":10000}' -H "X-ApiKeys: accessKey=${ACCESSKEY}; secretKey=${SECRETKEY}" https://cloud.tenable.com/assets/export | awk -F':' '{print $2}' | grep -o '[^\"\}]*'
  sleep ${SLEEP}
}

# Query Report API Call
query_report() {
  curl -H "X-ApiKeys: accessKey=${ACCESSKEY}; secretKey=${SECRETKEY}" https://cloud.tenable.com/assets/export/"$1"/status | awk -F':' '{print $3}' | grep -o '\w\]' | grep -o '\w'
  sleep ${SLEEP}
}

# Generate Asset
echo -e "\nGenerating Report";
EXPORT_UUID=$(generate_assets);
echo -e "Export UUID: ${EXPORT_UUID}\n";

# Query Reports
echo -e "\nQuery Report";
CHUNKS=$(query_report "${EXPORT_UUID}");
echo -e "Total Chunks: ${CHUNKS}\n";

# Download Report
echo -e "\nDownloading Report. Please wait..";
for i in $(eval echo "{1..${CHUNKS}}"); do
  curl -H "X-ApiKeys: accessKey=${ACCESSKEY}; secretKey=${SECRETKEY}" https://cloud.tenable.com/assets/export/"${EXPORT_UUID}"/chunks/"$i" >> ${OUTPUTDIR}/db/${DATE}_asset_db;
  echo "Count: $i";
  sleep ${SLEEP}
done;

echo -e "\nComplete. Results Written to ${OUTPUTDIR}/db."
