#!/bin/zsh --no-rcs

# Function to calculate the end time based on the given minutes
calculate_end_time() {
    local minutes=$1
    date -v+"$minutes"M +"%H:%M"
}

# Function to parse the input and calculate the total minutes
parse_input() {
    local input=("${(@s/ /)1}")  # Split the input into parts
    if [[ "${#input[@]}" -eq 1 && "${input[1]}" =~ ^[0-9]+$ ]]; then
        # Format: ams 30 (only minutes)
        echo "${input[1]}"
    elif [[ "${#input[@]}" -eq 2 ]]; then
        if [[ "${input[1]}" =~ ^[0-9]+$ && -z "${input[2]}" ]]; then
            # Format: ams 1 (hours only, with trailing space)
            echo $(( input[1] * 60 ))
        elif [[ "${input[1]}" =~ ^[0-9]+$ && "${input[2]}" =~ ^[0-9]+$ ]]; then
            # Format: ams 1 20 (hours and minutes)
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

# Function to generate Alfred JSON output
generate_output() {
    local total_minutes=$1
    if [[ "$total_minutes" -gt 0 ]]; then
        local end_time=$(calculate_end_time "$total_minutes")
        echo '{"items":[{"title":"Active for '"$total_minutes"' minutes","subtitle":"Keep awake until around '"$end_time"'","arg":"'"$total_minutes"'","icon":{"path":"icon.png"}}]}'
    fi
}

# Main function
main() {
    local total_minutes=$(parse_input "$1")
    generate_output "$total_minutes"
}

# Execute the main function with the input
main "$1"
