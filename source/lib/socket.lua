---@class SocketLib

---@type SocketLib
local socket = {}

local component = require("component")



local modems = {}

local function find_modems()
    modems = {}
    for v in component.list("modem") do
        modems[v] = component.proxy(v)
    end
end
find_modems()








return socket