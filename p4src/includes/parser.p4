/*
Author: Amedeo Sapio
amedeo.sapio@gmail.com
*/

#define ETHERTYPE_IPV4 0x0800
#define IP_PROTOCOLS_UDP 17

#define MAX_ENTRIES_PER_PACKET 10

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

header ipv4_t ipv4;

field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.diffserv;
        ipv4.totalLen;
        ipv4.identification;
        ipv4.flags;
        ipv4.fragOffset;
        ipv4.ttl;
        ipv4.protocol;
        ipv4.srcAddr;
        ipv4.dstAddr;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum;
    update ipv4_checksum;
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        IP_PROTOCOLS_UDP : parse_udp;
        default: ingress;
    }
}

/* Parser exception not yet supported in BMv2
parser_exception p4_pe_checksum {
    return parser_drop;
}*/

header udp_t udp;

parser parse_udp {
    extract(udp);
    return select(current(0, 8)) {
        0x00 : parse_preamble;
        0x01 : parse_end;
        default: ingress;
    }
}

header preamble_t preamble;
metadata metadata_t mdata;
metadata intrinsic_metadata_t intrinsic_metadata;

parser parse_preamble {
    extract(preamble);

    set_metadata(mdata.number_of_entries, latest.number_of_entries);
    set_metadata(mdata.original_tree_id, latest.tree_id);

    return select (mdata.number_of_entries) {
        0 : ingress;
        default : parse_entry;
    }
}

header entry_t entry[MAX_ENTRIES_PER_PACKET];

parser parse_entry {
    extract(entry[next]);
    set_metadata(mdata.number_of_entries, mdata.number_of_entries-1);

    return select (mdata.number_of_entries) {
        0 : ingress;
        default : parse_entry;
    }
}

header end_t end;

parser parse_end {
    extract(end);

    set_metadata(mdata.original_tree_id, latest.tree_id);

    return ingress;
}
