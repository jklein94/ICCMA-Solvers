#!/bin/sh
limit=$1
shift
time ./runsolver -w /dev/null -C $limit ./taas-dredd -h_scc 8 -h_paths_starting 1 -h_paths_starting_max_length 4 -h_paths_starting_weight 0.1 -h_paths_ending 0 -h_paths_ending_max_length 3 -h_paths_ending_weight -0.1 $@
