#!/bin/bash
# Automating the search and download of bad files to download from urlhaus submissions
# Author: Lauren Proehl

# Grabs system date for finding closest API search matches
DATE=$(date "+%Y-%m-%d")

# Output file for samples to be downloaded
RESULTS="/root/urlhaus.csv"

# Temporary output file for storing URLScan result IDs
TMP="/root/url_haus.txt"

# Clear output files before beginning
>"$TMP"
>"$RESULTS"

wget -O "$RESULTS" "https://urlhaus.abuse.ch/downloads/csv/"

awk -F "\"*,\"*" '{print $2,$3}' "$RESULTS" | grep "$DATE" | sort -u -k2,2 | sort -r > "$TMP"

while read first second third; do
	wget "$third" -tries=5  --waitretry=3 --retry-connrefused
done < "$TMP"

