library SimpleTriggerData initializer onInit

    globals
        private hashtable       triggerDataBank             = null


        private constant    integer         TRIGGER_DATA_KEY= 10000
    endglobals

    function NewTriggerEx takes integer data returns trigger
        local trigger   newTrigger      = CreateTrigger()
        
        call SaveInteger(triggerDataBank,TRIGGER_DATA_KEY,GetHandleId(newTrigger),data)
        
        return newTrigger
    endfunction

    function ReleaseTrigger takes trigger whichTrigger returns nothing
        call RemoveSavedInteger(triggerDataBank,TRIGGER_DATA_KEY,GetHandleId(whichTrigger))
        
        call DestroyTrigger(whichTrigger)
    endfunction

    function GetTriggerData takes trigger whichTrigger returns integer
        return LoadInteger(triggerDataBank,TRIGGER_DATA_KEY,GetHandleId(whichTrigger))
    endfunction

    private function onInit takes nothing returns nothing
        set triggerDataBank         = InitHashtable()        
    endfunction

endlibrary