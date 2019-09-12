#!/bin/bash

SCRIPT_PATH="/home/cecconi/GPUfarm/tests"
PERF_PATH="/home/cecconi/GPUfarm/log/cos"
rm -f $PERF_PATH/top_out.txt
touch $PERF_PATH/top_out.txt

rm -f $PERF_PATH/nvidia_smi_out.log
touch $PERF_PATH/nvidia_smi_out.log

#ENDALL=0
let GPU=2
#let GPU=3



#. "$SCRIPT_PATH/runAllTests.sh" 

#while [ $ENDALL -eq 0 ]
while true;
do

	#top
	echo "$(date)">> "$PERF_PATH/top_out.txt"
	top -n 2 -b | head -n 14 >> "$PERF_PATH/top_out.txt"
	echo "************************">> "$PERF_PATH/top_out.txt"

	#nvidia-smi
	#nvidia-smi -i $GPU --query-gpu=utilization.gpu --format=csv >> "$PERF_PATH/nvidia_smi_out.log"
	nvidia-smi -i $GPU >> "$PERF_PATH/nvidia_smi_out.log"

	echo "************************">> "$PERF_PATH/nvidia_smi_out.log"
	sleep 10
	#ENDALL=1
done
