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
	_version := "0.1.0" ; Version of class implementation
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
			OutputDebug % ">[" A_ThisFunc "(=" content ", type =" type ")] (version: " this._version ")" ; _DBG_
			
		; Store given parameters within properties
		this.content := content
		this.type := type 		

		if (this._debug) ; _DBG_
			OutputDebug % "<[" A_ThisFunc "(filename=" filename ", overwriteExisting =" overwriteExisting ")] (version: " this._version ")" ; _DBG_
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
