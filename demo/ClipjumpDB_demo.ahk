;#NoEnv
; #Warn
;#SingleInstance force
;SetWorkingDir, %A_ScriptDir%
;SetBatchLines, -1

#Include %A_ScriptDir%\..\lib\ClipjumpDB.ahk
#Include %A_ScriptDir%\..\lib\ClipjumpClip.ahk
#Include %A_ScriptDir%\..\lib\ClipjumpChannel.ahk

try  ; Attempts to execute code.
{
	DB := new ClipjumpDB(A_ScriptDir . "\clipjump.db",1,0)

	Version := DB.Ver . " - SQLite: " . DB.Ver_sqlite . " - Implementation: " DB.Ver_class
	OutputDebug % "Version:" . Version . "`nFilename:" . DB.filename

	DB.debug := 1

	Channel0 := new ClipjumpChannel("test0", 1)
	Channel0.DBFindOrCreate(DB)
	;Channel1 := new ClipjumpChannel("test1", 1)
	;Channel1.DBFindOrCreate(DB)	
	
	Clip := new ClipjumpClip("Hallo",,1)
	pk := Clip.DBAddToChannel(DB,"Archive")
	pk2 := Clip.DBAddToChannel(DB,"Default")
	pk := Clip.DBAddToChannel(DB,"test0")
	; Re-add same clip to same channel - with update of date
	;pk := Clip.DBAddToChannel(DB,"test0",,,1)
}
catch e  ; Handles the first error/exception raised by the block above.
{
	contents := "what: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    MsgBox, 16, % "Exception!", % contents 
    Exit
}


