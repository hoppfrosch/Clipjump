/*
	Title: ClipjumpDB
		
	Store Clipjump Clips and other data within SQLite Database
		
	Authors:
	<hoppfrosch at hoppfrosch@gmx.de>: Original

	About: License
	This program is free software. It comes without any warranty, to the extent permitted by applicable law. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See <WTFPL at http://www.wtfpl.net/> for more details.

*/
#include %A_LineFile%\..\SQLiteDB
#include Class_SQLiteDB.ahk

class ClipjumpDB extends SQLiteDB {
; ******************************************************************************************************************************************
/*
	Class: ClipjumpDB
		Store Clipjump Clips and other data within SQLite Database

	Authors:
	<hoppfrosch at hoppfrosch@gmx.de>: Original
*/	
	_version := "0.1.0"
	_debug := 0
	_filename := ""

	; ##################### Properties (AHK >1.1.16.x) #################################################################0
	debug[] {
	/* ------------------------------------------------------------------------------- 
	Property: debug [get/set]
	Debug flag for debugging the object

	Value:
	flag - *true* or *false*
	*/
		get {
			return this._debug
		}
		set {
			mode := value<1?0:1
			this._debug := mode
			return this._debug
		}
	}
	filename[] {
	/* ------------------------------------------------------------------------------- 
	Property: filename [get]
	Filename of the database file
	
	Value:
	fn - filename of database file
	*/
		get {
			return this._filename
		}
	}
	ver[] {
	/* ------------------------------------------------------------------------------- 
	Property: ver [get]
	Get the version of the class implementation
	*/
		get {
			return this._version
		}
	}
	ver_sqlite[] {
	/* ------------------------------------------------------------------------------- 
	Property: ver_sqlite [get]
	Get the version of the sqlite darabase module
	*/
		get {
			return this.base.Version
		}
	}

	/*!
		Constructor: (filename := A_ScriptDir . "/clipjump.db", overwriteExisting := 0)
			Creates the database object.
		Parameters:
			filename - (Optional) Name of the clipjump database to be created / opened.
			overwriteExisting - (Optional, Default: 0) Flag to Overwrite existig database 
				- else the existing datavase will be used.	
	*/
	__New(filename := "clipjump.db", overwriteExisting := 0) {
		base.__New()

		; Remove existing database if flag is set
		if (overwriteExisting == 1) {
			If FileExist(filename) {
				FileDelete, % DBFileName
			}
		}
		; Store given filename in property
		this._filename := filename

		If !base.OpenDB(filename) {
			throw, { what: " SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		}

		return
	}

	/*!
		Destructor: 
			Closes the database on object deconstruction
	*/
	__Delete() {
		If !base.CloseDB() {
			throw, { what: " SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		}
	}
}