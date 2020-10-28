
private struct DialogQueueElement
    public  Dialog                          dialogID                
    private integer                         playerCount    

    public static method create takes Dialog whatDialogStruct, integer amountOfPlayersUsingThis returns thistype

        local thistype this     = thistype.allocate()

        set this.dialogID       = whatDialogStruct
        set this.playerCount    = amountOfPlayersUsingThis
            
        return this
    endmethod

    public method getPlayerCount takes nothing returns integer
        return playerCount
    endmethod

    public method reducePlayerCount takes nothing returns nothing
        set playerCount = playerCount - 1
    endmethod
endstruct
    

private struct DialogQueue

    public static constant integer      QUEUE_EMPTY          = -1
    public static constant integer      MAX_QUEUES_REACHED   = -2

    public static constant integer      MAX_QUEUES           = bj_MAX_PLAYER_SLOTS
    public static constant integer      QUEUE_MAX_SIZE       = JASS_MAX_ARRAY_SIZE/MAX_QUEUES

    public static integer               Queues               = 0

    private     DialogQueueElement  array[QUEUE_MAX_SIZE]       data
    private     integer                                         start
    private     integer                                         end
    private     integer                                         size

    public static method create takes nothing returns thistype
        local thistype  this

        if Queues >= MAX_QUEUES then
            return MAX_QUEUES_REACHED
        endif
        set this                    = thistype.allocate()

        set start                   = 0
        set end                     = 0
        set size                    = 0

        set Queues                  = Queues + 1

        return this
    endmethod

    private method nextIndex takes integer index returns integer

        set index = index + 1
        if index >= QUEUE_MAX_SIZE then
            set index = 0
        endif

        return index

    endmethod

    public method destroy takes nothing returns nothing

        set Queues = Queues - 1

        loop
            exitwhen start == end

            call data[start].destroy()

            set start = nextIndex(start)
        endloop 

    endmethod

    public method Enqueue takes DialogQueueElement newData returns boolean
        if IsFull() then
            return false
        endif

        set data[end] = newData
        set size = size + 1
        set end = nextIndex(end)

        return true

    endmethod

    public method Dequeue takes nothing returns DialogQueueElement
        local DialogQueueElement   returnData

        if IsEmpty() then
            return QUEUE_EMPTY
        endif

        set returnData = data[start]
        size = size - 1
        start = nextIndex(start)

        return returnData

    endmethod

    public method IsEmpty takes nothing returns boolean
        return size <= 0
    endmethod

    public method IsFull takes nothing returns boolean
        return size >= QUEUE_MAX_SIZE
    endmethod

endstruct