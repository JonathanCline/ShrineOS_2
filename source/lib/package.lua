---
--- The basic shrine OS system package manager
---
--- @class shrine.packagelib

--- @type shrine.packagelib
local package = {}

---
--- Contains the paths that the find function will search.
---
--- '*' is replaced with the package name when searching.
---
--- @type table
package.path = { "/lib/*.lib.lua", "/lib/*.lib", "/lib/*.lua", "/*.lua" }

---
--- Contains the packages currently loaded. This is local to prevent modification.
---
--- @type table
local loaded = {}

---
--- Package object
---
--- @class shrine.package
---
--- @field name string       Name of the package
--- @field lib table         Package table
--- @field path string       Path to the package's source file
--- @field rcount integer    Reference counter to allow unloading of unused packages
---

local component = component
local computer = computer
local debug = debug

---
--- Registers a package
---
--- Will throw an error if the name is already used
---
--- @param _name string         Name of the package
--- @param _rcount integer      Sets default ref count. If this is -1, the package will not be garbage collected
--- @param _lib table           Package table
--- @param _path? string        Package source path
---
--- @return boolean|nil good    True unless the name is already used, in which case nil is returned
---
function package.register(_name, _rcount, _lib, _path)
    -- Check that name is available
    if loaded[_name] then
        -- Name is currently in use
        return nil
    end

    ---@type shrine.package
    local _entry =
    {
        name = _name,
        lib = _lib,
        path = _path,
        rcount = _rcount or -1
    }

    -- Add to package loaded ledger table
    loaded[_name] = _entry
    return true
end

-- Register the default loaded packages
package.register("math",        -1, math)
package.register("string",      -1, string)
package.register("debug",       -1, debug)
package.register("table",       -1, table)
package.register("coroutine",   -1, coroutine)
package.register("unicode",     -1, unicode)
package.register("os",          -1, os)
package.register("package",     -1, package)
package.register("computer",    -1, computer)

local primaryFilesystem
if computer.getBootAddress then
    primaryFilesystem = computer.getBootAddress()
else
    primaryFilesystem = component.list("filesystem")()
end

local function isfile(_fs, _path)
    return  component.invoke(_fs, "exists", _path) and
            not component.invoke(_fs, "isDirectory", _path)
end


---
--- Attempts to find a package file given its name
---
--- @param _name string         Package name to use for path replacements
---
--- @return string? path
---
function package.find(_name)
    for i, v in ipairs(package.path) do
        local path = string.gsub(v, "%*", _name)
        if isfile(primaryFilesystem, path) then
            return path
        end
    end
end

---
--- Loads a package and returns pass/fail
---
--- On failure, an error message is provided
---
--- @param _name  string        Name of the package to load
--- @param _path  string|nil    Path to load package from, if nil this is resolved automatically
--- @param _rcount? integer     Sets default ref count, defaults to 1, set this to -1 to disable auto-collection
---
--- @return boolean success, errormessage? error
---
function package.load(_name, _path, _rcount)
    _path = _path or package.find(_name)
    if not _path then
        return false, "bad path"
    else
        local _good, _results = xinvoke(dofile, nil, _path)
        if not _good then
            return false, _results
        elseif loaded[_name] and not loaded[_name].lib then
            loaded[_name].lib = _results[1]
            return true
        else
            return package.register(_name, _rcount or 0, _results[1], _path)
        end
    end
end

---
--- Loads a package if it isn't loaded and returns the package
---
--- @param _name string Package name
--- @param _nothrow? boolean Set this to true to prevent throwing errors on failure, defaults to false
---
--- @return table|nil
---
function package.require(_name, _nothrow)
    if not loaded[_name] or not loaded[_name].lib then
        local _good, _err = package.load(_name)
        if not _good then
            if not _nothrow then
                error("Failed to load package " .. _name .. ". Reason: " .. _err)
            else
                return nil, _err
            end
        end
    end

    local _lib = loaded[_name]

    local mt =
    {
        __index = _lib.lib,
        __gc = function(self)
            if _lib.rcount > 0 then
                _lib.rcount = _lib.rcount - 1
            end
        end
    }
    if _lib.rcount >= 0 then
        _lib.rcount = _lib.rcount + 1
    end

    return setmetatable({}, mt)
end

--- Load in the correct component library
component = package.require("component", true)

---
--- @deprecated
---
function package.collect()
    for k, v in pairs(loaded) do
        if v.rcount == 0 then
            v.lib = nil
        end
    end
end

return package