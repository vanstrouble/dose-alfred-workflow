on run argv
  tell application "Amphetamine"
    if (item 1 of argv = "on") then
        start new session
        -- display dialog "Your Mac will be active all the time."
    else if (item 1 of argv = "off") then
        end session
        -- display dialog "Your Mac will sleep then."
    end if
  end tell
end run
