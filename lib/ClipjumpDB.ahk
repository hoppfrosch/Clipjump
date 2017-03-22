/*
	Title: ClipjumpDB
		
	Store Clipjump Clips and other data within SQLite Database
		
	Authors:
	<hoppfrosch at hoppfrosch@gmx.de>: Original

	About: License
	This program is free software. It comes without any warranty, to the extent permitted by applicable law. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See <WTFPL at http://www.wtfpl.net/> for more details.

*/

#include %A_LineFile%\..
#include SHA-256.ahk
#include ClipjumpClip.ahk
#include ClipjumpChannel.ahk
#include DbgOut.ahk
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
    ; Versioning according SemVer http://semver.org/
	_version := "0.5.0-#10.1" ; Version of class implementation
	; Simple incrementing version
	_version_db := 1 ; version of the database scheme
	_debug := 0
	_filename := ""
	_chArchive := "Archive"
	idChArchive := ""
	_chDefault := "Default"
	idChDefault := ""
	_chCurrent := _chDefault	
	idChCurrent := ""

	class Helper {
	; ******************************************************************************************************************************************
	/*
		Class: ClipjumpDB.Helper
		Class providing helper functions for class ClipjumpDB

		Authors:
		<hoppfrosch at hoppfrosch@gmx.de>: Original
	*/
		/*!
			escapeQuotesSql: 
				replace quote (") in data content with double quote ("") - works like escaping
			Parameters:
				s - String to escape
			Return:  
				escaped string
		*/
		escapeQuotesSql(s){
			StringReplace, s, s, % """", % """""", All
			return s
		}
		/*!
			timestamp: 
				Converts AHK timestamp YYYYMMDDHHMMSSmmm to more human readable timestamp YYYY-MM-DD HH:MM:SS.mmm
			Parameters:
				t - AHK-timestamp (format YYYYMMDDHHMMSSmmm). If t == "", A_Now*1000+A_MSec will be assumed as default
			Return:  
				timestamp in format YYYY-MM-DD HH:MM:SS.mmm
		*/
		timestamp(t:=""){
			if (t == "") 
				t:= A_Now*1000+A_MSec
			S:= SubStr(t, 1, 4) "-" SubStr(t,5,2) "-" SubStr(t,7,2) " " SubStr(t, 9, 2) ":" SubStr(t,11,2) ":" SubStr(t,13,2) "." SubStr(t,15,3)

			return S
		}
	}

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
	Property: ver [get/set]
	Version of the database
	*/
		get {
			SQL := "PRAGMA user_version;"
			If !base.GetTable(SQL, TB)
				throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
			ver := TB.Rows[1][1]
			return ver
		}
		set {
			SQL := "PRAGMA user_version=""" value """;"
			If !base.Exec(SQL)
				throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
			return value
		}
	}
	ver_class[] {
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
		adds a clip (by PK) to a channel (by PK): (pkCl, pkCh, bShouldUpdateExisting)
			A clip, given by PK, is added to a channel, given byPK
		Parameters:
			pkCl - Primary key of clip
			pkCh - Primary key of channel
			bShouldUpdateExisting - Flag to update the entry in table Clip2Channel, if the entry already exists
	*/
	addClipPKToChannelPK(pkCl, pkCh, bShouldUpdateExisting := 0) {
		bSuccess := 0
		dbgOut(">[" A_ThisFunc "(pkCl=" pkCl ", pkCh=" pkCh ", bShouldUpdateExisting=" bShouldUpdateExisting ")]", this.debug)
		; Check whether the clip already is member of the channel
		SQL := "SELECT * FROM clip2channel WHERE clip2channel.fk_clip = " pkCl " AND clip2channel.fk_channel = " pkCh ";"
		If !base.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
			
		if(!RecordSet.HasRows) {
		; Clip IS NOT member of the channel -> create a new entry in Table Clip2Channel
			SQL := "INSERT INTO clip2channel (fk_clip, fk_channel, time) VALUES(" pkCl "," pkCh ",""" this.helper.timestamp() """);"
			If !base.Exec(SQL)
					throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
			bSuccess := 1
		} else {
		; Clip IS member of the channel -> update the existing entry in Table Clip2Channel or leave it untouched (dependent on options)
			RecordSet.Next(Row)
			pk := Row[1]
			if (bShouldUpdateExisting == 1) {
				SQL := "UPDATE clip2channel SET clip2channel.time = """ this.helper.timestamp() """ WHERE clip2channel.id = """ pk """;"
				If !base.Exec(SQL)
					throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
				bSuccess := 1
			}
		}
		dbgOut(">[" A_ThisFunc "(pkCl=" pkCl ", pkCh= " pkCh ", bShouldUpdateExisting=" bShouldUpdateExisting ")] => " bSucess, this.debug)

		return bSuccess
	}
	/*!
		adds a clip to a channel (by PK): (pkCl, pkCh, bShouldUpdateExisting)
			A clip is added to a channel, given byPK
		Parameters:
			clContent - Content of the clip
			pkCh - Primary key of channel
			bShouldUpdateExisting - Flag to update the entry in table Clip2Channel, if the entry already exists
	*/
	addClipToChannelPK(clContent, pkCh, bShouldUpdateExisting := 0) {
		bSuccess := 0
		dbgOut(">[" A_ThisFunc "(clContent=" clContent ", pkCh=" pkCh ", bShouldUpdateExisting=" bShouldUpdateExisting ")]", this.debug)

		Clip = new ClipjumpClip(clContent)
		pkCl := Clip.DBFindOrCreate(this)
		bSuccess := this.addClipPKToChannelPK(pkCl, pkCh, bShouldUpdateExisting) ; Add clip to given channel
		
		dbgOut(">[" A_ThisFunc "(clContent=" clContent ", pkCh= " pkCh ", bShouldUpdateExisting=" bShouldUpdateExisting ")] => " bSucess, this.debug)
		return bSuccess
	}

	; ##################### private methods ##############################################################################
	/*!
		Constructor: (filename := A_ScriptDir . "/clipjump.db", overwriteExisting := 0)
			Creates the database object.
		Parameters:
			filename - (Optional) Name of the clipjump database to be created / opened.
			overwriteExisting - (Optional, Default: 0) Flag to Overwrite existig database 
				- else the existing datavase will be used.	
	*/
	__New(filename := "clipjump.db", overwriteExisting := 0,  debug := 0) {
		this._debug := debug
		
		dbgOut(">[" A_ThisFunc "(filename=" filename ", overwriteExisting =" overwriteExisting ")] (version: " this._version ")", this.debug)
			
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
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		}

		; Initialize the database if database file if the flag is set
		if (shouldInitDB == 1) {
			this.__InitDB()
		}

		; Migrate DB to newer version if needed 
		this.__migrateDB()
		dbgOut("<[" A_ThisFunc "(filename=" filename ", overwriteExisting =" overwriteExisting ")] (version: " this._version ")", this.debug)
	}
	/*!
		Destructor: 
			Closes the database on object deconstruction
	*/
	__Delete() {
		dbgOut(">[" A_ThisFunc "()] (version: " this._version ")", this.debug)
		If !base.CloseDB() {
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		}
		dbgOut("<[" A_ThisFunc "()] (version: " this._version ")", this.debug)

	}
	/*!
		__InitDB: 
			Initializes the database by creating tables and fill in default values ....
	*/
	__InitDB() {
		dbgOut(">[" A_ThisFunc "()]", this.debug)

		SQL := "PRAGMA user_version=""" this._version_db """;"
		dbgOut("|[" A_ThisFunc "()] SQL: " SQL, this.debug)
		If !base.Exec(SQL)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
					
		; ------------------------------------------------------------------------------------------------------------
		; Enable foreign key support: http://www.sqlite.org/foreignkeys.html#fk_enable
		SQL := "PRAGMA foreign_keys=ON;"
		dbgOut("|[" A_ThisFunc "()] SQL: " SQL, this.debug)
		If !base.Exec(SQL)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }

		; ------------------------------------------------------------------------------------------------------------
		; Table Clip
		SQL := "CREATE TABLE Clip ("
		 . "id INTEGER PRIMARY KEY AUTOINCREMENT,"
		 . "sha256 TEXT UNIQUE NOT NULL,"
		 . "data TEXT NOT NULL,"
		 . "type INTEGER DEFAULT 0,"
		 . "fileid TEXT,"
		 . "size INTEGER"
		 . ");"
		dbgOut("|[" A_ThisFunc "()] SQL: " SQL, this.debug)
		If !base.Exec(SQL)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }

		; ------------------------------------------------------------------------------------------------------------
		; Table Channel
		SQL := "CREATE TABLE Channel ("
		 . "id   INTEGER PRIMARY KEY AUTOINCREMENT,"
		 . "name TEXT    UNIQUE      NOT NULL"
		 . ");"
		dbgOut("|[" A_ThisFunc "()] SQL: " SQL, this.debug)
		If !base.Exec(SQL)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }

		; ------------------------------------------------------------------------------------------------------------
		; Table Clip2Channel
		SQL := "CREATE TABLE Clip2Channel ("
		 . "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
		 . "  fk_clip REFERENCES clip(id),"
		 . "  fk_channel REFERENCES channel(id),"
		 . "  time TEXT NOT NULL,"
		 . "  order_number INTEGER"
		 . ");"
		dbgOut("|[" A_ThisFunc "()] SQL: " SQL, this.debug)
		If !base.Exec(SQL)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }

		chArchive := new ClipjumpChannel(this._chArchive, this.debug)
		this.idChArchive := chArchive.DBFindOrCreate(this)
		chDefault := new ClipjumpChannel(this._chDefault, this.debug)
		this.idChDefault := chDefault.DBFindOrCreate(this)
		this.idChCurrent := this.idChDefault
		
		dbgOut("<[" A_ThisFunc "()]", this.debug)
	}	
	/*!
		___migrateDB: 
			Automatically migrate the Clipjump DB to the recent version
	*/
	__migrateDB() {
		dbgOut(">[" A_ThisFunc "()]", this.debug)
			
		if (this._version_db > this.ver) { ; DB version supported with this implementation is NEWER than the given Database -> Migration
			; Migration is performed incrementally 0 -> 1 -> 2 -> 3 ....
			if (this.ver == 0)
				this.__migrate_0() ; Migrate to dbversion 1

			;if (this.ver == 1)
			;	this.__migrate_1() ; Migrate to dbversion 2
							
		} else if (this._version_db < this.ver) {
			throw, { what: " ClipjumpDB Error", message: "Database cannot be downgraded" , extra: "-1", file: A_LineFile, line: A_LineNumber }
		}

		dbgOut("<[" A_ThisFunc "()]", this.debug)
	}
	/*!
		__migrate_0: 
			Migrate database from Clipjump 12.7 DB to user_version 1
	*/
	__migrate_0() {
		Local Row
		dbgOut(">[" A_ThisFunc "()]", this.debug)
		; Move old database to backup and open backup to different handle
		base.CloseDB()
		bakDB := this.filename ".v0"
		currDB := this.filename
		FileMove, % currDB, % bakDB, 1
		OldDB := new SQLiteDB
		OldDB.OpenDB(bakDB)

		; Create a new database with the current scheme
		base.OpenDB(currDB)
		this.__InitDB()
		
		; Get all data from old database
		SQL:= "SELECT * from history"
		If !OldDB.GetTable(SQL, Result)
			throw, { what: " ClipjumpDB SQLite Error", message:  OldDB.ErrorMsg, extra: OldDB.ErrorCode, file: A_LineFile, line: A_LineNumber }

		; Associative Array to simply get the column index by column name
		columnNameToIndex := Object()
		Loop, % Result.ColumnCount
			columnNameToIndex[Result.ColumnNames[A_Index]] := A_Index

		; ToDo implement the migration from DB from clipjump 12.7 (user_version == 0) to user_version 1 ...
		Loop % Result.RowCount  {
			currIdRow := A_Index
		 	content := this.helper.escapeQuotesSql(result.rows[currIdRow][columnNameToIndex["data"]])
		 	type := result.rows[currIdRow][columnNameToIndex["type"]]
		 	ts := result.rows[currIdRow][columnNameToIndex["time"]] ".000"
		 	Clip := new ClipjumpClip(content, type, this.debug)
		 	pk := Clip.DBAddToChannel(this,this._chArchive, ts,,2) ; trailing "2" indicates that multiple clips per channel are allowed
		}
		dbgOut("<[" A_ThisFunc "()]", this.debug)
	}
}
