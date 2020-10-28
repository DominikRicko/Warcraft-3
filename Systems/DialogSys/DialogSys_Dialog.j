private struct ActiveDialog
    public static ActiveDialog array    playerDialog[bj_MAX_PLAYER_SLOTS]

    private dialog menu
    private Dialog mainDialog
    private integer playerIndex
    private trigger dialogTrigger

    private button array activeButton[DIALOG_MAX_BUTTONS_W_EXIT]

    public method Render takes nothing returns nothing
        local integer index     = 0

        call DialogClear(menu[playerIndex])

        loop
            exitwhen index >= buttonCount

            call mainDialog.CreateActiveButton(menu,playerIndex,index)

            set index = index + 1
        endloop

        call DialogDisplay(menu,Player(playerIndex),true)
        
    endmethod

    private static method DialogClick takes nothing returns nothing

        local thistype this = playerDialog[GetPlayerId(GetTriggerPlayer())]
        local integer index         = 0

        loop
            exitwhen index >= mainDialog.buttonCounter

            if GetClickedButton() == activeButton[index] then

                call menu.buttons[index].Click(playerIndex)

                if not menu.buttons[index].IsSingleOption() then

                    call Render()

                else

                    set mainDialog.buttonVote[index] = mainDialog.buttonVote[index] + 1

                endif

                return

            endif

            set index = index + 1

        endloop

    endmethod

    public static method create takes nothing returns thistype
        
        local thistype this = thistype.allocate()


        return this

    endmethod

    public method SetDialogHelper takes Dialog mainDialog, string name, integer playerIndex, integer buttonCount returns nothing

        call DialogDestroy(menu)
        call DestroyTrigger(dialogTrigger)

        set this.mainDialog = mainDialog
        set this.menu = DialogCreate()
        set this.playerIndex = playerIndex 
        set this.buttonCount = buttonCount
        set this.dialogTrigger = CreateTrigger()

        loop
            exitwhen index == buttonCount

            set activeButton[index] = menu.CreateActiveButton(menu, playerIndex,index)

            set index = index + 1
        endloop

        set thistype.playerDialog = this

        call DialogSetMessage(this.menu,name)
        call TriggerRegisterDialogEvent(this.dialogTrigger,this.menu)
        call TriggerAddAction(this.dialogTrigger,function thistype.DialogClick)

    endmethod

    public method destroy takes nothing returns nothing
        call DestroyTrigger(dialogTrigger)

        call DialogDestroy(menu)
    endmethod

endstruct


private struct Dialog
    public constant integer MAX_BUTTONS = 10
    public constant integer MAX_BUTTONS_W_EXIT = MAX_BUTTONS + 1

    public Button array buttons[DIALOG_MAX_BUTTONS_W_EXIT]
    public integer array buttonVote[DIALOG_MAX_BUTTONS_W_EXIT]
    public integer  buttonCounter = 0

    public string name

    public static method create takes string name returns thistype

        local thistype this = thistype.allocate()

        set this.name = name

        return this

    endmethod

    public method destroy takes nothing returns nothing

        local integer i = 0

        loop
            exitwhen i >= DIALOG_MAX_BUTTONS

            call buttons[i].destroy()
            set buttons[i] = 0

            set i = i + 1
        endloop

        call DialogClear(menu)
        call DialogDestroy(menu)

    endmethod

    public method AddButton takes Button newButton returns nothing

        set buttons[buttonCounter] = newButton
        set buttonVote[buttonCounter] = 0
        set buttonCounter = buttonCounter + 1

        return true

    endmethod

    public method CreateActiveDialog takes integer playerIndex returns nothing

        set ActiveDialog.playerDialog[playerIndex].SetDialogHelper(this, name, playerIndex, buttonCounter)

    endmethod

    public method CreateActiveButton takes dialog whatDialog, integer playerIndex, integer buttonIndex returns button
        return buttons[buttonIndex].CreateButton(whatDialog,playerIndex)
    endmethod
endstruct
