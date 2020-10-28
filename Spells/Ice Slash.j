
struct IceSlash

    private static group damageGroup

    public static method execute takes unit caster, real radius, real angle, real angleOfEffect, real damage returns nothing

        local integer unitAmount
        local integer unitIndex     = 0
        local real casterX          = GetUnitX(caster)
        local real casterY          = GetUnitY(caster)
        local real targetX
        local real targetY
        local real angleDifference 
        local unit target           

        call GroupEnumUnitsInRange(thistype.damageGroup, casterX, casterY, radius,null)
        set unitAmount = BlzGroupGetSize(thistype.damageGroup)
        set angleOfEffect = angleOfEffect * bj_DEGTORAD / 2.00
        set angle = angle * bj_DEGTORAD

        loop

            exitwhen unitIndex >= unitAmount

            set target = BlzGroupUnitAt(thistype.damageGroup,unitIndex)
            set targetX = GetUnitX(target)
            set targetY = GetUnitY(target)
            set angleDifference = angle - Atan2(targetY-casterY,targetX-casterX)

            if (angleDifference <= angleOfEffect) and (angleDifference >= -angleOfEffect) then
                call UnitDamageTarget(caster,target,damage,false,false,ATTACK_TYPE_CHAOS,DAMAGE_TYPE_COLD,WEAPON_TYPE_WHOKNOWS)
            endif

            set unitIndex = unitIndex + 1
        endloop

        set target = null

    endmethod

    private static method onInit takes nothing returns nothing

        set thistype.damageGroup = CreateGroup()

    endmethod

endstruct