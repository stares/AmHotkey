; AmUtils-common.ahk, part of AmHotkey suite.
;
; This ahk is not to be run standalone, it is to be #include-d as AHK function library.
;


#Include %A_LineFile%\..\AmUtils-const.ahk


dev_assert(torf, exitcode_now:=1)
{
	if(!torf)
	{
		dev_MsgBoxError(dev_getCallStack(), "AHK Assertion Fail! Stacktrace >>>")
		
		if(exitcode_now)
			ExitApp, % exitcode_now
	}
}

dev_getCallStack(deepness = 20, is_print_code = true)
{
	; Call this function to get current callstack.
	; Usage: If we want to report an error to user(MsgBox etc), showing a full callstack helps greatly.
	;
	; Thanks to: https://www.autohotkey.com/board/topic/76062-ahk-l-how-to-get-callstack-solution/
	
	lv_first_print := -1
	
	loop % deepness
	{
		lvl := -1 - deepness + A_Index
		oEx := Exception("", lvl)
		oExPrev := Exception("", lvl - 1)
		FileReadLine, line, % oEx.file, % oEx.line
		if(oEx.What = lvl)
			continue
			
		if(lv_first_print==-1) 
			lv_first_print := A_Index
		
		stack .= (stack ? "`n" : "") . Format("#{1}�� ",A_Index-lv_first_print+1) . "File '" oEx.file "', Line " oEx.line (oExPrev.What = lvl-1 ? "" : ", in " oExPrev.What) (is_print_code ? ":`n" line : "") "`n"
	}
	return stack
}


dev_EnvGet(varname)
{
	; Get environment variable value.
	EnvGet, val, %varname%
	return val
}

dev_str2num(str)
{
	; Convert "012" to 12, so that it can be used as array index.
	; Tip from Lexikos: https://www.autohotkey.com/board/topic/21271-converting-string-to-number/
	;
	; [2022-12-07] Memo: Convert "90%" to 90 .
	
	num := "0" . str
	num += 0
	return num
}

;dev_Str2Num(str) // chj
;{
;	; like ANSI C atoi(str),  str="90%", will return 90. 
;	foundpos := RegExMatch(str, "^([0-9]+)", subpat)
;	if(foundpos==1)
;		return subpat1
;	else
;		return 0
;}
;


dev_MsgBoxInfo(text, wintitle:="") ; with a blue (i) icon
{
	if(!wintitle)
		wintitle := "AHK Info"

	MsgBox, 64, % wintitle, % text
}

dev_MsgBoxWarning(text, wintitle:="") ; with a yellow (!) icon
{
	if(!wintitle)
		wintitle := "AHK Warning"

	MsgBox, 48, % wintitle, % text
}

dev_MsgBoxError(text, wintitle:="") ; with a red (x) icon
{
	if(!wintitle)
		wintitle := "AHK Error"

	MsgBox, 16, % wintitle, % text
}

dev_MsgBoxYesNo_title(title, text, default_yes:=true, icon:=64)
{
	; hope to display the message box at the center of parent_winid window...(pending)

	opt := icon + Amhk.mbopt_YesNo + (default_yes ? 0 : Amhk.mbopt_2nddefault)
	MsgBox, % opt, % title, %text%
		; [2016-02-09] I can't use ``%opt%`` for ``% opt`` here(dialogbox would display 260), don't know why.
	
	IfMsgBox, Yes
		return true
	Else
		return false
}

dev_MsgBoxYesNo(text, default_yes:=true, icon:=64)
{
	return dev_MsgBoxYesNo_title("", text, default_yes, icon)
}

dev_MsgBoxYesNo_Warning(text, default_yes:=true)
{
	return dev_MsgBoxYesNo(text, default_yes, Amhk.mbopt_IconExclamation)
}


dev_SendMessage(hwnd, wm_xxx, wparam, lparam)
{
    SendMessage, % wm_xxx, % wparam, % lparam, , ahk_id %hwnd%
}

dev_PostMessage(hwnd, wm_xxx, wparam, lparam)
{
    PostMessage, % wm_xxx, % wparam, % lparam, , ahk_id %hwnd%
}


dev_IniRead(inifilepath, section, key:="", default_val:="")
{
	; key=="" to return whole section content

	default_magic := "20221219.dev_IniRead.default"
	if(default_val=="")
		default_val := default_magic

	IniRead, outvar, % inifilepath, % section, % key, % default_val
	
	if(outvar==default_magic)
		return "" ; User just want a empty string as default
	else
		return outvar
	
}

dev_IniWrite(inifilepath, section, key, val)
{
	IniWrite, % val, % inifilepath, % section, % key
	return ErrorLevel ? false : true
}


dev_CreateDirIfNotExist(dirpath)
{
	; If dirpath already exists and is a directory or a junction (not file),
	; it will return true(=succ).
	try {
		FileCreateDir, % dirpath
	} catch e {
		return false
	}
	return true
}

dev_OnMessage_Register(wm_xxx, str_funcname)
{
	s := str_funcname
	dev_assert(s) ; If user pass in function name without double-quotes, this will fail
	
	OnMessage(wm_xxx, Func(str_funcname))
}

dev_OnMessage_Unregister(wm_xxx, str_funcname)
{
	s := str_funcname
	dev_assert(s) ; If user pass in function name without double-quotes, this will fail

	OnMessage(wm_xxx, Func(str_funcname), 0)
}

dev_WinMoveHwnd(hwnd, x:="", y:="", w:="", h="")
{
	wold := "bad"

	WinGetPos, xold,yold,wold,hold, ahk_id %hwnd%
	
	if(wold=="bad")
		return

	if(x=="")
		x := xold
	if(y=="")
		y := yold
	if(w=="")
		w := wold
	if(h=="")
		h := hold
	
	WinMove, ahk_id %hwnd%, , % x, % y, % w, % h
}

dev_TooltipAutoClear(text, keep_millisec:=2000)
{
	tooltip, %text%
	SetTimer, lb_TooltipAutoClear, % 0-keep_millisec
	return
	
lb_TooltipAutoClear:
	tooltip
	return
}

dev_TooltipDelayHide(keep_millisec:=2000)
{
	; Hide the tooltip after some millisec.
	SetTimer, lb_TooltipDelayHide, % 0-keep_millisec
	return 
	
lb_TooltipDelayHide:
	tooltip
	return
}

dev_FileDelete(filepath)
{
	if(!FileExist(filepath))
		return true

	FileDelete, % filepath
	return ErrorLevel ? false : true
}

dev_FileRemoveDir(dirpath, is_recurse)
{
	FileRemoveDir, % dirpath, % (is_recurse?1:0)
	if(ErrorLevel)
		return false
	else
		return true
}

dev_WriteFile(filepath, text, is_append)
{
	; memo: Use "`n" in text to represent a new line.
	;
	if(not filepath)
		return
	
	if(not is_append)
		FileDelete, %filepath%
	
	FileAppend, %text%, %filepath%
}

dev_WriteLogFile(filepath, text, is_append:=true)
{
	dev_WriteFile(filepath, text, is_append)
}

dev_WriteWholeFile(filepath, text)
{
	dev_WriteFile(filepath, text, false)
}

dev_Copy1File(srcfilepath, dstfilepath, is_overwrite:=false)
{
	dev_assert(InStr(srcfilepath, "*")==0)
	
	srcfileattr := FileExist(srcfilepath)

	if(srcfileattr=="")
		return false ; srcfile not exist
	
	if(InStr(srcfileattr, "D")>0)
		return false ; src must not be a folder
	
	if(InStr(FileExist(dstfilepath), "D")>0) 
		return false ; dst must not be a folder
	
	dstdir := dev_SplitPath(dstfilepath)
	dev_CreateDirIfNotExist(dstdir)
	
	FileCopy, % srcfilepath, % dstfilepath, % (is_overwrite?"1":"")
	
	if(ErrorLevel)
		return false
	else
		return true
}

dev_GetParentDir(path)
{
	dev_assert(InStr(path, "\")>0)
	
	foundpos := RegExMatch(path, "^(.+)\\.+$", subpat)
	
	return subpat1
}

dev_IsDiskFile(filepath)
{
	attr := FileExist(filepath)
	if( InStr(attr, "A") || InStr(attr, "N") ) ; but never see "N"
		return true
	else
		return false
}

dev_IsDiskFolder(dirpath)
{
	attr := FileExist(dirpath)
	if( InStr(attr, "D") )
		return true
	else
		return false
}


dev_InterpretHotkeySpec(spec)
{
	; spec is like "^#c", will return "Ctrl+Win+c"
	

	if(InStr(spec,"^") || InStr(spec,"#") || InStr(spec,"!"))
	{
		desc := ""
		if(InStr(spec,"^"))
			desc .= "Ctrl+"
		if(InStr(spec,"#"))
			desc .= "Win+"
		if(InStr(spec,"!"))
			desc .= "Alt+"
		
		desc .= LTrim(spec, "^#!")
		return desc
	}
	else
	{
		return spec
	}
}

dev_SplitPath(input, byref Filename:="")
{
	SplitPath, input, Filename, OutDir
	return OutDir
}

dev_SplitExtname(input, byref dot_ext:="")
{
	SplitPath, input, outname_nouse, OutDir, OutExt, OutNameNoExt
	dot_ext := "." OutExt
	if(OutDir)
		return Format("{}\{}", OutDir, OutNameNoExt) ; the stempath(no extname)
	else
		return OutNameNoExt
}

dev_AppendToStemname(input, stemname_suffix)
{
	stem := dev_SplitExtname(input, dot_ext)
	return stem . stemname_suffix . dot_ext
}

dev_StrIsEqualI(s1, s2) ; case insensitive compare
{
	StringUpper, s1u, s1
	StringUpper, s2u, s2
	if(s1u==s2u)
		return true
	else
		return false
}

StrIsStartsWith(str, prefix, anycase:=false)
{
	; Check if the string str starts with prefix
	
	if(anycase)
	{
		StringLower, str, str
		StringLower, prefix, prefix
	}
	
	pfxlen := strlen(prefix)
	if(pfxlen<=0)
		return false
	
	s1 := substr(str, 1, pfxlen)
	
	StringUpper, s1_u, s1
	StringUpper, s2_u, prefix
	
	if(s1_u==s2_u)
		return true
	else
		return false
}

StrIsEndsWith(str, suffix, anycase:=false)
{
	if(anycase)
	{
		StringLower, str, str
		StringLower, prefix, prefix
	}
	
	suffix_len := strlen(suffix)
	if(suffix_len==0)
		return false
	if(substr(str, 1-suffix_len)==suffix)
		return true
	else
		return false
}

dev_StripPrefix(str, prefix, is_case_sensitive:=false)
{
	if(StrIsStartsWith(str, prefix, is_case_sensitive))
		return SubStr(str, StrLen(prefix)+1)
	else
		return str
	
}

dev_StripSuffix(str, suffix, is_case_sensitive:=false)
{
	if(StrIsEndsWith(str, suffix, is_case_sensitive))
		return SubStr(str, 1, StrLen(str)-StrLen(suffix))
	else
		return str
	
}

Gui_IsValidVar(varname)
{
	; [2022-12-16] This is a fake function that always succeeds.
	; Currently, no solution for this semantic yet.

	; Wrong comment >>>
			; If varname is not defined, return false.
			; User note: When passed in, your varname should be surround by double-quotes.
			; Example:
			;	Gui_IsValidVar("g_count")    ; may get true
			;	Gui_IsValidVar("NoSuchVar")  ; will get false
			;
			; In order for a `global` var to pass this test, please initialize 
			; your global var with a explicit value, like this:
			; 	global g_count := 0
			; 	global g_errmsg := ""
	; Wrong comment <<<

	if(%varname%)
		return true
	else if(%varname%==0)
		return true
	else if(%varname%=="") ; [2022-12-16] This will be true even if varname is not defined.
		return true
	else
		return false
}

dev_EscapeHtmlChars(text)
{
	text := StrReplace(text, "&", "&amp;")
	text := StrReplace(text, "<", "&lt;")
	text := StrReplace(text, ">", "&gt;")
	return text
}

dev_IsSameFiletime(file1, file2)
{
	FileGetTime, time1, % file1
	FileGetTime, time2, % file2
	
	if(time1 && time1==time2)
		return true
	else
		return false
}

dev_FileGetSize(filepath)
{
	FileGetSize, outlen, % filepath
	return outlen
}

dev_IsBinaryFile(filepath, bytes_to_check:=8192)
{
	; Note: UTF-16 text files will be considered as binary.
	; We only check for byte-value >=0 and <9 , so, text files encoded in MBCS(GBK etc)
	; will still be considered text. For a GBK file, there will be byte-value >=128.
	; Also, UTF-8 file with BOM will not be considered binary.

	FileGetSize, filelen, % filepath
	if ErrorLevel
		return false

	if(filelen==0)
		return true

	isbin := false ; assume false

	if(filelen<bytes_to_check)
		bytes_to_check := filelen

;	dev_WriteLogFile("binlog.txt", "Byte dump of " filepath "`n", false) ; debug

	file := FileOpen(filepath, "r", "UTF-8-RAW")
	if(!IsObject(file))
		return false
	
	; Seek to file start explicitly.
	; Withouth this, Autohotkey will skip BOM bytes for us, which is not desired.
	file.Pos := 0
	
	file.RawRead(buffer, bytes_to_check)
	
	Loop, % bytes_to_check
	{
		byteval := NumGet(buffer, A_Index-1, "UChar")
		
;		dev_WriteLogFile("binlog.txt", Format("{1:02X}`n", byteval)) ; debug
		
		if(byteval>=0 && byteval<9)
		{
			isbin := true
		}
	}
	
	file.Close()
	return isbin
}

dev_mino(args*)
{
	nargs := args.Length()
	
	dev_assert(nargs>1)
	
	valmin := args[1]
	posmin := 1
	
	for i,n in args
	{
		if(n < valmin) {
			valmin := n
			posmin := i
		}
	}
	
	return {idx:posmin, val:valmin}
}

dev_min(args*)
{
	ret := dev_mino(args*)
	return ret.val
}

dev_maxo(args*)
{
	nargs := args.Length()
	
	dev_assert(nargs>1)
	
	valmax := args[1]
	posmax := 1
	
	for i,n in args
	{
		if(n > valmax) {
			valmax := n
			posmax := i
		}
	}
	
	return {idx:posmax, val:valmax}
}

dev_max(args*)
{
	ret := dev_maxo(args*)
	return ret.val
}

dev_JoinStrings(ar_strings, join_with:=",")
{
	; ar_strings is an array containing strings
	if(!IsObject(ar_strings))
		return ""
	
	ret := ""
	for index,value in ar_strings 
	{
		if(index==1)
			ret := value
		else
			ret := ret . join_with . value
	}
	return ret
}

dev_StringUpper(s)
{
	StringUpper, s, s
	return s
}

dev_StringLower(s)
{
	StringLower, s, s
	return s
}


IsWinXP()
{
	return IsWin5x()
}

IsWin5x()
{
	if A_OSVersion in WIN_2003,WIN_XP,WIN_2000
	{
	    return true
	}
	else
	{
		return false
	}
}


dev_IsProcessAlive(pid)
{
	access := 0x1000 ; PROCESS_QUERY_LIMITED_INFORMATION
	if(IsWinXP())
		access := PROCESS_QUERY_INFORMATION

	hProcess := DllCall( "OpenProcess" 
	                    , "uint", access
	                    , "int", false 
	                    , "uint", pid ) 
	if(hProcess)
	{
		DllCall("CloseHandle", "Ptr",hProcess)
		return true
	}
	else
		return false
}

dev_WaitUntilProcessExit(pid, timeout_millisec:=-1)
{
	waitmsec_start := A_TickCount
	Loop
	{
		if(!dev_IsProcessAlive(pid))
			return true
		
		if(timeout_millisec>0 && (A_TickCount-waitmsec_start)>timeout_millisec)
			return false ; timeout
		
		Sleep, 100
	}
}

dev_KillProcessByPid(pid, byref winerr:=0)
{
	hProcess := DllCall( "OpenProcess" 
	                    , "uint", 0x1    ; PROCESS_TERMINATE
	                    , "int", false 
	                    , "uint", pid ) 

	if(!hProcess) {
		winerr := DllCall("GetLastError")
;		Dbgwin_Output(Format("OpenProcess(pid={}) fail. WinErr={}", pid, winerr))
		return false
	}
	
	is_succ := DllCall("TerminateProcess", "Ptr",hProcess, "uint",444)
	if(!is_succ){
		winerr := DllCall("GetLastError")
;		Dbgwin_Output(Format("TerminateProcess(pid={}) fail. WinErr={}", pid, winerr))
	}
	
	DllCall("CloseHandle", "Ptr", hProcess)
	
	return is_succ
}

