#!/usr/bin/env sh

COMMAND="-c -t dns-01 -d $RENEW_DOMAIN -k /dnsimple_hook.rb $@"

ls /

/dehydrated --register --accept-terms
eval /dehydrated "$COMMAND"
