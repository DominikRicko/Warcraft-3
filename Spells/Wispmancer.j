globals
    private location           tempLocation            = Location(0,0)
endglobals

function GetLocalPointZ takes real x, real y returns real
    call MoveLocation(tempLocation,x,y)
    return GetLocationZ(tempLocation)
endfunction


interface Spell
    public method startEffect takes struct Wispomancer returns nothing
endinterface

struct Wips 
    private effect      wispModel                           = null
    public  real        x
    public  real        y
    public  real        z       

    public static method create takes string SFXPath, real x, real y, real z returns thistype
        local thistype this                                 = thistype.allocate()

        set this.wispModel                                  = AddSpecialEffect(SFXPath,x,y)
        set this.x                                          = x
        set this.y                                          = y
        set this.z                                          = z

        call BlzSetSpecialEffectZ(z)

        return this
    endmethod

    public method destroy takes nothing returns nothing
        call DestroyEffect(this.wispModel)
        call RemoveLocation(this.position)

        set this.wispModel                                  = null
        set this.position                                   = null
        call this.deallocate()
    endmethod

    public method playEffect takes animtype whichAnim, real timescale returns nothing
        call BlzPlaySpecialEffectWithTimeScale(this.wispModel,whichAnim,timescale)
    endmethod

endstruct

globals
    public constant string      WHIRLWIND_MODEL_PATH        = ""
endglobals

struct Wispomancer 
    public static  constant    integer MAX_WISPS           = 5

    private static  hashtable           unit2Wispomancer    = null

    private Wisp    array[MAX_WISPS]    wisps
    private integer                     wispCount  
    private unit                        wispomancerUnit

    public static method create takes unit newWispomancer returns thistype
        local thistype      this                            = thistype.allocate()

        set this.wispomancerUnit                            = newWispomancer
        set this.wispCount                                  = 0
        call SaveInteger(unit2Wispomancer,GetUnitTypeId(newWispomancer),GetHandleId(newWispomancer),this)

        return this
    endmethod

    public method destroy takes nothing returns nothing
        call RemoveSavedInteger(unit2Wispomancer)

        set this.wispomancerUnit                            = null
        call this.deallocate()
    endmethod

    public static method initialize takes nothing returns nothing
        if unit2Wispomancer == null then
            set unit2Wispomancer                            = InitHashtable()
        endif
    endmethod

    public method addWisp takes Wisp newWisp returns nothing
        if wispCount < MAX_WISPS then
            set wisps[wispCount]                            = newWisp
            set wispCount                                   = wispCount + 1
        else
            call DisplayTextToPlayer(GetOwningPlayer(wispomancer),0,0,"|cffFF0000Cannot how more than " + I2S(MAX_WISPS) + " wisps.|r")
        endif
    endmethod

    public method getWisp takes integer i returns Wisp wisp
        if i > MAX_WISPS then 
            return 0
        endif

        return wisps[i]
    endmethod

    public method GetWispomancer takes nothing returns unit
        return wispomancerUnit
    endmethod

endstruct

struct PlantWisp extends Spell
    private static constant string      defaultWispModel    = ""

    private string                      wispModel           
    private real                        x
    private real                        y

    public static method create takes real x, real y returns thistype
        local thistype  this                                = thistype.allocate()

        set this.x                                          = x
        set this.y                                          = y
        set this.wispModel                                  = thistype.defaultWispModel

        return this
    endmethod

    public method startEffect takes Wispomancer wispomancer returns nothing
        call wispomancer.addWisp(Wisp.create(wispModel,x,y,GetLocalPointZ(x,y)))
    endmethod

    public method destroy takes nothing returns nothing
        set this.wispModel                                  = null

        call this.deallocate()
    endmethod

    public method setModel takes string newModelPath returns nothing
        set wispModel                                       = newModelPath
    endmethod

    public method setNewPosition takes real x, real y returns nothing
        set this.x                                          = x
        set this.y                                          = y
    endmethod

endstruct



globals
    private unit            currentCaster       
    private real            damageAmount
endglobals

private function DealDamageToGroup takes nothing returns nothing
    call UnitDamageTarget(currentCaster, GetEnumUnit(),damageAmount,false,false,ATTACK_TYPE_MAGIC,DAMAGE_TYPE_MAGIC,WEAPON_TYPE_WHOKNOWS)
endfunction

private function interface DamageDistribution takes unit caster, real damage, real range, real x, real y, filterfunc targetFilter returns nothing

private function Uniform takes unit caster, real damage, real range, real x, real y, filterFunc targetFilter returns nothing
    local group         targetGroup                     = CreateGroup()

    set currentCaster                                   = caster
    set damageAmount                                    = damage
    call GroupEnumUnitsInRange(targetGroup,x,y,targetFilter)
    call ForGroup(targetGroup, function DealDamageToGroup)
    call DestroyGroup(targetGroup)
endfunction




struct DetonateWisps extends Spell

    public  Wispomancer                 caster    
    public  real                        damage             
    public  real                        range           
    public  DamageDistribution          damageFunc    
    public  filterfunc                  targetFilter

    public static method create takes Wispomancer caster returns thistype
        local thistype          this                    = thistype.allocate()

        set this.damage                                 = 100.0
        set this.range                                  = 100.0
        set this.damageFunc                             = DamageDistribution.Uniform
        set this.caster                                 = caster

        return this
    endmethod

    public method destroy takes nothing returns nothing
        call DestroyBoolExpr(targetFilter)
        call this.deallocate()
    endmethod

    public method startEffect takes Wispomancer wispomancer returns nothing

        local unit      spellCaster                     = caster.getWispomancer() 
        local Wisp      wisp    
        local integer   i                               = 0

        loop 
            exitwhen i < Wispomancer.MAX_WISPS

            set wisp                                    = spellCaster.getWisp(i)
            call damageFunc.Evaluate(spellCaster,damage,range,wisp.x,wisp.y, targetFilter)    

            set i                                       = i + 1
        endloop
        
    endmethod

endstruct

struct WispStorm extends Spell


    public static method create takes nothing returns thistype

    endmethod

    public method destroy takes nothing returns nothing

    endmethod

    



    public method startEffect takes struct Wispomancer returns nothing

    endmethod

endstruct






private function onInit takes nothing returns nothing
    call Wispomancer.initialize()
endfunction