library DialogSystem initializer Init requires Ascii
    globals
        private boolean DialogQueueRunning = false
        private boolean array DialogRunningForPlayer
        private DialogQueue array DialogQueueForPlayer
        private DialogQueueElement array    currentDialogElementForPlayer
    endglobals

    private function CountPlayersInForce takes force whichForce returns integer

        local integer   playerIndex         = 0
        local integer   count               = 0

        loop
            exitwhen playerIndex >= bj_MAX_PLAYER_SLOTS

            if IsPlayerInForce(Player(playerIndex),whichForce) then
                set count = count + 1
            endif

            set playerIndex = playerIndex + 1
        endloop

        return count

    endfunction

    private function DoAllQueuesHaveSpace takes force whichForce returns boolean

        local integer   playerIndex         = 0
        local boolean   result              = true

        loop
            exitwhen playerIndex >= bj_MAX_PLAYER_SLOTS

            if IsPlayerInForce(Player(playerIndex),whichForce) then
                
                set result = result and not DialogQueueForPlayer[playerIndex].IsFull()

            endif

            set playerIndex = playerIndex + 1
        endloop

        return result

    endfunction

    public function RunNextDialogForPlayer takes integer playerIndex returns nothing
        local DialogQueueElement    currentElement

        if not DialogRunningForPlayer[playerIndex] and not DialogQueueForPlayer[playerIndex].IsEmpty() then

            set DialogRunningForPlayer[playerIndex] = true
            set currentElement = DialogQueueForPlayer[playerIndex].Dequeue()

            call currentElement.dialogID.Render()
            set currentDialogForPlayer[playerIndex] = currentElement.dialogID.GetDialog()

            call DialogDisplay(Player(playerIndex),currentDialogForPlayer[playerIndex])

        endif
    endfunction

    private function DialogClicked takes nothing returns nothing
        local integer playerIndex = GetPlayerId(GetTriggerPlayer())
         
        if currentDialogElementForPlayer[playerIndex].DialogID.ButtonPress(GetClickedButton(),playerIndex) then
            call DisplayDialog(GetClickedDialog())
        else
            set DialogRunningForPlayer[playerIndex] = false
            call RunNextDialogForPlayer(playerIndex)
        endif

        if currentDialogElementForPlayer[playerIndex].getPlayerCount() == 0 then
            call DialogDestroy()
            call DestroyTrigger(GetTriggeringTrigger())
            call RunNextDialogForPlayer(playerIndex)

            call currentDialogElementForPlayer[playerIndex].DialogID.RunHighestButtonOptions()
            call currentDialogElementForPlayer[playerIndex].DialogID.destroy()
            call currentDialogElementForPlayer[playerIndex].destroy()
        endif

    endfunction

    public function EnqueueDialogForForce takes force whichForce, Dialog whatDialog returns nothing
        local integer playerCount = CountPlayersInForce(whichForce)
        local DialogQueueElement newElement
        local integer playerIndex = 0
        local trigger newTrigger     

        if not DoAllQueuesHaveSpace() then
            call BJDebugMsg("Unable to add dialog to queue")
        endif
        
        set newElement = DialogQueueElement.create(whatDialog,playerCount)

        set newTrigger = CreateTrigger()
        call TriggerRegisterDialogEvent(newTrigger,whatDialog)
        call TriggerAddAction(newTrigger, function DialogClicked)

        loop    
            exitwhen playerIndex >= bj_MAX_PLAYER_SLOTS

            if IsPlayerInForce(Player(playerIndex,whichForce)) then
                call DialogQueueForPlayer[index].Enqueue(newElement)
            endif

            set playerIndex = playerIndex + 1
        endloop
        
    endfunction

    public function StartDialogQueue takes nothing returns nothing
        local integer playerIndex           = 0

        if DialogQueueRunning then
            return
        endif

        set DialogQueueRunning = true

        loop
            exitwhen playerIndex >= bj_MAX_PLAYER_SLOTS

            call RunNextDialogForPlayer(playerIndex)

            set playerIndex = playerIndex + 1
        endloop


    endfunction
    
    private function onInit takes nothing returns nothing

        local integer index = 0 

        loop
            exitwhen index >= bj_MAX_PLAYER_SLOTS

            set DialogRunningForPlayer[index] = false
            set DialogQueueForPlayer[index] = DialogQueue.create()

            set index = index + 1
        endloop

    endfunction

endlibrary