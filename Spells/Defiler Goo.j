
globals
    string      GOO_MODEL       = ""
endglobals

struct DefilerGoo

    private static  hashtable           Indentifier = InitHashtable()
    private unit        defiler
    private trigger     defilerDeath
    private trigger     gooDamageRegister
    private trigger     gooDamageUnregister
    private timer       defilerTrackMovement
    private timer       damageTimer
    private region      gooRegion
    private group       damageGroup

    private static method AddToRegion takes nothing returns nothing
        local thistype      this        = LoadInteger(thistype.Indentifier, 0, GetHandleId(GetExpiredTimer()))

        call AddSpecialEffect(GOO_MODEL, GetUnitX(this.defiler), GetUnitY(this.defiler))
        call RegionAddCell(this.gooRegion, GetUnitX(this.defiler), GetUnitY(this.defiler))
    endmethod

    private static method Register takes nothing returns nothing
        local thistype      this        = LoadInteger(thistype.Indentifier, 0, GetHandleId(GetTriggeringTrigger()))
        local unit          target      = GetTriggerUnit()

        if target != this.defiler then 
            call GroupAddUnit(this.damageGroup, target)    
        endif

    endmethod

    private static method Unregister takes nothing returns nothing
        local thistype      this        = LoadInteger(thistype.Indentifier, 0, GetHandleId(GetTriggeringTrigger()))

        call GroupRemoveUnit(this.damageGroup, GetTriggerUnit())
    endmethod

    private static method Death takes nothing returns nothing
        local thistype      this        = LoadInteger(thistype.Indentifier, 0, GetHandleId(GetTriggeringTrigger()))

        call this.destroy()
    endmethod

    private static method Damage takes nothing returns nothing
        local thistype      this        = LoadInteger(thistype.Indentifier, 0, GetHandleId(GetExpiredTimer()))
        local integer       index       = 0
        local integer       endIndex    = BlzGroupGetSize(this.damageGroup)

        loop
            exitwhen index >= endIndex

            call UnitDamageTarget(this.defiler, BlzGroupUnitAt(this.damageGroup,index),50.0, false, false, ATTACK_TYPE_PIERCE, DAMAGE_TYPE_ACID, WEAPON_TYPE_WHOKNOWS)

            set index = index + 1
        endloop
        
    endmethod

    public static method create takes unit defiler returns thistype
        local thistype  this            = thistype.allocate()

        set this.defiler                = defiler
        set this.gooRegion              = CreateRegion()
        set this.gooDamageRegister      = CreateTrigger()
        set this.gooDamageUnregister    = CreateTrigger()
        set this.defilerDeath           = CreateTrigger()
        set this.defilerTrackMovement   = CreateTimer()
        set this.damageTimer            = CreateTimer()
        set this.damageGroup            = CreateGroup()

        call SaveInteger(thistype.Indentifier, 0, GetHandleId(this.defiler), this)
        call SaveInteger(thistype.Indentifier, 0, GetHandleId(this.gooDamageRegister), this)
        call SaveInteger(thistype.Indentifier, 0, GetHandleId(this.gooDamageUnregister), this)
        call SaveInteger(thistype.Indentifier, 0, GetHandleId(this.defilerDeath),this)
        call SaveInteger(thistype.Indentifier, 0, GetHandleId(this.damageTimer),this)
        call SaveInteger(thistype.Indentifier, 0, GetHandleId(this.defilerTrackMovement),this)

        call TimerStart(this.defilerTrackMovement,0.02,true, function thistype.AddToRegion)
        call TimerStart(this.damageTImer, 1.00, true, function thistype.Damage)

        call TriggerRegisterEnterRegion(this.gooDamageRegister, this.gooRegion, null)
        call TriggerRegisterLeaveRegion(this.gooDamageUnregister, this.gooRegion, null)
        call TriggerRegisterUnitEvent(this.defilerDeath, this.defiler, EVENT_UNIT_DEATH)

        call TriggerAddAction(this.gooDamageRegister, function thistype.Register)
        call TriggerAddAction(this.gooDamageUnregister, function thistype.Unregister)
        call TriggerAddAction(this.defilerDeath, function thistype.Death)

        return this
    endmethod

    public method destroy takes nothing returns nothing
        call RemoveSavedInteger(thistype.Indentifier, 0, GetHandleId(this.defiler))
        call RemoveSavedInteger(thistype.Indentifier, 0, GetHandleId(this.gooDamageRegister))
        call RemoveSavedInteger(thistype.Indentifier, 0, GetHandleId(this.gooDamageUnregister))
        call RemoveSavedInteger(thistype.Indentifier, 0, GetHandleId(this.defilerDeath))
        call RemoveSavedInteger(thistype.Indentifier, 0, GetHandleId(this.defilerTrackMovement))

        call RemoveRegion(gooRegion)
        call DestroyTrigger(defilerDeath)
        call DestroyTrigger(gooDamageRegister)
        call DestroyTrigger(gooDamageUnregister)
        call DestroyTimer(defilerTrackMovement)
        call DestroyGroup(damageGroup)
    endmethod

endstruct