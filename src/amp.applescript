tell application "Amphetamine"
    if (q = "on") then
        start new session
        "Your Mac will be active all the time."
    else if (q = "off") then
        end session
        "Your Mac will sleep then."
    end if
end tell
