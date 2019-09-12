#!/bin/bash

SCRIPT_PATH="/home/cecconi/GPUfarm/tests"
PERF_PATH="/home/cecconi/GPUfarm/log/fut"

rm -f $PERF_PATH/launch_times.txt
touch $PERF_PATH/launch_times.txt

GREEN='\033[0;32m'
BLUE='\033[1;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
#let END=0



. "$SCRIPT_PATH/monitor_fut.sh" &

sleep 7

echo -e "${GREEN}running script dev_cos_st_fut_P100.sh${NC}"
echo ""
echo "***dev_cos_st_fut_P100.sh***">> "$PERF_PATH/launch_times.txt"
echo "start: $(date)">> "$PERF_PATH/launch_times.txt"
. "$SCRIPT_PATH/dev_cos_st_fut_P100.sh"
echo "end: $(date)">> "$PERF_PATH/launch_times.txt"

#echo -e "${GREEN}running script dev_cos_invert.sh${NC}"
#echo ""
#echo "***dev_cos_invert.sh***">> "$PERF_PATH/launch_times.txt"
#echo "start: $(date)">> "$PERF_PATH/launch_times.txt"
#. "$SCRIPT_PATH/dev_cos_invert.sh"
#echo "end: $(date)">> "$PERF_PATH/launch_times.txt"
######################################

#make clean

#cp $PERF_PATH/*.txt $PERF_PATH/devcos
#cp $PERF_PATH/*.log $PERF_PATH/devcos

#killall -u cecconi



















