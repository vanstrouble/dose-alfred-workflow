#!/bin/bash

# Function to calculate the end time based on the given minutes
calculate_end_time() {
    local minutes=$1
    date -v+"$minutes"M +"%H:%M"
}

# Function to parse the input and calculate the total minutes
parse_input() {
    local input=("${(@s/ /)1}")  # Split the input into parts
    if [[ "${#input[@]}" -eq 1 && "${input[1]}" =~ ^[0-9]+$ ]]; then
        # Format: 20 (only minutes)
        echo "${input[1]}"
    elif [[ "${#input[@]}" -eq 2 ]]; then
        if [[ "${input[1]}" =~ ^[0-9]+$ && -z "${input[2]}" ]]; then
            # Format: 1 (hours only, but second number not yet entered)
            echo $(( input[1] * 60 ))
        elif [[ "${input[1]}" =~ ^[0-9]+$ && "${input[2]}" =~ ^[0-9]+$ ]]; then
            # Format: 1 20 (hours and minutes)
            echo $(( input[1] * 60 + input[2] ))
        else
            # Invalid second part
            echo "0"
        fi
    else
        # Invalid input or incomplete
        echo "0"
    fi
}

# Function to start an Amphetamine session
start_amphetamine_session() {
    local total_minutes=$1
    osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$total_minutes, interval:minutes, displaySleepAllowed:false}" || {
        echo "Error: Failed to start Amphetamine session."
        exit 1
    }
}

# Main function
main() {
    local total_minutes=$(parse_input "$INPUT")
    if [[ "$total_minutes" -gt 0 ]]; then
        local end_time=$(calculate_end_time "$total_minutes")
        start_amphetamine_session "$total_minutes"
        echo "Keeping awake until around $end_time."
    else
        echo "Error: Invalid input. Please provide a valid duration."
        exit 1
    fi
}

INPUT="$1"
main
