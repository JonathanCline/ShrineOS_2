local raw_component = component

--- @class shrine.componentlib : oc.componentlib

--- @type shrine.componentlib
local component = {}

do
    local component_lib_mt =
    {
        __index = raw_component
    }
    setmetatable(component, component_lib_mt)
end

local component_mt =
{
    __index = function(self, key)
        return function(...)
            return component.invoke(self.address, key, ...)
        end
    end
}

---
--- Creates a wrapper around a component that allows direct usage of component API functions
---
--- @param _component oc.address      Address of component to proxy
---
--- @return oc.component.proxy
---
function component.proxy(_component)
    --- @type oc.component
    local o = { address = _component }
    return setmetatable(o, component_mt)
end

return component