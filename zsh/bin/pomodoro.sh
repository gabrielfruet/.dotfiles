#!/bin/bash

# Set work and rest times ⏰
X=${1:-25}  # Work time in minutes
Y=${2:-5}   # Rest time in minutes

REASK_TIME=8
FIFO_PATH="/tmp/pomodoro_fifo"

# Function to send notification 📣
send_notification() {
    notify-send "Pomodoro 🍅" "$1"
}

# Function to ask if user wants to continue 🤔
ask_continue() {
    gum confirm --no-show-help "🌟 Continue Pomodoro session? 🌟"
    if [ $? -eq 0 ]; then
        echo "CONTINUE" > $FIFO_PATH
    else
        echo "STOP" > $FIFO_PATH
    fi
}

# Function to remind user to answer 📞
remember_to_answer() {
    while true; do
        send_notification "🙋‍♂️ Please respond to continue or stop the Pomodoro session! 🕒"
        sleep $REASK_TIME
    done
}

# Main loop 🔁
while true; do
    # Work session 💼
    send_notification "🔔 Start working for $X minutes! ⏰"
    echo -e "\e[32mWork session started for $X minutes...\e[0m"
    sleep $((X * 60))

    # Break time 🛋️
    send_notification "🛋️ Take a break for $Y minutes! 😴"
    echo -e "\e[33mBreak time! Relax for $Y minutes...\e[0m"
    sleep $((Y * 60))

    # Go back to work notification 🔔
    send_notification "🔔 Back to work! 💼"
    echo -e "\e[32mBack to work! Let's get productive...\e[0m"

    # Create FIFO 📝
    mkfifo $FIFO_PATH @&>/dev/null

    # Wait for confirmation to continue 🤔
    ask_continue & 
    while true; do
        # Start thread that reminds the user to answer 📞
        remember_to_answer &

        pid=$!
        line=$(cat $FIFO_PATH)
        kill $pid

        if [[ $line == "CONTINUE" ]]; then
            send_notification "🔄 Continuing session... 🔁"
            echo -e "\e[34mContinuing Pomodoro session...\e[0m"
            rm $FIFO_PATH
            break
        elif [[ $line == "STOP" ]]; then
            send_notification "🛑 Stopping session... 👋"
            echo -e "\e[31mStopping Pomodoro session...\e[0m"
            rm $FIFO_PATH
            exit 0
        fi
    done
done

