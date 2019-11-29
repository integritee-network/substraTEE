#!/bin/bash

# name of the docker image
DOCKER_IMAGE=scssubstratee/substratee:M5.2

# clone the rust-sgx-sdk (used to run the substratee-worker in the docker)
git clone https://github.com/baidu/rust-sgx-sdk.git

# get the substraTEE docker image from docker hub
docker pull $DOCKER_IMAGE

# if you want to build the docker image yourself, use the following command:
# docker build -t substratee -f DockerfileM5 .

# prepare the docker specific network
docker network rm substratee-net
docker network create --subnet 192.168.10.0/24 substratee-net

# prepare the output log directory
mkdir -p output

# start the tmux session
SESSION=substraTEEM5Demo
tmux has-session -t $SESSION

if [ $? != 0 ]
then
    tmux -2 new -d -s $SESSION -n "substraTEE M5 Demo"

    # create a window split by 3
    tmux split-window -v
    tmux split-window -h

    # enable pane titles
    tmux set -g pane-border-status top

    # set length of left status to 50
    tmux set -g status-left-length 50

    # color the panes
    tmux select-pane -t 1 -P 'fg=colour073' # node
    tmux select-pane -t 2 -P 'fg=colour011' # client
    tmux select-pane -t 3 -P 'fg=colour043' # worker 1

    # start the substratee-node in pane 1
    tmux send-keys -t1 "docker run -ti \
        --ip=192.168.10.10 \
        --network=substratee-net \
        -v $(pwd)/output:/substraTEE/output \
        $DOCKER_IMAGE \
        \"/substraTEE/start_node.sh\"" Enter

    # start the substratee-worker in pane 2
    tmux send-keys -t2 "docker run -ti \
        --ip=192.168.10.21 \
        --network=substratee-net \
        --device /dev/isgx \
        -v $(pwd)/output:/substraTEE/output \
        -v $(pwd)/rust-sgx-sdk:/root/sgx \
        -v /var/run/aesmd:/var/run/aesmd \
        -v $(pwd)/intel_cert:/substraTEE/intel_cert \
        $DOCKER_IMAGE \
        \"/substraTEE/start_worker.sh\"" Enter

    # start the substratee-client in pane 3
    tmux send-keys -t3 "docker run -ti \
        --ip=192.168.10.30 \
        --network=substratee-net \
        -v $(pwd)/output:/substraTEE/output \
        $DOCKER_IMAGE \
        \"/substraTEE/start_client.sh\"" Enter
fi

# Attach to session
tmux attach -t $SESSION
