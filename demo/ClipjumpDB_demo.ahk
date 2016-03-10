#NoEnv
; #Warn
;#SingleInstance force
;SetWorkingDir, %A_ScriptDir%
;SetBatchLines, -1

#Include %A_ScriptDir%\..\lib\ClipjumpDB.ahk

DB := new ClipjumpDB(A_ScriptDir . "\clipjump.db")

Version := DB.Ver . " (SQLite: " . DB.Ver_sqlite . ")"
MsgBox % "Version:" . Version . "`nFilename:" . DB.filename

