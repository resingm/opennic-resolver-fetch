# OpenNIC Resolver Fetch

This repository is my implementation to fetch the OpenNIC servers from
the official website. Further, the `extract-resolvers.py` function reads
through the HTML and extracts the information about the resolvers. Then,
it outputs the data as CSV to the stdout.

The `fetch-servers.sh` script fetches the raw HTML from the website. It
calls the `extract-resolvers.py` script after fetching the HTML sites.
Last but not least, it uploads the data to HDFS.


