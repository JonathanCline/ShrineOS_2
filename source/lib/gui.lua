---@class GUILib
---@type GUILib
local gui = {}

---@class GFXElement
---@field __element table GFX element meta table

local elementLibs = {}

function gui.isLoaded(_name)
    return type("elementLibs[_name]") ~= nil
end

function gui.register(_name, _elementLib)
    elementLibs[_name] = _elementLib
end

function gui.lib(_name)
    return elementLibs[_name]
end

---@param _element GFXElement
function gui.draw(_element, _device)
    local _mt = _element.__element
    assert(_mt, "cannot draw non-element type")
    _mt.__draw(_element, _device)
end

do
    ---@class GFXRect: GFXElement

    local rect = {}

    local rectmt =
    {
        __draw = function(self, device)
            device.fill(self.x, self.y, self.width, self.height, self.color)
        end,
        __name = "rect"
    }

    function rect.new(_x, _y, _width, _height, _color)
        ---@type GFXRect
        local o =
        {
            x = _x,
            y = _y,
            width = _width,
            height = _height,
            color = _color or 0xFFFFFF,
            __element = rectmt
        }
        return o
    end

    gui.register("rect", rect)

end

do
    local group = {}

    local groupElement =
    {
        __draw = function(self, _device)
            for k, v in pairs(self.children) do
                gui.draw(v, _device)
            end
        end,
        __name = "group"
    }

    local groupMeta =
    {
        __newindex = function(self, key, value)
            self.children[key] = value
        end,
        __len = function(self)
            return #self.children
        end,
        __pairs = function(self)
            return next, self.children, nil
        end
    }

    function group.new()
        local o =
        {
            children = {},
            __element = groupElement
        }
        return setmetatable(o, groupMeta)
    end

    gui.register("group", group)

end

do
    local string = {}

    ---@class GFXString: GFXElement

    local stringmt =
    {
        __draw = function(self, device)
            device.set(self.x, self.y, self.text, self.color)
        end,
        __name = "string"
    }

    function string.new(_x, _y, _text, _color)
        ---@type GFXString
        local o =
        {
            x = _x,
            y = _y,
            text = _text,
            color = _color or 0xFFFFFF,
            __element = stringmt
        }
        return o
    end

    gui.register("string", string)
end


local buttons = {}

do
    local button = {}
    local buttonElement =
    {
        __draw = function(self, _device)
            gui.draw(self.rect, _device)
        end,
        __press = function(self, _device, _x, _y, _button, _player)
            if self.callbacks.press then
                self.callbacks.press(self, _device, _x, _y, _button, _player)
            end
        end,
        __release = function(self, _device, _x, _y, _button, _player)
            if self.callbacks.release then
                self.callbacks.release(self, _device, _x, _y, _button, _player)
            end
        end,
        __name = "button"
    }
    local mt =
    {
        __gc = function(self)
            buttons[self.id] = nil
        end
    }

    function button.new(_rect, _onPress, _onRelease)
        local o =
        {
            id = #buttons + 1,
            rect = _rect,
            callbacks =
            {
                press = _onPress,
                release = _onRelease
            },
            __element = buttonElement
        }
        buttons[o.id] = o
        return setmetatable(o, mt)
    end
    gui.register("button", button)
end


function gui.press(_device, _x, _y, _button, _player)
    for k, v in pairs(buttons) do
        local _rect = v.rect
        if _x >= _rect.x and _x < _rect.x + _rect.width and
           _y >= _rect.y and _y < _rect.y + _rect.height then
            v.__element.__press(v, _device, _x, _y, _button, _player)
            return
        end
    end
end

function gui.release(_device, _x, _y, _button, _player)
    for k, v in pairs(buttons) do
        local _rect = v.rect
        if _x >= _rect.x and _x < _rect.x + _rect.width and
           _y >= _rect.y and _y < _rect.y + _rect.height then
            v.__element.__release(v, _device, _x, _y, _button, _player)
            return
        end
    end
end

return gui