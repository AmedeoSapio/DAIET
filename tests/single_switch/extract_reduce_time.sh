#!/bin/bash
for i in {1..12}; do
    docker container exec h$i cat simplemr_examples.log |grep "REDUCERTIME";
done

