#!/bin/zsh --no-rcs

calculate_end_time() {
    local minutes=$1
    date -v+"$minutes"M +"%H:%M"
}

INPUT=("${(@s/ /)1}")  # Split the input into parts

if [[ "${#INPUT[@]}" -eq 1 && "${INPUT[1]}" =~ ^[0-9]+$ ]]; then
    # Format: ams 30 (only minutes)
    TOTAL_MINUTES=${INPUT[1]}
elif [[ "${#INPUT[@]}" -eq 2 && "${INPUT[1]}" =~ ^[0-9]+$ && "${INPUT[2]}" =~ ^[0-9]+$ ]]; then
    # Format: ams 1 20 (hours and minutes)
    TOTAL_MINUTES=$(( INPUT[1] * 60 + INPUT[2] ))
else
    exit 0  # Do not generate output if the format is incorrect
fi

END_TIME=$(calculate_end_time "$TOTAL_MINUTES")

echo '{"items":[{"title":"Active for '"$TOTAL_MINUTES"' minutes","subtitle":"Keep awake until around '"$END_TIME"'","arg":"'"$TOTAL_MINUTES"'","icon":{"path":"icon.png"}}]}'
