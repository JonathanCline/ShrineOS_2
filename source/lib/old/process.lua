---
--- ShrineOS Process library for the creation of and management of seperate threads of execution.
---
--- @class shrine.processlib

---
--- Provides functions for working with individual processes
---
--- @type shrine.processlib
local process = {}

---
--- Contains the processes currently active
---
local processLedger = {}


local coroutine = require("coroutine")
local table = require("table")
local uuid = require("uuid")

---
--- ID associated with processes to uniquely identify them
---
--- @class shrine.process.id : shrine.uuid

---
--- The active process ID
---
--- @type shrine.process.id|nil
local thisProcess

---
--- Table containing a process and its associated state
---
--- @class shrine.process
---
--- @field id shrine.process.id     Process ID
--- @field coid thread              Process coroutine ID
--- @field data table               Process thread local data
--- @field children table           Child processes
---

---
--- The root process of the computer, this is the process of the code that loaded this file
---
--- @type shrine.process
---
local rootProcess =
{
    id = require("computer").address(),
    coid = nil,
    data = {},
    children = {}
}
processLedger[rootProcess.id] = rootProcess

--- Initialize the current process as the root
thisProcess = rootProcess.id

---
--- Creates a new process and returns its ID
---
--- @param _fn fun() Process main function
---
--- @return shrine.process.id
---
local function newproc(_fn)

    ---
    --- New process object
    ---
    --- @type shrine.process
    ---
    local _proc =
    {
        id = uuid.next(),
        coid = coroutine.create(_fn),
        data = {},
        children = {}
    }

    -- Add process to ledger
    local _id = _proc.id
    processLedger[_id] = _proc

    -- Add process as child of current process
    processLedger[thisProcess].children[_id] = {}

    return _id
end

---
--- Resumes a process
---
--- @param _procID shrine.process.id    Child process ID to resume
--- @param _signal string               Signal name
--- @vararg any                         Values passed on call to resume
---
--- @return any
---
local function resumeproc(_procID, _signal, ...)
    assert(processLedger[thisProcess].children[_procID] ~= nil, "bad permissions")
    local _proc = processLedger[_procID]
    local _oldProc = thisProcess
    thisProcess = _procID
    local o = table.pack(coroutine.resume(_proc.coid, _signal, ...))
    thisProcess = _oldProc
    return table.unpack(o)
end

---
--- Yields the running process
---
--- @param _signal string Signal name
---
--- @return any
---
local function yieldproc(_signal, ...)
    assert(thisProcess ~= rootProcess.id, "root process cannot yield!")
    return coroutine.yield(processLedger[thisProcess].coid, _signal, ...)
end

---
--- Deletes a process
---
--- @param _procID shrine.process.id
---
local function delproc(_procID)
    assert(processLedger[thisProcess].children[_procID] ~= nil, "bad permissions")
    local _proc = processLedger[_procID]
    if _proc then
        for k, v in pairs(_proc.children) do
            delproc(k)
        end
        if coroutine.status(_proc.coid) ~= "dead" then
            coroutine.resume(_proc.coid, "exit")
        end
        processLedger[_procID] = nil
    end
end

---
--- Creates a new process and returns its ID, remember to close() it!
---
--- @param _fn function
---
--- @return shrine.process.id
---
function process.raw_create(_fn)
    local _procID = newproc(_fn)
    local _parent = processLedger[thisProcess]
    _parent.children[#_parent.children + 1] = _procID
    return _procID
end

--- Process proxy metatable
local proc_mt =
{
    __index = function(self, key)
        if self[key] then
            return self[key]
        else
            return processLedger[self._id()].data[key]
        end
    end,
    __newindex = function(self, key, name)
        processLedger[self._id()].data[key] = name
    end,
    __gc = function(self)
        delproc(self._id())
    end
}


---
--- Process handle implementing RAII and exposes the underlying child data table
---
--- @class ProcessProxy
---
--- @field _id function Returns the ID of the process
---

---
--- Creates a new child process and returns a proxy to it
---
--- @param _fn function Process function or chunk to
--- @return ProcessProxy
---
function process.create(_fn)
    local _procID = process.raw_create(_fn)
    ---@type ProcessProxy
    local o =
    {
        _id = function() return _procID end,
        close = function() return process.close(_procID) end
    }
    return setmetatable(o, proc_mt)
end

---
--- Stops and deletes a child process
---
--- @param _procID shrine.process.id|ProcessProxy Child process
---
function process.close(_procID)
    assert(_procID, "process.close arguement #1 expected process, got " .. type(_procID))
    if type(_procID) == "table" then
        _procID = _procID._id()
    end
    delproc(_procID)
end

---
--- Resumes a child process
---
--- @param _procID shrine.process.id|ProcessProxy Child process to resume
--- @param _signal string Signal name to pass
---
--- @return any
---
function process.resume(_procID, _signal, ...)
    assert(_procID, "process.resume arguement #1 expected process, got " .. type(_procID))
    if type(_procID) == "table" then
        _procID = _procID._id()
    end
    assert(processLedger[_procID], "process.resume no such process " .. _procID)
    return resumeproc(_procID, _signal, ...)
end

---
--- Yields the running process and returns control to the parent process
---
--- @param _signal string Process yielding mode
---
--- @return any
---
function process.yield(_signal, ...)
    return yieldproc(_signal, ...)
end

---
--- Returns an iterator to the running process's children
---
--- @return function
---
function process.children()
    local _table = processLedger[thisProcess].children
    local _index = nil
    return function()
        local _k, _v = next(_table, _index)
        _index = _k
        return _k, _v
    end
end

---
--- Returns the data table for a child process useful for storing things like timeouts and state
---
--- @param _procID ProcessProxy|shrine.process.id Child process to detach
---
--- @return table
---
function process.child(_procID)
    assert(_procID, "process.close arguement #1 expected process, got " .. type(_procID))
    if type(_procID) == "table" then
        _procID = _procID._id()
    end
    assert(processLedger[thisProcess].children[_procID], "invalid process on call to process.child()")
    return processLedger[thisProcess].children[_procID]
end

---
--- Detaches a child process and gives it to the root process to manage
---
--- @param _procID ProcessProxy|shrine.process.id Child process to detach
---
function process.detach(_procID)
    assert(_procID, "process.close arguement #1 expected process, got " .. type(_procID))
    if type(_procID) == "table" then
        _procID = _procID._id()
    end
    local _parent = processLedger[thisProcess]
    local _this = _parent.children[_procID]

    assert(_this, "bad permissions")
    _parent.children[_procID] = nil
    rootProcess.children[_procID] = _this
end

---
--- Gets the running process's thread local data table
---
--- @return table
---
function process.this()
    local _proc = processLedger[thisProcess]
    return _proc.data
end

return process