#!/bin/bash

# Function to detect system time format (12h or 24h)
detect_time_format() {
    local time_format=$(date +%X | grep -E "AM|PM" &>/dev/null && echo "12" || echo "24")
    echo "$time_format"
}

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

# Function to get the nearest future time based on input hour and minute
get_nearest_future_time() {
    local hour=$1
    local minute=$2
    local current_hour=$3
    local current_minute=$4

    # Calculate current time in minutes since midnight (once instead of twice)
    local current_total=$(( current_hour * 60 + current_minute ))

    # Special handling for hour 12 and conversion to AM/PM using shorter syntax
    local am_hour=$hour
    local pm_hour=$hour
    [[ $hour -eq 12 ]] && am_hour=0  # 12 AM is actually 0 in 24-hour format
    [[ $hour -lt 12 ]] && pm_hour=$(( hour + 12 ))

    # Calculate minutes for AM and PM interpretations
    local am_total=$(( am_hour * 60 + minute ))
    local pm_total=$(( pm_hour * 60 + minute ))

    # Calculate differences once
    local am_diff=$(( am_total - current_total ))
    local pm_diff=$(( pm_total - current_total ))

    # Use the same logic but with pre-calculated differences
    if [[ $am_diff -lt 0 && $pm_diff -gt 0 ]]; then
        echo $pm_diff
    elif [[ $am_diff -gt 0 ]]; then
        echo $am_diff
    else
        echo $(( am_diff + 1440 ))
    fi
}

# Function to parse the input and calculate the total minutes
parse_input() {
    local input=("${(@s/ /)1}")  # Split the input into parts
    local current_hour=$(date +"%H")
    local current_minute=$(date +"%M")
    local system_format=$(detect_time_format)

    if [[ "${#input[@]}" -eq 1 ]]; then
        if [[ "${input[1]}" == "i" ]]; then
            # Special value for indefinite mode
            echo "indefinite"
        elif [[ "${input[1]}" =~ ^[0-9]+h$ ]]; then
            # Format: 2h (hours with 'h' suffix)
            local hours=${input[1]%h}  # Remove the 'h' suffix with parameter expansion
            echo $(( hours * 60 ))
        elif [[ "${input[1]}" =~ ^[0-9]+$ ]]; then
            # Format: 30 (only minutes)
            echo "${input[1]}"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):?$ ]]; then
            # Format: 8 (hour only)
            local hour=${input[1]}
            local minute=0
            # Use parameter expansion instead of sed
            hour=${hour#0}

            # Use nearest future time logic
            local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
            echo "$total_minutes"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2})([aApP])?(m)?$ ]]; then
            # Format: 8a, 8am, 8p, 8pm
            local hour=${input[1]}
            local minute=0

            # Extract the hour and AM/PM part
            if [[ $hour =~ ^([0-9]+)([aApP])[mM]?$ ]]; then
                hour=${BASH_REMATCH[1]}
                local ampm=${BASH_REMATCH[2]}

                # Use parameter expansion instead of sed
                hour=${hour#0}

                # Process explicit AM/PM
                if [[ "$ampm" =~ [pP] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$ampm" =~ [aA] && "$hour" -eq 12 ]]; then
                    hour=0
                fi

                local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
                (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
                echo "$total_minutes"
            else
                # If no AM/PM specified, use nearest future time
                hour=${hour#0}
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
                echo "$total_minutes"
            fi
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):([0-9]{1,2})([aApP])?([mM])?$ ]]; then
            # Format: 8:30, 8:30a, 8:30am, 8:30p, 8:30pm
            local full_match=${input[1]}
            local hour=""
            local minute=""
            local ampm=""

            # Extract hour, minute and AM/PM
            if [[ $full_match =~ ^([0-9]{1,2}):([0-9]{1,2})$ ]]; then
                # Format: 8:30
                hour=${BASH_REMATCH[1]}
                minute=${BASH_REMATCH[2]}

                # Use parameter expansion instead of sed
                hour=${hour#0}

                # Use nearest future time logic
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
                echo "$total_minutes"
            elif [[ $full_match =~ ^([0-9]{1,2}):([0-9]{1,2})([aApP])([mM])?$ ]]; then
                # Format: 8:30a, 8:30am, 8:30p, 8:30pm
                hour=${BASH_REMATCH[1]}
                minute=${BASH_REMATCH[2]}
                ampm=${BASH_REMATCH[3]}

                # Use parameter expansion instead of sed
                hour=${hour#0}

                # Process explicit AM/PM
                if [[ "$ampm" =~ [pP] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$ampm" =~ [aA] && "$hour" -eq 12 ]]; then
                    hour=0
                fi

                local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
                (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
                echo "$total_minutes"
            else
                echo "0"
            fi
        else
            # Invalid single input
            echo "0"
        fi
    elif [[ "${#input[@]}" -eq 2 ]]; then
        if [[ "${input[1]}" =~ ^[0-9]+$ && "${input[2]}" =~ ^[0-9]+$ ]]; then
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
    local allow_display_sleep=$2

    osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$total_minutes, interval:minutes, displaySleepAllowed:$allow_display_sleep}" || {
        echo "Error: Failed to start Amphetamine session."
        exit 1
    }
}

# Function to handle indefinite session
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

    # Check direct input for "indefinite" or parse the input
    if [[ "$INPUT" == "indefinite" ]]; then
        start_indefinite_session "$display_sleep_allow"
        exit 0
    fi

    local total_minutes=$(parse_input "$INPUT")

    if [[ "$total_minutes" == "indefinite" ]]; then
        start_indefinite_session "$display_sleep_allow"
    elif [[ "$total_minutes" -gt 0 ]]; then
        local end_time=$(calculate_end_time "$total_minutes")
        start_amphetamine_session "$total_minutes" "$display_sleep_allow"

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
