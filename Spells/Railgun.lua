Railgun = {
    __index = self,
    checkRect = Rect(0,0,0,0),
    foundDestructable = false
}

function Railgun:new(object)

    object = object or {}
    setmetatable(object, self)

    self.range = 0
    self.startX = 0
    self.startY = 0
    self.startZ = 0
    self.angleX_Y = 0
    self.angleXY_Z = 0
    self.checkRadius = 0
    self.checkDistance = 0
    self.visualizer = Railgun.Visualizer:new()
    self.beam = Railgun.Beam:new()
    self.checker = Railgun.Checker

    return object

end

Railgun.Visualizer = {}

function Railgun.Visualizer:new(object)

    object = object or {}
    setmetatable(object,self)
    self.__index = self

    self.zOffset = 0
    self.visualDistance = 0
    self.modelPath = nil
    self.destructFilter = nil
    self.visualizerGroup = Group.SpecialEffect:Create()

    return object

end

function Railgun.Visualizer:destroy()

    local endIndex = self.visualizerGroup:GetSize()

    self.visualizerGroup:Execute(DestroyEffect)
    self.visualizerGroup:Destroy()

    self.visualizerGroup = nil
    self.destructFilter = nil
    self = nil

end

function Railgun.Visualizer:execute()

    local endIndex = self:getEndIndex()

    local targetX = self.startX
    local targetY = self.startY
    local targetZ = self.startZ

    local offsetX = self.visualDistance*Cos(self.angleXY_Z)*Cos(self.angleX_Y)
    local offsetY = self.visualDistance*Cos(self.angleXY_Z)*Sin(self.angleX_Y)
    local offsetZ = self.visualDistance*Sin(self.angleXY_Z)
    
    for index = 0, endIndex, 1 do

        targetX = targetX + offsetX    
        targetY = targetY + offsetY    
        targetZ = targetZ + offsetZ    

        local visualizer = AddSpecialEffect(self.modelPath,targetX,targetY)
        BlzSetSpecialEffectHeight(visualizer,targetZ - BlzGetLocalSpecialEffectZ(visualizer) + self.zOffset)
        self.visualizerGroup:AddEffect(visualizer)

    end

end

Railgun.Beam = {
    
}