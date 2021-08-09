local function init()
    do
        local computer = computer
        local component = component
        local function raw_loadfile(_path)
            local bootfs = computer.getBootAddress()
            local file = component.invoke(bootfs, "open", _path)
            local chunk = ""
            for v in function() return component.invoke(bootfs, "read", file, computer.freeMemory() / 4) end do
                chunk = chunk .. v
            end
            return load(chunk, "=" .. _path, "bt")
        end
        local _good, _err = xpcall(raw_loadfile("/system/boot.lua"), debug.traceback)
        assert(_good, _err)
    end

    local _chunk, _err = loadfile("/home/main.lua")
    assert(_chunk, _err)
    local _kernel, _err = dofile("/system/kernel.lua")
    assert(_kernel, _err)

    _kernel(_chunk)
end

local _good, _err = xpcall(init, debug.traceback)
assert(_good, _err)
