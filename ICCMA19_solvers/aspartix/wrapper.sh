#!/bin/sh
limit=$1
shift
time ./runsolver -w /dev/null -C $limit ./aspartix-V-interface-2019.sh $@

