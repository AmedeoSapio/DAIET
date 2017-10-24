#!/bin/bash

for i in {1..12}; do
    value=$(docker container exec h$i cat simplemr.log |grep "REDUCER ID" |tail -n 1 | sed 's/.*\(..\)/\1/');
    let "value=value+36";
    echo $value;
done

