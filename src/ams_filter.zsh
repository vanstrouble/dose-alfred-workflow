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

# Add leading zero to single digit numbers
pad_zero() {
    local num=${1#0}
    [[ -z "$num" ]] && num=0
    [[ "$num" -lt 10 ]] && echo "0$num" || echo "$num"
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
    future_hour=$(pad_zero "$future_hour")
    future_minute=$(pad_zero "$future_minute")

    echo "TIME:$future_hour:$future_minute"
}

# Function to get Amphetamine session time remaining
get_amphetamine_time_remaining() {
    osascript -e 'tell application "Amphetamine" to get session time remaining' 2>/dev/null
}

# Function to get Amphetamine status data
check_status() {
    # Get Amphetamine session information
    local time_remaining
    time_remaining=$(get_amphetamine_time_remaining)

    # Handle case where Amphetamine is not running or command fails
    if [[ $? -ne 0 || -z "$time_remaining" ]]; then
        echo "DEACTIVATED|Run a command to start an Amphetamine session|false"
        return
    fi

    local title=""
    local subtitle=""
    local needs_rerun="false"

    case "$time_remaining" in
        -3)
            # No active session
            title="Amphetamine deactivated"
            subtitle="Run a command to start an Amphetamine session"
            needs_rerun="false"
            ;;
        0)
            # Indefinite session - for indefinite sessions, we don't need elapsed time
            # since we can't calculate it reliably without additional API calls
            title="Amphetamine active indefinitely"
            subtitle="Session running indefinitely"
            needs_rerun="false"  # No need for frequent updates on indefinite sessions
            ;;
        [1-9]*)
            # Timed session - calculate end time and format remaining time efficiently
            # Single date call to get both current timestamp and formatted end time
            local date_output
            if [[ "${alfred_time_format:-a}" == "a" ]]; then
                # Get current timestamp and calculate end time in one operation
                date_output=$(date "+%s|$(date -v+"$time_remaining"S "+%l:%M %p" | sed 's/^ //')")
            else
                date_output=$(date "+%s|$(date -v+"$time_remaining"S "+%H:%M")")
            fi

            local current_timestamp=${date_output%%|*}
            local end_time=${date_output#*|}

            title="Amphetamine active until $end_time"

            # Format remaining time naturally (similar to format_duration logic)
            if [[ $time_remaining -lt 60 ]]; then
                subtitle="${time_remaining}s remaining"
            elif [[ $time_remaining -lt 3600 ]]; then
                local minutes=$(( time_remaining / 60 ))
                local seconds=$(( time_remaining % 60 ))
                if [[ $seconds -eq 0 ]]; then
                    subtitle="${minutes}m remaining"
                else
                    subtitle="${minutes}m ${seconds}s remaining"
                fi
            else
                local hours=$(( time_remaining / 3600 ))
                local minutes=$(( (time_remaining % 3600) / 60 ))
                if [[ $minutes -eq 0 ]]; then
                    subtitle="${hours}h remaining"
                else
                    subtitle="${hours}h ${minutes}m remaining"
                fi
            fi

            # Smart rerun: only for sessions under 2 hours for better performance
            if [[ $time_remaining -le 7200 ]]; then
                needs_rerun="true"
            else
                needs_rerun="false"
            fi
            ;;
    esac

    # Return structured data: title|subtitle|needs_rerun
    echo "$title|$subtitle|$needs_rerun"
}

# Function to parse the input and calculate the total minutes
parse_input() {
    local input=(${(@s/ /)1})  # Split the input into parts
    local current_hour=$(date +"%H")
    local current_minute=$(date +"%M")

    # Early return for invalid input when empty
    [[ -z "${input[1]}" ]] && echo "0" && return

    # Check for status command
    [[ "${input[1]}" == "s" ]] && echo "status" && return

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
                hour=$(pad_zero "$hour")
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
                hour=$(pad_zero "$hour")
                minute=$(pad_zero "$minute")
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

    # Check for status command
    if [[ "$input_result" == "status" ]]; then
        local status_data=$(check_status)
        local title=${status_data%%|*}
        local remaining=${status_data#*|}
        local subtitle=${remaining%%|*}
        local needs_rerun=${status_data##*|}

        # Escape JSON special characters
        title=${title//\"/\\\"}
        subtitle=${subtitle//\"/\\\"}

        # Generate JSON with conditional rerun
        local rerun_part=""
        [[ "$needs_rerun" == "true" ]] && rerun_part='"rerun":1,'

        echo '{'${rerun_part}'"items":[{"title":"'"$title"'","subtitle":"'"$subtitle"'","arg":"status","icon":{"path":"icon.png"}}]}'
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
