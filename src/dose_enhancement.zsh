#!/bin/bash

INPUT="$1"

# Use hotkey_value if provided
if [[ -n "$hotkey_value" ]]; then
    INPUT="$hotkey_value"
fi

# Default value for display_sleep_allow if not set
display_sleep_allow=${display_sleep_allow:-false}

if [[ "$INPUT" == "off" ]]; then
    osascript -e "tell application \"Amphetamine\" to end session"
    echo "Amphetamine deactivated."
elif [[ "$INPUT" == "on" ]]; then
    # Use display_sleep_allow parameter only when turning on
    osascript -e "tell application \"Amphetamine\" to start new session with options {displaySleepAllowed:$display_sleep_allow}"

    if [[ "$display_sleep_allow" == "true" ]]; then
        echo "Amphetamine activated (display can sleep)."
    else
        echo "Amphetamine activated."
    fi
else
    exit 1
fi
