#!/usr/bin/env sh

COMMAND="-c -t dns-01 -d $RENEW_DOMAIN -k ./dnsimple_hook.rb $@"

pwd && ls

./dehydrated --register --accept-terms
./dehydrated "$COMMAND"
