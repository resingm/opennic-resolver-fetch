#!/usr/bin/env bash
#
#

hdfs_upload=1

yyyy=$(date --utc +%Y)
yyyymmdd=$(date --utc +%Y%m%d)
base_url="https://servers.opennic.org/"

# HDFS remote directory
hdfs_raw_dir="/usr/hadoop/opennic/resolvers/raw/year=${yyyy}"
hdfs_csv_dir="/usr/hadoop/opennic/resolvers/csv/year=${yyyy}"

extract_resolvers="extract-resolvers.py"
base_dir="/tmp/opennic"

mkdir -p ${base_dir}

base_tier1="${base_dir}/${yyyymmdd}.tier1"
base_tier2="${base_dir}/${yyyymmdd}.tier2"

# Reset files if they exist.
echo -n "" > "${base_tier1}.html"
echo -n "" > "${base_tier2}.html"
echo -n "" > "${base_tier1}.csv"
echo -n "" > "${base_tier2}.csv"

# Fetch Tier 2
curl -ks -X GET "${base_url}?tier=2" >> "${base_tier2}.html"

# Fetch Tier 1
curl -ks -X GET "${base_url}?tier=1" >> "${base_tier1}.html"

python3 $extract_resolvers "${base_tier1}.html" >> "${base_tier1}.csv"
python3 $extract_resolvers "${base_tier2}.html" >> "${base_tier2}.csv"


if (( $hdfs_upload == 1)) ; then
    # Upload raw html
    hdfs dfs -put "${base_tier1}.html" "${hdfs_raw_dir}/${yyyymmdd}.tier1.html"
    hdfs dfs -put "${base_tier2}.html" "${hdfs_raw_dir}/${yyyymmdd}.tier2.html"
    # Upload CSVs
    hdfs dfs -put "${base_tier1}.csv" "${hdfs_csv_dir}/${yyyymmdd}.tier1.csv"
    hdfs dfs -put "${base_tier2}.csv" "${hdfs_csv_dir}/${yyyymmdd}.tier2.csv"
fi

if [[ "${base_dir}" != "." ]] ; then
    rm -rf $base_dir/$
fi
