/*
Author: Amedeo Sapio
amedeo.sapio@gmail.com
*/

#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/registers.p4"

#define CLONE_SPEC 100
#define NUMBER_OF_HOSTS 13

field_list key_hash_fields {
    entry[0].key;
}

field_list_calculation key_hash {
    input {
        key_hash_fields;
    }
    algorithm : crc32;
    output_width : 32;
}

field_list clone_fields {
    standard_metadata;
}

action _drop(){
    drop();
}

/* Read remaining_children from register */
action load_remaining_children(){
    register_read(mdata.remaining_children, remaining_children, mdata.tree_id);
}

action load_valid_entries_index(offset){
    register_read(mdata.valid_entries_index, valid_entries_index, mdata.tree_id);
    modify_field(mdata.valid_entries_offset, offset);
}

action set_child_nodes (child_nodes) {
    register_write(remaining_children, mdata.tree_id, child_nodes);
    load_remaining_children();
}

action set_tree_id (actual_tree_id) {
    modify_field(mdata.tree_id, actual_tree_id);
}

action process_single_entry(){

    /* index = Hash(key) */
    modify_field_with_hash_based_offset(mdata.key_index, mdata.tree_id*NUMBER_OF_CELLS, key_hash, NUMBER_OF_CELLS);

    /* Write key */
    register_write(keys, mdata.key_index, entry[0].key);

    /* Write bitmap */
    register_read(mdata.conditional_unit, bitmap, mdata.key_index);
    register_write(bitmap, mdata.key_index, 1);

    /* Update value */
    register_read(mdata.value, values, mdata.key_index);
    add_to_field(mdata.value, entry[0].value);
    register_write(values, mdata.key_index, mdata.value);
    
    /* Update valid entries */
    add(mdata.actual_index, mdata.valid_entries_index, mdata.valid_entries_offset);
    register_write(valid_entries_stack, mdata.actual_index, mdata.key_index);

    /* cond xor 1 = not cond */
    bit_xor(mdata.conditional_unit,mdata.conditional_unit, 1);

    add_to_field(mdata.valid_entries_index,mdata.conditional_unit);

    register_write(valid_entries_index, mdata.tree_id, mdata.valid_entries_index);

    pop(entry, 1);
}

action process_entry_1(){
    process_single_entry();
    drop();
}

action process_entry_2(){
    process_single_entry();
    process_entry_1();
}

action process_entry_3(){
    process_single_entry();
    process_entry_2();
}

action process_entry_4(){
    process_single_entry();
    process_entry_3();
}

action process_entry_5(){
    process_single_entry();
    process_entry_4();
}

action process_entry_6(){
    process_single_entry();
    process_entry_5();
}

action process_entry_7(){
    process_single_entry();
    process_entry_6();
}

action process_entry_8(){
    process_single_entry();
    process_entry_7();
}

action process_entry_9(){
    process_single_entry();
    process_entry_8();
}

action process_entry_10(){
    process_single_entry();
    process_entry_9();
}

action end_action(){

    /* Update remaining children */
    register_read(mdata.remaining_children, remaining_children, mdata.tree_id);
    subtract_from_field(mdata.remaining_children, 1);
    register_write(remaining_children, mdata.tree_id, mdata.remaining_children);
}

action preamble_setup(entries) {
    /* We use the entries parameter to limit the entries to the max value */
    remove_header(end);
    add_header(preamble);
    
    modify_field(preamble.frame_type, 0);
    modify_field(preamble.number_of_entries, entries);
    modify_field(preamble.tree_id, mdata.original_tree_id);
}

action next_valid_entry(){

    /* Decrement valid_entries_index */
    subtract_from_field(mdata.valid_entries_index, 1);
    register_write(valid_entries_index, mdata.tree_id, mdata.valid_entries_index);

    /* Read valid entry */
    add(mdata.actual_index, mdata.valid_entries_index, mdata.valid_entries_offset);
    register_read(mdata.key_index, valid_entries_stack, mdata.actual_index);
}

action clear_registry(){
    register_write(keys, mdata.key_index, 0);
    register_write(values, mdata.key_index, 0);
    register_write(bitmap, mdata.key_index, 0);
}

action set_port(port){
    modify_field(standard_metadata.egress_spec, port);
}

action _recirculate(){
    recirculate(clone_fields);
}

action send_1_entries(){

    next_valid_entry();
    
    /* Add header */
    add_header(entry[0]);
    register_read(entry[0].key, keys,  mdata.key_index);
    register_read(entry[0].value, values,  mdata.key_index);

    clear_registry();

    /* Not supported by BMv2 */
    /* clone_ingress_pkt_to_ingress(CLONE_SPEC, clone_fields); */

    /* Clone to egress and recirculate */
    clone_ingress_pkt_to_egress(CLONE_SPEC, clone_fields);    
}

action send_2_entries(){

    send_1_entries();

    next_valid_entry();
 
    /* Add header */
    add_header(entry[1]);
    register_read(entry[1].key, keys,  mdata.key_index);
    register_read(entry[1].value, values,  mdata.key_index);

    clear_registry();
}

action send_3_entries(){

    send_2_entries();

    next_valid_entry();
 
    /* Add header */
    add_header(entry[2]);
    register_read(entry[2].key, keys,  mdata.key_index);
    register_read(entry[2].value, values,  mdata.key_index);

    clear_registry();
}

action send_4_entries(){

    send_3_entries();

    next_valid_entry();
 
    /* Add header */
    add_header(entry[3]);
    register_read(entry[3].key, keys,  mdata.key_index);
    register_read(entry[3].value, values,  mdata.key_index);

    clear_registry();
}

action send_5_entries(){

    send_4_entries();

    next_valid_entry();
 
    /* Add header */
    add_header(entry[4]);
    register_read(entry[4].key, keys,  mdata.key_index);
    register_read(entry[4].value, values,  mdata.key_index);

    clear_registry();
}

action send_6_entries(){

    send_5_entries();

    next_valid_entry();
 
    /* Add header */
    add_header(entry[5]);
    register_read(entry[5].key, keys,  mdata.key_index);
    register_read(entry[5].value, values,  mdata.key_index);

    clear_registry();
}

action send_7_entries(){

    send_6_entries();

    next_valid_entry();
 
    /* Add header */
    add_header(entry[6]);
    register_read(entry[6].key, keys,  mdata.key_index);
    register_read(entry[6].value, values,  mdata.key_index);

    clear_registry();
}

action send_8_entries(){

    send_7_entries();

    next_valid_entry();
 
    /* Add header */
    add_header(entry[7]);
    register_read(entry[7].key, keys,  mdata.key_index);
    register_read(entry[7].value, values,  mdata.key_index);

    clear_registry();
}

action send_9_entries(){

    send_8_entries();

    next_valid_entry();
 
    /* Add header */
    add_header(entry[8]);
    register_read(entry[8].key, keys,  mdata.key_index);
    register_read(entry[8].value, values,  mdata.key_index);

    clear_registry();
}

action send_10_entries(){

    send_9_entries();

    next_valid_entry();
 
    /* Add header */
    add_header(entry[9]);
    register_read(entry[9].key, keys,  mdata.key_index);
    register_read(entry[9].value, values,  mdata.key_index);

    clear_registry();
}

action skip_packet(){
    modify_field(mdata.skip, 1);
}

table load_remaining_children_table {
    actions {
        load_remaining_children;
    }
    size: 0;
}

table load_valid_entries_index_table {
    reads {
        mdata.tree_id : exact;
    }
    actions {
        load_valid_entries_index;
    }
    size: NUMBER_OF_TREES;
}

table tree_id_adapter_table {
    reads {
        mdata.original_tree_id : exact;
    }
    actions {
        set_tree_id;
        skip_packet;
    }
    size: NUMBER_OF_TREES;
}

table set_child_nodes_table {
    reads {
        mdata.tree_id : exact;
    }
    actions {
        set_child_nodes;
    }
    size: NUMBER_OF_TREES;
}

table entry_processing_table {
    reads {
        preamble.number_of_entries : exact;
    }
    actions {
        process_entry_1;
        process_entry_2;
        process_entry_3;
        process_entry_4;
        process_entry_5;
        process_entry_6;
        process_entry_7;
        process_entry_8;
        process_entry_9;
        process_entry_10;
        _drop;
    }
    size: MAX_ENTRIES_PER_PACKET;
}

table end_table {
    actions {
        end_action;
    }
    size: 0;
}

table preamble_setup_table {
    reads {
        mdata.valid_entries_index : exact;
    }
    actions {
        preamble_setup;
    }
    size: MAX_ENTRIES_PER_PACKET;
}

table flush_table {
    reads {
        mdata.valid_entries_index : exact;
    }
    actions {
        send_1_entries;
        send_2_entries;
        send_3_entries;
        send_4_entries;
        send_5_entries;
        send_6_entries;
        send_7_entries;
        send_8_entries;
        send_9_entries;
        send_10_entries;
    }
    size: MAX_ENTRIES_PER_PACKET;
}

table forwarding_table {
    reads{
        mdata.original_tree_id : exact;
    }
    actions {
        set_port;
    }
    size : NUMBER_OF_TREES;
}

table mac_forwarding_table {
    reads{
        ethernet.dstAddr : exact;
    }
    actions {
        set_port;
        _drop;
    }
    size : NUMBER_OF_HOSTS;
}

table recirculate_table {
    reads { 
        standard_metadata.instance_type : exact;
    }
    actions {
        _recirculate;
    }
    size : 1;
}

control ingress {

    /* Common table 
    /* Here because of 
    /* https://github.com/p4lang/p4c/issues/457 */
    if(valid(preamble) or valid(end)){

        /* Adjust tree_id */
        apply(tree_id_adapter_table);

        if (mdata.skip!=1){
            /* Load valid_entries_index */
            apply(load_valid_entries_index_table);
        }

    }

    if(valid(preamble) and mdata.skip!=1){

        /* Read remaining_children from register */
        apply(load_remaining_children_table);
 
        if (mdata.remaining_children == 0){
            /* set remaining_children */
            apply(set_child_nodes_table);
        }

        /* Load valid_entries_index */
        /*apply(load_valid_entries_index_table);*/

        /* process entries */
        apply(entry_processing_table);

    } else if(valid(end) and mdata.skip!=1){

        if (standard_metadata.instance_type==0){
            /* Not a clone -> decrease remaining children */
            apply(end_table);
        }

        if (mdata.remaining_children == 0 or not standard_metadata.instance_type==0){
            /* Clone or end from the only remaining child */

            /* Load valid_entries_index */
            /*apply(load_valid_entries_index_table);*/

            if (mdata.valid_entries_index!=0){
                /* preamble_setup */
                apply(preamble_setup_table);
                /* Add valid_entries_index entries */
                apply(flush_table);
           }
        }

        /* Forward the packet */
        apply(forwarding_table);

    }else{

        apply(mac_forwarding_table);
    }
}

control egress {
    apply(recirculate_table);
}
