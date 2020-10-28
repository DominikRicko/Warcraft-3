library HostDetection initializer Init
/***************************************************************
*
*   v1.0.0, by TriggerHappy
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*   Detect which player hosted the current match.
*   _________________________________________________________________________
*   1. Requirements
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       - Patch 1.31 or higher.
*       - JassHelper (vJASS)
*   _________________________________________________________________________
*   2. Installation
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*   Copy the script to your map and save it.
*   _________________________________________________________________________
*   3. API
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       function GetHost takes nothing returns boolean
*       function IsHostDetected nothing returnrs boolean
*       function IsLocalPlayerHost nothing returnrs boolean
*
*       function OnHostDetect takes code callback returns triggeraction
*       function RemoveHostDetect takes triggeraction action returns nothing
*
***************************************************************/

    globals
        private hashtable HostDetectHT = InitHashtable()
        private boolean LocalHostFlag = not HaveSavedString(HostDetectHT, 0, 0) and (BlzGetFrameByName("NameMenu", 1) == null) and Location(0, 0) != null and SaveStr(HostDetectHT, 0, 0, "1")
        private trigger SyncTrig = CreateTrigger()
        private trigger EventTrig = CreateTrigger()
        private player HostPlayer = null
    endglobals
  
    function GetHost takes nothing returns player
        return HostPlayer
    endfunction
  
    function IsHostDetected takes nothing returns boolean
        return HostPlayer != null
    endfunction
  
    function IsLocalPlayerHost takes nothing returns boolean // async
        return LocalHostFlag
    endfunction
  
    function OnHostDetect takes code callback returns triggeraction
        return TriggerAddAction(EventTrig, callback)
    endfunction
  
    function RemoveHostDetect takes triggeraction action returns nothing
        call TriggerRemoveAction(EventTrig, action)
    endfunction
  
    private function OnHostSync takes nothing returns nothing
        set HostPlayer = GetTriggerPlayer()
        call TriggerExecute(EventTrig)
        call DisableTrigger(GetTriggeringTrigger())
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 0
        loop
            exitwhen i > bj_MAX_PLAYERS
            call BlzTriggerRegisterPlayerSyncEvent(SyncTrig, Player(i), "hostdetect", false)
            set i = i + 1
        endloop
        call TriggerAddAction(SyncTrig, function OnHostSync)
        if (IsLocalPlayerHost()) then
            call BlzSendSyncData("hostdetect", "1")
        endif
    endfunction
  
endlibrary