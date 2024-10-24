#!/bin/bash

# Ensure fzf and docker are installed
if ! command -v fzf &> /dev/null || ! command -v docker &> /dev/null; then
    echo "fzf and docker must be installed"
    exit 1
fi

# Function to list and stop a running container
stop_container() {
    local container
    container=$(docker ps --format '{{.ID}}: {{.Names}}' | fzf --prompt="Select a container to stop: ")
    
    if [ -n "$container" ]; then
        container_id=$(echo "$container" | cut -d: -f1)
        docker stop "$container_id"
        echo "Stopped container: $container"
    else
        echo "No container selected."
    fi
}

# Function to list and start a stopped container
start_container() {
    local container
    container=$(docker ps -a --filter "status=exited" --format '{{.ID}}: {{.Names}}' | fzf --prompt="Select a container to start: ")
    
    if [ -n "$container" ]; then
        container_id=$(echo "$container" | cut -d: -f1)
        docker start "$container_id"
        echo "Started container: $container"
    else
        echo "No container selected."
    fi
}

# Function to attach to a running container
attach_container() {
    local container
    container=$(docker ps --format '{{.ID}}: {{.Names}}' | fzf --prompt="Select a container to attach to: ")
    
    if [ -n "$container" ]; then
        container_id=$(echo "$container" | cut -d: -f1)
        docker exec -it "$container_id" bash
    else
        echo "No container selected."
    fi
}

# Main menu using fzf
action=$(echo -e "Stop a container\nStart a container\nAttach to a container" | fzf --prompt="Select an action: ")

case $action in
    "Stop a container")
        stop_container
        ;;
    "Start a container")
        start_container
        ;;
    "Attach to a container")
        attach_container
        ;;
    *)
        echo "Invalid action selected."
        ;;
esac
