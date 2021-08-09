local computer = require("computer")

--
--  Main function
--


local component = require("component")

--- @type oc.component.glasses
local glasses = component.proxy(component.list("glasses")())



do
    glasses.setTerminalName("ShrineOS ARG")
    local _players = glasses.getConnectedPlayers()
    print(#_players)

    glasses.startLinking()
end

--- @type oc.openglasses.cube3D
local _widget = glasses.addCube3D()

_widget.setVisibleThroughObjects(false)

local _wPos = _widget.addTranslation(2, 2, -2)

local _glassesDiscon = (function()
    local _mt =
    {
        __gc = function()
            glasses.removeAll()
        end
    }
    return setmetatable({}, _mt)
end)()

while true do
    computer.beep(700, 0.1)
    computer.pullSignal()
end

