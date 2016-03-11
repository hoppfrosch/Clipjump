#NoEnv
; #Warn
;#SingleInstance force
;SetWorkingDir, %A_ScriptDir%
;SetBatchLines, -1

#Include %A_ScriptDir%\..\lib\ClipjumpDB.ahk

DB := new ClipjumpDB(A_ScriptDir . "\clipjump.db",0,1)

Version := DB.Ver . " (SQLite: " . DB.Ver_sqlite . ")"
OutputDebug % "Version:" . Version . "`nFilename:" . DB.filename

try  ; Attempts to execute code.
{
    x := DB.getChannelByName("test1")
	x := DB.getChannelByName("test2")
    x := DB.getChannelByName("test3")
}
catch e  ; Handles the first error/exception raised by the block above.
{
    MsgBox, An exception was thrown!`nSpecifically: %e%
    Exit
}


