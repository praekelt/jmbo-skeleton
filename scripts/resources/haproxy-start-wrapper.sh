#!/bin/bash

# haproxy accepts multiple -f parameters. This script collects them and starts 
# haproxy with them.

FILES=""
for f in `ls /etc/haproxy/*.cfg`
do
    FILES="$FILES -f $f"
done

haproxy $FILES -p /tmp/pids/haproxy.pid -sf
