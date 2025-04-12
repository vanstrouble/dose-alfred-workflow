#!/bin/zsh --no-rcs

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

    # Special handling for hour 12
    local am_hour=$hour
    local pm_hour=$hour

    # For 12-hour format conversion
    if [[ $hour -eq 12 ]]; then
        am_hour=0  # 12 AM is actually 0 in 24-hour format
    elif [[ $hour -lt 12 ]]; then
        pm_hour=$(( hour + 12 ))
    fi

    # Calculate minutes for AM and PM interpretations
    local am_total_minutes=$(( (am_hour * 60 + minute) - (current_hour * 60 + current_minute) ))
    local pm_total_minutes=$(( (pm_hour * 60 + minute) - (current_hour * 60 + current_minute) ))

    # If AM time is in the past and PM time is in future, use PM
    if [[ $am_total_minutes -lt 0 && $pm_total_minutes -gt 0 ]]; then
        echo $pm_total_minutes
    # If AM time is in the future, use that
    elif [[ $am_total_minutes -gt 0 ]]; then
        echo $am_total_minutes
    # If both are in the past, roll over to tomorrow
    else
        echo $(( am_total_minutes + 1440 ))
    fi
}

# Function to parse the input and calculate the total minutes
parse_input() {
    local input=(${(@s/ /)1})  # Split the input into parts
    local current_hour=$(date +"%H")
    local current_minute=$(date +"%M")
    local system_format=$(detect_time_format)

    if [[ "${#input[@]}" -eq 1 ]]; then
        if [[ "${input[1]}" == "i" ]]; then
            # Special value for indefinite mode
            echo "indefinite"
        elif [[ "${input[1]}" =~ ^[0-9]+h$ ]]; then
            local hours=${input[1]%h}
            echo $(( hours * 60 ))
        elif [[ "${input[1]}" =~ ^[0-9]+$ ]]; then
            echo "${input[1]}"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):?$ ]]; then
            local hour=${match[1]}
            local minute=0
            hour=$(echo "$hour" | sed 's/^0*//')

            # Use nearest future time logic
            if [[ -n "$ampm" ]]; then
                # Process explicit AM/PM if provided
                if [[ "$ampm" =~ [pP] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$ampm" =~ [aA] && "$hour" -eq 12 ]]; then
                    hour=0
                fi
                local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
                (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
            else
                # Use new function to get nearest future time
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
            fi

            echo "$total_minutes"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2})([aApP])?(m)?$ ]]; then
            # New case to handle inputs like 1p, 1pm, 8a, 8am
            local hour=${match[1]}
            local partial_am=${match[2]:-""}
            local complete_ampm=${match[3]:-""}

            hour=$(echo "$hour" | sed 's/^0*//')
            local minute=0

            # If AM/PM is provided, use that
            if [[ -n "$partial_am" ]]; then
                if [[ "$partial_am" =~ [pP] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$partial_am" =~ [aA] && "$hour" -eq 12 ]]; then
                    hour=0
                fi
                local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
                (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
            else
                # Use new function to get nearest future time
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
            fi

            echo "$total_minutes"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):([0-9]{1,2})([aApP])?$ ]]; then
            # Case to handle inputs like 11:10, 11:10a, 11:10p
            local hour=${match[1]}
            local partial_minute=${match[2]}
            local partial_ampm=${match[3]:-""}

            hour=$(echo "$hour" | sed 's/^0*//')

            # Complete minutes if partial
            local minute=0
            if [[ "${#partial_minute}" -eq 1 ]]; then
                minute=0
            else
                minute=$partial_minute
            fi

            # If AM/PM is provided, use that
            if [[ -n "$partial_ampm" ]]; then
                if [[ "$partial_ampm" =~ [pP] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$partial_ampm" =~ [aA] && "$hour" -eq 12 ]]; then
                    hour=0
                fi
                local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
                (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
            else
                # Use new function to get nearest future time
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
            fi

            echo "$total_minutes"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):([0-9]{2})([aApP][mM])?$ ]]; then
            local hour=${match[1]}
            local minute=${match[2]}
            local ampm=${match[3]:-""}

            hour=$(echo "$hour" | sed 's/^0*//')

            # If AM/PM is provided, use that
            if [[ -n "$ampm" ]]; then
                if [[ "$ampm" =~ [pP][mM] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$ampm" =~ [aA][mM] && "$hour" -eq 12 ]]; then
                    hour=0
                fi
                local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
                (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
            else
                # Use new function to get nearest future time
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
            fi

            echo "$total_minutes"
        else
            echo "0"
        fi
    elif [[ "${#input[@]}" -eq 2 ]]; then
        if [[ "${input[1]}" =~ ^[0-9]+$ && "${input[2]}" =~ ^[0-9]+$ ]]; then
            echo $(( input[1] * 60 + input[2] ))
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Function to format the duration in hours and minutes
format_duration() {
    local total_minutes=$1
    local hours=$(( total_minutes / 60 ))
    local minutes=$(( total_minutes % 60 ))

    if [[ "$hours" -gt 0 && "$minutes" -gt 0 ]]; then
        echo "$hours hour(s) $minutes minute(s)"
    elif [[ "$hours" -gt 0 ]]; then
        echo "$hours hour(s)"
    else
        echo "$minutes minute(s)"
    fi
}

# Function to generate Alfred JSON output
generate_output() {
    local total_minutes=$1
    if [[ "$total_minutes" == "indefinite" ]]; then
        echo '{"items":[{"title":"Active indefinitely","subtitle":"Keep awake indefinitely","arg":"indefinite","icon":{"path":"icon.png"}}]}'
    elif [[ "$total_minutes" -gt 0 ]]; then
        local end_time=$(calculate_end_time "$total_minutes")
        local formatted_duration=$(format_duration "$total_minutes")
        echo '{"items":[{"title":"Active for '"$formatted_duration"'","subtitle":"Keep awake until around '"$end_time"'","arg":"'"$total_minutes"'","icon":{"path":"icon.png"}}]}'
    else
        echo '{"items":[{"title":"Invalid input","subtitle":"Please provide a valid time format","arg":"0","icon":{"path":"icon.png"}}]}'
    fi
}

# Main function
main() {
    local total_minutes=$(parse_input "$1")
    generate_output "$total_minutes"
}

# Execute the main function with the input
main "$1"
