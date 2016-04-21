#NoEnv
; #Warn
;#SingleInstance force
;SetWorkingDir, %A_ScriptDir%
;SetBatchLines, -1

#Include %A_ScriptDir%\..\lib\ClipjumpDB.ahk

try  ; Attempts to execute code.
{
	DB := new ClipjumpDB(A_ScriptDir . "\clipjump.db",1,1)

	Version := DB.Ver . " - SQLite: " . DB.Ver_sqlite . " - Implementation: " DB.Ver_class
	OutputDebug % "Version:" . Version . "`nFilename:" . DB.filename


	x1 := DB.channelByName("test1")
	x2 := DB.channelByName("test2")
	x3 := DB.channelByName("test3")

	y1a := DB.clipByContent("Eins")
	y2a := DB.clipByContent("Zwei")
	y1b := DB.clipByContent("Eins")

	bSuccess := DB.addClipToChannelPK("test4", x3)
	OutputDebug % y1a " - " y2a " - " y1b
	
}
catch e  ; Handles the first error/exception raised by the block above.
{
	contents := "what: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    MsgBox, 16, % "Exception!", % contents 
    Exit
}


