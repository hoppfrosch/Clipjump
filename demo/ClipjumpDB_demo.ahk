#NoEnv
; #Warn
;#SingleInstance force
;SetWorkingDir, %A_ScriptDir%
;SetBatchLines, -1

#Include %A_ScriptDir%\..\lib\ClipjumpDB.ahk

try  ; Attempts to execute code.
{
	DB := new ClipjumpDB(A_ScriptDir . "\clipjump.db",0,1)

	Version := DB.Ver . " (SQLite: " . DB.Ver_sqlite . ")"
	OutputDebug % "Version:" . Version . "`nFilename:" . DB.filename


	x := DB.channelByName("test1")
	x := DB.channelByName("test2")
	x := DB.channelByName("test3")
}
catch e  ; Handles the first error/exception raised by the block above.
{
    MsgBox, An exception was thrown!`nSpecifically: %e%
    Exit
}


