#!/usr/bin/env bash
#
#

hdfs_upload=1

yyyy=$(date --utc +%Y)
yyyymmdd=$(date --utc +%Y%m%d)
base_url="https://servers.opennic.org/"

# Check if we gave a date as an argument
if [[ "$#" == "1" ]] ; then
  yyyy=$(date --date="$1" +%Y)
  yyyymmdd=$(date --date="$1" +%y%m%d)
fi

# HDFS remote directory
hdfs_raw_dir="/user/hadoop/opennic/resolvers/raw/year=${yyyy}"
hdfs_csv_dir="/user/hadoop/opennic/resolvers/csv/year=${yyyy}"

extract_resolvers="/opt/hadoop/.local/share/opennic-resolver-fetch/extract-resolvers.py"
hdfs="/opt/hadoop/hadoop/bin/hdfs"
base_dir="/srv/hdd0/share/hadoop/opennic"

mkdir -p ${base_dir}

base_tier1="${base_dir}/${yyyymmdd}.tier1"
base_tier2="${base_dir}/${yyyymmdd}.tier2"

# Reset files if they exist.
echo -n "" > "${base_tier1}.html"
echo -n "" > "${base_tier2}.html"
echo -n "" > "${base_tier1}.csv"
echo -n "" > "${base_tier2}.csv"

# If we have a date, fetch the raw data from HDFS, else fetch the URL
if [[ "$#" == "1" ]] ; then
  echo "Fetch raw HTML with tier 1 and 2 information from HDFS ..."
  # Fetch Tier 1 and 2 from HDFS
  hdfs dfs -get "${hdfs_raw_dir}/${yyyymmdd}.tier1.html" "${base_tier1}.html"
  hdfs dfs -get "${hdfs_raw_dir}/${yyyymmdd}.tier2.html" "${base_tier2}.html"
else
  echo "Fetch server lists from web ..."
  # Fetch Tier 2
  curl -ks -X GET "${base_url}?tier=2" >> "${base_tier2}.html"
  # Fetch Tier 1
  curl -ks -X GET "${base_url}?tier=1" >> "${base_tier1}.html"
fi


echo "Extract servers to CSV ..."
python3 $extract_resolvers "${base_tier1}.html" >> "${base_tier1}.csv"
python3 $extract_resolvers "${base_tier2}.html" >> "${base_tier2}.csv"


if (( $hdfs_upload == 1)) ; then
    echo "Upload files to HDFS ..."
    # Upload raw html
    $hdfs dfs -mkdir -p "${hdfs_raw_dir}"
    $hdfs dfs -put "${base_tier1}.html" "${hdfs_raw_dir}/${yyyymmdd}.tier1.html"
    $hdfs dfs -put "${base_tier2}.html" "${hdfs_raw_dir}/${yyyymmdd}.tier2.html"
    # Upload CSVs
    $hdfs dfs -mkdir -p "${hdfs_csv_dir}"
    $hdfs dfs -put "${base_tier1}.csv" "${hdfs_csv_dir}/${yyyymmdd}.tier1.csv"
    $hdfs dfs -put "${base_tier2}.csv" "${hdfs_csv_dir}/${yyyymmdd}.tier2.csv"
    echo "Upload files to HDFS complete"
fi

if [[ "${base_dir}" != "." ]] ; then
    rm -rf $base_dir/$
fi
