

---
--- The basic device API, shared between the device library and the device
---
--- @class shrine.gfx.device.api



-- Device API meta table
local device_api_mt

do
    --- @type shrine.gfx.device.api
    local device_api = {}

    ---
    --- Writes a string to the device
    ---
    --- @param _device shrine.gfx.device    Output device to write to
    --- @param _x integer                   Horizontal start position
    --- @param _y integer                   Vertical start position
    --- @param _str string                  String to write
    ---
    function device_api.set(_device, _x, _y, _str)
    end



    -- Set api __index meta field
    device_api_mt =
    {
        __index = device_api
    }

end

---
--- Defines a generic output device and general output support functions
---
--- @class shrine.gfx.devicelib: shrine.gfx.device.api

--- @type shrine.gfx.devicelib
local device = setmetatable({}, device_api_mt)


---
--- Generic graphical output device
---
--- @class shrine.gfx.device: shrine.gfx.device.doc


---
--- GPU output device
---
--- @class shrine.gfx.device.gpu : shrine.gfx.device, oc.component.gpu

---
---
---
--- @param _gpu oc.address.gpu    GPU component address
---
--- @return shrine.gfx.device.gpu
---
function device.gpu_device(_gpu)
    return component.proxy(_gpu)
end




return device