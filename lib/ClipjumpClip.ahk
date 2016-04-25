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

class ClipjumpClip {
; ******************************************************************************************************************************************
/*
	Class: ClipjumpClip
		Helper class to hold data for a single clip

	Authors:
	<hoppfrosch at hoppfrosch@gmx.de>: Original
*/	
    ; Versioning according SemVer http://semver.org/
	_version := "0.1.3" ; Version of class implementation
	_debug := 0
	_content := ""
	_type := 0
	_checksum := 0
	_fileId := ""

	; ##################### Properties (AHK >1.1.16.x) #################################################################
	checksum[] {
	/* ------------------------------------------------------------------------------- 
	Property: ver [get]
	Get the version of the class implementation
	*/
		get {
			return this._checksum
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
			update - if same clip is added to same channel either leave db entry as is (default) or update the existing entry 
		Return:  
			pk - primary key of created database row
	*/
	DBAddToChannel(database, channel := "Default", ts := "", order_number := -1, update := 0){
		bSuccess := 0
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(...)]" ; _DBG_

		idClip := this.DBFindOrCreate(database)
		channel := new ClipjumpChannel(channel, this.debug)
		idChannel := channel.DBFindOrCreate(database)

		if (ts = "")
			ts := database.timestamp()
			
		SQL := "SELECT * FROM clip2channel WHERE clip2channel.fk_clip = " idClip " AND clip2channel.fk_channel = " idChannel ";"
		if (this._debug) ; _DBG_
			OutputDebug % "..[" A_ThisFunc "(...)] SQL: " SQL ; _DBG_
		If !database.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
		
		if(RecordSet.HasRows) {
			if (update) {
				SQL := "update clip2channel set fk_clip=" idClip ", fk_channel=" idChannel ", time='" ts "', order_number=" order_number ";"
				if (this._debug) ; _DBG_
					OutputDebug % "..[" A_ThisFunc "(...)] SQL: " SQL ; _DBG_
				ret := database.Exec(SQL)
				If !ret
					throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
			}
		} else {
			SQL := "INSERT INTO clip2channel (fk_clip, fk_channel, time, order_number) VALUES (" idClip "," idChannel ",'" ts "'," order_number ");"
			if (this._debug) ; _DBG_
				OutputDebug % "..[" A_ThisFunc "(...)] SQL: " SQL ; _DBG_
			ret := database.Exec(SQL)
			If !ret
				throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
		}

		SQL := "SELECT * FROM clip2channel WHERE clip2channel.fk_clip = " idClip " AND clip2channel.fk_channel = " idChannel ";"
		if (this._debug) ; _DBG_
			OutputDebug % "..[" A_ThisFunc "(...)] SQL: " SQL ; _DBG_
		If !database.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
		
		RecordSet.Next(Row)
		pk := Row[1]

		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(...)] -> pk:" pk ; _DBG_

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
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(...)]" ; _DBG_

		SQL := "SELECT * FROM clip WHERE clip.sha256 = """ this.checksum """;"
		if (this._debug) ; _DBG_
			OutputDebug % "..[" A_ThisFunc "(...)] SQL: " SQL ; _DBG_
		If !database.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
		
		if(RecordSet.HasRows) {
			RecordSet.Next(Row)
			pk := Row[1]
		}

		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(...)] -> pk:" pk ; _DBG_

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
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(...)]" ; _DBG_

		pk := this.DBFind(database)
		
		if (pk == 0) {
			SQL := "INSERT INTO Clip (data, sha256, type, fileid) VALUES ('" this.content "','" this.checksum "','" this.type "','" this.fileid "');"
			if (this._debug) ; _DBG_
				OutputDebug % "..[" A_ThisFunc "(...)] SQL: " SQL ; _DBG_
			ret := database.Exec(SQL)
			If !ret
				throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
			pk := this.DBFind(database)
		}
		
		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(... )] -> pk:" pk ; _DBG_

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
		
		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(content=""" content """, type =" type ")] (version: " this._version ")" ; _DBG_
			
		; Store given parameters within properties
		this._content := content
		this._type := type 	
		this._checksum := SHA256(this._content)

		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(content=""" content """, type =" type ")] (version: " this._version ")"	; _DBG_
	}
	/*!
		Destructor: 
			Closes the database on object deconstruction
	*/
	__Delete() {
		if (this._debug) ; _DBG_
			OutputDebug % "*[" A_ThisFunc "()]" ; _DBG_
	}

}
