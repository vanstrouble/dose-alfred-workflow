#!/bin/zsh --no-rcs

INPUT="$1"
STATE=$(osascript -e 'tell application "Amphetamine" to return session is active' 2>/dev/null)

if [[ "$STATE" == "true" ]]; then
    echo '{"items":[{"title":"Turn Off","subtitle":"Allow computer to sleep","arg":"off","icon":{"path":"icon.png"}}]}'
else
    echo '{"items":[{"title":"Turn On","subtitle":"Prevent sleep indefinitely","arg":"on","icon":{"path":"icon.png"}}]}'
fi
