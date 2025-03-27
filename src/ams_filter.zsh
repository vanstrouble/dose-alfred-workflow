#!/bin/zsh --no-rcs

# Function to detect system time format (12h or 24h)
detect_time_format() {
    local time_format=$(date +%X | grep -E "AM|PM" &>/dev/null && echo "12" || echo "24")
    echo "$time_format"
}

# Function to calculate the end time based on the given minutes
calculate_end_time() {
    local minutes=$1
    date -v+"$minutes"M +"%H:%M"
}

# Function to parse the input and calculate the total minutes
parse_input() {
    local input=(${(@s/ /)1})  # Split the input into parts
    local current_hour=$(date +"%H")
    local current_minute=$(date +"%M")
    local system_format=$(detect_time_format)

    if [[ "${#input[@]}" -eq 1 ]]; then
        if [[ "${input[1]}" =~ ^[0-9]+h$ ]]; then
            local hours=${input[1]%h}
            echo $(( hours * 60 ))
        elif [[ "${input[1]}" =~ ^[0-9]+$ ]]; then
            echo "${input[1]}"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):?$ ]]; then
            local hour=${match[1]}
            local minute=0
            hour=$(echo "$hour" | sed 's/^0*//')

            if [[ "$system_format" -eq 12 && "$hour" -lt "$current_hour" ]]; then
                hour=$(( hour + 12 ))
            fi

            local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
            (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
            echo "$total_minutes"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2})([aApP])?(m)?$ ]]; then
            # New case to handle inputs like 1p, 1pm, 8a, 8am
            local hour=${match[1]}
            local partial_am=${match[2]:-""}
            local complete_ampm=${match[3]:-""}

            # Convert the hour considering 12h format and AM/PM
            hour=$(echo "$hour" | sed 's/^0*//')
            local minute=0

            # Adjust hour based on partial or complete AM/PM input
            if [[ -n "$partial_am" ]]; then
                if [[ "$partial_am" =~ [pP] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$partial_am" =~ [aA] && "$hour" -eq 12 ]]; then
                    hour=0
                fi
            elif [[ -z "$partial_am" && -n "$complete_ampm" ]]; then
                # If only completed with 'm' (defaults to system format)
                if [[ "$system_format" -eq 12 && "$hour" -lt "$current_hour" ]]; then
                    hour=$(( hour + 12 ))
                fi
            elif [[ "$system_format" -eq 12 && "$hour" -lt "$current_hour" ]]; then
                hour=$(( hour + 12 ))
            fi

            local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
            (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
            echo "$total_minutes"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):([0-9]{1,2})([aApP])?$ ]]; then
            # Case to handle inputs like 11:10, 11:10a, 11:10p
            local hour=${match[1]}
            local partial_minute=${match[2]}
            local partial_ampm=${match[3]:-""}

            # Convert the hour considering 12h format and AM/PM
            hour=$(echo "$hour" | sed 's/^0*//')

            # Adjust hour based on partial AM/PM input
            if [[ -n "$partial_ampm" ]]; then
                if [[ "$partial_ampm" =~ [pP] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$partial_ampm" =~ [aA] && "$hour" -eq 12 ]]; then
                    hour=0
                fi
            elif [[ "$system_format" -eq 12 && "$hour" -lt "$current_hour" ]]; then
                hour=$(( hour + 12 ))
            fi

            # Complete minutes if partial
            local minute=0
            if [[ "${#partial_minute}" -eq 1 ]]; then
                minute=0
            else
                minute=$partial_minute
            fi

            local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
            (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
            echo "$total_minutes"
        elif [[ "${input[1]}" =~ ^([0-9]{1,2}):([0-9]{2})([aApP][mM])?$ ]]; then
            local hour=${match[1]}
            local minute=${match[2]}
            local ampm=${match[3]:-""}

            if [[ -n "$ampm" ]]; then
                hour=$(echo "$hour" | sed 's/^0*//')
                if [[ "$ampm" =~ [pP][mM] && "$hour" -lt 12 ]]; then
                    hour=$(( hour + 12 ))
                elif [[ "$ampm" =~ [aA][mM] && "$hour" -eq 12 ]]; then
                    hour=0
                fi
            elif [[ "$system_format" -eq 12 ]]; then
                if [[ "$hour" -lt "$current_hour" ]]; then
                    hour=$(( hour + 12 ))
                fi
            fi

            local total_minutes=$(( (hour * 60 + minute) - (current_hour * 60 + current_minute) ))
            (( total_minutes < 0 )) && total_minutes=$(( total_minutes + 1440 ))
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
    if [[ "$total_minutes" -gt 0 ]]; then
        local end_time=$(calculate_end_time "$total_minutes")
        local formatted_duration=$(format_duration "$total_minutes")
        echo '{"items":[{"title":"Active for '"$formatted_duration"'","subtitle":"Keep awake until around '"$end_time"'","arg":"'"$total_minutes"'","icon":{"path":"icon.png"}}]}'
    fi
}

# Main function
main() {
    local total_minutes=$(parse_input "$1")
    generate_output "$total_minutes"
}

# Execute the main function with the input
main "$1"
