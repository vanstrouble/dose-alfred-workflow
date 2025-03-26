#!/bin/bash

calculate_end_time() {
    local minutes=$1
    date -v+"$minutes"M +"%H:%M"
}

start_amphetamine_session() {
    local minutes=$1
    osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$minutes, interval:minutes, displaySleepAllowed:false}" || {
        echo "Error: Failed to start Amphetamine session."
        exit 1
    }
}

main() {
    local end_time=$(calculate_end_time "$INPUT")
    start_amphetamine_session "$INPUT"
    echo "Keeping awake until around $end_time."
}

INPUT="$1"
main
