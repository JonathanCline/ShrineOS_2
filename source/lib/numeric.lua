--- @class NumericLib
--- @type NumericLib
local numeric = {}

--- @type mathlib
local math = require("math")

numeric.max = math.max
numeric.min = math.min

---
--- Clamps a value between a min and max
---
--- @param _value number    Value to clamp
--- @param _min number      Lower bound
--- @param _max number      Upper bound
---
--- @return number
---
function numeric.clamp(_value, _min, _max)
    return numeric.min(numeric.max(_value, _min), _max)
end


return numeric