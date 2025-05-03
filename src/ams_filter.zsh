#!/bin/zsh --no-rcs

# Function to calculate the end time based on the given minutes
calculate_end_time() {
    local minutes=$1

    # Check Alfred variable for time format preference
    # 'a' is 12-hour format, 'b' is 24-hour format
    if [[ "${alfred_time_format:-a}" == "a" ]]; then
        # 12-hour format with AM/PM including seconds
        date -v+"$minutes"M +"%l:%M:%S %p" | sed 's/^ //'
    else
        # 24-hour format including seconds
        date -v+"$minutes"M +"%H:%M:%S"
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
    local input=(${(@s/ /)1})  # Split the input into parts
    local current_hour=$(date +"%H")
    local current_minute=$(date +"%M")

    if [[ "${#input[@]}" -eq 1 ]]; then
        if [[ "${input[1]}" == "i" ]]; then
            # Special value for indefinite mode
            echo "indefinite"
            return
        elif [[ "${input[1]}" =~ ^[0-9]+h$ ]]; then
            # Use parameter expansion instead of separate variable
            echo $(( ${input[1]%h} * 60 ))
            return
        elif [[ "${input[1]}" =~ ^[0-9]+$ ]]; then
            # Direct number input (minutes)
            echo "${input[1]}"
            return
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):?$ ]]; then
            # Format: 8 or 8: (hour only)
            local hour=${match[1]}
            local minute=0

            # Parameter expansion is more efficient than sed
            hour=${hour#0}

            # Check if the input has a colon at the end
            if [[ "${input[1]}" =~ :$ ]]; then
                # If it has a colon, use the same nearest future time logic
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")

                # Convert minutes to hours and minutes since midnight
                local future_hour=$(( (total_minutes + current_hour * 60 + current_minute) / 60 % 24 ))

                # Ensure the hour has two digits for formatted output
                [[ "$future_hour" -lt 10 ]] && future_hour="0$future_hour"
                echo "TIME:$future_hour:00"
            else
                # No colon, use nearest future time logic
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
                echo "$total_minutes"
            fi
            return
        # For formats like "8a", "8am", "8p", "8pm"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2})([aApP])?(m)?$ ]]; then
            local hour=${match[1]}
            local ampm=${match[2]:-""}

            hour=${hour#0}
            local minute=0

            # Convert to 24-hour format
            if [[ -n "$ampm" ]]; then
            if [[ "$ampm" =~ [pP] && "$hour" -lt 12 ]]; then
                hour=$(( hour + 12 ))
            elif [[ "$ampm" =~ [aA] && "$hour" -eq 12 ]]; then
                hour=0
            fi

            # For exact hours, return "TIME:HH:MM" in 24-hour format
            # Ensure the hour has two digits
            [[ "$hour" -lt 10 ]] && hour="0$hour"
            echo "TIME:$hour:00"
            else
            # Without AM/PM, use nearest future time logic
            echo $(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
            fi
            return
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):([0-9]{1,2})([aApP])?([mM])?$ ]]; then
            # Format: 8:30, 8:30a, 8:30am, 8:30p, 8:30pm
            local hour=${match[1]}
            local minute=${match[2]}
            local ampm=${match[3]:-""}

            hour=${hour#0}

            # Ensure that the minute has two digits
            [[ "${#minute}" -eq 1 ]] && minute="0$minute"

            if [[ -n "$ampm" ]]; then
                # Convert to 24-hour format
                if [[ "$ampm" =~ [pP] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$ampm" =~ [aA] && "$hour" -eq 12 ]]; then
                    hour=0
                fi

                # Ensure the hour has two digits
                [[ "$hour" -lt 10 ]] && hour="0$hour"
                echo "TIME:$hour:$minute"
            else
                # Without explicit AM/PM, use nearest future time logic
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")

                # Convert minutes to hours and minutes since midnight
                local future_hour=$(( (total_minutes + current_hour * 60 + current_minute) / 60 % 24 ))
                local future_minute=$(( (total_minutes + current_hour * 60 + current_minute) % 60 ))

                # Ensure the hour and minute have two digits
                [[ "$future_hour" -lt 10 ]] && future_hour="0$future_hour"
                [[ "$future_minute" -lt 10 ]] && future_minute="0$future_minute"

                echo "TIME:$future_hour:$future_minute"
            fi
            return
        else
            # Invalid single input
            echo "0"
            return
        fi
    elif [[ "${#input[@]}" -eq 2 ]]; then
        if [[ "${input[1]}" =~ ^[0-9]+$ && "${input[2]}" =~ ^[0-9]+$ ]]; then
            # Format: 1 20 (hours and minutes)
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
    local input_result=$1

    # Check for invalid input first (fastest check)
    if [[ "$input_result" == "0" ]]; then
        echo '{"items":[{"title":"Invalid input","subtitle":"Please provide a valid time format","arg":"0","icon":{"path":"icon.png"}}]}'
        return
    fi

    # Check for indefinite mode (no rerun needed)
    if [[ "$input_result" == "indefinite" ]]; then
        echo '{"items":[{"title":"Active indefinitely","subtitle":"Keep your Mac awake until manually disabled","arg":"indefinite","icon":{"path":"icon.png"}}]}'
        return
    fi

    # Check for target time format
    if [[ "$input_result" == TIME:* ]]; then
        local target_time=${input_result#TIME:}
        local hour=${target_time%:*}
        local minute=${target_time#*:}

        # To display the time in a user-friendly format
        local display_time=$(date -j -f "%H:%M" "$target_time" "+%l:%M %p" 2>/dev/null | sed 's/^ //')
        [[ $? -ne 0 ]] && display_time="$target_time"

        echo '{"items":[{"title":"Active until '"$display_time"'","subtitle":"Keep awake until specified time","arg":"'"$input_result"'","icon":{"path":"icon.png"}}]}'
        return
    fi

    # Finally, handle duration in minutes (most common case)
    local end_time=$(calculate_end_time "$input_result")
    local formatted_duration=$(format_duration "$input_result")
    echo '{"rerun":1,"items":[{"title":"Active for '"$formatted_duration"'","subtitle":"Keep awake until around '"$end_time"'","arg":"'"$input_result"'","icon":{"path":"icon.png"}}]}'
}

# Main function
main() {
    local total_minutes=$(parse_input "$1")
    generate_output "$total_minutes"
}

# Execute the main function with the input
main "$1"
