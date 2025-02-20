on run argv
    set inputHour to item 1 of argv as integer
    set inputMinutes to item 2 of argv as integer

    set durationMinutes to (inputHour * 60) + inputMinutes

    tell application "Amphetamine"
        start new session with options {duration:durationMinutes, interval:minutes, displaySleepAllowed:false}
    end tell
end run
