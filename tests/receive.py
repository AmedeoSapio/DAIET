#!/usr/bin/env python

# USAGE: receive.py input-interface

import sys
from scapy.all import *
from headers import *

def show_pkt(pkt):

    if (UDP in pkt) and pkt[UDP].dport==10000:

        if ord(str(pkt[UDP].payload)[0])==0:

            PREAMBLE(str(pkt[UDP].payload)).show()

        elif ord(str(pkt[UDP].payload)[0])==1:

            END(str(pkt[UDP].payload)).show()
    else:
        pkt.show();

sniff(iface = sys.argv[1], prn = show_pkt)
