---
---     File management and normalization library
---

--- @class FilesystemLib

--- @type FilesystemLib
local filesystem = {}


local component = require("component")
local computer = require("computer")
local string = require("string")

local algorithm = require("algorithm")
local event = require("event")


---
--- Raw file handle
---
--- @class file_id: integer

---
--- RAII File handle
---
--- @class file
---
--- @field id file_id
--- @field device oc.address
---


---
--- List of filesystem devices
---
--- @type table
local devices = {}

--- @class MediaDevice

--- @class MediaRoot : string

---
--- Registers a filesystem device and returns its root segment
---
--- @param _address oc.address
---
--- @return MediaRoot
---
local function add_device(_address)
    local _root = string.sub(_address, 1, 4)

    --- @type MediaDevice
    devices[_root] =
    {
        address = _address,
        root = _root
    }
    return _root
end

---
--- The root filesystem device
---
--- @type MediaRoot
local root = add_device(computer.getBootAddress())

---
--- Removes a registered filesystem device
---
--- @param _address oc.address
---
local function remove_device(_address)
    devices[string.sub(_address, 1, 4)] = nil
end

--- Registers existing filesystem components
for k in component.list("filesystem") do
    add_device(k)
end

--- Automatically adds new filesystem devices
event.listen("component_added", function(_, _address, _type)
    if _type == "filesystem" then
        add_device(_address)
    end
end)

--- Automatically removes filesystem devices
event.listen("component_removed", function(_, _address, _type)
    if _type == "filesystem" then
        remove_device(_address)
    end
end)

---
--- File path segment delimiters
---
--- @type string
---
filesystem.delimiters = "/\\"

---
--- Returns the preffered path segment delimeter
---
--- @return string
---
function filesystem.preffered_delimeter()
    return "/"
end

---
--- Returns a character class matching file segment delimiter
---
--- @return string
---
local function delims()
    return filesystem.delimiters
end

---
--- Returns a match pattern for splitting a file path into segments
---
--- @return string
---
local function split_match()
    local _delims = delims()
    return string.format("([^%s]+)[%s]*", _delims, _delims)
end

--- @class PathLib
--- @type PathLib
filesystem.path = {}

---
--- File path object
---
--- @class path
---
--- @field segments table

do
    --- @type PathLib
    local path = filesystem.path

    --- Path lib metatable to improve usage
    local pathlib_mt =
    {
        __call = function(self, ...)
            return self.new(...)
        end
    }
    setmetatable(path, pathlib_mt)

    --- @class path_mt

    ---
    --- Path object metatable
    ---
    --- @type path_mt
    ---
    local path_mt =
    {
        ---
        --- @param self path    Path object
        ---
        --- @return function, table, nil
        ---
        __pairs = function(self)
            return next, self.segments, nil
        end,

        ---
        --- @param self path    Path object
        ---
        --- @return integer
        ---
        __len = function(self)
            return #self.segments
        end,

        --- @type string Path object type name
        __name = "path",

        ---
        --- @param self path    Path object
        --- @param key integer  Path segment index
        ---
        --- @return string
        ---
        __index = function(self, key)
            return self.segments[key]
        end,

        ---
        --- Converts a path object into a string
        ---
        --- @param self path    Path object
        ---
        --- @return string
        ---
        __tostring = function(self)
            return table.concat(self.segments, filesystem.preffered_delimeter())
        end,

        ---
        --- Concatination operator overload
        ---
        --- @param self path            Path object
        --- @param other path|string    Path object to concat or string convertible
        ---
        --- @return path self
        ---
        __concat = function(self, other)
            return path.concat(self, other)
        end,

        ---
        --- Append (addition) operator overload
        ---
        --- @param self path            Path object
        --- @param other path|string    Path object to concat or string convertible
        ---
        --- @return path self
        ---
        __add = function(self, other)
            return path.append(self, other)
        end
    }

    ---
    --- Splits a raw path string into a segment table
    ---
    --- @param _path string
    ---
    --- @return table
    ---
    local function raw_split(_path)
        local _splitter = string.gmatch(_path, split_match())
        local _segs = {}
        for v in _splitter do
            _segs[#_segs + 1] = v
        end
        return _segs
    end

    ---
    --- Creates a new file path object
    ---
    --- @param _pathstr? path|string|table   File path object, file path string, or path segments table
    ---
    --- @return path
    ---
    function path.new(_pathstr)

        if type(_pathstr) == "table" then
            local _mt = getmetatable(_pathstr)
            if _mt and _mt.__name == path_mt.__name then
                _pathstr = _pathstr.segments
            end
        elseif type(_pathstr) == "string" then
            _pathstr = raw_split(_pathstr)
        else
            _pathstr = { ":" }
        end

        --- @type path
        local _path = { segments = _pathstr }
        assert(type(_path.segments) == "table", "bad path segments")
        for i, v in ipairs(_path.segments) do
            assert(type(v) == "string", "bad path segment strings")
        end

        return setmetatable(_path, path_mt)
    end

    ---
    --- Appends two paths together (inserts a delimeter between each segment)
    ---
    --- @param _path path           Path object to append onto the end of
    --- @param _rhs  path|string    Path to be appended
    ---
    --- @return path
    ---
    function path.append(_path, _rhs)

        -- Split the path string into segments
        if type(_rhs) == "string" then
            _rhs = raw_split(_rhs)
        end

        -- Append segments
        for i, v in pairs(_rhs) do
            _path[#_path + 1] = v
        end

        return _path
    end

    ---
    --- Concatenates two paths together without inserting a delimiter
    ---
    --- @param _path path           Path object to concat onto the end of
    --- @param _rhs  path|string    Path to be concatted
    ---
    --- @return path
    ---
    function path.concat(_path, _rhs)

        -- Split the path string into segments
        if type(_rhs) == "string" then
            _rhs = raw_split(_rhs)
        end

        -- Concat a segment table
        for i, v in pairs(_rhs) do
            if i ~= 1 then
                -- Append the rest of the segments
                _path[#_path + 1] = v
            else
                -- Concat onto last segment
                _path[#_path] = _path[#_path] .. v
            end
        end

        return _path
    end

    ---
    --- Returns the filename pointed to by a file path
    ---
    --- @param _path path           Path object to concat onto the end of
    ---
    --- @return path
    ---
    function path.filename(_path)
        return path( _path[#_path] )
    end

    ---
    --- Returns the root of a file path if there is one
    ---
    --- @param _path path           Path object to concat onto the end of
    ---
    --- @return path|nil
    ---
    function path.root(_path)
        local _pattern = string.format("[^%s:]*:", delims())
        local _root = string.match(_path[1], _pattern)
        if _root then return path( _root ) end
    end

    ---
    --- Converts a file path into a useable path string
    ---
    --- @param _path path   File path to convert to string
    ---
    --- @return string
    ---
    function path.string(_path)
        local _out = ""
        if  string.match(_path[1], ":") then
            _out = filesystem.preffered_delimeter()
        end

        for i, v in pairs(_path) do
            if i ~= 1 or not string.match(v, ":") then
                _out = _out .. v
                if i ~= #_path then
                    _out = _out .. filesystem.preffered_delimeter()
                end
            end
        end
        return _out
    end

end

---
--- Returns the filesystem device that the given file path resides on if present
---
--- @param _path path       File path
---
--- @return oc.address?
---
function filesystem.device(_path)
    local _root = filesystem.path.root(_path)
    if _root then
        local _name = string.match(_root[1], "[^:]+")
        _name = _name or root
        if devices[_name] then
            return devices[_name].address
        end
    end
end

---
--- Returns an iterator over the list of filesystem devices
---
--- @return iterator
---
function filesystem.list_devices()
    local _next, _table, _index = pairs(devices)
    return function()
        local _k, _v = _next(_table, _index)
        _index = _k
        if _v then
            return _k, _v.address
        end
    end
end


---
--- Checks if a file path exists
---
--- @param _path    path            File path to check
--- @param _device? MediaDevice     File media device ID, defaults to path's device (root)
---
--- @return boolean
---
function filesystem.exists(_path, _device)
    _device = _device or filesystem.device(_path)
    if not _device then return false end
    return component.invoke(_device, "exists", filesystem.path.string(_path))
end

---
--- Checks if a file path is a directory
---
--- @param _path    path            File path to check
--- @param _device? MediaDevice     File media device ID, defaults to path's device (root)
---
--- @return boolean
---
function filesystem.is_directory(_path, _device)
    _device = _device or filesystem.device(_path)
    if not _device then return false end
    return component.invoke(_device, "isDirectory", filesystem.path.string(_path)) or false
end




local file_mt =
{
    --- @param self file
    __gc = function(self)
        filesystem.close(self.id)
    end
}

---@alias openmode string
---|> '"r"'
---| '"rb"'
---| '"w"'
---| '"wb"'
---| '"a"'
---| '"ab"'

---
--- Opens a file and returns a handle to it
---
--- @param _path path           File path to open
--- @param _mode openmode       Open mode for the file
--- @param _device? MediaDevice Filesystem device, defaults to path root device
---
--- @return file
---
function filesystem.open(_path, _mode, _device)

    _device = _device or filesystem.device(_path)
    if not _device then
        return nil, "path has no device (root)"
    end

    --- @type file
    local _file =
    {
        device = _device,
        id = component.invoke(_device, "open", filesystem.path.string(_path), _mode)
    }

    return setmetatable(_file, file_mt)
end

---
--- Closes a file
---
--- @param _file file       File handle
---
function filesystem.close(_file)
    if _file.id then
        component.invoke(_file.device, "close", _file.id)
        _file.id = nil
    end
end


---
--- Reads from an open file, returns nil once EOF has been reached
---
--- @param _file file       File handle
--- @param _count integer   Maximum characters to read
---
--- @return string|nil
---
function filesystem.read(_file, _count)
    return component.invoke(_file.device, "read", _file.id, _count)
end

---
--- Writes to an open file
---
--- @param _file file       File handle
--- @param _str  string     String to write
---
--- @return boolean
---
function filesystem.write(_file, _str)
    return component.invoke(_file.device, "write", _file.id, tostring(_str))
end


---
--- Removes a file from its media device
---
--- @param _path path           File path to remove
--- @param _device? MediaDevice Filesystem device, defaults to path root device
---
--- @return boolean
---
function filesystem.remove(_path, _device)
    _device = _device or filesystem.device(_path)
    if not _device then
        return false
    else
        return component.invoke(_device, "remove", filesystem.path.string(_path))
    end
end


---
--- Copies a file or directory from the source to the destination
---
--- @param _source      path        Source file path, must be absolute
--- @param _dest        path        Destination file path, must be absolute
--- @param _overwrite?  boolean     Enables overwriting existing files, defaults to false
---
--- @return boolean
---
function filesystem.copy(_source, _dest, _overwrite)

    -- Remove the destination if it already exists
    if filesystem.exists(_dest) then
        if _overwrite then
            filesystem.remove(_dest)
        else
            return false
        end
    end

    if filesystem.is_directory(_source) then
        -- Make new directory
        return component.invoke(filesystem.device(_dest), "makeDirectory", filesystem.path.string(_dest))
    else
        -- Open file handles
        _source = filesystem.open(_source, "r")
        _dest = filesystem.open(_dest, "w")

        -- Copy file data part by part
        local _readsome = function() filesystem.read(_source, 2048) end
        for v in _readsome do
            filesystem.write(_dest, v)
        end
    end

    return true
end

---
--- Returns a table containing the child paths of the given path
---
--- @param _path path               File path to get children of
--- @param _device? MediaDevice     File device, defaults to path device (root)
---
--- @return table
---
function filesystem.list(_path, _device)
    local _pathStr = filesystem.path.string(_path)

    _device = _device or filesystem.device(_path)
    local _children = component.invoke(_device, "list", _pathStr)
    local _out = {}

    for i, v in ipairs(_children) do
        _out[#_out + 1] = filesystem.path.new(tostring(_path) .. filesystem.preffered_delimeter() .. v)
    end

    return _out
end


return filesystem