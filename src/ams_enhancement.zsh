#!/bin/bash

INPUT="$1"

if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
  osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$INPUT, interval:minutes, displaySleepAllowed:false}"
elif [[ "$INPUT" == "on" ]]; then
  osascript -e "tell application \"Amphetamine\" to start new session"
elif [[ "$INPUT" == "off" ]]; then
  osascript -e "tell application \"Amphetamine\" to end session"
else
  echo "Usage: $0 [on|off|minutes]"
fi
