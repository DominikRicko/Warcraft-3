library Railgun requires TimerUtils

//==================================================================================================
//---------------------------------Railgun-----by-Insanity_AI---------------------------------------
//==================================================================================================
/*/*    DISCLAIMER:         This spell visually works better on 1.30 PTR                        */*/
/*/*                  Primarily because of BlzGetLocalUnitZ() working properly there...         */*/
//
//  Setup:  Create a Railgun ability and modify trigger spell condition.
//          Create a dummy unit for trajectory visualizaton. 
//          Make sure to match those objectIDs with configuration settings in here:
//          Primarily in SpellCondition() and in the Visuals category; VISUALIZATION_ID
/*          Make sure that you have a /*/*Unit Indexer*/*/ in your map.                         
*/
//  A bit of configuration info:
//          You can edit in the Configuration Section just down below.
//          Each configurable function or variable has a little comment describing what it does.
//          There are also functions that are responsible for damaging units, killing destructables,
//          And blacklisting them, those are all at your disposal.
//          I added a lot of visual configuration, I'm pretty sure you can use things like GetTriggerUnit()
//          in there, so I'm pretty sure that alone opens a lot of doors and posibilities.
//
//  About the damage:
//          At the moment it deals percentage of target's max health.
//          The damage is stacked on the target depending on how close they're to the beam,
//          which is determined by the RADIUS.
//          It goes up from 0% to 90%(in configuration) depending on how close the target is
//          to the beam.
//
//  Limitation: 
//          It will shoot through terrain hills, so I'd suggest using some sort of pathingblockers
//          ... that is, unless you don't want this intended interaction (or lack of.)
//
//  Modifications: 
//          Cast time, cooldown and mana cost is edited in the object editor,
//          as for the other things, they're editable right here.
//
//==================================================================================================
    globals
        private real        array   angle
        private real        array   offsetZ
        private group       array   visualizers
        private lightning   array   beam
        private real        array   fadeOutDuration
        private real        array   fadeOutRate
        private real        array   fadeOutPeriod
        private boolean     array   stopPoint
    
        private trigger     cast                        = CreateTrigger()
        private trigger     stop                        = CreateTrigger()
        private trigger     fire                        = CreateTrigger()
        private boolexpr    destructFilter		        = null
        private boolexpr    unitFilter		            = null
        private boolexpr    castFunction                = null
        private boolexpr    stopFunction                = null
        private boolexpr    fireFunction                = null
    endglobals
    
    /*-----------------------------------------------------------------------------*/
    /*========================Configuration Section================================*/
    /*-----------------------------------------------------------------------------*/
    
    //A little foreword; All of these functions have access to GetTriggerUnit() and GetSpellAbilityId(),
    //and with such, opens many customization options. 
    //No need for have the library twice to make 2 different spells, is what I am saying.
    private function SpellCondition takes nothing returns boolean
        return (GetSpellAbilityId() == 'A000')
    endfunction
        
    private function GetRange takes nothing returns real   
        //Range to where the railgun shoots
        return 4000.00
    endfunction

    private function GetRadius takes nothing returns real
        //Railgun's visualizer area check for destructables and units
        return 100.00    
    endfunction

    private function GetBeamStepDistance takes nothing returns real
        //Distance-step to check for beam's object blockers
        //Eg. A tree.
        return 40.00 
    endfunction
    
    /*/*/*----------------------------------------------------------------------*/*/*/
    /*/*/*===========================Visuals====================================*/*/*/
    /*/*/*----------------------------------------------------------------------*/*/*/
    globals
        //UnitID of Railgun Trajectory visualization
        private integer     VISUALIZATION_ID        = 'n000'        
        private integer     VISUALIZATION_PLAYER    = PLAYER_NEUTRAL_PASSIVE
        private string      VISUAL_HIT_MODEL        = "Objects\\Spawnmodels\\NightElf\\NECancelDeath\\NECancelDeath.mdl"
        //Aka, how many lightnings does 1 beam contain, stacked up on 1 another.
        private integer     MAXLIGHTNINGCOUNT       = 5
            //- After a lot of thinking, I decided to put this back into variable form, because having multiple spells
            //with different lightningcounts, would cause interference in the lightning array.
    endglobals
    
    private function FadeOut takes nothing returns boolean
        //Would you like the railgun beam to fade out rather than just dissapear
        return true
    endfunction
    
    private function GetBeamDuration takes nothing returns real
        //Time before the railgun beam is removed from the map
        //I should note that you shouldn't cast another beam from the same unit, until this time has passed
        //So, set spell cooldown accordingly
        return 0.2
    endfunction
    
    private function GetFadeOutPeriod takes nothing returns real
        //In what intervals will it apply the fade out rate
        return 0.04
    endfunction
    
    private function GetFadeOutRate takes nothing returns real
        //By how much does the beam fade out per period,
        //(remember lightning colour, including alpha channel, goes from 0.00 to 1.00)
        //also if duration is lower than period, the beam will just dissapear instead, regardless if you have FadeOut as true.
        return 0.2
    endfunction
    
    private function GetVisualizationDistance takes nothing returns real
        //Distance between each of the visualization lights 
        return 266.00  
    endfunction
    
    private function GetLightningName takes nothing returns string
        // Change beam's lightning model, would suggest vanilla DRAM, DRAL, DRAB and LEAS models
        //Other models don't retain a "beam" sort of structure.
        return "LEAS"
    endfunction
    
    private function SetBeamColor takes lightning beam returns nothing
        //The real values are by order: Red, Green, Blue, Alpha
        //And take values from 0.00  to 1.00, apparently.
        //Now this won't change the beam to actual color, but just reduce the amount of colour the lightning
        //model already has. If you're unsatisfied with the results this gives you, try a different model.
        call SetLightningColor(beam,1.00,1.00,0.75,1.00)
        set beam                                    = null
    endfunction

    private function GetLightningVisualHeightOffset takes nothing returns real
        //Visual Z offset for the lightning.
        return 60.00
    endfunction
    
    private function GetCastAnimation takes nothing returns string
    //Used when the caster is prepearing to fire
        return "stand ready"
    endfunction
    
    private function GetFireAnimation takes nothing returns string
    //Used when caster is firing
        return "spell"
    endfunction
    
    private function GetStandAnimation takes nothing returns string
    //Queued after firing
        return "stand"
    endfunction
    
    /*/*/*----------------------------------------------------------------------*/*/*/
    /*/*/*=====================End of Visuals===================================*/*/*/
    /*/*/*----------------------------------------------------------------------*/*/*/
    
    private function UnitBlacklist takes nothing returns boolean
        //Any unit or unit-type you want it to be immune to this? You can add it here.
        return true
    endfunction
        
    private function DamageVictims takes real squaredDistance returns nothing
    //Function responsible for damaging units, you can edit this however you'd like.
    //squaredDistance is the distance of the unit from the beam... squared.
        local unit target                       = GetEnumUnit()
        local unit caster                       = GetTriggerUnit()
        local real maxRangeSquared              = Pow(GetRadius(),2)
        local real damage 

        if(target !=  caster)then
            set damage                          = (maxRangeSquared - squaredDistance)/maxRangeSquared
            if damage > 0.90 then  
                set damage                      = 0.90
            endif
            set damage                          = damage * GetUnitState(target,UNIT_STATE_MAX_LIFE)
            call UnitDamageTarget(caster,target,damage,true,false,ATTACK_TYPE_CHAOS,DAMAGE_TYPE_UNKNOWN,WEAPON_TYPE_WHOKNOWS)
            call DestroyEffect(AddSpecialEffectTarget(VISUAL_HIT_MODEL,target,"chest"))
        endif
        
        set target                              = null
        set caster                              = null
    endfunction

    private function DestructableBlacklist takes nothing returns boolean
    //Any additions you'd like to add here?
        local integer   destructType            = GetDestructableTypeId(GetFilterDestructable())
        
        //if the destructable is alive and is not a pathblocker of any kind.
        if GetDestructableLife(GetFilterDestructable()) <= 0 then 
            return false
        endif
        set stopPoint[GetUnitUserData(GetTriggerUnit())]          = true
        return not((destructType == 'YTlb') or (destructType == 'YTab') or (destructType == 'YTpb') or (destructType == 'YTfb'))
    endfunction

    private function DestructSearchAndDestroy takes nothing returns nothing
        //How destructables are being destroyed.
        call SetDestructableLife(GetEnumDestructable(), 0.00)
    endfunction

    /*-----------------------------------------------------------------------------*/
    /*===================End of configuration section==============================*/
    /*-----------------------------------------------------------------------------*/
    
      private function CheckUnitTarget takes nothing returns nothing
        local unit target                       = GetEnumUnit()
        local real targetX                      = GetUnitX(target)
        local real targetY                      = GetUnitY(target)
        local unit caster                       = GetTriggerUnit()
        local real casterX                      = GetUnitX(caster)
        local real casterY                      = GetUnitY(caster)
        local integer casterData                = GetUnitUserData(caster)
        local real maxRangeSquared              = Pow(GetRadius(),2)
        local real angleT                       = Atan2(targetY-casterY,targetX-casterX) - angle[casterData]
        local real targetDistance
        
        //Ignore units that are behind the caster.
        if not(angleT < bj_PI/2 and angleT > -bj_PI/2) then
            set target                          = null
            set caster                          = null
            return 
        endif
        
        //A slightly modified Distance between a line and a point formula 
        //Ax + By + C = 0 => -ax + y + b = 0 from y = ax - b, where a = tan(angle) and b = a(x1) - y1
        //Formula: |Ax + By + C|/Sqrt(A^2 + B^2)=> ((-ax + y + b)^2)/(a^2 + 1)
        set angleT                              = Tan(angle[casterData])
        set targetDistance                      = Pow(-angleT*targetX + targetY + angleT*casterX - casterY,2)/(Pow(angleT,2) + 1)
        if targetDistance > maxRangeSquared then
            set target                          = null
            set caster                          = null
            return
        endif
        
        //If it checks out, damage it
        call DamageVictims(targetDistance)
        set target                          = null
        set caster                          = null
    endfunction
    
    private function GetVisualizationStopIndex takes nothing returns integer
        return R2I(GetRange()/GetVisualizationDistance())
    endfunction
    
    private function GetBeamStopIndex takes nothing returns integer
        return R2I(GetRange()/GetBeamStepDistance())
    endfunction
        
    private function Cast takes nothing returns nothing
        local unit      caster                  = GetTriggerUnit()          
        local rect      destructCheckRect       = Rect(0,0,0,0)  
        local unit      visualizer              = null
        local group     visualizerGroup         = CreateGroup()

        local real      casterX                 = GetUnitX(caster)
        local real      casterY                 = GetUnitY(caster)
        local real      casterZ                 = BlzGetLocalUnitZ(caster)
        local real      targetX                 = GetSpellTargetX()
        local real      targetY                 = GetSpellTargetY()
        local real      targetZ                
       
        local real      range                   = GetRange()
        local real      visualDistance          = GetVisualizationDistance()
        local real      radius                  = GetRadius()
        
        local integer   iteration               = 1
        local integer   iterationEnd            = GetVisualizationStopIndex()
        local integer   casterData              = GetUnitUserData(caster)
        
        local real      offsetX      
        local real      offsetY
        
        call SetUnitAnimation(caster, GetCastAnimation())
        set angle[casterData]                   = Atan2(targetY-casterY,targetX-casterX)
        set offsetX                             = visualDistance*Cos(angle[casterData])  
        set offsetY                             = visualDistance*Sin(angle[casterData])
        
        set visualizers[casterData]             = CreateGroup()
        set stopPoint[casterData]               = false

        loop
            exitwhen iteration > iterationEnd
            set targetX                         = casterX + offsetX*I2R(iteration)
            set targetY                         = casterY + offsetY*I2R(iteration) 
            
            set visualizer                      = CreateUnit(Player(VISUALIZATION_PLAYER),VISUALIZATION_ID,targetX,targetY,angle[casterData])
            call GroupAddUnit(visualizerGroup,visualizer)
            
            call SetRect(destructCheckRect,targetX-radius,targetY-radius,targetX+radius,targetY+radius)
            call EnumDestructablesInRect(destructCheckRect,destructFilter, null)
            
            exitwhen stopPoint[casterData]
            set iteration                       = iteration +1
        endloop
            
        set targetZ                             = BlzGetLocalUnitZ(visualizer)
        set offsetZ[casterData]                 = (targetZ - casterZ)/range 
        
        set iteration                           = 1
        loop
            set visualizer                      = FirstOfGroup(visualizerGroup)
            exitwhen visualizer == null
            
            call UnitAddAbility(visualizer,'Amrf')
            call SetUnitFlyHeight(visualizer,offsetZ[casterData] * I2R(iteration) + casterZ - BlzGetLocalUnitZ(visualizer) ,0.00)
            call UnitRemoveAbility(visualizer,'Amrf')
            
            set iteration                       = iteration + 1
            call GroupRemoveUnit(visualizerGroup,visualizer)
            call GroupAddUnit(visualizers[casterData],visualizer)
        endloop
            
        call RemoveRect(destructCheckRect)
        call DestroyGroup(visualizerGroup)
        
        set visualizerGroup                     = null 
        set visualizer                          = null
        set caster                              = null
        set destructCheckRect                   = null    
    endfunction


    private function Stop takes nothing returns nothing
        //in case the caster stops casting the railgun
        local integer   casterData              = GetUnitUserData(GetTriggerUnit())
        local unit      dummy                   = null
        
        loop   
            set dummy                           = FirstOfGroup(visualizers[casterData])
            exitwhen (dummy == null)
            call GroupRemoveUnit(visualizers[casterData],dummy)
            call RemoveUnit(dummy)
        endloop
        call DestroyGroup(visualizers[casterData])

        set dummy                               = null
        set visualizers[casterData]             = null
    endfunction


    private function FireCleanup takes nothing returns nothing
        local timer     t                       = GetExpiredTimer()
        local integer   casterData              = GetTimerData(t)
        local integer   iteration               = 0
        local integer   endIteration            = MAXLIGHTNINGCOUNT
        
        loop
            exitwhen iteration >= endIteration
            call DestroyLightning(beam[casterData*endIteration + iteration])
            set iteration                       = iteration + 1
        endloop
        
        call ReleaseTimer(t)
        set t                                   = null
    endfunction
    
    private function FireFadeOut takes nothing returns nothing
        local timer     t                       = GetExpiredTimer()
        local integer   casterData              = GetTimerData(t)
        local integer   iteration               = 0
        local integer   endIteration            = MAXLIGHTNINGCOUNT
        local lightning localBeam               = null
        
        set fadeOutDuration[casterData]         = fadeOutDuration[casterData] - fadeOutPeriod[casterData]
        
        if fadeOutDuration[casterData] <= 0.00 then
            call PauseTimer(t)
            call FireCleanup()
        endif
        
        loop
            exitwhen iteration >= endIteration
            set localBeam                       = beam[casterData*endIteration+iteration]
            call SetLightningColor(localBeam, GetLightningColorR(localBeam),GetLightningColorG(localBeam),GetLightningColorB(localBeam),GetLightningColorA(localBeam)- fadeOutRate[casterData])
            set iteration                       = iteration + 1
        endloop
        
        set t                                   = null
        set localBeam                           = null
    endfunction

    private function Fire takes nothing returns nothing
        local unit      caster                  = GetTriggerUnit()
        local integer   casterData              = GetUnitUserData(caster)
        local timer     t                       = NewTimerEx(casterData)
        local rect      multipurposeRect        = Rect(0,0,0,0)
        local group     victims                 = CreateGroup()
        
        local real      lightningZOffset        = GetLightningVisualHeightOffset()
        
        local real      casterX                 = GetUnitX(caster)
        local real      casterY                 = GetUnitY(caster)
        local real      casterZ                 = BlzGetLocalUnitZ(caster) + lightningZOffset

        local real      stepDistance            = GetBeamStepDistance()
        local real      radius                  = GetRadius()
        local string    lightningName           = GetLightningName()

        local real      offsetX                 = stepDistance*Cos(angle[casterData])
        local real      offsetY                 = stepDistance*Sin(angle[casterData])
        
        local real      rectX                   
        local real      rectY
        
        local integer   iteration               = 0
        local integer   endIteration            = MAXLIGHTNINGCOUNT
        
        local real      targetX
        local real      targetY
        local real      targetZ 
        
        set stopPoint[casterData]               = false
        
        //visual appeal
        call SetUnitAnimation(caster, GetFireAnimation())
        call QueueUnitAnimation(caster, GetStandAnimation())
        
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
    
    private function Cast_Wrapper takes nothing returns boolean
        if SpellCondition() then
            call Cast()
            return true
        endif
        return false
    endfunction

    private function Stop_Wrapper takes nothing returns boolean
        if SpellCondition() then
            call Stop()
            return true
        endif
        return false
    endfunction

    private function Fire_Wrapper takes nothing returns boolean
        if SpellCondition() then
            call Fire()
            return true
        endif
        return false
    endfunction
    //================================================================================
    function InitTrig_Railgun takes nothing returns nothing
        
        //this is so that the system knows when to stop the railgun. Value depends on 3 pre-set constants.
        set destructFilter                      = Filter(function DestructableBlacklist)
        set unitFilter                          = Filter(function UnitBlacklist)
        
        set castFunction                        = Condition(function Cast_Wrapper)
        set stopFunction                        = Condition(function Stop_Wrapper)
        set fireFunction                        = Condition(function Fire_Wrapper)
        
        //Cast the Railgun
        call TriggerRegisterAnyUnitEventBJ(cast, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
        call TriggerAddCondition(cast, castFunction)
        
        //Stop the Railgun
        call TriggerRegisterAnyUnitEventBJ(stop, EVENT_PLAYER_UNIT_SPELL_ENDCAST )
        call TriggerAddCondition(stop, stopFunction)
        
        //Be the... no wait, Fire the Railgun
        call TriggerRegisterAnyUnitEventBJ(fire, EVENT_PLAYER_UNIT_SPELL_FINISH)
        call TriggerAddCondition(fire, fireFunction)
        
        call Preload(VISUAL_HIT_MODEL)
    endfunction
endlibrary