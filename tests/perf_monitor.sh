#!/bin/bash
rm -f ./log/top_out.txt
touch ./log/top_out.txt

rm -f ./log/nvidia_smi_out.log
touch ./log/nvidia_smi_out.log

ENDALL=0
GPU=1

SCRIPT_PATH="/home/cecconi/GPUfarm/tests"
PERF_PATH="/home/cecconi/GPUfarm/log"

#. "$SCRIPT_PATH/runAllTests.sh" 

while [ $ENDALL -eq 0 ]
do

	#htop
	echo "$(date)">> "$PERF_PATH/top_out.txt"
	top -n 2 -b | head -n 17 >> "$PERF_PATH/top_out.txt"
	echo "************************">> "$PERF_PATH/top_out.txt"
	#nvidia-smi
	#nvidia-smi -i $GPU | tee -a logfile && sleep 10

	nvidia-smi -i $GPU --query-gpu=utilization.gpu --format=csv >> "$PERF_PATH/nvidia_smi_out.log"
	nvidia-smi -i $GPU >> "$PERF_PATH/nvidia_smi_out.log"

	echo "************************">> "$PERF_PATH/nvidia_smi_out.log"
	sleep 10
	ENDALL=1
done
