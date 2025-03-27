#!/bin/zsh

# Receive the input
inputString="$1"
inputHour=0
inputMinutes=0
ampm=""
currentHour=$(date +"%H")
currentMinutes=$(date +"%M")

# Split the input string by spaces
parts=("${(@s/ /)inputString}")
partsCount=${#parts[@]}

# Process the input
if (( partsCount == 1 )); then
    inputHour=${parts[1]}
    inputMinutes=0
elif (( partsCount == 2 )); then
    inputHour=${parts[1]}
    inputMinutes=${parts[2]}
elif (( partsCount == 3 )); then
    inputHour=${parts[1]}
    inputMinutes=${parts[2]}
    ampm=${parts[3]}
else
    echo "Error: Incorrect format. Use: amh [hour] [optional minutes] [optional am/pm]"
    exit 1
fi

# Determine am/pm if not provided
if [[ -z "$ampm" ]]; then
    if (( inputHour == 12 )); then
        if (( currentHour < 12 )); then
            ampm="pm"
        else
            ampm="am"
        fi
    else
        if (( inputHour < (currentHour % 12) )); then
            if (( currentHour < 12 )); then
                ampm="pm"
            else
                ampm="am"
            fi
        else
            if (( currentHour < 12 )); then
                ampm="am"
            else
                ampm="pm"
            fi
        fi
    fi
fi

# Adjust the hours according to am/pm
if [[ "$ampm" == "pm" && inputHour -ne 12 ]]; then
    inputHour=$(( inputHour + 12 ))
elif [[ "$ampm" == "am" && inputHour -eq 12 ]]; then
    inputHour=0
fi

# Calculate the difference in minutes between the current time and the input time
currentTotalMinutes=$(( currentHour * 60 + currentMinutes ))
targetTotalMinutes=$(( inputHour * 60 + inputMinutes ))
durationMinutes=$(( targetTotalMinutes - currentTotalMinutes ))

# If the duration is negative (the input time has already passed today), add 24 hours in minutes
if (( durationMinutes < 0 )); then
    durationMinutes=$(( durationMinutes + 24 * 60 ))
fi

# Start a new session in Amphetamine with the calculated duration
osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$durationMinutes, interval:minutes, displaySleepAllowed:true}"

echo "Amphetamine activated for $durationMinutes minutes."
