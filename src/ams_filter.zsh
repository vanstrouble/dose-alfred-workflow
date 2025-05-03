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

# Helper function to format hours with leading zero
format_hour() {
    local hour=$1
    # Ensure hour is a number without leading zeros
    hour=${hour#0}
    [[ -z "$hour" ]] && hour=0
    [[ "$hour" -lt 10 ]] && echo "0$hour" || echo "$hour"
}

# Helper function to format minutes with leading zero
format_minute() {
    local minute=$1
    # Ensure minute is a number without leading zeros
    minute=${minute#0}
    [[ -z "$minute" ]] && minute=0
    [[ "$minute" -lt 10 ]] && echo "0$minute" || echo "$minute"
}

# Helper function to convert AM/PM hour to 24-hour format
convert_to_24h_format() {
    local hour=$1
    local ampm=$2

    # Trim leading zeros
    hour=${hour#0}
    [[ -z "$hour" ]] && hour=0

    if [[ "$ampm" =~ [pP] && "$hour" -lt 12 ]]; then
        echo $(( hour + 12 ))
    elif [[ "$ampm" =~ [aA] && "$hour" -eq 12 ]]; then
        echo 0
    else
        echo $hour
    fi
}

# Helper function to calculate future time from minutes
calculate_future_time() {
    local total_minutes=$1
    local current_hour=$2
    local current_minute=$3

    local future_hour=$(( (total_minutes + current_hour * 60 + current_minute) / 60 % 24 ))
    local future_minute=$(( (total_minutes + current_hour * 60 + current_minute) % 60 ))

    # Format with leading zeros (after removing any existing leading zeros)
    future_hour=$(format_hour "$future_hour")
    future_minute=$(format_minute "$future_minute")

    echo "TIME:$future_hour:$future_minute"
}

# Function to parse the input and calculate the total minutes
parse_input() {
    local input=(${(@s/ /)1})  # Split the input into parts
    local current_hour=$(date +"%H")
    local current_minute=$(date +"%M")

    # Early return for invalid input when empty
    [[ -z "${input[1]}" ]] && echo "0" && return

    # Handle single input cases with early returns
    if [[ "${#input[@]}" -eq 1 ]]; then
        # Special value for indefinite mode
        [[ "${input[1]}" == "i" ]] && echo "indefinite" && return

        # Format: 2h (hours)
        if [[ "${input[1]}" =~ ^[0-9]+h$ ]]; then
            echo $(( ${input[1]%h} * 60 ))
            return
        fi

        # Direct number input (minutes)
        if [[ "${input[1]}" =~ ^[0-9]+$ ]]; then
            echo "${input[1]}"
            return
        fi

        # Format: 8 or 8: (hour only)
        if [[ "${input[1]}" =~ ^([0-9]{1,2}):?$ ]]; then
            local hour=${match[1]}
            local minute=0

            # Parameter expansion is more efficient than sed
            hour=${hour#0}

            # Check if the input has a colon at the end
            if [[ "${input[1]}" =~ :$ ]]; then
                # If it has a colon, calculate specific time
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")

                # Use helper function to calculate future time
                local future_time=$(calculate_future_time "$total_minutes" "$current_hour" "$current_minute")
                # For hour-only format with colon, we want to force minutes to 00
                echo "${future_time%:*}:00"
            else
                # No colon, return minutes
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
                echo "$total_minutes"
            fi
            return
        fi

        # Format: 8a, 8am, 8p, 8pm
        if [[ "${input[1]}" =~ ^([0-9]{1,2})([aApP])?(m)?$ ]]; then
            local hour=${match[1]}
            local ampm=${match[2]:-""}
            local minute=0

            # With AM/PM indicator
            if [[ -n "$ampm" ]]; then
                # Convert to 24-hour format using helper function
                hour=$(convert_to_24h_format "$hour" "$ampm")

                # Format hour with leading zero
                hour=$(format_hour "$hour")
                echo "TIME:$hour:00"
            else
                # Without AM/PM, use nearest future time
                hour=${hour#0}
                echo $(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")
            fi
            return
        fi

        # Format: 8:30, 8:30a, 8:30am, 8:30p, 8:30pm
        if [[ "${input[1]}" =~ ^([0-9]{1,2}):([0-9]{1,2})([aApP])?([mM])?$ ]]; then
            local hour=${match[1]}
            local minute=${match[2]}
            local ampm=${match[3]:-""}

            # With AM/PM indicator
            if [[ -n "$ampm" ]]; then
                # Convert to 24-hour format using helper function
                hour=$(convert_to_24h_format "$hour" "$ampm")

                # Format output with leading zeros
                hour=$(format_hour "$hour")
                minute=$(format_minute "$minute")
                echo "TIME:$hour:$minute"
            else
                # Without explicit AM/PM, calculate future time
                hour=${hour#0}
                local total_minutes=$(get_nearest_future_time "$hour" "$minute" "$current_hour" "$current_minute")

                # Use helper function to calculate and format future time
                echo $(calculate_future_time "$total_minutes" "$current_hour" "$current_minute")
            fi
            return
        fi

        # If we get here, it's an invalid single input
        echo "0"
        return
    fi

    # Handle two-part input (hours and minutes)
    if [[ "${#input[@]}" -eq 2 ]]; then
        if [[ "${input[1]}" =~ ^[0-9]+$ && "${input[2]}" =~ ^[0-9]+$ ]]; then
            echo $(( input[1] * 60 + input[2] ))
            return
        fi

        # Invalid two-part input
        echo "0"
        return
    fi

    # Default case: invalid input
    echo "0"
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
