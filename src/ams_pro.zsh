#!/bin/bash

# Function to calculate the end time based on the given minutes
calculate_end_time() {
    local minutes=$1

    # Check Alfred variable for time format preference
    # 'a' is 12-hour format, 'b' is 24-hour format
    if [[ "${alfred_time_format:-a}" == "a" ]]; then
        # 12-hour format with AM/PM
        date -v+"$minutes"M +"%l:%M %p" | sed 's/^ //'
    else
        # 24-hour format
        date -v+"$minutes"M +"%H:%M"
    fi
}

# Function to start an Amphetamine session with minutes
start_amphetamine_session() {
    local total_minutes=$1
    local allow_display_sleep=$2

    osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$total_minutes, interval:minutes, displaySleepAllowed:$allow_display_sleep}" || {
        echo "Error: Failed to start Amphetamine session."
        exit 1
    }
}

# Function to start an Amphetamine session with a target time
start_amphetamine_target_time() {
    local target_time=$1
    local allow_display_sleep=$2

    # Extract hour and minute from TIME:HH:MM format
    local hour=${target_time#TIME:}
    hour=${hour%:*}
    local minute=${target_time#*:}

    # Calculate total minutes until target time
    local current_hour=$(date +"%H")
    local current_minute=$(date +"%M")

    local target_minutes=$(( hour * 60 + minute ))
    local current_minutes=$(( current_hour * 60 + current_minute ))
    local duration_minutes=$(( target_minutes - current_minutes ))

    # If target time is earlier than current time, add 24 hours
    [[ $duration_minutes -lt 0 ]] && duration_minutes=$(( duration_minutes + 1440 ))

    # Start the session
    start_amphetamine_session "$duration_minutes" "$allow_display_sleep"

    # Format the time for display
    local display_time
    if [[ "${alfred_time_format:-a}" == "a" ]]; then
        display_time=$(date -j -f "%H:%M" "${hour}:${minute}" "+%l:%M %p" 2>/dev/null | sed 's/^ //')
    else
        display_time="${hour}:${minute}"
    fi

    if [[ "$allow_display_sleep" == "true" ]]; then
        echo "Keeping awake until ${display_time}. (Display can sleep)"
    else
        echo "Keeping awake until ${display_time}."
    fi
}

# Function to start an indefinite Amphetamine session
start_indefinite_session() {
    local allow_display_sleep=$1

    osascript -e "tell application \"Amphetamine\" to start new session with options {displaySleepAllowed:$allow_display_sleep}" || {
        echo "Error: Failed to start Amphetamine session."
        exit 1
    }

    if [[ "$allow_display_sleep" == "true" ]]; then
        echo "Keeping awake indefinitely. (Display can sleep)"
    else
        echo "Keeping awake indefinitely."
    fi
}

# Main function
main() {
    # Default value for display_sleep_allow if not set
    display_sleep_allow=${display_sleep_allow:-false}

    # Handle different input types from the Filter Script
    if [[ "$INPUT" == "0" ]]; then
        echo "Error: Invalid input. Please provide a valid duration."
        exit 1
    elif [[ "$INPUT" == "indefinite" ]]; then
        start_indefinite_session "$display_sleep_allow"
    elif [[ "$INPUT" == TIME:* ]]; then
        start_amphetamine_target_time "$INPUT" "$display_sleep_allow"
    elif [[ "$INPUT" =~ ^[0-9]+$ ]]; then
        local end_time=$(calculate_end_time "$INPUT")
        start_amphetamine_session "$INPUT" "$display_sleep_allow"

        if [[ "$display_sleep_allow" == "true" ]]; then
            echo "Keeping awake until around $end_time. (Display can sleep)"
        else
            echo "Keeping awake until around $end_time."
        fi
    else
        echo "Error: Invalid input. Please provide a valid duration."
        exit 1
    fi
}

INPUT="$1"
main
