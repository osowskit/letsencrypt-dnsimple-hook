#!/usr/bin/env sh

COMMAND="-c -t dns-01 -d $RENEW_DOMAIN -k /workspace/dnsimple_hook.rb $@"

pwd && ls

ls /
ls /workspace

/workspace/dehydrated --register --accept-terms
/workspace/dehydrated "$COMMAND"
