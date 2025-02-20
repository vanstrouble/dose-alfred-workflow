on run argv
    set inputString to argv as string

    set AppleScript's text item delimiters to " "
    set parts to every text item of inputString
    set AppleScript's text item delimiters to ""

    set currentTime to (current date)
    set currentHour to hours of currentTime
    set currentMinutes to minutes of currentTime

    set inputHour to 0
    set inputMinutes to 0
    set ampm to ""

    set partsCount to count of parts

    if partsCount = 1 then
        set inputHour to item 1 of parts as integer
        set inputMinutes to 0
    else if partsCount = 2 then
        set inputHour to item 1 of parts as integer
        set inputMinutes to item 2 of parts as integer
    else if partsCount = 3 then
        set inputHour to item 1 of parts as integer
        set inputMinutes to item 2 of parts as integer
        set ampm to item 3 of parts as string
    else
        log "Error: Incorrect format. Use: amh [hour] [optional minutes] [optional am/pm]"
        return
    end if

    if ampm = "" then
        if inputHour = 12 then
            if currentHour < 12 then
                set ampm to "pm"
            else
                set ampm to "am"
            end if
        else
            if inputHour < (currentHour mod 12) then
                if currentHour < 12 then
                    set ampm to "pm"
                else
                    set ampm to "am"
                end if
            else
                if currentHour < 12 then
                    set ampm to "am"
                else
                    set ampm to "pm"
                end if
            end if
        end if
    end if

    if inputHour = currentHour then
        if ampm is "am" then
            set ampm to "pm"
        else
            set ampm to "am"
        end if
    end if

    if ampm is "pm" and inputHour is not 12 then
        set inputHour to inputHour + 12
    else if ampm is "am" and inputHour is 12 then
        set inputHour to 0
    end if

    set currentTotalMinutes to (currentHour * 60) + currentMinutes
    set targetTotalMinutes to (inputHour * 60) + inputMinutes

    set durationMinutes to targetTotalMinutes - currentTotalMinutes
    if durationMinutes < 0 then
        set durationMinutes to durationMinutes + (24 * 60)
    end if

    tell application "Amphetamine" to start new session with options {duration:durationMinutes, interval:minutes, displaySleepAllowed:true}
end run
