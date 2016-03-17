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
	_version := "0.1.1"
	_debug := 0
	_filename := ""

	; ##################### Properties (AHK >1.1.16.x) #################################################################
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

	; ##################### public methods ##############################################################################
	/*!
		getChannelByName: (chName)
			Gets the Channel PK by name - if the given channel does not exist, create a new one.
		Parameters:
			chName - Name of the channel
	*/
	getChannelByName(chName) {
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(chName=" chName ")]" ; _DBG_

		SQL := "SELECT * FROM channel WHERE channel.name = """ chName """;"
		If !base.Query(SQL, RecordSet)
			this.__exceptionSQLite()
		
		if(!RecordSet.HasRows) {
			if (this._debug) ; _DBG_
			OutputDebug % "  [" A_ThisFunc "(chName=" chName ")]: Create new channel" ; _DBG_
			SQL := "INSERT INTO Channel (name) VALUES ('" chName "');"
			ret := base.Exec(SQL)
			If !ret
				this.__exceptionSQLite()
		}
		
		SQL := "SELECT * FROM channel WHERE channel.name = """ chName """;"
		If !base.Query(SQL, RecordSet)
			this.__exceptionSQLite()
		RecordSet.Next(Row)
		pk := Row[1]
			
		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(chName=" chName ")] -> pk=" pk ; _DBG_
		
		return pk
	}

	
	; ##################### private methods ##############################################################################
	__exceptionSQLite() {
		throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
	}
	
	/*!
		Constructor: (filename := A_ScriptDir . "/clipjump.db", overwriteExisting := 0)
			Creates the database object.
		Parameters:
			filename - (Optional) Name of the clipjump database to be created / opened.
			overwriteExisting - (Optional, Default: 0) Flag to Overwrite existig database 
				- else the existing datavase will be used.	
	*/
	__New(filename := "clipjump.db", overwriteExisting := 0,  debug := 0) {

		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(filename=" filename ", overwriteExisting =" overwriteExisting ")] (version: " this._version ")" ; _DBG_
			
		; Store given parameters within properties
		this._filename := filename
		this._debug := debug

		; Call base class constructor
		base.__New()

		
		; Remove existing database if flag is set
		if (overwriteExisting == 1) {
			If FileExist(filename) {
				FileDelete, % filename
			}
		}
		
		; Check whether the db file exists - if not it has to be created and initialized 
		shouldInitDB := 0
		If !FileExist(filename) {
			shouldInitDB := 1
		}
		else {
			file := FileOpen(filename,"r")
			if (File.Length == 0)
				shouldInitDB := 1
		}
		
		; Open existing or create new database
		If !base.OpenDB(filename) {
			this.__exceptionSQLite()
		}

		; Initialize the database if database file if the flag is set
		if (shouldInitDB == 1) {
			this.__InitDB()
		}

		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(filename=" filename ", overwriteExisting =" overwriteExisting ")] (version: " this._version ")" ; _DBG_
	}
	/*!
		Destructor: 
			Closes the database on object deconstruction
	*/
	__Delete() {
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "()]" ; _DBG_
		If !base.CloseDB() {
			this.__exceptionSQLite()
		}
		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "()]" ; _DBG_

	}
	/*!
		__InitDB: 
			Initializes the database by creating tables and fill in default values ....
	*/
	__InitDB() {
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "()]" ; _DBG_
		; ------------------------------------------------------------------------------------------------------------
		; Enable foreign key support: http://www.sqlite.org/foreignkeys.html#fk_enable
		SQL := "PRAGMA foreign_keys=ON;"
		If !base.Exec(SQL)
			this.__exceptionSQLite()

		; ------------------------------------------------------------------------------------------------------------
		; Table Clip
		SQL := "CREATE TABLE Clip ("
		 . "id INTEGER PRIMARY KEY AUTOINCREMENT,"
		 . "data TEXT        NOT NULL,"
		 . "sha256 TEXT UNIQUE NOT NULL"
		 . ");"
		If !base.Exec(SQL)
			this.__exceptionSQLite()

		; ------------------------------------------------------------------------------------------------------------
		; Table Channel
		SQL := "CREATE TABLE Channel ("
		 . "id   INTEGER PRIMARY KEY AUTOINCREMENT,"
		 . "name TEXT    UNIQUE      NOT NULL"
		 . ");"
		If !base.Exec(SQL)
			this.__exceptionSQLite()

		; ------------------------------------------------------------------------------------------------------------
		; Table Clip2Channel
		SQL := "CREATE TABLE Clip2Channel ("
		 . "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
		 . "  fk_clip REFERENCES clip(id),"
		 . "  fk_channel REFERENCES channel(id),"
		 . "  date INTEGER,"
		 . "  order_number, INTEGER"
		 . ");"
		If !base.Exec(SQL)
			this.__exceptionSQLite()

		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "()]" ; _DBG_
		}
}
