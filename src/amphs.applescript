on run argv
    set inputHour to item 1 of argv as integer
    set inputMinutes to item 2 of argv as integer
    -- set totalMinutes to (inputHour * 60) + inputMinutes as integer

    set currentTime to (current date)
    set currentHour to hours of currentTime as integer
    set currentMinutes to minutes of currentTime as integer

    set currectTotalMinutes to (currentHour * 60) + currentMinutes as integer
    set targetTotalMinutes to (inputHour * 60) + inputMinutes as integer

    set durationMinutes to targetTotalMinutes - currectTotalMinutes

    -- Concatenar la hora y los minutos en una sola cadena
    set timeString to "Duration Minutes: " & durationMinutes

    -- Mostrar el diálogo con la hora y los minutos
    display dialog timeString buttons {"Ok"}
end run
