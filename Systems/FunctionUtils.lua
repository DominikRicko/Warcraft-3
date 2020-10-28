
FunctionUtils = {}

function SetFunctionParameters(func, args)
    FunctionUtils[func] = {args}
end

function GetFunctionParameters(func)
    return table.unpack(FunctionUtils[func])
end
