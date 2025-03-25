#!/bin/bash

function notification {
    ./notificator --title "Amphetamine Control" --message "${1}"
}

INPUT="$1"

if [[ -n "$hotkey_value" ]]; then
    INPUT="$hotkey_value"
fi

# Depuración
echo "DEBUG: INPUT='$INPUT', HOTKEY_VALUE='$hotkey_value'" >&2

if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$INPUT, interval:minutes, displaySleepAllowed:false}"
    notification "Amphetamine activado por $INPUT minutos."
elif [[ "$INPUT" == "on" ]]; then
    osascript -e "tell application \"Amphetamine\" to start new session"
    notification "Amphetamine activado."
elif [[ "$INPUT" == "off" ]]; then
    osascript -e "tell application \"Amphetamine\" to end session"
    notification "Amphetamine desactivado."
else
    echo "Usage: $0 [on|off|minutes]"
fi
