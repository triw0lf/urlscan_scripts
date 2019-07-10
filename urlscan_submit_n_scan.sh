#!/bin/bash
# Bulk submit and check the status of a URL via urlscan.io. You'll need your own API key from urlscan.io

# Using ANSI codes with printf to show status messages: "\e[1;32m TEXT HERE \e[0m" - this shows TEXT HERE in green lettering


# Assign output file
RESULTS="urlscan_submit_status.txt"

# Fill in your own API key from urlscan
API=""

# Clear output file before beginning
>"$RESULTS"

# Read the input file URL by line
while IFS= read -r URL; do
	printf "\e[1;32m Now submitting "$URL" to urlscan.io \e[0m"
	printf "\n"
# Submit the url to a public urlscan check and extract the UUID result from that scan (remove the following option to make it private: , \"public\": \"on\")
	UUID=$(curl -X POST "https://urlscan.io/api/v1/scan/" -H "Content-Type: application/json" -H "API-Key: "$API"" -d "{\"url\": \""$URL"\", \"public\": \"on\"}" | grep "uuid" | awk '{ print $2 }' | sed 's/\"//g'| sed 's/\,//g')
# Wait a bit an add the url + UUID to the outfile
	sleep 3;
	printf "$URL" >> "$RESULTS"
	printf " - " >> "$RESULTS"
	printf "$UUID" >> "$RESULTS"
# Wait longer to ensure the urlscan completes	
	sleep 35;
	printf "\e[1;32m Checking for status codes for urlscan report "$UUID" \e[0m"
	printf "\n"
# Check the results of the previously submitted urlscan and grep for the first page status seen	
	STATUS=$(curl "https://urlscan.io/api/v1/result/"$UUID"/" | jq '.data.requests[0].response.response.status')
# Prine the status results to the outfile and put a new line separator in
	printf " - " >> "$RESULTS"
	printf "$STATUS" >> "$RESULTS"
	printf "\n" >> "$RESULTS"
# Wait a bit more
	sleep 3;
# Read the file passed with the program as the infile (make sure you have a blank new line at the very end of your infile!)
done < "$1"

printf "\e[1;32m All submissions complete. \e[0m"

# Infile example:
# https://goggle.com
# https://github.com
# https://twitter.com
# 
