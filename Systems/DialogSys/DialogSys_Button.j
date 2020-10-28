interface ButtonHelper
    public method ButtonClick takes nothing returns nothing
    public method ExecuteButton takes nothing returns nothing
endinterface

private struct SingleOptionButtonHelper extends ButtonHelper

    private SingleOptionButton  mainButton
    private integer             votes

    public static method create takes SingleOptionButton whatButtonStruct returns thistype

        local thistype this = thistype.allocate()

        set this.mainButton = whatButtonStruct
        set this.votes = 0

        return this

    endmethod

    public method ButtonClick takes nothing returns nothing
        set votes = votes + 1
    endmethod

endstruct

private struct MultiOptionButtonHelper extends ButtonHelper
    private MultiOptionButton   mainButton
    private integer             optionCount
    private integer             currentOption
    private integer array       votes[ButtonBuilder.MAX_BUTTONS]

    public static method create takes MultiOptionButton whatButtonStruct, integer optionCount returns thistype

        local thistype this = thistype.allocate()

        set this.mainButton = whatButtonStruct
        set this.currentOption = 0

        loop
            exitwhen this.optionCount >= optionCount

            set votes[this.optionCount] = 0

            set this.optionCount = this.optionCount + 1
        endloop

        return this

    endmethod

    public method ButtonClick takes nothing returns nothing

        set currentOption = currentOption + 1

        if currentOption >= optionCount then
            set currentOption = 0
        endif

    endmethod
endstruct

interface Button
    public method IsMultiOption     takes nothing                                   returns boolean
    public method CreateHelper      takes nothing                                   returns ButtonHelper
endinterface

private struct SingleOptionButton extends Button
    private trigger         executableTrigger
    private string          name
    private integer         hotkey

    public static method create takes string name, integer hotkey, trigger buttonTrigger returns thistype
        
        local thistype this         = thistype.allocate()

        if hotkey == 0 then
            set this.name = name
        else
            set this.name = HOTKEY_COLOR + "[" + Ascii2Char(hotkey) + "]|r" + name
        endif

        set this.executableTrigger = buttonTrigger
        set this.hotkey = hotkey

        return this

    endmethod

    public method CreateButton takes dialog whatDialog returns button
        return DialogAddButton(whatDialog,name,hotkey)
    endmethod

    public method CreateHelper takes nothing returns ButtonHelper
        return SingleOptionButtonHelper.create(this)
    endmethod

    public method RunTrigger takes nothing returns nothing
        call TriggerExecute(executableTrigger)
    endmethod

    public method IsMultiOption takes nothing returns boolean
        return false
    endmethod

endstruct

private struct MultiOptionButton extends Button
    private string array    optionName[ButtonBuilder.MAX_OPTIONS]
    private trigger array   optionTrigger[ButtonBuilder.MAX_OPTIONS]
    private integer         optionCounter           = 0
    
    private integer         hotkey                  = 0
    private string          name                    = null

    public static method create takes string name, integer hotkey returns thistype

        local thistype this             = thistype.allocate()
        local integer index             = 0

        set this.hotkey                 = newHotkey

        if this.hotkey == 0 then
            set this.name   = name
        else
            set this.name   = HOTKEY_COLOR + "[" + Ascii2Char(hotkey) + "]|r" + name
        endif

        set this.name = this.name + "|r: "

        return this

    endmethod

    public method AddOption takes string optionName, trigger optionTrigger returns nothing
        set this.optionName[optionCounter]          = optionName
        set this.optionTrigger[optionCounter]       = optionTrigger
        set this.optionCounter                      = optionCounter + 1
    endmethod

    public method CreateButton takes dialog whatDialog, integer optionIndex returns button
        return DialogAddButton(whatDialog,name + optionName[optionIndex],hotkey)
    endmethod

    public method CreateHelper takes nothing returns ButtonHelper
        return MultiOptionButtonHelper.create(this, optionCounter)
    endmethod

    public method RunTrigger takes integer optionIndex returns nothing

        call TriggerExecute(optionTrigger[optionIndex])

    endmethod

    public method IsMultiOption takes nothing returns boolean
        return true
    endmethod
endstruct    
