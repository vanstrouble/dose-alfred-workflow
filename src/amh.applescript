on run argv
    set q to item 1 of argv
    set qMinutes to q * 60
    tell application "Amphetamine"
        start new session with options {duration:qMinutes, interval:minutes, displaySleepAllowed:false}
    end tell
end run
