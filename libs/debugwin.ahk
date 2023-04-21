﻿; Note: If this file contains non-ASCII characters, you must saved it in UTF8 with BOM,
; in order for the Unicode characters to be recognized by Autohotkey engine.

/* APIs:

Dbgwin_Output("Your debug message.")
	; This debug-message window will be created automatically.
	; On first call, the dbg-window is popped to front;
	; on second call, the dbg-window remains in background so it does not disturb your active window.
	; To force second call window foreground, call Dbgwin_Output_fg() or Dbgwin_Output(msg, true) .

Dbgwin_Output_fg("Your msg") ; Force debug-window bring to front.
	
Dbgwin_ShowGui(true)
	; Show the Gui, in case it was hidden(closed by user).
	; Parameter: `true` to bring it to front; `false` to keep it background(not have keyboard focus).

Amdbg_ShowGui()
	; Pop up the dialog UI that allows user to change AHK global vars on the fly.

Amdbg_output(clientId, newmsg, msglv)
Amdbg_Lv1(clientId, newmsg)
Amdbg_Lv2(clientId, newmsg)
Amdbg_Lv3(clientId, newmsg)
	; Output a debug message in the name of `clientId`.
	; By calling Amdbg_ShowGui(), final user can control which clientId's messages appear onto 
	; Dbgwin GUI instantly.

AmDbg_SetDesc(clientId, desc)
	; [Optional] Associate a piece of description text to `clientId`, which can be seen in 
	; Dbgwin GUI instantly, so tht final user knows what is `clientId` is for.

*/

; [[ Dbgwin ]]

global g_dbgwinHwnd

global gu_dbgwinBtnCopy
global gu_dbgwinHint
global gu_dbgwinBtnClear
global gu_dbgwinMLE

global g_dbgwinMsgCount := 0

; [[ Amdbg ]]

global g_amdbgHwnd

global gu_amdbgCbxClientId
global gu_amdbgBtnRefresh
global gu_amdbgMleDesc
global gu_amdbgTxtNewValue
global gu_amdbgEdtNewValue
global gu_amdbgSetBtn


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; If you define any global variables, you MUST define them ABOVE this line.
;
;return ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


class Dbgwin ; as global var container
{
	; We define Dbgwin class, in order to define these "global constant"
	; without the help of AUTOEXEC_debugwin label.
	;
	static IniFilename := "debugwin.ini"
	static IniSection  := "cfg"
}

class CTimeGapTeller
{
	_gap_millisec := 0
	_msec_prev := 0
	
	__New(gap_millisec)
	{
		this._msec_prev := 0
		this._gap_millisec := gap_millisec
	}
	
	CheckGap()
	{
		; If _gap_millisec time-period has passed since previous CheckGap() call,
		; return true, otherwise, return false. First-run returns false.
		
		ret := false ; assume false
		now_msec := dev_GetTickCount64()
		
		if(this._msec_prev>0)
		{
			if(now_msec - this._msec_prev >= this._gap_millisec)
				ret := true
		}

		this._msec_prev := now_msec
		return ret
	}
}

Dbgwin_Output_fg(msg)
{
	Dbgwin_Output(msg, true)
}

Dbgwin_Output(msg, force_fgwin:=false)
{
	linemsg := AmDbg_MakeLineMsg(msg, 1)
	
	Dbgwin_AppendRaw(linemsg)
}
	
Dbgwin_AppendRaw(linemsg, force_fgwin:=false)
{	
	static s_tgt := new CTimeGapTeller(1000)

	if(s_tgt.CheckGap())
		linemsg := ".`r`n" linemsg
	
	Dbgwin_ShowGui(force_fgwin)
	
	; We append msg to end of current multiline-editbox. (AppendText)
	; Using WinAPI like this:
	;
    ; int pos = GetWindowTextLength (hedit);
    ;
    ; Edit_SetSel(hedit, pos, pos);
    ; Edit_ReplaceSel(hedit, text);
    
    hwndEdit := GuiControl_GetHwnd("Dbgwin", "gu_dbgwinMLE")

    pos := DllCall("GetWindowTextLength", "Ptr", hwndEdit)
    
    EM_SETSEL := 0x00B1
    EM_REPLACESEL := 0x00C2
    dev_SendMessage(hwndEdit, EM_SETSEL, pos, pos)
    dev_SendMessage(hwndEdit, EM_REPLACESEL, 0, &linemsg)
    
   	g_dbgwinMsgCount += 1
	;
    GuiControl_SetText("Dbgwin", "gu_dbgwinHint"
    	, Format("{} Messages from Dbgwin_Output():", g_dbgwinMsgCount))

}


Dbgwin_CreateGui()
{
	Gui, Dbgwin:New ; Destroy old window if any
	Gui_ChangeOpt("Dbgwin", "+Resize +MinSize300x150 +E0x0080 +E0x40000")
	; -- +E0x0080: WS_EX_TOOLWINDOW (thin title);  +E0x40000: WS_EX_APPWINDOW (want taskbar thumbnail)
	
	Gui_AssociateHwndVarname("Dbgwin", "g_dbgwinHwnd")
	Gui_Switch_Font("Dbgwin", 8, "Black", "Tahoma") 
	
	Gui_Add_Button("Dbgwin", "gu_dbgwinBtnCopy" , 40, "Section g" "Dbgwin_evtBtnCopy", "&Copy")
	Gui_Add_TxtLabel("Dbgwin", "gu_dbgwinHint", 200, "x+5 yp+4", "Message from Dbgwin_Output():")
	Gui_Add_Button("Dbgwin", "gu_dbgwinBtnClear", 40, "ys x+115 g" "Dbgwin_evtClear", "Clea&r")
	Gui_Add_Editbox("Dbgwin", "gu_dbgwinMLE", 400, "xm r10")

	g_dbgwinMsgCount := 0

	Gui_Show("Dbgwin")
	Dbgwin_LoadWindowPos()
}

Dbgwin_ShowGui(bring_to_front:=false)
{
	if(!g_dbgwinHwnd)
	{
		Dbgwin_CreateGui()
	}
	
	Gui_Show("Dbgwin", bring_to_front ? "" : "NoActivate", "AmHotkey Debugwin")
}

Dbgwin_HideGui()
{
	Dbgwin_SaveWindowPos()

	Gui_Hide("Dbgwin")
}

Dbgwin_SaveWindowPos()
{
	WinGetPos, x,y,w,h, ahk_id %g_dbgwinHwnd%

	if(w!=0 and h!=0)
	{
		xywh := Format("{},{},{},{}", x,y,w,h)
		succ := dev_IniWrite(Dbgwin.IniFilename, Dbgwin.IniSection, "WinposXYWH", xywh)
		if(!succ)
			dev_MsgBoxWarning(Format("Dbgwin_SaveWindowPos(): Fail to save ini file: {}", Dbgwin.IniFilename))
	}

;	Msgbox, % "Dbgwin.IniFilename=" Dbgwin.IniFilename
}

Dbgwin_LoadWindowPos()
{
	xywh := dev_IniRead(Dbgwin.IniFilename, Dbgwin.IniSection, "WinposXYWH")

	num := StrSplit(xywh, ",")
	x := num[1] , y := num[2] , w := num[3] , h := num[4]
	if(w>0 and h>0)
	{
		dev_WinMoveHwnd(g_dbgwinHwnd, x,y, w,h)
	}
}

DbgwinGuiClose()
{
	Dbgwin_HideGui()
}

DbgwinGuiEscape()
{
	; This enables ESC to close AHK window.
	Dbgwin_HideGui()
}


DbgwinGuiSize()
{
;	Dbgwin_Output(Format("In DbgwinGuiSize(), A_GuiWidth={}, A_GuiHeight={}", A_GuiWidth, A_GuiHeight))
	
	rsdict := {}
	rsdict.gu_dbgwinMLE := "0,0,100,100" ; Left/Top/Right/Bottom
	rsdict.gu_dbgwinBtnClear := "100,0,100,0"
	dev_GuiAutoResize("Dbgwin", rsdict, A_GuiWidth, A_GuiHeight)
}

Dbgwin_evtBtnCopy()
{
	text := GuiControl_GetText("Dbgwin", "gu_dbgwinMLE")
	
	if(text)
	{
		Clipboard := text
		slen := strlen(text)
		dev_TooltipAutoClear(Format("Copied to clipboard, {} chars", slen))
	}

	Dbgwin_SaveWindowPos()
}

Dbgwin_evtClear()
{
	GuiControl_SetText("Dbgwin", "gu_dbgwinMLE", "")

	Dbgwin_SaveWindowPos()
}


; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 

; Amdbg : a GUI that allow user to change global vars on the fly.

class Amdbg ; as global var container
{
	static GuiName := "Amdbg"
	static GuiWidth := 400 ; px
	
	static dictClients := {}
	; -- each dict-key represent a "client", and each client is described in
	; 	yet another dict which has the following keys:
	;	.desc     : description text of  
	; 	.allmsg   : all debug messaged accumulated(as a circular buffer).
	;	.outputlv : output level, 0,1,2... If 0, msg is only buffered but not sent to Dbgwin_Output().
	
	static maxbuf := 1024000 ; allmsg buffer size, in bytes
}

Amdbg_CreateGui()
{
	GuiName := Amdbg.GuiName
	guiwidth := 400
	
	Gui_New(GuiName)
	Gui_AssociateHwndVarname(GuiName, "g_amdbgHwnd")
	Gui_ChangeOpt(GuiName, "+Resize +MinSize")
	
	Gui_Switch_Font( GuiName, 9, "", "Tahoma")
	
	Gui_Add_TxtLabel(GuiName, "", -1, "xm", "Configure debug message UI output levels.")
	Gui_Add_TxtLabel(GuiName, "", -1, "xm", "AmDbg client id:")
	
	Gui_Add_Combobox(GuiName, "gu_amdbgCbxClientId", 300, "xm g" "Amdbg_SyncUI")
	Gui_Add_Button(  GuiName, "gu_amdbgBtnRefresh", 40, "yp x+5 g" "Amdbg_RefreshClients", "&Refresh")
	
	Gui_Add_Editbox( GuiName, "gu_amdbgMleDesc", Amdbg.GuiWidth-20, "xm-2 readonly r3 -E0x200")
	
	Gui_Add_TxtLabel(GuiName, "gu_amdbgTxtNewValue", -1, "xm", "New output level:")
	Gui_Add_Editbox( GuiName, "gu_amdbgEdtNewValue", 60, "")

	Gui_Add_Button(  GuiName, "gu_amdbgSetBtn", -1, "Default g" "Amdbg_SetValueBtn", "&Set new")
	
	Amdbg_RefreshClients()
}

Amdbg_RefreshClients()
{
	; Amdbg clients can be dynamically created/deleted, so we need this function.
	
	GuiName := Amdbg.GuiName
	vnCbx := "gu_amdbgCbxClientId"
	
	cbTextOrig := GuiControl_GetText(GuiName, vnCbx)
	
	hwndCombobox := GuiControl_GetHwnd(GuiName, vnCbx)
	dev_assert(hwndCombobox)
	dev_Combobox_Clear(hwndCombobox)

	varlist := []
	for clientId in Amdbg.dictClients
	{
		varlist.Push(clientId)
	}
	GuiControl_ComboboxAddItems(GuiName, vnCbx, varlist) ; already sorted by AHKGUI
	
	Combobox_SetText(GuiName, vnCbx, cbTextOrig)
}

Amdbg_ShowGui()
{
	GuiName := Amdbg.GuiName

	if(!g_amdbgHwnd) {
		Amdbg_CreateGui() ; destroy old and create new
	}
	
	Gui_Show(GuiName, Format("w{} center", Amdbg.GuiWidth), "AmHotkey AmDbg configurations")
	
}

Amdbg_HideGui()
{
	GuiName := Amdbg.GuiName

	Gui_Hide(GuiName)
}

AmdbgGuiClose()
{
	Amdbg_HideGui()
}

AmdbgGuiEscape()
{
	Amdbg_HideGui()
}

Amdbg_SetValue()
{
	GuiName := Amdbg.GuiName

	clientId := GuiControl_GetText(GuiName, "gu_amdbgCbxClientId")
	outputlv := GuiControl_GetText(GuiName, "gu_amdbgEdtNewValue")
	
;	GuiControl_SetText(GuiName, "gu_amdbgMleDesc", Amdbg.dictClients[uservar]) ; to-delete
	
	Amdbg.dictClients[clientId].outputlv := outputlv
}

Amdbg_SetValueBtn()
{
	Amdbg_SetValue()
	
	Amdbg_HideGui()
}

AmdbgGuiSize()
{
	rsdict := {}
    rsdict.gu_amdbgMleDesc := "0,0,100,100" ; Left/Top/Right/Bottom pct
    rsdict.gu_amdbgEdtNewValue := "0,100,100,100"
    rsdict.gu_amdbgSetBtn := "0,100,0,100"
    dev_GuiAutoResize(Amdbg.GuiName, rsdict, A_GuiWidth, A_GuiHeight, true)
}



;Amdbg_evtCbxVarSelect()
;{
;	Amdbg_SyncUI()
;}
;

Amdbg_SyncUI()
{
	GuiName := Amdbg.GuiName

	clientId := GuiControl_GetText(GuiName, "gu_amdbgCbxClientId")
	
	GuiControl_SetText(GuiName, "gu_amdbgMleDesc", Amdbg.dictClients[clientId].desc)
	
	outputlv := Amdbg.dictClients[clientId].outputlv
	GuiControl_SetText(GuiName, "gu_amdbgEdtNewValue", outputlv)
}



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Implement Amdbg_output()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AmDbg_MakeLineMsg(msg, lv)
{
	; Makes single \n become \r\n, bcz Win32 editbox recognized only \r\n as newline.
	msg := StrReplace(msg, "`r`n", "`n")
	msg := StrReplace(msg, "`n", "`r`n")
	
	; I will report millisecond fraction, so need some extra work.
	;
	static s_start_msec   := A_TickCount
	static s_start_ymdhms := A_Now
	static s_prev_msec    := s_start_msec
	
	
	now_tick := A_TickCount
	msec_from_prev := now_tick - s_prev_msec

;Dbgwin_AppendRaw(Format("s_prev_msec={} , now_tick={} ({})`r`n", s_prev_msec, now_tick, now_tick-s_prev_msec))
	
	sec_from_start := (A_TickCount-s_start_msec) // 1000
	msec_frac := Mod(A_TickCount-s_start_msec, 1000)
	
	now_ymdhsm := dev_Ts14AddSeconds(s_start_ymdhms, sec_from_start)

	; now_ymdhsm is like "20221212115851"
;	year := substr(now_ymdhsm, 1, 4)
;	mon  := substr(now_ymdhsm, 5, 2)
;	day  := substr(now_ymdhsm, 7, 2)
	ymd  := substr(now_ymdhsm, 1, 8)
	hour := substr(now_ymdhsm, 9, 2)
	minu := substr(now_ymdhsm, 11, 2)
	sec  := substr(now_ymdhsm, 13, 2)
	
	stimestamp := Format("{}_{}:{}:{}.{:03}", ymd, hour, minu, sec, msec_frac)
	stimeplus  := Format("+{}.{:03}s", msec_from_prev//1000, Mod(msec_from_prev,1000)) ; "+1.002s" etc
	
;	msg := now_ymdhsm "  " msg . "`r`n"
	
	linemsg := Format("{1}*[{2}] ({3}) {4}`r`n"
		, lv, stimestamp, stimeplus, msg)
	
    s_prev_msec := now_tick
	
	return linemsg
}

_Amdbg_CreateClientId(clientId) ; Create client object is not-exist yet
{
	if(not Amdbg.dictClients.HasKey(clientId))
	{
		Amdbg.dictClients[clientId] := {}
		Amdbg.dictClients[clientId].desc := "Unset yet"
		Amdbg.dictClients[clientId].allmsg := ""
		Amdbg.dictClients[clientId].timegapteller := new CTimeGapTeller(1000)
		
		; Check for g_DefaultDbgLv_xxx global var to determine initial dbgLv .
		; User can set those vars in custom_env.ahk, for example, if 
		; clientId="Clipmon", then put this into custom_env.ahk :
		;
		; 	global g_DefaultDbgLv_Clipmon := 1
		;
		gvarname := "g_DefaultDbgLv_" clientId 
		defaultlv := %gvarname%
		
		if(defaultlv>0)
			Amdbg.dictClients[clientId].outputlv := defaultlv
		else
			Amdbg.dictClients[clientId].outputlv := 0
	}

	return Amdbg.dictClients[clientId]
}

_Amdbg_AppendLineMsg(client, linemsg)
{
	; client is the object returned by _Amdbg_CreateClientId()
	
	if(client.timegapteller.CheckGap())
		linemsg := ".`r`n" linemsg
	
	client.allmsg .= linemsg
}

Amdbg_output(clientId, newmsg, msglv:=1)
{
	; clientId is a short string describing to which client this newmsg belongs
	
	dev_assert(clientId) ; clientId must NOT be empty
	dev_assert(dev_IsString(clientId))
	dev_assert(dev_IsString(newmsg))
	
	client := _Amdbg_CreateClientId(clientId)
	
	; Truncate buffer if full
	if(StrLen(client.allmsg)>=Amdbg.maxbuf)
	{
		halfmax := Amdbg.maxbuf / 2
		
		client.allmsg := SubStr(client.allmsg, halfmax)
	}
	
	linemsg := AmDbg_MakeLineMsg(newmsg, msglv)
	
	_Amdbg_AppendLineMsg(client, linemsg)
	
	if(msglv <= client.outputlv)
	{
		Dbgwin_AppendRaw(linemsg)
	}
}

Amdbg_Lv1(clientId, newmsg)
{
	Amdbg_output(clientId, newmsg, 1)
}

Amdbg_Lv2(clientId, newmsg)
{
	Amdbg_output(clientId, newmsg, 2)
}

Amdbg_Lv3(clientId, newmsg)
{
	Amdbg_output(clientId, newmsg, 3)
}

Amdbg_SetDesc(clientId, desc)
{
	client := _Amdbg_CreateClientId(clientId)
	
	client.desc := desc
}
