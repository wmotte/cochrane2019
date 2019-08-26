#!/bin/bash

# read all urls
IFS=$'\n' read -d '' -r -a urls < ./urls.txt

sleep 10

#echo "${urls[@]}"
for url in "${urls[@]}"
do
	# create tmp_dir
	tmp_dir=$(mktemp -d -t 'chrome-remote-XXXXXX' )

	echo "Processing [$url] in temp dir [$tmp_dir]"

	# call browser
	/usr/bin/google-chrome \
	--remote-debugging-port=9222 \
	--no-first-run \
	--no-default-browser-check \
	--user-data-dir=$tmp_dir &

	sleep 3

	# scrape
	node ./rm5_downloader.js $url
done
