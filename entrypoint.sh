#!/usr/bin/env sh

COMMAND="-c -t dns-01 -d $RENEW_DOMAIN -k /dnsimple_hook.rb $@"

ls /workspace

/workspace/dehydrated --register --accept-terms
/workspace/dehydrated "$COMMAND"
