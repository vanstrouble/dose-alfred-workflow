#!/bin/zsh --no-rcs

# Function to calculate the end time based on the given minutes
calculate_end_time() {
    local minutes=$1
    date -v+"$minutes"M +"%H:%M"
}

# Function to parse the input and calculate the total minutes
parse_input() {
    local input=("${(@s/ /)1}")  # Split the input into parts
    if [[ "${#input[@]}" -eq 1 ]]; then
        if [[ "${input[1]}" =~ ^[0-9]+h$ ]]; then
            # Format: 2h (hours with 'h' suffix)
            local hours=${input[1]%h}  # Remove the 'h' suffix
            echo $(( hours * 60 ))
        elif [[ "${input[1]}" =~ ^[0-9]+$ ]]; then
            # Format: 30 (only minutes)
            echo "${input[1]}"
        else
            # Invalid single input
            echo "0"
        fi
    elif [[ "${#input[@]}" -eq 2 ]]; then
        if [[ "${input[1]}" =~ ^[0-9]+$ && -z "${input[2]}" ]]; then
            # Format: 1 (hours only, but second number not yet entered)
            echo "${input[1]}"  # Treat as minutes until the second number is entered
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
