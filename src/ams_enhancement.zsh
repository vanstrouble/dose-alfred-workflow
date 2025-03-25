#!/bin/bash

function notification {
    ./notificator --title "Amphetamine Control" --message "${1}"
}

INPUT="$1"

if [[ -n "$hotkey_value" ]]; then
    INPUT="$hotkey_value"
fi

# Debugging
echo "DEBUG: INPUT='$INPUT', HOTKEY_VALUE='$hotkey_value'" >&2

if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$INPUT, interval:minutes, displaySleepAllowed:false}"
    notification "Amphetamine activated for $INPUT minutes."
elif [[ "$INPUT" == "on" ]]; then
    osascript -e "tell application \"Amphetamine\" to start new session"
    notification "Amphetamine activated."
elif [[ "$INPUT" == "off" ]]; then
    osascript -e "tell application \"Amphetamine\" to end session"
    notification "Amphetamine deactivated."
else
    echo "Usage: $0 [on|off|minutes]"
fi
