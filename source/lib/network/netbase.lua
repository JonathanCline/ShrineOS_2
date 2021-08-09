local component = require("component")
local computer = require("computer")

local event = require("event")


local netbase = {}







local modems = {}

local function add_modem(_modemID)
    if modems[_modemID] then
        return false
    end
    modems[_modemID] = component.proxy(_modemID)
    return true
end

local function remove_modem(_modemID)
    modems[_modemID] = nil
    return true
end





local function component_callback(_signal, _componentID, _componentType)
    if _componentType == "modem" then
        if _signal == "component_added" then
            modems[_componentID] = component.proxy(_componentID)
        elseif _signal == "component_removed" then
        end
    end
end

event.listen("component_added", component_callback)
event.listen("component_removed", component_callback)



