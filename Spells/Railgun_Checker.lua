Railgun_Checker = {

    checkRect = Rect(0,0,0,0), unitGroup = CreateGroup(), groupID,

    check2D = function(range,checkDistance,filterTable,checkRadius,angleX_Y,originX,originY)       
    
        if type(filterTable) == "table" then
            
            local unitFilter, destructFilter, itemFilter = table.unpack(filterTable)

        end

        local offsetX = checkDistance*Cos(angleX_Y)  
        local offsetY = checkDistance*Sin(angleX_Y)
        
        local targetX = originX
        local targetY = originY

        local index = 0
        local endIndex = R2I(range/checkDistance)

        railgunTargetGroup = Group:create()

        SetRect(railgun.checkRect, -checkRadius, -checkRadius, checkRadius, checkRadius)

        while index < endIndex do
            
            targetX = targetX + offsetX
            targetY = targetY + offsetY
            MoveRectTo(self.checkRect,targetX,targetY)

            EnumDestructablesInRect(self.checkRect,destructFilter, function() railgunTargetGroup:add(GetEnumDestructable()) end )
            EnumItemsInRect(self.checkRect,itemFilter, function() railgunTargetGroup:add(GetEnumItem()) end)
            GroupEnumUnitsInRange(self.unitGroup, targetX,targetY, checkRadius, unitFilter)
            ForGroup(self.unitGroup, function() railgunTargetGroup:add(GetEnumUnit()) end)

            index = index + 1
        end

        return range*index/endIndex, targetGroup 

    end
    ,

    check3D = function(range,checkDistance,filterTable,checkRadius,angleX_Y,originX,originY,angleXY_Z, originZ)       

        if type(filterTable) == "table" then
            
            local unitFilter, destructFilter, itemFilter = table.unpack(filterTable)

        end

        local offsetX = checkDistance*Cos(angleXY_Z)*Cos(angleX_Y)  
        local offsetY = checkDistance*Cos(angleXY_Z)*Sin(angleX_Y)
        local offsetZ = checkDistance*Sin(angleXY_Z)
        
        local targetX = originX
        local targetY = originY
        targetZ = originZ

        local index = 0
        local endIndex = R2I(range/checkDistance)

        railgunTargetGroup = Group:create()

        SetRect(railgun.checkRect, -checkRadius, -checkRadius, checkRadius, checkRadius)

        while index < endIndex do
            
            targetX = targetX + offsetX
            targetY = targetY + offsetY
            targetZ = targetZ + offsetZ

            if targetZ <= GetPointZ(targetX,targetY)  then

                break

            end

            MoveRectTo(self.checkRect,targetX,targetY)

            EnumDestructablesInRect(self.checkRect,destructFilter, DestructCheckZ )
            EnumItemsInRect(self.checkRect,itemFilter,ItemCheckZ)
            GroupEnumUnitsInRange(self.unitGroup, targetX,targetY, checkRadius, unitFilter)
            ForGroup(self.unitGroup, UnitCheckZ)

            index = index + 1
        end

        return range*index/endIndex, targetGroup 

    end
}

function DestructCheckZ()

    local destruct = GetEnumDestructable()

    if math.abs(GetPointZ(GetWidgetX(destruct), GetWidgetY(destruct)) - targetZ) < checkRadius then

        railgunTargetGroup:add(destruct)

    end

end

function ItemCheckZ()

    local item = GetEnumItem()

    if math.abs(GetPointZ(GetWidgetX(destruct), GetWidgetY(destruct)) - targetZ) < checkRadius then

        railgunTargetGroup:add(item)

    end

end

function UnitCheckZ()

    local unit = GetEnumUnit()

    if math.abs(BlzGetLocalUnitZ(unit) - targetZ) < checkRadius then

        railgunTargetGroup:add(unit)
    end
end
