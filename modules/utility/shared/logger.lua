local printLevel = {
    error = 1,
    warn = 2,
    info = 3,
    verbose = 4,
    debug = 5,
}

local currResourceName = GetCurrentResourceName()

local levelPrefixes = {
    "^1[ERROR]",
    "^3[WARN]",
    "^7[INFO]",
    "^4[VERBOSE]",
    "^6[DEBUG]",
}

local resourcePrintLevel = printLevel[GetConvar(currResourceName .. ":printlevel", GetConvar("global:printlevel", "info"))]

local template = ("^5[%s] %%s %%s^7"):format(currResourceName)

local function handleException(reason, value)
    if type(value) == "function" then
        return tostring(value)
    end
    return reason
end

local jsonOptions = { sort_keys = true, indent = true, exception = handleException }

---@param level PrintLevel
---@param ... any
local function log(level, ...)
    return
    --if level > resourcePrintLevel then
    --    return
    --end
    --
    --local args = { ... }
    --
    --for i = 1, #args do
    --    local arg = args[i]
    --    args[i] = type(arg) == "table" and json.encode(arg, jsonOptions) or tostring(arg)
    --end
    --
    --print(template:format(levelPrefixes[level], table.concat(args, "\t")))
end

local logger = {
    error = function(...)
        log(printLevel.error, ...)
    end,
    warn = function(...)
        log(printLevel.warn, ...)
    end,
    info = function(...)
        log(printLevel.info, ...)
    end,
    verbose = function(...)
        log(printLevel.verbose, ...)
    end,
    debug = function(...)
        log(printLevel.debug, ...)
    end,
}

return logger
