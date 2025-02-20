on run argv
    set inputString to argv as string

    set AppleScript's text item delimiters to " "
    set parts to every text item of inputString

    set inputHour to item 1 of parts as integer
    set inputMinutes to item 2 of parts as integer

    set AppleScript's text item delimiters to ""

    set durationMinutes to (inputHour * 60) + inputMinutes

    tell application "Amphetamine"
        start new session with options {duration:durationMinutes, interval:minutes, displaySleepAllowed:false}
    end tell
end run
