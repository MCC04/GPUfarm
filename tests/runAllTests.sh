#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[1;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_PATH="/home/cecconi/GPUfarm/tests"

echo -e "${GREEN}running script dev_cos.sh${NC}"
echo ""
. "$SCRIPT_PATH/dev_cos.sh"

echo -e "${GREEN}running script dev_cos_invert.sh${NC}"
echo ""
. "$SCRIPT_PATH/dev_cos_invert.sh"
######################################
echo -e "${GREEN}running script dev_imageMat.sh${NC}"
echo ""
. "$SCRIPT_PATH/dev_imageMat.sh"

echo -e "${GREEN}running script dev_imageMat_invert.sh${NC}"
echo ""
. "$SCRIPT_PATH/dev_imageMat_invert.sh"
 
echo -e "${GREEN}running script low_par.sh${NC}"
echo ""
. "$SCRIPT_PATH/low_par.sh"
#######################################
echo -e "${GREEN}running script host_cosMat.sh${NC}"
echo ""
. "$SCRIPT_PATH/host_cosMat.sh"

echo -e "${GREEN}running script host_cosMat_invert.sh${NC}"
echo ""
. "$SCRIPT_PATH/host_cosMat_invert.sh"

let END=1

make clean










