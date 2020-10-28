-- Delayed Action v1.0.1

--  requires https://www.hiveworkshop.com/threads/lua-timerutils.316957/

--[[Description:

    A function that offers you to run a function with arguments after some delay,
        without the use of polled waits, or manually setting up timers.
]]

--[[Use example:
        DelayedAction(3.00, RemoveUnit, GetTriggerUnit())
            will remove the triggering unit of some trigger after 3 seconds.
]]


function DelayedAction(delay, func, ...)

    if type(func) == "nil" or type(delay) == "nil" or delay < 0.00 then
        return
    end

    local timer = NewTimer({func,...})

    TimerStart(timer, delay, false, DelayedActionExecute)
 
    return timer
end

function DelayedActionExecute()
    local data = GetTimerData()

    local func = table.unpack(data,1)
    table.remove(data,1)

    ReleaseTimer(GetExpiredTimer())

    pcall(func,table.unpack(data))
end