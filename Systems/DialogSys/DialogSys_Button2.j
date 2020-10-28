interface IExecutableOption
    public string name
    public method Execute takes nothing returns nothing
endinterface

private struct TriggerExecuteOption extends IExecutableOption

    public string name
    private trigger executableTrigger

    public static method create takes string name, trigger whichTrigger returns thistype

        local thistype this = thistype.allocate()

        set this.name = optionName
        set this.executableTrigger = whichTrigger

        return this

    endmethod

    public method Execute takes nothing returns nothing
        call TriggerExecute(executableTrigger)
    endmethod

endstruct

private struct Button
    public static constant integer MAX_OPTIONS = 5
    public static constant string HOTKEY_COLOR = "|cFF334D4D"

    private IExecutableOption array option[MAX_OPTIONS]
    private integer array optionVote[MAX_OPTIONS]
    private integer maxOptions
    private string name
    private integer hotkey

    private integer array currentOption[bj_MAX_PLAYER_SLOTS]

    public static method create takes string name, integer hotkey, boolean isMultiOption returns thistype

        local thistype this = thistype.allocate()
        local integer index = 0
        
        set this.hotkey = hotkey

        if hotkey == 0 then
            set this.name = name
        else
            set this.name = HOTKEY_COLOR + "[" + Ascii2Char(hotkey) + "]|r" + name
        endif

        if isMultiOption then
            set this.name = this.name + ": "
        endif

        loop
            exitwhen index == bj_MAX_PLAYER_SLOTS

            set this.currentOption[index] = 0

            set index = index + 1
        endloop

        return this

    endmethod

    public method destroy takes nothing returns nothing
        local integer index = 0

        loop
            exitwhen index == maxOptions

            call option[index].destroy()

            set index = index + 1
        endloop
        
    endmethod

    public method Click takes integer playerIndex returns nothing

        set currentOption[playerIndex] = currentOption[playerIndex] + 1 

        if currentOption[playerIndex] >= maxOptions then
            set currentOption[playerIndex] = 0
        endif

    endmethod

    public method CreateButton takes dialog whichDialog, integer playerIndex returns button
        return DialogAddButton(whichDialog, name + option[currentOption[playerIndex]].name, hotkey)
    endmethod

    public method Execute takes integer optionIndex returns nothing
        call option[optionIndex].Execute()
    endmethod

    public method AddOption takes IExecutableOption newOption returns nothing
        set option[maxOptions] = newOption
        set optionVote[maxOptions] = 0
        set maxOptions = maxOptions + 1
    endmethod

    public method GetHighestVotedOption takes nothing returns integer

        local integer index = 0
        local integer topOption = 0

        loop
            exitwhen index == bj_MAX_PLAYER_SLOTS

            set optionVote[currentOption[index]] = optionVote[currentOption[index]] + 1

            set index = index + 1
        endloop

        set index = 0

        loop
            exitwhen index == maxOptions

            if optionVote[topOption] < optionVote[index] then
                set topOption = index
            endif

            set index = index + 1
        endloop

        return topOption
        
    endmethod

    public method IsSingleOption takes nothing returns boolean
        return maxOptions < 2
    endmethod
endstruct
