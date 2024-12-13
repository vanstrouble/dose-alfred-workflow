on run argv
    tell application "Amphetamine"
        if (item 1 of argv is "on") then
                start new session
        else if (item 1 of argv is "off") then
                end session
        end if
    end tell
end run
