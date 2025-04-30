#!/bin/bash

# Use hotkey_value if provided, otherwise use first argument
INPUT="${hotkey_value:-$1}"

# Default value for display_sleep_allow if not set
display_sleep_allow=${display_sleep_allow:-false}

if [[ "$INPUT" == "off" ]]; then
    osascript -e "tell application \"Amphetamine\" to end session"
    echo "Amphetamine deactivated."
elif [[ "$INPUT" == "on" ]]; then
    # Use display_sleep_allow parameter only when turning on
    osascript -e "tell application \"Amphetamine\" to start new session with options {displaySleepAllowed:$display_sleep_allow}"

    # Use parameter expansion for conditional message
    display_text=""
    [[ "$display_sleep_allow" == "true" ]] && display_text=" (display can sleep)"
    echo "Amphetamine activated${display_text}."
else
    echo "Error: Invalid input. Use 'on' or 'off'."
    exit 1
fi
