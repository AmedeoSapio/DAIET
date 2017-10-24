#!/usr/bin/env python

# USAGE: send_data.py output-interface destination-interface #replicas #children

import sys
from scapy.all import *
from headers import *

MACS ={'veth0' : '4a:45:35:c6:38:10',
       'veth1' : 'f6:ba:c5:43:bb:1a',
       'veth2' : 'ee:45:8d:ed:15:c2',
       'veth3' : 'ba:6c:cd:d4:ee:bf',
       'veth4' : '56:c0:1f:a4:ff:d5',
       'veth5' : '56:0b:9e:46:d6:d5',
       'veth6' : '56:b7:99:93:eb:70',
       'veth7' : '76:2b:93:99:18:19'}

# TREE 0
data1 = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / PREAMBLE(number_of_entries=4,tree_id=7) / ENTRY(key='a',value=1) / ENTRY(key="b",value=2) / ENTRY(key="c",value=3) / ENTRY(key="d",value=4) 

data2 = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / PREAMBLE(number_of_entries=2,tree_id=7) / ENTRY(key='AA',value=5) / ENTRY(key="BB",value=6) 

for i in range(int(sys.argv[3])):
    sendp(data1, iface = sys.argv[1])

for i in range(int(sys.argv[3])):
    sendp(data2, iface = sys.argv[1])

# PACKET TO SKIP
data1 = Ether(dst="aa:aa:aa:aa:aa:aa") / IP(dst="10.0.1.10") / UDP(dport=10000) / PREAMBLE(number_of_entries=4,tree_id=151) / ENTRY(key='a',value=10) / ENTRY(key="b",value=20) / ENTRY(key="c",value=30) / ENTRY(key="d",value=40) 
sendp(data1, iface = sys.argv[1])

# TREE 1
data1 = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / PREAMBLE(number_of_entries=4,tree_id=8) / ENTRY(key='a',value=10) / ENTRY(key="b",value=20) / ENTRY(key="c",value=30) / ENTRY(key="d",value=40) 

data2 = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / PREAMBLE(number_of_entries=2,tree_id=8) / ENTRY(key='AA',value=50) / ENTRY(key="BB",value=60) 

for i in range(int(sys.argv[3])):
    sendp(data1, iface = sys.argv[1])

for i in range(int(sys.argv[3])):
    sendp(data2, iface = sys.argv[1])

# END
for i in range(int(sys.argv[4])):
    end = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / END (tree_id=7)
    sendp(end, iface = sys.argv[1])
    end = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / END (tree_id=8)
    sendp(end, iface = sys.argv[1])
