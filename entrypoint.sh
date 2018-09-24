#!/usr/bin/env sh

# COMMAND="-X POST -H 'Content-type: application/json' --data '{\"text\":\"Success! $* \"}' $SLACK_WEBHOOK_URL"
eval dehydrated/dehydrated --register --accept-terms
eval dehydrated/dehydrated "-c -t dns-01 -d $RENEW_DOMAIN -k dnsimple_hook.rb"
