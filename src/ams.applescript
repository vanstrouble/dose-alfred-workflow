on run argv
    set q to item 1 of argv
    tell application "Amphetamine"
        start new session with options {duration:q, interval:minutes, displaySleepAllowed:false}
    end tell
end run
