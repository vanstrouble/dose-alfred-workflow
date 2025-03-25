#!/bin/bash

INPUT="$1"
STATE=$(osascript -e 'tell application "Amphetamine" to return session is active' 2>/dev/null)

if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    END_TIME=$(date -v+"$INPUT"M +"%H:%M")

    echo '{"items":[{"title":"Turn On for '"$INPUT"' minutes","subtitle":"Keep awake until around '"$END_TIME"'","arg":"'"$INPUT"'","icon":{"path":"icon.png"}}]}'
else
    if [[ "$STATE" == "true" ]]; then
        echo '{"items":[{"title":"Turn Off","subtitle":"Allow computer to sleep","arg":"off","icon":{"path":"icon.png"}}]}'
    else
        echo '{"items":[{"title":"Turn On","subtitle":"Prevent sleep indefinitely","arg":"on","icon":{"path":"icon.png"}}]}'
    fi
fi
