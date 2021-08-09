---
---
---
---
---

---
--- Functional programming support library
---
--- @class FunctionalLib

--- @type FunctionalLib
local functional = {}

---
---
--- @return function
---
function functional.reverse(_function)
    return function(...)
        return _function(table.pack())
    end
end




return functional