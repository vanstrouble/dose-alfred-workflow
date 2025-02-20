on run argv
    set inputString to argv as string

    set AppleScript's text item delimiters to " "
    set parts to every text item of inputString

    set inputHour to item 1 of parts as integer
    set inputMinutes to item 2 of parts as integer
    set ampm to item 3 of parts as string

    set AppleScript's text item delimiters to ""

    if ampm is "pm" and inputHour is not 12 then
        set inputHour to inputHour + 12
    else if ampm is "am" and inputHour is 12 then
        set inputHour to 0
    end if

    set currentTime to (current date)
    set currentHour to hours of currentTime as integer
    set currentMinutes to minutes of currentTime as integer

    set currectTotalMinutes to (currentHour * 60) + currentMinutes as integer
    set targetTotalMinutes to (inputHour * 60) + inputMinutes as integer

    set durationMinutes to (targetTotalMinutes - currectTotalMinutes) as integer

    if durationMinutes < 0 then
        set durationMinutes to durationMinutes + (24 * 60) as integer
    end if

    if durationMinutes > 0 then
        tell application "Amphetamine" to start new session with options {duration:durationMinutes, interval:minutes, displaySleepAllowed:true}
    else
        log "Error: The entered time has already passed."
    end if
end run
