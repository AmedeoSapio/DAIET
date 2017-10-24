#!/usr/bin/env python

from scapy.all import *

class PREAMBLE(Packet):
    name = "PREAMBLE"
    fields_desc = [ XBitField("frame_type", 0, 8),
                    IntField("number_of_entries", 0),
                    IntField("tree_id", 0)]

    def guess_payload_class(self, payload):

        if self[PREAMBLE].number_of_entries!=0:
            return ENTRY
        else:
            return Packet.guess_payload_class(self, payload)

class ENTRY(Packet):
    name = "ENTRY"
    fields_desc = [ StrFixedLenField("key", 0, 16),
                    IntField("value", 0)]

    def guess_payload_class(self, payload):
        return ENTRY

class END(Packet):
    name = "END"
    fields_desc = [ XBitField("frame_type", 1, 8),
                    IntField("tree_id", 0)]

