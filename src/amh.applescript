on run argv
    set totalMinutes to ((item 1 of argv) * 100 div 100 * 60) + ((item 1 of argv) * 100 mod 100) as integer

    tell application "Amphetamine"
        start new session with options {duration:totalMinutes, interval:minutes, displaySleepAllowed:false}
    end tell
end run
