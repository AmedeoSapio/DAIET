#!/bin/bash

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

BMV2_PATH=$THIS_DIR/../bmv2

P4C_BM_PATH=$THIS_DIR/../p4c-bmv2

P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py

SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch

#CLI_PATH=$BMV2_PATH/tools/runtime_CLI.py
CLI_PATH=$BMV2_PATH/targets/simple_switch/sswitch_CLI

if [ $# -eq 0 ]; then 
    INTFS="-i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6"
else
    INTFS=$@
fi

# Probably not very elegant but it works nice here: we enable interactive mode
# to be able to use fg. We start the switch in the background, sleep for 2
# minutes to give it time to start, then add the entries and put the switch
# process back in the foreground
set -m
$P4C_BM_SCRIPT p4src/daiet.p4 --json daiet.json
# This gets root permissions, and gives libtool the opportunity to "warm-up"
sudo $SWITCH_PATH >/dev/null 2>&1 
sudo $SWITCH_PATH daiet.json \
     $INTFS \
    --nanolog ipc:///tmp/bm-0-log.ipc \
    --pcap \
    --log-file daiet \
    --log-flush \
    --log-level trace & 
sleep 2
echo "#"
echo $CLI_PATH daiet.json 
$CLI_PATH daiet.json < commands.txt 
echo "READY!!!"
fg
