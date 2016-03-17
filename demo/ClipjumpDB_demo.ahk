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

	y1a := DB.clipByContent("Eins")
	y2a := DB.clipByContent("Zwei")
	y1b := DB.clipByContent("Eins")
	OutputDebug % y1a " - " y2a " - " y1b
	
}
catch e  ; Handles the first error/exception raised by the block above.
{
    MsgBox, 16, % "Exception thrown!`n`nwhat: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    Exit
}


