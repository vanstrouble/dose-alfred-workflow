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

# Function to extract hour and minute from TIME:HH:MM format
parse_time_format() {
    local time_str=$1

    # Remove the TIME: prefix
    time_str=${time_str#TIME:}

    # Extract hour and minute directly
    local hour=${time_str%%:*}
    local minute=${time_str#*:}

    # Validate input - purely numeric and in range
    if [[ ! "$hour" =~ ^[0-9]+$ || ! "$minute" =~ ^[0-9]+$ || "$hour" -gt 23 || "$minute" -gt 59 ]]; then
        echo "Error: Invalid time format: $time_str" >&2
        exit 1
    fi

    # Return as space-separated values
    echo "$hour $minute"
}

# Function to start an Amphetamine session with minutes
start_amphetamine_session() {
    local total_minutes=$1
    local allow_display_sleep=$2

    # Ensure the minutes are a valid number and greater than 0
    if [[ ! "$total_minutes" =~ ^[0-9]+$ || "$total_minutes" -eq 0 ]]; then
        echo "Error: Invalid duration: $total_minutes minutes" >&2
        exit 1
    fi

    osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$total_minutes, interval:minutes, displaySleepAllowed:$allow_display_sleep}" || {
        echo "Error: Failed to start Amphetamine session." >&2
        exit 1
    }
}

# Function to start an Amphetamine session with a target time
start_amphetamine_target_time() {
    local target_time=$1
    local allow_display_sleep=$2

    # Extract hour and minute using the dedicated function
    read -r hour minute <<< "$(parse_time_format "$target_time")"

    # Debug output
    echo "Debug: Parsed time - Hour: $hour, Minute: $minute" >&2

    # Calculate total minutes until target time
    local current_hour=$(date +"%H")
    local current_minute=$(date +"%M")

    # Debug output
    echo "Debug: Current time - Hour: $current_hour, Minute: $current_minute" >&2

    local target_minutes=$(( hour * 60 + minute ))
    local current_minutes=$(( current_hour * 60 + current_minute ))
    local duration_minutes=$(( target_minutes - current_minutes ))

    # Debug output
    echo "Debug: Minutes calculation - Target: $target_minutes, Current: $current_minutes, Duration: $duration_minutes" >&2

    # If target time is earlier than current time, add 24 hours
    [[ $duration_minutes -le 0 ]] && duration_minutes=$(( duration_minutes + 1440 ))

    # Debug output after adjustment
    echo "Debug: Final duration minutes: $duration_minutes" >&2

    # Start the session
    start_amphetamine_session "$duration_minutes" "$allow_display_sleep"

    # Format the time for display based on user preference
    local display_time
    if [[ "${alfred_time_format:-a}" == "a" ]]; then
        # 12-hour format
        if [[ "$hour" -gt 12 ]]; then
            display_time="$((hour-12)):${minute} PM"
        elif [[ "$hour" -eq 12 ]]; then
            display_time="12:${minute} PM"
        elif [[ "$hour" -eq 0 ]]; then
            display_time="12:${minute} AM"
        else
            display_time="${hour}:${minute} AM"
        fi

        # Ensure minutes have leading zero if needed
        [[ ${#minute} -eq 1 ]] && display_time="${display_time/\:$minute/\:0$minute}"
    else
        # 24-hour format
        [[ ${#hour} -eq 1 ]] && hour="0$hour"
        [[ ${#minute} -eq 1 ]] && minute="0$minute"
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
        echo "Error: Failed to start Amphetamine session." >&2
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
