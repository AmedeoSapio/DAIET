#!/bin/bash

if [ $# -eq 1 ]; then 
    int=$1
else 
    int="veth0"
fi

while [ true ]
do 
    cat /sys/class/net/$int/statistics/rx_bytes >> ${int}_rx_bytes.dat
    cat /sys/class/net/$int/statistics/tx_bytes >> ${int}_tx_bytes.dat
    sleep 1s
done
