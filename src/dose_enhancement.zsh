#!/bin/bash

INPUT="$1"

if [[ -n "$hotkey_value" ]]; then
    INPUT="$hotkey_value"
fi

notification_message=""

if [[ "$INPUT" == "on" ]]; then
    osascript -e "tell application \"Amphetamine\" to start new session"
    notification_message="Amphetamine activated."
elif [[ "$INPUT" == "off" ]]; then
    osascript -e "tell application \"Amphetamine\" to end session"
    notification_message="Amphetamine deactivated."
else
    exit 1
fi

echo "$notification_message"
