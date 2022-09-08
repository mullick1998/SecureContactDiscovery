#!/usr/bin/env bash

set -e

export RED='\e[31m'
export BLUE='\e[34m'
export ORANGE='\e[33m'
export NC='\e[0m' # No Color


# print an error message on an error exiting
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'if [ $? -ne 0 ]; then echo "${RED}\"${last_command}\" command failed - exiting.${NC}"; fi' EXIT

function error_exit() {
  trap 'echo -e  "${RED}Exiting with error.${NC}"' EXIT
  exit 1
}

echo -e "${BLUE}Checking that we have access to golang${NC}"
if ! command -v go &> /dev/null
then
    echo -e "${ORANGE}No golang found! Installing go!${NC}"
    echo -e "${ORANGE}Ensuring that we have access to a new go installation${NC}"
    curl -OL https://golang.org/dl/go1.18.4.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.18.4.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin'  >> ~/.profile
fi
go version

echo -e "${BLUE}Checking that we have access to EGo${NC}"
if ! command -v ego &> /dev/null
then
    echo -e "${ORANGE}No EGo found! Installing ego!${NC}"
    echo -e "${ORANGE}Ensuring that we have access to a new ego installation${NC}"
    wget -qO- https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key | sudo apt-key add
    sudo add-apt-repository "deb [arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu `lsb_release -cs` main"
    wget https://github.com/edgelesssys/ego/releases/download/v1.0.0/ego_1.0.0_amd64.deb
    sudo apt install ./ego_1.0.0_amd64.deb build-essential libssl-dev -y
fi
echo EGo v1.0.0