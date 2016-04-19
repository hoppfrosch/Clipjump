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
	_version := "0.3.0-#1.2" ; Versioning according SemVer http://semver.org/
	_debug := 0
	_filename := ""
	_chArchive := "Archive"
	idChArchive := ""
	idChDefault := ""	
	idChCurrent := ""

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
		adds a clip (by PK) to a channel (by PK): (pkCl, pkCh, bShouldUpdateExisting)
			A clip, given by PK, is added to a channel, given byPK
		Parameters:
			pkCl - Primary key of clip
			pkCh - Primary key of channel
			bShouldUpdateExisting - Flag to update the entry in table Clip2Channel, if the entry already exists
	*/
	addClipPKToChannelPK(pkCl, pkCh, bShouldUpdateExisting := 0) {
		bSuccess := 0
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(pkCl=" pkCl ", pkCh=" pkCh ", bShouldUpdateExisting=" bShouldUpdateExisting ")]" ; _DBG_

		; Check whether the clip already is member of the channel
		SQL := "SELECT * FROM clip2channel WHERE clip2channel.fk_clip = " pkCl " AND clip2channel.fk_channel = " pkCh ";"
		If !base.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
			
		if(!RecordSet.HasRows) {
		; Clip IS NOT member of the channel -> create a new entry in Table Clip2Channel
			SQL := "INSERT INTO clip2channel (fk_clip, fk_channel, date) VALUES(" pkCl "," pkCh ",""" A_Now*1000+A_Msec """);"
			If !base.Exec(SQL)
					throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
			bSuccess := 1
		} else {
		; Clip IS member of the channel -> update the existing entry in Table Clip2Channel or leave it untouched (dependent on options)
			RecordSet.Next(Row)
			pk := Row[1]
			if (bShouldUpdateExisting == 1) {
				SQL := "UPDATE clip2channel SET clip2channel.date = """ A_Now*1000+A_Msec """ WHERE clip2channel.id = """ pk """;"
				If !base.Exec(SQL)
					throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
				bSuccess := 1
			}
		}
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(pkCl=" pkCl ", pkCh= " pkCh ", bShouldUpdateExisting=" bShouldUpdateExisting ")] => " bSucess ; _DBG

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
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(clContent=" clContent ", pkCh=" pkCh ", bShouldUpdateExisting=" bShouldUpdateExisting ")]" ; _DBG_

		pkCl := this.clipByContent(clContent, 0) ; Create or search clip and don't add Clip to current channel 
		bSuccess := this.addClipPKToChannelPK(pkCl, pkCh, bShouldUpdateExisting) ; Add clip to given channel
		
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(clContent=" clContent ", pkCh= " pkCh ", bShouldUpdateExisting=" bShouldUpdateExisting ")] => " bSucess ; _DBG

		return bSuccess
	}
	
	/*!
		channelByName: (chName)
			Gets the Channel PK by name - if the given name does not exist, create a new channel with given name.
		Parameters:
			chName - Name of the channel
	*/
	channelByName(chName) {
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(chName=" chName ")]" ; _DBG_

		SQL := "SELECT * FROM channel WHERE channel.name = """ chName """;"
		If !base.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		
		if(!RecordSet.HasRows) {
			if (this._debug) ; _DBG_
			OutputDebug % "  [" A_ThisFunc "(chName=" chName ")]: Create new channel" ; _DBG_
			SQL := "INSERT INTO Channel (name) VALUES ('" chName "');"
			ret := base.Exec(SQL)
			If !ret
				throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		}
		
		SQL := "SELECT * FROM channel WHERE channel.name = """ chName """;"
		If !base.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		RecordSet.Next(Row)
		pk := Row[1]
			
		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(chName=" chName ")] -> pk=" pk ; _DBG_
		
		return pk
	}

	/*!
		clipByContent: (clContent, bAddToChCurrent)
			Gets a Clip from DB by clip-content - if no clip with the given content exists, a new clip is created in DB
			The new clip is added automatically to Archive-Channel and optionally to current Channel
		Parameters:
			clContent: content of the clip
			bAddToChCurrent: Flag to select whether clip is added to current channel
			
	*/
	clipByContent(clContent, bAddToChCurrent := 1) {
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(clContent=" clContent ")]" ; _DBG_

		; Determine Checksum from content
		checksum := SHA256(clContent)

		SQL := "SELECT * FROM clip WHERE clip.sha256 = """ checksum """;"
		If !base.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		
		if(!RecordSet.HasRows) {
			if (this._debug) ; _DBG_
			OutputDebug % "  [" A_ThisFunc "(clContent=" clContent ")]: Create new clip" ; _DBG_
			SQL := "INSERT INTO Clip (data, sha256) VALUES ('" clContent "','" checksum "');"
			ret := base.Exec(SQL)
			If !ret
				throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		}
		
		SQL := "SELECT * FROM clip WHERE clip.sha256 = """ checksum """;"
		If !base.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
		RecordSet.Next(Row)
		pk := Row[1]

		this.addClipPKToChannelPK(pk, this.idChArchive)
		if (bAddToChCurrent == 1)
			this.addClipPKToChannelPK(pk, this.idChCurrent)
		
		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(clContent=" clContent ")] -> pk=" pk ; _DBG_
		
		return pk
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
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
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
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }
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
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }

		; ------------------------------------------------------------------------------------------------------------
		; Table Clip
		SQL := "CREATE TABLE Clip ("
		 . "id INTEGER PRIMARY KEY AUTOINCREMENT,"
		 . "data TEXT        NOT NULL,"
		 . "sha256 TEXT UNIQUE NOT NULL"
		 . ");"
		If !base.Exec(SQL)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }

		; ------------------------------------------------------------------------------------------------------------
		; Table Channel
		SQL := "CREATE TABLE Channel ("
		 . "id   INTEGER PRIMARY KEY AUTOINCREMENT,"
		 . "name TEXT    UNIQUE      NOT NULL"
		 . ");"
		If !base.Exec(SQL)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }

		; ------------------------------------------------------------------------------------------------------------
		; Table Clip2Channel
		SQL := "CREATE TABLE Clip2Channel ("
		 . "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
		 . "  fk_clip REFERENCES clip(id),"
		 . "  fk_channel REFERENCES channel(id),"
		 . "  date INTEGER UNIQUE NOT NULL,"
		 . "  order_number INTEGER"
		 . ");"
		If !base.Exec(SQL)
			throw, { what: " ClipjumpDB SQLite Error", message:  base.ErrorMsg, extra: base.ErrorCode, file: A_LineFile, line: A_LineNumber }

		this.idChArchive := this.channelByName(this._chArchive)
		this.idChDefault := this.channelByName("Default")
		this.idChCurrent := this.idChDefault

		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "()]" ; _DBG_

	}	
}
