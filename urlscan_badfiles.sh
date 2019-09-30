#!/bin/bash
# Automating the search and download of bad files from public URLScan submissions.
# Author: Lauren Proehl

# Grabs system date for finding closest API search matches
DATE=$(date +"%Y-%m-%d")

# Output file for samples to be downloaded
RESULTS="~/urlscan_badfiles.txt"

# Temporary output file for storing URLScan result IDs
TMP="~/temp_urlscan_badfilesearch.txt"

# Only variable passed with the script is the file extension you want to hunt (exe, dll, php, etc), and then lower case the file extension for use in the API call and file naming
EXT=$1
EXT=${EXT,,}

# Clear output files before beginning
>"$TMP"
>"$RESULTS"

# Example URLScan result search API query
# https://urlscan.io/api/v1/search/?q=filename:.exe&size=500

# curl the URLScan API for any results with a filename containing the selected extension, up to 1000 search results. (Feel free to change this if you need, I've found around 251 works just as well.) Also output to a holding json file.
curl -o "~/findings.json" "https://urlscan.io/api/v1/search/?q=filename:."$EXT"&size=1001"

# Take the json file and parse to find any scans that have been marked 'public,' contain the selected file extension, and are within today's date. Then output the URLScan scan results and the original url to the same line, but separate for unique original URLs only.
cat "~/findings.json" | jq '.results[] | select(.task.visibility =="public") | select (.task.url | contains(".'$EXT'")) | select(.task.time | contains("'$DATE'")) | "\(.result) \(.task.url)"' -r | sort -uk2,2 > "$TMP"

# While reading the URLScan scan URLs and original URLs, curl the URLScan results to see if the scan was 'public,' and if there were any confirmed malicious results. If the scan was both public and malicious, output the original URL and the malicious file SHA256 to the same line in a new file.
while read first second; do
	curl "$first" | jq 'select(.task.visibility == "public") | select(.verdicts.overall.malicious == true) | "\(.task.url) \(.meta.processors.download.data[].sha256)"' -r >> "$RESULTS"
	sleep 3s
done < "$TMP"

# While reading all confirmed malicious URLs and SHA256, wget the original URL to try to download the malicious file. If first connection succesful, output the file name as the SHA256 paired with the selected extension. If first connection is not succesful, attempt connection up to 5 times, with a 3 second wait in between each retry attempt. 
# Also leverages the '--retry-connrefused' flag in an attempt to catch intermittently unavailable websites.
while read first second; do
	wget -O "$second"."$EXT" --tries=5  --waitretry=3 --retry-connrefused "$first"
done < "$RESULTS"
