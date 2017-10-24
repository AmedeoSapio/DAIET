/*
Author: Amedeo Sapio
amedeo.sapio@gmail.com
*/

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        len : 16;
        checksum : 16;
    }
}

header_type end_t {
    fields {
        frame_type : 8; /* type=1 */
        tree_id : 32;
    }
}

header_type preamble_t {
    fields {
        frame_type : 8; /* type=0 */
        number_of_entries : 32;
        tree_id : 32;
    }
}

header_type entry_t {
    fields {
        key : 128; /* 16 bytes */
        value : 32;
    }
}

header_type metadata_t {
    fields {
        number_of_entries : 32;
        tree_id : 32;
        original_tree_id : 32;
        remaining_children : 32;
        key_index : 20; /* log(REGISTER_SIZE) */
        value : 32;
        valid_entries_index : 20; /* log(REGISTER_SIZE) */
        valid_entries_offset : 20; /* log(REGISTER_SIZE) */
        actual_index : 20; /* log(REGISTER_SIZE) */
        conditional_unit : 1;
        skip : 1;
    }
}

header_type intrinsic_metadata_t {
    fields {
        ingress_global_timestamp : 48;
        lf_field_list : 8;
        mcast_grp : 16;
        egress_rid : 16;
        resubmit_flag : 8;
        recirculate_flag : 8;
    }
}
