

local computer = computer or require("computer")
local component = component or require("component")
local table = table or require("table")
local debug = debug or require("debug")


---
--- Loads a file from the boot filesystem device
---
--- @param _path string     File path
--- @param _mode openmode   File open mode
--- @param _env? table       Gloval environment table for the chunk, defaults to _G
---
--- @return function?, string errormessage
---
function loadfile(_path, _mode, _env)
    local _fs = computer.getBootAddress()
    local _file = component.invoke(_fs, "open", tostring(_path), "r")

    if not _file then
        return nil, "bad file path"
    end

    local _data = ""
    local _chunk = component.invoke(_fs, "read", _file, computer.freeMemory() / 4)
    while _chunk do
        _data = _data .. _chunk
        _chunk = component.invoke(_fs, "read", _file, computer.freeMemory() / 4)
    end
    component.invoke(_fs, "close", _file)
    return load(_data, "=" .. _path, _mode or "bt", _env)
end
assert(_G.loadfile ~= nil)

_G.dofile = function(_path, ...)
    local _chunk, _err = loadfile(_path)
    if not _chunk then
        return nil, _err
    else
        return _chunk(...)
    end
end

local old_rawset = _G.rawset
_G.rawset = nil
local old_rawget = _G.rawget
_G.rawget = nil

---Returns a const version of the provided table
---@param _table table
---@return table
const = function(_table)
    local _const = {}
    local _mt =
    {
        __const = true,
        __index = function(self, key)
            local o = _table[key]
            if type(o) == "table" then
                o = const(o)
            end
            return o
        end,
        __newindex = function(self, key, value)
            error("cannot modify const table", 2)
        end
    }
    return setmetatable(_const, _mt)
end

---Returns true if a table has a metafield
---@param _table table
---@param _meta string
---@return boolean
has_meta = function(_table, _meta)
    local _mt = getmetatable(_table)
    return _mt and _mt[_meta]
end

--- Returns true if the table is marked const
---@param _table table
---@return boolean
is_const = function(_table)
    return has_meta(_table, "__const")
end



---@alias errormessage string

---   Invokes a function with the provided arguements and returns a status code and the results
--- of the function.
---
---   If an error occured, the status code will be false and the second return value contains the
--- error message.
---
---@param fn function Function to invoke
---@return boolean status, table|errormessage results
function invoke(fn, ...)
    local _results = table.pack(pcall(fn, ...))
    local _status = table.remove(_results, 1)
    if _status == true then
        return true, _results
    else
        return false, _results[1]
    end
end

---   Invokes a function with the provided arguements and returns a status code and the results
--- of the function.
---
---   If an error occured, the status code will be false and the second return value contains the
--- error message.
---
---@param fn function Function to invoke
---@param errfn function|nil Error handling function, if this is nil then 'debug.traceback' will be used
---@return boolean status, table|errormessage results
function xinvoke(fn, errfn, ...)
    local _results = table.pack(xpcall(fn, errfn or debug.traceback, ...))
    local _status = table.remove(_results, 1)
    if _status == true then
        return true, _results
    else
        return false, _results[1]
    end
end

