
struct Beam

    private static rect checkRect
    private static bool isDestructableFound

    public real         startX
    public real         startY
    public real         startZ
    public real         angleX_Y
    public real         angleXY_Z
    public real         zOffset
    public real         range
    public real         checkDistance
    public real         checkRadius
    public boolexpr     destructFilter
    public string       lightningCode
    public integer      lightningAmount

    private unit        caster
    private group       targets

    private timer       fadeOutTimer

    private static method destructableFound takes nothing returns nothing
        set thistype.visualizer = true
        call KillDestructable(GetEnumDestructable())
    endmethod

    private method getEndIndex takes nothing returns integer

        local real offsetX = checkDistance*Cos(angleXY_Z)*Cos(angleX_Y)  
        local real offsetY = checkDistance*Cos(angleXY_Z)*Sin(angleX_Y)

        local real targetX = startX
        local real targetY = startY

        local integer index = 0
        local integer endIndex = R2I(range/checkDistance)

        set thistype.isDestructableFound = false

        loop

            exitwhen index >= endIndex

            set targetX = targetX + offsetX
            set targetY = targetY + offsetY
            
            call SetRect(checkRect,targetX-checkRadius,targetY-checkRadius,targetX+checkRadius,targetY+checkRadius)
            call EnumDestructablesInRect(destructCheckRect,destructFilter, function thistype.destructableFound)
            exitwhen thistype.isDestructableFound

            set index = index + 1

        endloop

        return index

    endmethod

    private method getTargets takes integer endIndex returns nothing
        
        local integer index = 0

        local real offsetX = checkDistance*Cos(angleXY_Z)*Cos(angleX_Y)  
        local real offsetY = checkDistance*Cos(angleXY_Z)*Sin(angleX_Y)

        local real targetX = startX
        local real targetY = startY

        local group unitsInRange = CreateGroup()

        set targets = CreateGroup()

        loop
            exitwhen index >= endIndex

            call GroupEnumUnitsInRange(unitsInRange,targetX,targetY,checkRadius,null)

            call BlzGroupAddGroupFast(targets,unitsInRange)

            set targetX = targetX + offsetX
            set targetY = targetY + offsetY

            set index = index + 1
        endloop

    endmethod

    public static method create takes unit caster returns thistype

        local thistype this = thistype.allocate()

        set this.caster = caster

        return this

    endmethod

    public static method execute takes nothing returns nothing

        local integer endIndex = getEndIndex()    
        local unit target
        local integer index = 0
        local real endX = startX + range*Cos(angleXY_Z)*Cos(angleX_Y)
        local real endY = startY + range*Cos(angleXY_Z)*Sin(angleX_Y)
        local real endZ = startZ + range*Sin(angleXY_Z)
        local lightning newLightningEffect

        call getTargets(endIndex)
        set endIndex = BlzGroupGetSize(targets)

        loop
            exitwhen index >= endIndex

            set target = BlzGroupUnitAt(targets, index)

            call UnitDamageTarget(caster, target, amount, false, false, ATTACK_TYPE_CHAOS, DAMAGE_TYPE_UNKNOWN, WEAPON_TYPE_WHOKNOWS)

            set index = index + 1
        endloop

        set index = 0
        set endIndex = lightningAmount


        loop
            exitwhen index >= endIndex

            set newLightningEffect = AddLightningEx(lightningCode ,true ,endX ,endY ,endZ ,startX ,startY ,startZ)
            call DestroyLightningTimed(newLightningEffect,1.00)

            set index = index + 1
        endloop

    endmethod

    public method destroy takes nothing returns nothing
        
        call DestroyGroup(targets)
        call DestroyTimer(fadeOutTimer)

        set destructFilter = null
        set caster = null
        set targets = null
        set fadeOutTimer = null
        
    endmethod

endstruct




    private function Fire takes nothing returns nothing
        
        local real      rectX                   
        local real      rectY
        
        local integer   iteration               = 0
        local integer   endIteration            = MAXLIGHTNINGCOUNT
        
        local real      targetX
        local real      targetY
        local real      targetZ 
        
        set stopPoint[casterData]               = false
        
        loop
            exitwhen iteration >= endIteration
            set beam[casterData*endIteration + iteration] = AddLightningEx(lightningName ,true ,casterX,casterY ,0.00 ,casterX + 1.00,casterY + 1.00,0.00)
            
            set iteration                       = iteration + 1
        endloop
        
        set iteration                           = 1
        set endIteration                        = GetBeamStopIndex()
        loop
            exitwhen iteration >= endIteration
            set targetX                         = casterX + offsetX*I2R(iteration)
            set targetY                         = casterY + offsetY*I2R(iteration)
            
            call SetRect(multipurposeRect,targetX-radius,targetY-radius,targetX+radius,targetY+radius)
            call EnumDestructablesInRect(multipurposeRect,destructFilter, function DestructSearchAndDestroy)
            
            exitwhen stopPoint[casterData]
            set iteration                       = iteration +1
        endloop
        
        //OffsetX/Y is no longer used, so I'll repurpose them here!
        set offsetX                             = targetX
        set offsetY                             = targetY
        set rectX                               = casterX
        set rectY                               = casterY
        
        if targetX > casterX then
            set offsetX                         = casterX
            set rectX                           = targetX
        endif
        
        if targetY > casterY then
            set offsetY                         = casterY
            set rectY                           = targetY
        endif
        
        call SetRect(multipurposeRect,offsetX-radius,offsetY-radius,rectX+radius,rectY+radius)
        call GroupEnumUnitsInRect(victims,multipurposeRect,unitFilter) 
        call ForGroup(victims, function CheckUnitTarget)
        
        set targetZ                             = casterZ + offsetZ[casterData]*R2I(iteration)*stepDistance
        set iteration                           = 0
        set endIteration                        = MAXLIGHTNINGCOUNT
        
        loop 
            exitwhen iteration >= endIteration
            call MoveLightningEx(beam[casterData*endIteration + iteration],true,targetX,targetY,targetZ,casterX,casterY,casterZ)
            call SetBeamColor(beam[casterData*endIteration + iteration])
            set iteration                       = iteration + 1
        endloop
        
        if FadeOut() then
            set fadeOutDuration[casterData]     = GetBeamDuration()
            set fadeOutRate[casterData]         = GetFadeOutRate()
            set fadeOutPeriod[casterData]       = GetFadeOutPeriod()
            call TimerStart(t,GetFadeOutPeriod(),true,function FireFadeOut)
        else
            call TimerStart(t,GetBeamDuration(),false,function FireCleanup)
        endif
        
        call DestroyGroup(victims) 
        call RemoveRect(multipurposeRect)
        set caster                              = null
        set multipurposeRect                    = null
        set victims                             = null
        set t                                   = null
    endfunction