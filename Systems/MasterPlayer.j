// Requires: https://www.hiveworkshop.com/threads/hostdetection-gethost.316767/

library MasterPlayer initializer onInit requires HostDetection
    
    globals
        private constant integer    DEFAULT_PLAYER_IF_NO_HOST_DETECTED  = 0

        private player master           
    endglobals

    private function onInit takes nothing returns nothing
        if IsHostDetected() then
            set master              = GetHost()
        else
            set master              = Player(DEFAULT_PLAYER_IF_NO_HOST_DETECTED)
        endif
    endfunction

    public function Set takes player newHost returns nothing
        set master = newHost
    endfunction

    public function Get takes nothing returns player
        return master
    endfunction

    function IsMasterPlayer takes player whichPlayer returns boolean
        return whichPlayer == master
    endfunction

endlibrary
