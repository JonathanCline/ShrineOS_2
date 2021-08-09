---@class AlgorithmLib: table

---@type AlgorithmLib
local algorithm = {}

---
---  Integer indexed table
---
--- @class array: table

---
---  Iterator function
---
--- @class iterator: function

---
--- Fills an array with a value
---
--- @param _table   array     Array to fill
--- @param _value   any       Value that will be filled into the array
--- @param _count?  integer  How many values to fill, defaults to array len
--- @param _index?  integer  Start position, defaults to first position
---
--- @return array
---
function algorithm.fill(_table, _value, _count, _index)
    _index = _index or 1
    _count = _count or #_table
    for i = _index, _count do
        _table[i] = _value
    end
    return _table
end

---
--- Creates a function that will keep returning the results of the bound function
---
--- Additional arguements are passed to the bound function upon each invocation and reffered to as "bound arguements"
---
--- @param _function function   Function to bind, reffered to as "bound function"
--- @vararg any                 Bound arguements
---
--- @return function
---
function algorithm.cbind(_function, ...)
    -- Bound arguements
    local _boundArgs = { ... }

    -- This is a simple optimization to avoid additional table api calls if no arguements were bound
    if #_boundArgs > 0 then

        ---
        --- Bound function with bound arguements
        ---
        --- @vararg any
        ---
        --- @return any
        ---
        return function()
            return _function(table.unpack(_boundArgs))
        end

    else

        ---
        --- Bound function without any bound arguements
        ---
        --- @vararg any
        ---
        --- @return any
        ---
        return function()
            return _function()
        end

    end
end

---
--- Creates a function that will keep returning the results of the bound function
---
--- Additional arguements are passed to the bound function upon each invocation and reffered to as "bound arguements"
---
--- Function returned may take additional arguements which are passed the bound function following any bound arguements
---
--- @param _function function Function to bind, reffered to as "bound function"
--- @vararg any               Bound arguements
---
--- @return function
---
function algorithm.bind(_function, ...)

    -- Bound arguements
    local _boundArgs = { ... }

    -- This is a simple optimization to avoid additional table api calls if no arguements were bound
    if #_boundArgs > 0 then

        ---
        --- Bound function with bound arguements
        ---
        --- Passes any arguements into the bound function after the bound arguements
        ---
        --- @vararg any
        ---
        --- @return any
        ---
        return function(...)
            return _function(table.unpack({ table.unpack(_boundArgs), ... }))
        end

    else

        ---
        --- Bound function without any bound arguements
        ---
        --- Passes any arguements into the bound function
        ---
        --- @vararg any
        ---
        --- @return any
        ---
        return function(...)
            return _function(...)
        end

    end
end

---
--- Drains a function into a array containing its results, passes additional arguements to the given function
---
--- Continues draining until the function returns nil
---
--- @param _table array         Array to add results to
--- @param _function function   Function to drain into the array
--- @vararg any                 Arguements to invoke function with
---
--- @overload fun(_function: function, ...)
---
--- @return array
---
function algorithm.drain(_table, _function, ...)

    -- Shift arguements over if no table was provided
    if type(_table) == "function" then
        _function = _table
        _table = nil
    end

    -- Create default table to drain into
    _table = _table or {}

    -- Drain function into table
    local _results
    repeat
        -- Invoke function and add arguements to table if any were returned
        _results = table.pack(_function(...))
        if #_results ~= 0 then
            _table[#_table + 1] = _results
        else
            _results = nil
        end

    until not _results

    -- Return modified table
    return _table
end

---
--- Returns an array containing the contents of the given array, but reversed
---
--- Notice: This function DOES NOT modify the given array
---
--- @param _table array    Array to reverse
---
--- @return array
---
function algorithm.reverse(_table)
    --- Reversed array
    --- @type array
    local _out = {}

    -- Loop through values and reverse
    local i = #_table
    repeat
        _out[#_out + 1] = _table[i]
        i = i - 1
    until i < 1

    -- Return reversed table
    return _out
end






return algorithm