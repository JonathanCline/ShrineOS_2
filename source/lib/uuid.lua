---
--- Shrine OS UUID library
---
--- @class shrine.uuidlib

---
--- UUID string
---
--- @class shrine.uuid

--- @type shrine.uuidlib
local uuid = {}


--- Dependencies

local math = require("math")
local string = require("string")
local computer = require("computer")
local os = require("os")


--- UUID constant variables

local node = string.match(computer.address(), "%x+")
local version = 1

---
--- Creates a new UUID
---
--- @return shrine.uuid
---
function uuid.next()
    local _segments = {}
    _segments[1] = os.time()

    local _time = math.floor(computer.uptime() * 100)
    local _timeMid = _time & 0x0000FFFF
    local _timeHigh = (_time & 0x0FFF0000) >> 12
    _segments[2] = _timeHigh | version

    local _rnd, _ = math.modf(math.random(0, math.maxinteger))
    _segments[3] = _rnd & 0x0000FFFF
    _segments[4] = (_rnd & 0xFFFF0000) >> 16
    return string.format("%x-%x-%x-%x-%x%s", _segments[1], _timeMid, _segments[2],  _segments[3],  _segments[4], node)
end

return uuid