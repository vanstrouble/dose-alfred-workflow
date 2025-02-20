on run argv
    set inputString to argv as string

    set AppleScript's text item delimiters to " "
    set parts to every text item of inputString
    set AppleScript's text item delimiters to ""

    set inputHour to 0
    set inputMinutes to 0

    set partsCount to count of parts

    try
        if partsCount = 1 then
            set firstValue to item 1 of parts
            if firstValue contains "." then
                set inputHour to firstValue as real
                set durationMinutes to round (inputHour * 60)
            else
                set inputHour to firstValue as integer
                set durationMinutes to (inputHour * 60)
            end if
        else if partsCount = 2 then
            set inputHour to item 1 of parts as integer
            set inputMinutes to item 2 of parts as integer
            set durationMinutes to (inputHour * 60) + inputMinutes
        else
            log "Incorrect format. Use: amh [hours] [optional minutes] or amh [decimal hours]"
            return
        end if

        if durationMinutes > 0 then
            tell application "Amphetamine"
                start new session with options {duration:durationMinutes, interval:minutes, displaySleepAllowed:false}
            end tell
        else
            log "Error: Duration must be greater than 0 minutes."
        end if

    on error
        log "Error processing the time. Make sure to enter a valid number."
    end try
end run
