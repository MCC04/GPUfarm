#!/bin/bash

rm -f ./log/launch_times.txt
touch ./log/launch_times.txt

GREEN='\033[0;32m'
BLUE='\033[1;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
let END=0

SCRIPT_PATH="/home/cecconi/GPUfarm/tests"
PERF_PATH="/home/cecconi/GPUfarm/log"

#. "$SCRIPT_PATH/perf_monitor.sh" &
. "$SCRIPT_PATH/host_perf_monitor.sh" &


sleep 7

#######################################

echo -e "${GREEN}running script host_cos.sh${NC}"
echo ""
echo "***host_cos.sh***">> "$PERF_PATH/launch_times.txt"
echo "start: $(date)">> "$PERF_PATH/launch_times.txt"
. "$SCRIPT_PATH/host_cos.sh"
echo "end: $(date)">> "$PERF_PATH/launch_times.txt"

echo -e "${GREEN}running script host_cos_invert.sh${NC}"
echo ""
echo "***host_cos_invert.sh***">> "$PERF_PATH/launch_times.txt"
echo "start: $(date)">> "$PERF_PATH/launch_times.txt"
. "$SCRIPT_PATH/host_cos_invert.sh"
echo "end: $(date)">> "$PERF_PATH/launch_times.txt"


make clean

cp $PERF_PATH/*.txt $PERF_PATH/hostcos
cp $PERF_PATH/*.log $PERF_PATH/hostcos

killall -u cecconi








