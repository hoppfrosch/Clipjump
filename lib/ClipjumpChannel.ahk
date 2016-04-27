/*
	Title: ClipjumpChannel
		
	Helper class to hold data for a clipjump channel
	
	Authors:
	<hoppfrosch at hoppfrosch@gmx.de>: Original

	About: License
	This program is free software. It comes without any warranty, to the extent permitted by applicable law. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See <WTFPL at http://www.wtfpl.net/> for more details.

*/

#include %A_LineFile%\..

class ClipjumpChannel {
; ******************************************************************************************************************************************
/*
	Class: ClipjumpChannel
		Helper class to hold data for a clipjump channel

	Authors:
	<hoppfrosch at hoppfrosch@gmx.de>: Original
*/	
    ; Versioning according SemVer http://semver.org/
	_version := "0.1.1" ; Version of class implementation
	_debug := 0
	_name := ""
	_caseInsensitive := "1"
	
	; ##################### Properties (AHK >1.1.16.x) #################################################################
	name[] {
	/* ------------------------------------------------------------------------------- 
	Property: name [get/set]
	name of the channel

	Value:
	name - name of the channel
	*/
		get {
			return this._name
		}
		set {
			this._name := value
			return this._name
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
	caseInsensitive[] {
	/* ------------------------------------------------------------------------------- 
	Property: caseInsensitive [get/set]
	Should channel name be considered case insensitive? (default := 1)

	Value:
	caseInsensitive
	*/
		get {
			return this._caseInsensitive
		}
		set {
			this._caseInsensitive := value
			return this._caseInsensitive
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
		DBFind
			Find Channel in the given database
		Parameters:
			database - SQLite database (Class_SqLiteDB)
		Return:  
			pk - primary key of found database row
	*/
	DBFind(database){
		pk := 0

		if (this._debug) ; _DBG_
			OutputDebug % ">[" A_ThisFunc "(name='" this.name "')]" ; _DBG_

		SQL := "SELECT * FROM channel WHERE channel.name = """ this.name """"
		if (this.caseInsensitive)
			SQL := SQL " COLLATE NOCASE"
		SQL := SQL ";"
		if (this._debug) ; _DBG_
			OutputDebug % "..[" A_ThisFunc "(name='" this.name "')] SQL: " SQL ; _DBG_
		If !database.Query(SQL, RecordSet)
			throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
		
		if(RecordSet.HasRows) {
			RecordSet.Next(Row)
			pk := Row[1]
		}

		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(name='" this.name "')] -> pk:" pk ; _DBG_

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
			OutputDebug % ">[" A_ThisFunc "(name='" this.name "')]" ; _DBG_

		pk := this.DBFind(database)
		
		if(pk == 0) {
			SQL := "INSERT INTO Channel (name) VALUES ('" this.name "');"
			if (this._debug) ; _DBG_
				OutputDebug % "..[" A_ThisFunc "(...)] SQL: " SQL ; _DBG_
			ret := database.Exec(SQL)
			If !ret
				throw, { what: " ClipjumpDB SQLite Error", message:  database.ErrorMsg, extra: database.ErrorCode, file: A_LineFile, line: A_LineNumber }
			pk := this.DBFind(database)
		}
		
		
		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(name='" this.name "')] -> pk:" pk ; _DBG_

		return pk
	}

 	; ##################### private methods ##############################################################################
	/*!
		Constructor: (name)
			Creates a clip object.
		Parameters:
			name - Clip content
			type - Clip type (0: text (DEFAULT), 1: Image)
	*/
	__New(name, debug) {

		this._debug := debug
		
		if (this._debug) ; _DBG_
			OutputDebug % "*[" A_ThisFunc "(name=""" name """)] (version: " this._version ")" ; _DBG_
			
		; Store given parameters within properties
		this._name := name
		this._caseInsensitive := 1
	}
	/*!
		Destructor: 
			Closes the database on object deconstruction
	*/
	__Delete() {
		if (this._debug) ; _DBG_
			OutputDebug % "*[" A_ThisFunc "(name=""" this.name """)] (version: " this._version ")" ; _DBG_
	}

}
