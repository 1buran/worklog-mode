Output worklog-mode-demo.gif

Set Shell "bash"
Set FontSize 16
Set Width 1020
Set Height 1050
Set Padding 10
Set Margin 0
Set TypingSpeed 35ms
Set Theme "Catppuccin Frappe"

Hide
Type "emacs -nw worklog.txt"
Enter
Sleep 6s
Ctrl+X
Type "1"
Sleep 500ms
Show

# @date via the C-c C-c menu
Ctrl+C
Ctrl+C
Sleep 600ms
Type "d"
Sleep 400ms

Enter
Enter

# @title via the menu
Ctrl+C
Ctrl+C
Sleep 600ms
Type "t"
Sleep 400ms
Type "Incident: nil pointer in inventory sync"
Enter
Enter

# @pt subtitle via the menu
Ctrl+C
Ctrl+C
Sleep 600ms
Type "p"
Sleep 400ms
Type "Root cause"
Enter
Enter

# paragraph
Type "The sync worker panics when the Mongo cursor returns nil. The same missing nil-check is in all three services:"
Enter
Enter

# Go block
Type "If look at the 356 line of main.go:"
Enter
Enter
Type "    cursor, err := coll.Find(ctx, filter)"
Enter
Type "    if err != nil {"
Enter
Type `        return fmt.Errorf("find: %w", err)`
Enter
Type "    }"
Enter
Enter

# Python block
Type "and the same thing in migrate.py:"
Enter
Enter
Type "    rows = cursor.fetchall()"
Enter
Type "    for row in rows:"
Enter
Type "        process(row)"
Enter
Enter

# PHP block
Type "and, again, the same in cron.php:"
Enter
Enter
Type "    $bulk = new \MongoDB\Driver\BulkWrite();"
Enter
Type "    $mongo->executeBulkWrite($bulk);"
Enter
Enter

# conclusions list
Type "Conclusions:"
Enter
Type "- The nil check is missing in all three services"
Ctrl+J
Type "- A shared helper would prevent this class of bug"
Ctrl+J
Ctrl+J

# proposals list
Type "Proposals:"
Enter
Type "1. Add tests for all parts of systems, think about integration tests"
Enter
Type "fix by check nil pointer before use it, also check the same bug in all projects, create appropriate tickets for all three departments and assign them to tech leads, ask Mick to review the code and coordinate all teammates"
Ctrl+J
Ctrl+J

# analysis steps (checkmarks via C-c d)
Type "Analysis steps:"
Enter
Type "1. check error logs, found a lot of errors, need to adjust monitoring alerts (currently that errors silent for monitoring)"
Enter
Type "reproduce the panic locally, in docker environment"
Enter
Type "run code analysis tools"
Ctrl+C
Type "d"
Sleep 400ms
Up 2
Ctrl+C
Type "d"
Sleep 400ms
Up 3
Ctrl+C
Type "d"
Sleep 400ms
Down 6
Ctrl+J
Ctrl+J

# @next via the menu
Ctrl+C
Ctrl+C
Sleep 600ms
Type "n"
Sleep 400ms
Type "create ticket and assign it to maintainers, follow-up Mick"

Sleep 2s
