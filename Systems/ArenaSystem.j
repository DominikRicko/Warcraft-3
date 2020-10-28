library Arena initializer Init
    globals
        private constant    integer             RESPAWN_AREAS               = 20
        private constant    integer             MOB_AREA                    = 10
        private constant    integer             ITEM_AREA                   = 30
        private constant    real                RESPAWN_AREA_CHECK_RADIUS   = 500.0
    endglobals
       
    private struct MobArea
        rect                        Rectangle
    endstruct
    
    private struct ItemArea
        rect                        Rectangle
        real                        CenterX
        real                        CenterY
    endstruct
       
    private struct RespawnArea
        rect                        Rectangle
        real                        CenterX
        real                        CenterY
        real                        Radius
    endstruct
    
    private struct Arena
        rect                        Rectangle
        real                        CenterX
        real                        CenterY
        string                      Name
        integer                     RespawnAreaCount
        integer                     MobAreaCount
        integer                     ItemAreaCount
        RespawnArea     array       RespawnAreas[RESPAWN_AREAS]
        MobArea         array       MobArea[MOB_AREA]
        ItemArea        array       ItemArea[ITEM_AREA]
    endstruct
    
    globals
            //Arena Register
        public      Arena     array     Arenas         
        public      location            lastLocation                = null
        private     integer             Counter                     = 0
        public      Arena               current                     = 0
        private     boolean             isGroupEmpty                = true
        private     boolean             Pause                       = true
    endglobals
    
    public function SetCurrent takes Arena ID returns nothing
        set current                                                 = ID
    endfunction
    
    public function GetName takes nothing returns string
        return current.Name
    endfunction
    
    public function Register takes rect r ,string name returns integer
        local Arena Ar                                              = Arena.create()
        
        set Ar.Rectangle                                            = r
        set Ar.CenterX                                              = GetRectCenterX(r)
        set Ar.CenterY                                              = GetRectCenterY(r)
        set Ar.Name                                                 = name
        set Ar.RespawnAreaCount                                     = 0
        set Ar.MobAreaCount                                         = 0
        set Ar.ItemAreaCount                                        = 0
        
        set Arenas[Counter]                                         = Ar
        set Counter                                                 = Counter + 1
       
        set r                                                       = null
        set name                                                    = null
        
        return Ar
    endfunction
    
    public function RegisterPlayerRespawnArea takes Arena arenaID,rect r, real x, real y, real radius returns nothing
        local RespawnArea Ra                                        = RespawnArea.create()
        
        if arenaID.RespawnAreaCount >= RESPAWN_AREAS then
            call Ra.destroy()
            call DisplayTextToForce(GetPlayersAll(),"|cFFDD00DDArena Core:|r |cFFFF0000Failed attempt at registering a new respawn area for |r|cFF00FFFF" + arenaID.Name + "|r.")
            return
        endif
        
        set arenaID.RespawnAreas[arenaID.RespawnAreaCount]          = Ra
        set arenaID.RespawnAreaCount                                = arenaID.RespawnAreaCount + 1 
        
        if r == null then
            //Circle it is!
            set Ra.CenterX                                          = x
            set Ra.CenterY                                          = y
            set Ra.Radius                                           = radius
        else
            //Rect it is!
            set Ra.Rectangle                                        = r
            set Ra.CenterX                                          = GetRectCenterX(r)
            set Ra.CenterY                                          = GetRectCenterY(r)
        endif
        
        set r                                                       = null
    endfunction
    
    public function RegisterMobSpawnArea takes Arena arenaID, rect r returns nothing
        local MobArea Ra                                            = MobArea.create()
        
        if arenaID.MobAreaCount >= MOB_AREA then
            call Ra.destroy()
            call DisplayTextToForce(GetPlayersAll(),"|cFFDD00DDArena Core:|r |cFFFF0000Failed attempt at registering a new mob area for |r|cFF00FFFF" + arenaID.Name + "|r.")
            return
        endif
        
        set Ra.Rectangle                                            = r
        set arenaID.MobArea[arenaID.MobAreaCount]                   = Ra
        set arenaID.MobAreaCount                                    = arenaID.MobAreaCount + 1
        
        set r                                                       = null
    endfunction
    
    public function RegisterItemArea takes Arena arenaID, rect r returns nothing
        local ItemArea IA                                           = ItemArea.create()
        
        if arenaID.ItemAreaCount >= ITEM_AREA then
            call IA.destroy()
            call DisplayTextToForce(GetPlayersAll(),"|cFFDD00DDArena Core:|r |cFFFF0000Failed attempt at registering a new item area for |r|cFF00FFFF" + arenaID.Name + "|r.")
            return
        endif
        
        set IA.Rectangle                                            = r
        set IA.CenterX                                              = GetRectCenterX(r)
        set IA.CenterY                                              = GetRectCenterY(r)
        set arenaID.ItemArea[arenaID.ItemAreaCount]                 = IA
        set arenaID.ItemAreaCount                                   = arenaID.ItemAreaCount + 1
        
        set r                                                       = null
    endfunction
    
    private function DoesGroupHaveSomething takes nothing returns nothing
        set isGroupEmpty                                            = false
    endfunction
    
    public function GetPlayerRespawnLocation takes nothing returns location
        //For rect specified cases!
        local integer   array       validLocations
        local integer               validLocationCounter            = 0
        local integer       i                                       = 0
        local group         g                                       = CreateGroup()
        
        //Out of all, select what spawn locations are empty
        loop 
            exitwhen i >= current.RespawnAreaCount
            call GroupEnumUnitsInRange(g,current.RespawnAreas[i].CenterX,current.RespawnAreas[i].CenterY,RESPAWN_AREA_CHECK_RADIUS,null)
            set isGroupEmpty                                        = true
            call ForGroup(g,function DoesGroupHaveSomething)
            if isGroupEmpty then
                set validLocations[validLocationCounter]            = i
                set validLocationCounter                            = validLocationCounter + 1
            endif
            set i                                                   = i + 1
        endloop
        
        //Cases if there are locations, or not
        if validLocationCounter == 0 then
            set i                                                   = GetRandomInt(0,current.RespawnAreaCount-1)
        else
            set i                                                   = GetRandomInt(0,validLocationCounter-1)
            set i                                                   = validLocations[i] //<- get proper location pls
        endif
        
        //Say hello to room-cleaning service.
        call DestroyGroup(g)
        call RemoveLocation(lastLocation)
        //Time to send out the signals
        set g                                                       = null
        set lastLocation                                            = Location(current.RespawnAreas[i].CenterX,current.RespawnAreas[i].CenterY)
        return lastLocation
    endfunction
    
    private function GetMobSpawnPoint takes nothing returns location
        call RemoveLocation(lastLocation)
        //some smart spawning thinggy, to-do
        return lastLocation
    endfunction
    
    public function GetItemSpawnPoint takes nothing returns location
        local integer   array       validLocations
        local integer               validLocationCounter            = 0
        local integer               i                               = 0
       
        loop
            exitwhen i >= current.ItemAreaCount
            set isGroupEmpty                                        = true
            call EnumItemsInRect(current.ItemArea[i].Rectangle,null,function DoesGroupHaveSomething) //recycling finished functions, lol
            if isGroupEmpty then
                set validLocations[validLocationCounter]            = i
                set validLocationCounter                            = validLocationCounter + 1
            endif
            
            set i                                                   = i + 1
        endloop
    
        //Cases if there are locations, or not
        if validLocationCounter == 0 then
            set i                                                   = GetRandomInt(0,current.RespawnAreaCount-1)
        else
            set i                                                   = GetRandomInt(0,validLocationCounter-1)
            set i                                                   = validLocations[i] //<- get proper location pls
        endif
        
        call RemoveLocation(lastLocation)
        set lastLocation                                            = Location(current.ItemArea[i].CenterX,current.ItemArea[i].CenterY)
        return lastLocation
    endfunction
    
    private function InitGameplay takes nothing returns nothing
        
        
        
        
        call TriggerSleepAction(2.00)
    
    
    
    
    
    
        call DestroyTrigger(GetTriggeringTrigger())
    endfunction
    
    private function Init takes nothing returns nothing
        local trigger tr                                            = CreateTrigger()
        set udg_Hashtable                                           = InitHashtable()
        
        call TriggerAddAction(tr,function InitGameplay)
        call TriggerRegisterTimerEvent(tr,0.00,false)
        set tr                                                      = null
    endfunction
endlibrary