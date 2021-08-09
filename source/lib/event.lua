---
---     Provides event pulling functionality
---
--- @class EventLib

--- @type EventLib
local event = {}

---
---
---
--- @class Listener
---
--- @field coid thread      Coroutine ID
--- @field signal string    Signal match string
---

---
---
---
--- @class ListenerID: shrine.uuid Unique listener ID

local thread = require("thread")
local computer = require("computer")
local uuid = require("uuid")

local listeners = {}

---
--- Main process function for the event listening daemon
---
local function listen_process()
    while true do
        local _signal = table.pack(computer.pullSignal())
        if _signal[1] then
            if _signal[1] == "exit" then
                listeners = {}
                return
            else
                local _dead = {}
                for k, v in pairs(listeners) do
                    if _signal[1] == v.signal then
                        coroutine.resume(v.coid, table.unpack(_signal))
                        if coroutine.status(v.coid) == "dead" then
                            _dead[#_dead + 1] = k
                        end
                    end
                end
                for i, v in ipairs(_dead) do
                    listeners[v] = nil
                end
            end
        end
    end
end

---
--- @type ProcessProxy Main process for managing listeners
---
local _listenProc = thread.new(listen_process)

---
--- @type table Thread local variables, the event process is stored here
---
local thread_local = thread.current().locals
thread_local.listenProc = _listenProc

--- Detach listen thread so it is a part of the root process
thread.detach(_listenProc)

---
--- Creates a new event listener callback that will execute when the associated signal is pulled
--- Returns the listener ID.
---
--- @param _fn function Listener callback function
--- @param _signalMatch string Signal to listen for
---
--- @return ListenerID
---
function event.listen(_signalMatch, _fn)
    assert(type(_fn) == "function", "listen invalid arguement #2 : exepcted function, got \"" .. type(_fn) .. "\"")

    --- @type ListenerID
    local _id = uuid.next()

    --- @type Listener
    listeners[_id] =
    {
        signal = _signalMatch,
        coid = coroutine.create(function(_listenFn)
            while true do
                local _signal = table.pack(coroutine.yield())
                local _result = _listenFn(table.unpack(_signal))
                if type(_result) == "boolean" and _result == false then
                    return
                end
            end
        end)
    }
    coroutine.resume(listeners[_id].coid, _fn)

    return _id
end

---
--- Stops and removes an event listener
---
--- @param _listenerID ListenerID Listener to cancel
---
function event.cancel(_listenerID)
    listeners[_listenerID] = nil
end

return event