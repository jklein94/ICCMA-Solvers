#!/bin/sh
limit=$1
shift
time ./runsolver -w /dev/null -C $limit ./argpref $@
