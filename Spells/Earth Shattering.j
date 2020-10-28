
struct EarthShattering

    public static constant integer  DUMMY_ID = 'n000'
    public static constant real     MOVEMENT_PERIOD = 0.02
    public static constant real     MOVEMENT_TIMED_LIFE = 1.00
    public static constant string   EFFECT_PATH = "Doodads\\Felwood\\Rocks\\FelwoodFissure\\FelwoodFissure1.mdl"
    public static constant string   SOUND_EFFECT_PATH = "Sound\\Buildings\\Death\\HCancelBuilding.wav"
    public static constant string   SOUND_EFFECT2_PATH = "Sounds\\Interface\\GlueScreenMeteorHit1.wav"
    public static constant string   UBERSPLAT_NAME = "NVCR"
    public static constant integer  RARETY_OF_EFFECTS = 10

    public real     damage
    public real     duration
    public real     damagePerPeriod
    public real     period
    public real     angle

    private real    velocity
    private real    timedLife
    private integer counter

    private unit    dummy
    private unit    caster

    private group   targetGroup
    private region  damageRegion
    private rect    dummyRect

    private trigger collisionTrigger
    private trigger enterRegion
    private trigger leaveRegion

    private timer   spellTimer
    private timer   damageTimer

    private static Sound soundEffect
    private static Sound soundEffect2
    
    private static method newTarget takes nothing returns nothing
        local thistype this = GetTriggerData(GetTriggeringTrigger())
        local unit triggerUnit = GetTriggerUnit()

         if (not IsUnitAlly(triggerUnit,GetOwningPlayer(this.caster))) and UnitAlive(triggerUnit) then

            call GroupAddUnit(this.targetGroup, triggerUnit)
            call UnitDamageTarget(this.caster, triggerUnit, this.damage, false,false,ATTACK_TYPE_CHAOS,DAMAGE_TYPE_DEMOLITION,WEAPON_TYPE_WHOKNOWS)

        endif

        set triggerUnit = null

    endmethod

    private static method enteredRegion takes nothing returns nothing

        local thistype this = GetTriggerData(GetTriggeringTrigger())
        local unit triggerUnit = GetTriggerUnit()

        if (not IsUnitAlly(triggerUnit,GetOwningPlayer(this.caster))) and UnitAlive(triggerUnit) then

            call GroupAddUnit(this.targetGroup, triggerUnit)

        endif

    endmethod

    private static method leftRegion takes nothing returns nothing

        local thistype this = GetTriggerData(GetTriggeringTrigger())

        call GroupRemoveUnit(this.targetGroup, GetTriggerUnit())

    endmethod

    private static method damageTick takes nothing returns nothing
        local thistype this = GetTimerData(GetExpiredTimer())
        local integer index = 0
        local integer endIndex = BlzGroupGetSize(this.targetGroup)

        set this.duration = this.duration - this.period

        call thistype.soundEffect2.runPoint(GetRectCenterX(this.dummyRect),GetRectCenterY(this.dummyRect),0.00)

        loop
            exitwhen index >= endIndex
            
            call UnitDamageTarget(this.caster, BlzGroupUnitAt(this.targetGroup,index), this.damagePerPeriod, false,false,ATTACK_TYPE_CHAOS,DAMAGE_TYPE_UNKNOWN,WEAPON_TYPE_WHOKNOWS)

            set index = index + 1
        endloop

        if (duration > 0.00 and period <= duration) then
            call TimerStart(this.damageTimer,period,false, function thistype.damageTick)
        else
            call this.destroy()
        endif

    endmethod

    private static method move takes nothing returns nothing

        local thistype this = GetTimerData(GetExpiredTimer())
        local real dummyX = GetUnitX(this.dummy) + velocity*Cos(this.angle)
        local real dummyY = GetUnitY(this.dummy) + velocity*Sin(this.angle)
        local real calculatedTime
        local effect dummyEffect = null
        local ubersplat dummyUbersplat = null

        call SetUnitX(this.dummy, dummyX)
        call SetUnitY(this.dummy, dummyY)
        
        set this.timedLife = this.timedLife - MOVEMENT_PERIOD
        
        call MoveRectTo(this.dummyRect, dummyX,dummyY)
        call RegionAddRect(this.damageRegion, this.dummyRect)

        set this.counter = this.counter + 1

        if this.timedLife > 0.00 then

            if this.counter >= RARETY_OF_EFFECTS then
                set this.counter = 0

                set calculatedTime = this.timedLife + this.duration - MOVEMENT_TIMED_LIFE

                set dummyEffect = AddSpecialEffect(EFFECT_PATH,dummyX,dummyY)
                call BlzSetSpecialEffectYaw(dummyEffect, this.angle)

                call DestroyEffectTimed(dummyEffect,calculatedTime) 
                
                set dummyUbersplat = CreateUbersplat(dummyX,dummyY,UBERSPLAT_NAME,255,255,255,255,false,true)
                call SetUbersplatRender(dummyUbersplat,true)
                call ShowUbersplat(dummyUbersplat,true)

                call DestroyUbersplatTimed(dummyUbersplat, calculatedTime)

                call thistype.soundEffect.runPoint(dummyX,dummyY,BlzGetLocalUnitZ(this.dummy))

                set dummyEffect = null

            endif

            call TimerStart(this.spellTimer, MOVEMENT_PERIOD, false, function thistype.move)

        else

            call RemoveUnit(this.dummy)

        endif

    endmethod

    public static method create takes unit caster, real damage, real damagePerPeriod, real period, real duration, real radius, real range, real angle returns thistype

        local thistype this = thistype.allocate()
        local real casterX = GetUnitX(caster)
        local real casterY = GetUnitY(caster)
        local real smallRadius = radius/ SquareRoot(2)

        set this.damage = damage
        set this.damagePerPeriod = damagePerPeriod
        set this.period = period
        set this.duration = duration
        set this.angle = angle*bj_DEGTORAD

        set this.velocity = range*thistype.MOVEMENT_PERIOD
        set this.timedLife = MOVEMENT_TIMED_LIFE
        set this.counter = 0

        set this.caster = caster
        set this.dummy = CreateUnit(GetOwningPlayer(caster),DUMMY_ID,casterX,casterY,angle)

        set this.targetGroup = CreateGroup()
        set this.dummyRect = Rect(smallRadius,smallRadius,smallRadius,smallRadius)
        set this.damageRegion = CreateRegion()
        call MoveRectTo(this.dummyRect,casterX,casterY)

        set this.collisionTrigger = NewTriggerEx(this)
        set this.enterRegion = NewTriggerEx(this)
        set this.leaveRegion = NewTriggerEx(this)

        set this.spellTimer = NewTimerEx(this)
        set this.damageTimer = NewTimerEx(this)
        
        call TriggerAddAction(this.collisionTrigger,function thistype.newTarget)
        call TriggerAddAction(this.enterRegion, function thistype.enteredRegion)
        call TriggerAddAction(this.leaveRegion, function thistype.leftRegion)
        call TriggerRegisterEnterRegion(this.enterRegion, this.damageRegion, null)
        call TriggerRegisterLeaveRegion(this.leaveRegion, this.damageRegion, null)
        call TriggerRegisterUnitInRange(this.collisionTrigger,this.dummy,radius,null)
    
        call TimerStart(this.spellTimer,MOVEMENT_PERIOD, false, function thistype.move)
        call TimerStart(this.damageTimer,RMinBJ(duration,period),false, function thistype.damageTick)

        return this

    endmethod

    public method destroy takes nothing returns nothing

        call DestroyGroup(this.targetGroup)
        call RemoveRegion(this.damageRegion)
        call RemoveRect(this.dummyRect)
        call RemoveUnit(this.dummy)
        call PauseTimer(this.spellTimer)
        call PauseTimer(this.damageTimer)
        call DestroyTimer(this.spellTimer)
        call DestroyTimer(this.damageTimer)
        call DestroyTrigger(this.collisionTrigger)
        call DestroyTrigger(this.enterRegion)
        call DestroyTrigger(this.leaveRegion)

        set this.dummy = null
        set this.caster = null
        set this.spellTimer = null
        set this.damageTimer = null
        set this.targetGroup = null
        set this.collisionTrigger = null
        set this.dummyRect = null
        set this.damageRegion = null
        set this.enterRegion = null
        set this.leaveRegion = null

        call this.deallocate()

    endmethod

    private static method onInit takes nothing returns nothing

        set thistype.soundEffect = NewSound(SOUND_EFFECT_PATH,2818,false,true)
        set thistype.soundEffect2 = NewSound(SOUND_EFFECT2_PATH,1500,false,true)

    endmethod

endstruct