/*
	Title: ClipjumpClip
		
	Helper class to hold data for a single clip
	Authors:
	<hoppfrosch at hoppfrosch@gmx.de>: Original

	About: License
	This program is free software. It comes without any warranty, to the extent permitted by applicable law. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See <WTFPL at http://www.wtfpl.net/> for more details.

*/

#include %A_LineFile%\..
#include SHA-256.ahk
#include DbgOut.ahk


class ClipjumpClip {
; ******************************************************************************************************************************************
/*
	Class: ClipjumpClip
		Helper class to hold data for a single clip

	Authors:
	<hoppfrosch at hoppfrosch@gmx.de>: Original
*/	
    ; Versioning according SemVer http://semver.org/
	_version := "0.1.4-#10.1" ; Version of class implementation
	_debug := 0
	_content := ""
	_type := 0
	_checksum := 0
	_fileId := ""

	; ##################### Properties (AHK >1.1.16.x) #################################################################
	checksum[] {
	/* ------------------------------------------------------------------------------- 
	Property: ver [get]
	Get the checksum (SHA256) of the clip contents
	*/
		get {
			return this._checksum
		}
	}
	chksum[] {
	/* ------------------------------------------------------------------------------- 
	Property: chksum [get]
	Get the short checksum (SHA256) of the clip contents
	*/
		get {
			S:= SubStr(this._checksum, 1, 8)
			return S
		}
	}
	content[] {
	/* ------------------------------------------------------------------------------- 
	Property: content [get/set]
	Contents of the clip

	Value:
	content - content of the clip
	*/
		get {
			return this._content
		}
		set {
			this._content := value
			this.checksum := SHA256(this._content)
			return this._content
		}
	}
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
	fileid[] {
	/* ------------------------------------------------------------------------------- 
	Property: fileid [get/set]
	fileid of the clip

	Value:
	fileid
	*/
		get {
			return this._fileid
		}
		set {
			this._fileid := fileid
			return this._fileid
		}
	}
	type[] {
	/* ------------------------------------------------------------------------------- 
	Property: type [get/set]
	Type of the clip (0 = TEXT, 1 = IMAGE)

	Value:
	type
	*/
		get {
			return this._type
		}
		set {
			this._type := type
			return this._type
		}
	}
	ver[] {
	/* ------------------------------------------------------------------------------- 
	Property: ver [get]
	Get the version of the class implementation
	*/
		get {
			return this._version_class
		}
	}

	; ##################### public methods ##############################################################################
	/*!
		DBAddToChannel
			Adds the Clip to a Channel
		Parameters:
			database - SQLite database (Class_SqLiteDB)
			channel - name of the Channel (DEFAULT: "Default")
			ts - timestamp when clip was added (if left empty the current time is used - DEFAULT)
			order_number - order_number
			insertMode - if same clip is added to same channel either leave db entry as is (=0), update the existing entry (=1) or create identical entry (=2) 
		Return:  
			pk - primary key of created database row
	*/
	DBAddToChannel(database, chInsert := "Default", ts := "", order_number := -1, insertMode := 0){
		bSuccess := 0
		dbgOut(">[" A_ThisFunc "(sha256='" this.chksum "', channel='" chInsert "', ts='" ts "', order_number =" order_number ", insertMode= " insertMode ")]", this.debug)

		idClip := this.DBFindOrCreate(database)
		channel := new ClipjumpChannel(chInsert, this.debug)
		idChannel := channel.DBFindOrCreate(database)

		if (ts = "")
			ts := database.helper.timestamp()
			
		SQL := "SELECT * FROM clip2channel WHERE clip2channel.fk_clip = " idClip " AND clip2channel.fk_channel = " idChannel ";"
		dbgOut("|[" A_ThisFunc "(sha256='" this.chksum "', channel='" chInsert "')] SQL: " SQL, this.debug)
		If !database.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }

		shouldBeAdded := 0
		if(RecordSet.HasRows) {
			if (insertMode==1) {
				SQL := "update clip2channel set fk_clip=" idClip ", fk_channel=" idChannel ", time='" ts "', order_number=" order_number ";"
				dbgOut("|[" A_ThisFunc "(sha256='" this.chksum "', channel='" chInsert "')] SQL: " SQL, this.debug)
				ret := database.Exec(SQL)
				If !ret
					throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
			} else if (insertMode ==2) {
				dbgOut("|[" A_ThisFunc "(...):Clip already exists in channel - will be added as duplicate ...", this.debug)
				; Unless an identical entry exists, the clip should be added again -> allows duplicate/multiple identical clips in one channel
				shouldBeAdded := 1
			}
		} else {
			shouldBeAdded := 1
		}	
		
		if (shouldBeAdded) {
			; An new entry should be generated in two cases:
			; 1.) The entry does not exist yet
			; 2.) Duplicate/Multiple entries are allowed 
			SQL := "INSERT INTO clip2channel (fk_clip, fk_channel, time, order_number) VALUES (" idClip "," idChannel ",'" ts "'," order_number ");"
			dbgOut("|[" A_ThisFunc "(sha256='" this.chksum "', channel='" chInsert "')] SQL: " SQL, this.debug)
			ret := database.Exec(SQL)
			If !ret
				throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
		}

		SQL := "SELECT * FROM clip2channel WHERE clip2channel.fk_clip = " idClip " AND clip2channel.fk_channel = " idChannel ";"
		dbgOut("|[" A_ThisFunc "(sha256='" this.chksum "', channel='" chInsert "')] SQL: " SQL, this.debug)
		If !database.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
		
		RecordSet.Next(Row)
		pk := Row[1]

		dbgOut("<[" A_ThisFunc "(sha256='" this.chksum "', channel='" chInsert "')] -> pk:" pk, this.debug)

		return pk
	}
	; ##################### public methods ##############################################################################
	/*!
		DBFind
			Find Clip in the given database
		Parameters:
			database - SQLite database (Class_SqLiteDB)
		Return:  
			pk - primary key of found database row
	*/
	DBFind(database){
		pk := 0
		dbgOut(">[" A_ThisFunc "(sha256='" this.chksum "')]", this.debug)

		SQL := "SELECT * FROM clip WHERE clip.sha256 = """ this.checksum """;"
		dbgOut("|[" A_ThisFunc "(sha256='" this.chksum "')] SQL: " SQL, this.debug)
		If !database.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
		
		if(RecordSet.HasRows) {
			RecordSet.Next(Row)
			pk := Row[1]
		}

		dbgOut("<[" A_ThisFunc "(sha256='" this.chksum "')] -> pk:" pk, this.debug)

		return pk
	}
	
	; ##################### public methods ##############################################################################
	/*!
		DBFindOrCreate 
			Find or Create Clip in the given database
		Parameters:
			database - SQLite database (Class_SqLiteDB) to insert the clip into
		Return:  
			pk - primary key of inserted clip
	*/
	DBFindOrCreate(database){
		pk := 0
		dbgOut(">[" A_ThisFunc "(sha256='" this.chksum "')]", this.debug)

		pk := this.DBFind(database)
		
		if (pk == 0) {
			SQL := "INSERT INTO Clip (data, sha256, type, fileid) VALUES (""" this.content """,""" this.checksum """,""" this.type """,""" this.fileid """);"
			dbgOut("|[" A_ThisFunc "(sha256='" this.chksum "')] SQL: " SQL, this.debug)
			ret := database.Exec(SQL)
			If !ret
				throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
			pk := this.DBFind(database)
		}
		
		dbgOut("<[" A_ThisFunc "(sha256='" this.chksum "')] -> pk:" pk, this.debug)

		return pk
	}

 	; ##################### private methods ##############################################################################
	/*!
		Constructor: (content, type := 0)
			Creates a clip object.
		Parameters:
			content - Clip content
			type - Clip type (0: text (DEFAULT), 1: Image)
	*/
	__New(content, type := 0, debug := 0) {

		this._debug := debug

		; Store given parameters within properties
		this._content := content
		this._type := type 	
		this._checksum := SHA256(this._content)

		dbgOut("=[" A_ThisFunc "(content=""" content """, type =" type ")] (version: " this._version ")", this.debug)
	}
	/*!
		Destructor: 
			Closes the database on object deconstruction
	*/
	__Delete() {
		dbgOut("=[" A_ThisFunc "(sha256='" this.chksum "')] (version: " this._version ")", this.debug)
	}

}
