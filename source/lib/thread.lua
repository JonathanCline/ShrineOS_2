



---
--- ShrineOS system thread library
---
--- @class shrine.threadlib

---
--- Thread library
---
--- @type shrine.threadlib
local thread = {}


--- Dependencies

local uuid = require("uuid")
local computer = require("computer")

---
--- Returns a time point in seconds
---
--- @return seconds
---
local function now()
    return computer.uptime()
end

---
--- Internal thread object
---
--- @class shrine.thread.obj : shrine.thread.obj.doc

---
--- Thread object representing a seperate thread of execution
---
--- Will join the associated thread on __gc
---
--- @class shrine.thread : shrine.thread.doc

local thread_mt =
{
    __gc = function(self)
        thread.join(self)
    end
}

---
--- Thread ID
---
--- @class shrine.thread.id : shrine.uuid

---
--- Ledger containing all running threads with keys set to their IDs
---
--- @type table
local thread_ledger = {}

---
--- The running thread
---
--- @type shrine.thread
---
local this_thread

---
--- The root thread
---
--- @type shrine.thread
local root_thread

---
--- Throws an error due to bad permissions
---
--- @param _message? string Optional additional message, this is appended to the error message
--- @param _level? integer  Stack levels above caller for traceback, defaults to 0
---
--- @overload fun(_level: integer)
---
local function throw_bad_permissions(_message, _level)
    -- Handle function overload
    if type(_message) == "integer" then
        _level = _message
        _message = nil
    end

    -- Throws error from calling function + '_level' stack levels
    _level = (_level or 0) + 1
    return error(debug.traceback(_message or "bad thread permissions", _level), _level)
end


---
--- Returns a handle to the current running thread
---
--- @return shrine.thread
---
function thread.current()
    return this_thread
end

---
--- Creates a new thread as a child of the current thread
---
--- @param _fn fun(): integer   Thread main function
---
--- @return shrine.thread
---
function thread.new(_fn)

    --- @type shrine.thread.obj
    local _thread =
    {
        id = uuid.next(),
        coid = coroutine.create(_fn),
        children = {},
        locals = {},
        signals = {},
        sleeping = false
    }

    -- Add thread to ledger
    thread_ledger[_thread.id] = _thread

    --- @type shrine.thread
    local _handle =
    {
        id = _thread.id,
        locals = _thread.locals
    }

    -- Add the new thread handle to current thread's children
    local _current = thread_ledger[this_thread.id]
    _current.children[_thread.id] = _handle

    return setmetatable(_handle, thread_mt)
end

---
--- Checks if a thread is a child of the current thread
---
--- @param _thread shrine.thread    Thread to check
---
--- @return boolean
---
function thread.is_child(_thread)

    --- @type shrine.thread.obj  Current thread object
    local _this = thread_ledger[this_thread.id]

    -- Check for thread in child table
    return _this.children[_thread.id] ~= nil
end

---
--- Removes a thread from the current thread's child list and gives it to the root process
---
--- @param _thread shrine.thread    Thread to detach
---
function thread.detach(_thread)

    -- Check for valid permissions
    if not thread.is_child(_thread) then
        throw_bad_permissions()
    end

    -- Add thread to the root thread's children
    local _root = thread_ledger[root_thread.id]
    _root.children[_thread.id] = thread_ledger[_thread.id]

    -- Remove thread from current
    do
        local _current = thread_ledger[thread.current().id]
        _current.children[_thread.id] = nil
    end

end

---
--- Explicitly resumes a child thread regardless of wake_after value
---
--- Returns false + an error message if the child thread threw an error while running
---
--- NOTICE: This doesn't check permissions!!!
---
--- @param _thread shrine.thread    Thread to resume
---
--- @return boolean, errormessage? error
---
local function wake(_thread)

    -- Child thread object
    local _child = thread_ledger[_thread.id]

    -- Parent (current) thread
    local _parent = this_thread

    -- Set the current thread as the child
    this_thread = _thread

    -- Resume the child thread function
    local _good, _value = coroutine.resume(_child.coid)

    -- Reset the current thread to parent (current) thread
    this_thread = _parent

    -- Check results
    if not _good then
        -- Return error
        return false, _value
    else
        -- Set wake after time
        _child.wake_after = _value
        return true
    end

end

---
--- Explicitly resumes a child thread if the child thread is not sleeping
---
--- Returns false + an error message if the child thread threw an error while running
---
--- @param _thread shrine.thread    Thread to resume
---
--- @return boolean, errormessage? error
---
function thread.resume(_thread)

    -- Check permissions
    if not thread.is_child(_thread) then
        throw_bad_permissions()
    end

    -- Child thread object
    local _child = thread_ledger[_thread.id]

    -- Handle sleeping child thread
    if _child.wake_after then
        -- Check if nap time is over
        if _child.wake_after < now() then
            return true                             -- returns early
        else
            _child.wake_after = nil
        end
    end

    -- Run wake function to resume the child thread
    return wake(_thread)
end

---
--- Yields the running thread or puts it into "sleep" mode if _wakeAfter is provided
---
--- @param _wakeAfter? seconds Time point to sleep until
---
local function yield_impl(_wakeAfter)

    local _current = thread_ledger[thread.current().id]

    -- Before yielding, make sure and resume and child threads
    for k, v in pairs(_current.children) do
        thread.resume(v)
    end

    -- If this is the root process, return early
    if _current.id == root_thread.id then
        return
    end

    -- Yield to parent thread
    coroutine.yield(_wakeAfter)

end

---
--- Resumes child threads before yielding to the parent thread
---
function thread.yield()
    yield_impl()
end

---
--- Yields until the given timepoint
---
--- @param _timepoint seconds Time to sleep until
---
function thread.sleep_until(_timepoint)

    -- Set sleeping flag
    thread_ledger[this_thread.id].sleeping = true

    -- Nap time
    yield_impl(_timepoint)

    -- Clear sleeping flag
    thread_ledger[this_thread.id].sleeping = false

end

---
--- Yields until the given duration has passed
---
--- @param _duration seconds Duration to sleep for
---
function thread.sleep(_duration)
    return thread.sleep_until(now() + _duration)
end

---
--- Pushes a signal to a thread and returns a pass/fail value + the size of the thread's signal queue
---
--- If _wake is set to true, then this will resume the thread after pushing, do
--- not provide this if the thread being pushed to is the parent thread.
---
--- If _wake is set to true and the thread throws an error while being resumed,
--- then this will return false + the error message.
---
--- NOTICE: This function doesn't check permissions!
---
--- @param _thread  shrine.thread   Thread to push to
--- @param _wake    boolean         If true, resumes the destination thread, defaults to false
--- @param _signal  string          Signal to push
--- @vararg         any             Signal values
---
--- @return boolean good, integer|errormessage error
---
local function push_impl(_thread, _wake, _signal, ...)

    -- Thread to push the signal to
    local _dest = thread_ledger[_thread.id]

    -- Check for valid thread
    if not _dest then
        error(debug.traceback("invalid thread handle", 3), 3)
    end

    -- Push the signal into the thread signal queue
    _dest.signals[#_dest.signals+1] = { _signal, ... }

    -- Check if thread should be woken
    if _wake and not _dest.sleeping then

        -- Wake thread
        local _good, _error = wake(_thread)

        -- Return error if there was one
        if not _good then
            return false, _error
        end

    end

    -- Return results
    return true, #_dest.signals
end

---
--- Pushes a signal to a child thread and return pass/fail + size of the child thread's signal queue or error on failure
---
--- @param _thread  shrine.thread   Child thread to push to
--- @param _wake    boolean         If true, resumes the destination thread, defaults to false
--- @param _signal  string          Signal to push
--- @vararg         any             Signal values
---
--- @overload fun(_thread: shrine.thread, _signal: string, ...)
---
--- @return boolean, errormessage|integer
---
function thread.push(_thread, _wake, _signal, ...)

    -- Check permissions
    if not thread.is_child(_thread) then
        throw_bad_permissions()
    end

    -- Handle function overload
    if type(_wake == "string") then

        -- Wake wasn't provided, so provide the arguements as if they were "shifted" by 1
        -- Just pretend:
        --       _wake is _signal
        --       _signal is first signal value
        return push_impl(_thread, false, _wake, _signal, ...)

    else
        -- Wake was provided
        return push_impl(_thread, _wake, _signal, ...)
    end

end

---
--- Pulls the next available signal or blocks until a signal was pushed or _timeout has passed
---
--- This will only yield if no signals are available to pull
---
--- @param _timeout seconds     Max duration to pull for
---
--- @return string? signal, any? signal_values
---
function thread.pull(_timeout)

    -- The running thread
    local _current = thread_ledger[thread.current().id]

    -- If no signals are available, yield until _timeout or available signal
    if #_current.signals == 0 then

        -- Convert timeout into a time_point if it was provided
        if _timeout then
            _timeout = _timeout + now()
        end

        -- Nap time!
        yield_impl(_timeout)

        -- Return nil if no signals were pushed while yielding
        if #_current.signals == 0 then
            return
        end
    end

    -- Pull next signal and remove it from the signal queue
    return table.unpack(table.remove(_current.signals, 1))
end

---
--- Closes and deletes a child thread
---
--- @param _thread shrine.thread Thread to join
---
function thread.join(_thread)

    -- Check permissions
    if not thread.is_child(_thread) then
        throw_bad_permissions()
    end

    -- Push exit signal
    local _good, _error = thread.push(_thread, true, "exit")

    -- Remove thread from the current thread's children
    local _current = thread_ledger[thread.current().id]
    _current.children[_thread.id] = nil

    -- Remove the thread from the ledger
    thread_ledger[_thread.id] = nil

    -- If the resume was successful, then remove the _error value (normally the signal queue backlog)
    if _good then _error = nil end
    return _good, _error
end

--- @alias shrine.thread.status
---|"dead"
---|"yield"
---|"sleep"

---
--- Gets the status of a child thread
---
--- If thread is yielding or sleeping, this will also return the wake_after time point
---
--- @param _thread shrine.thread    Child thread to get status of
---
--- @return shrine.thread.status, seconds?
---
function thread.status(_thread)

    -- Check permissions
    if not thread.is_child(_thread) then
        return throw_bad_permissions()
    end

    -- Child thread
    local _child = thread_ledger[_thread.id]

    -- Determine status
    if not _child.coid then
        return "dead"
    elseif _child.sleeping then
        return "sleep", _child.wake_after
    else
        return "yield", _child.wake_after
    end

end


---
--- Returns an iterator to the current thread's children
---
--- @return fun() : shrine.thread?
---
function thread.children()

    local _current = thread_ledger[this_thread.id]
    local _next, _children, _index = pairs(_current.children)

    --- @return shrine.thread?
    return function()
        local _out
        _index, _out = _next(_children, _index)
        return _out
    end
end


---
--- Set the root / current thread
---

do
    --- @type shrine.thread.obj
    local _rootThread =
    {
        id = uuid.next(),

        locals = {},
        children = {},
        signals = {},

        sleeping = false,
        wake_after = nil
    }
    thread_ledger[_rootThread.id] = _rootThread

    --- @type shrine.thread
    root_thread =
    {
        id = _rootThread.id,
        locals = _rootThread.locals
    }

    this_thread = root_thread
end

return thread