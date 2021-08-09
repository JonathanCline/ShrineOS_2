local computer = computer

local raw_push = computer.pushSignal
local raw_pull = computer.pullSignal
local raw_shutdown = computer.shutdown

local thread

computer.pushSignal = function(_signal, ...)
    return thread.push(_signal, ...)
end
computer.pullSignal = function(_timeout)
    return thread.pull(_timeout)
end
computer.shutdown = function(_reboot)
    computer.pushSignal("shutdown", _reboot)
end

do
    local _good, _result = xinvoke(dofile, nil, "/lib/package.lua")
    assert(_good, _result)
    local package = _result[1]

    _G.unicode = nil
    _G.computer = nil
    _G.component = nil
    _G.package = package
    _G.require = package.require
end

computer.beep(500, 0.2)
thread = require("thread")

local terminal = require("terminal")

local function kernel_main(_main)
    local _yieldDur = 0
    local _signal

    local state = { shutdown = 0, running = 1, reboot = 2 }
    local _computerState = state.running

    --- Main process
    local proc = thread.new(_main)

    local _beginTime = computer.uptime()

    while _computerState == state.running do

        _yieldDur = -1
        _beginTime = computer.uptime()

        -- Resumes child threads
        thread.yield()

        for v in thread.children() do
            local _status, _wakeAfter = thread.status(v)
            if (_status == "yield" or _status == "sleep") and _wakeAfter then
                local _sleepDur = _wakeAfter - _beginTime
                if _sleepDur > _yieldDur then
                    _yieldDur = _sleepDur
                end
            end
        end

        if _yieldDur < 0 then
            _yieldDur = nil
        end

        _signal = table.pack(raw_pull(_yieldDur))
        if _signal[1] then
            if _signal[1] == "shutdown" then
                if _signal[2] then
                    _computerState = state.reboot
                else
                    _computerState = state.shutdown
                end
            else
                for v in thread.children() do
                    thread.push(v, true, table.unpack(_signal))
                end
            end
        end
    end

    raw_shutdown(_computerState == state.reboot)
end

return kernel_main