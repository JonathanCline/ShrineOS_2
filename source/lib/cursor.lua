---
--- Cursor library
---
--- @class CursorLib

---
--- Minimal cursor library, consider this heavily experimental
---
--- @type CursorLib
---
local cursor =
{
    off = 0,
    on = 1
}

local numeric = require("numeric")
local unicode = require("unicode")

---
--- The meta table for cursor objects
---
--- @type table
---
local cursor_mt =
{
    __gc = function(self)
        cursor.clear(self)
    end
}

---
--- Represents an output position that can be shifted
---
--- @class shrine.cursor

---
---
--- @class shrine.cursor.device: oc.component.gpu, shrine.gfx.device

---
--- Creates a new cursor object
---
--- @param _device shrine.cursor.device Cursor output device
--- @param _viewport Viewport           Cursor viewport region
--- @param _char? string|nil     	    Cursor display character, defaults to "█"
--- @param _x? integer|nil              Initial cursor x position, defaults to 0
--- @param _y? integer|nil              Initial cursor y position, defaults to 0
--- @param _state? integer|nil          Initial cursor state, defaults to cursor.off
---
--- @return shrine.cursor
---
function cursor.new(_device, _viewport, _char, _x, _y, _state)
	--- @type shrine.cursor
    local o =
    {
        x = _x or 0,
        y = _y or 0,
		char = _char or "█",
        state = _state or cursor.off,
        device = _device,
        viewport = _viewport
    }
	return setmetatable(o, cursor_mt)
end

---
--- Gets the position of the cursor relative to its viewport
---
--- @param _cursor shrine.cursor   Cursor to get position of
---
--- @return integer x, integer y
---
function cursor.relative(_cursor)
    return _cursor.x, _cursor.y
end

---
--- Gets the absolute position of the cursor
---
--- @param _cursor shrine.cursor   Cursor to get position of
---
--- @return integer x, integer y
---
function cursor.absolute(_cursor)
    local _x = _cursor.x + _cursor.viewport.x
    local _y = _cursor.y + _cursor.viewport.y
    return _x, _y
end

---
--- Refreshes the cursor on the screen
---
--- @param _cursor shrine.cursor    Cursor to refresh
--- @param _silent? boolean         Causes the cursor to not update the display if true
---
--- @return integer _cursor.state
---
function cursor.refresh(_cursor, _silent)
	-- Remove from the scren if not silent
	if not _silent then

        -- Get the absolute position
        local _ax, _ay = cursor.absolute(_cursor)

        if _cursor.state == cursor.on then
			-- Draw it if its on
			_cursor.device.set(_ax, _ay, _cursor.char)
		elseif _cursor.state == cursor.off then
			-- Remove it if its off
			_cursor.device.fill(_ax, _ay, 1, 1, " ")
		else
			-- Just throw an error on unrecognized state for now
			error("unknown cursor state " .. tostring(_cursor.state))
		end
	end
	return _cursor.state
end

---
--- Sets the cursor "off"
---
--- @param _cursor shrine.cursor    Cursor to turn "off"
--- @param _silent? boolean         Causes the display to not be updated if true
---
function cursor.clear(_cursor, _silent)
    if _cursor.state ~= cursor.off then
        -- Update state and refresh
        _cursor.state = cursor.off
		return cursor.refresh(_cursor, _silent)
    end
end

---
--- Sets the cursor "on"
---
--- @param _cursor shrine.cursor    Cursor to turn "on"
--- @param _silent? boolean         Causes the display to not be updated if true
---
function cursor.set(_cursor, _silent)
    if _cursor.state ~= cursor.on then
        -- Update state and refresh
        _cursor.state = cursor.on
		return cursor.refresh(_cursor, _silent)
	end
end

---
--- Toggles the cursor based on its current state
---
--- @param _cursor shrine.cursor    Cursor to toggle
--- @param _silent? boolean         Causes the cursor to not update the display if true
---
function cursor.toggle(_cursor, _silent)
	if _cursor.state == cursor.on then
        _cursor.state = cursor.off
	else
        _cursor.state = cursor.on
	end
    cursor.refresh(_cursor, _silent)
end

---
--- Shifts the cursor and updates display accordingly, will move the cursor onto the next line
--- if possible
---
--- @param _cursor shrine.cursor    Cursor to shift
--- @param _dx integer              Change in x position
--- @param _dy integer              Change in y position
--- @param _silent? boolean         Causes the cursor to not update the display if true
---
function cursor.shift(_cursor, _dx, _dy, _silent)

    -- Clear cursor to prevent leaving behind an artifact
    cursor.clear(_cursor, _silent)

    -- Preform the horizontal shift
    _cursor.x = _cursor.x + _dx

    -- Handle shifting passed the bounds
    if _cursor.x >= _cursor.viewport.w then
        -- Handle shifting past the right bound
        local _jump = math.floor(_cursor.x / _cursor.viewport.w)
        _cursor.x = _cursor.x - (_jump * _cursor.viewport.w)
        _dy = _dy + _jump
    elseif _cursor.x < 0 then
        -- TODO: Handle shifting past the left bound
        local _jump = math.floor(_cursor.x / _cursor.viewport.w)
        _dy = _dy + _jump
        return error("unfinished cursor.shift() on shifting passed the left bound")
    end

    -- Preform the vertical shift
    _cursor.y = _cursor.y + _dy

    -- Handle shifting passed the bounds
    numeric.clamp(_cursor.y, 0, _cursor.viewport.h - 1)

    -- Set cursor on
    return cursor.set(_cursor, _silent)
end

---
--- Advances the cursor
---
--- @param _cursor shrine.cursor    Cursor to shift
--- @param _count? integer          Positions to advance by, defaults to 1
--- @param _silent? boolean         Causes the cursor to not update the display if true
---
--- @return integer _cursor.x
---
function cursor.advance(_cursor, _count, _silent)
    cursor.shift(_cursor, _count, 0, _silent)
    return _cursor.x
end
---
--- Moves the cursor to the given position relative to its viewport
---
--- @param _cursor shrine.cursor    Cursor to seek
--- @param _x integer               Seek position x
--- @param _y integer               Seek position y
--- @param _silent? boolean         Causes the display to not be updated if true
---
function cursor.seek(_cursor, _x, _y, _silent)
    -- Set redraw boolean to prevent uneccesary function calls
    if not _silent then
        -- Clear cursor
        cursor.clear(_cursor)
    end

    -- Set new positions
    _cursor.x = numeric.clamp(_x, 0, _cursor.viewport.w - 1)
    _cursor.y = numeric.clamp(_y, 0, _cursor.viewport.h - 1)

    -- Redraw cursor if needed
    if not _silent then
        cursor.set(_cursor)
    end
end

---
--- Shifts the cursor onto the beginning of the next line
---
--- @param _cursor shrine.cursor    Cursor to shift
--- @param _silent? boolean         Causes the cursor to not update the display if true
---
function cursor.nextline(_cursor, _silent)
    local _, _ry = cursor.relative(_cursor)
    cursor.seek(_cursor, 0, _ry + 1)
end

---
--- Seeks the cursor the the upper left corner of its viewport
---
--- @param _cursor shrine.cursor    Cursor to reset
--- @param _silent? boolean         Causes the display to not be updated if true
---
function cursor.reset(_cursor, _silent)
    return cursor.seek(_cursor, 0, 0, _silent)
end

---
--- Inserts a string at the given cursor's position and returns the length of the string
---
--- @param _cursor shrine.cursor    Cursor
--- @param _str string              String to insert
---
--- @return integer
---
local function raw_insert(_cursor, _str)
    -- Get absolute cursor position
    local _ax, _ay = cursor.absolute(_cursor)

    -- Set string at the cursor position
    _cursor.device.set(_ax, _ay, _str)

    -- Return length of written string
    return unicode.len(_str)
end

---
--- Inserts a string at the given cursor's position
--- Returns the length of the written string
---
--- @param _cursor shrine.cursor    Cursor
--- @param _str string              String to insert
---
--- @return integer
---
function cursor.insert(_cursor, _str)
    -- Redraw cursor flag
    local _redraw = (_cursor.state == cursor.on)

    -- Clear cursor if needed
    if _redraw then
        cursor.clear(_cursor)
    end

    -- Insert the string
    local _len = raw_insert(_cursor, _str)

    -- Redraw cursor if needed
    if _redraw then
        cursor.set(_cursor)
    end

    -- Return length of inserted string
    return _len
end

---
--- Writes a string to the cursor's device and advances it by the length of the string
--- Returns the length of the written string
---
--- @param _cursor shrine.cursor    Cursor
--- @param _str string              String to insert
---
function cursor.write(_cursor, _str)
    -- Redraw cursor flag
    local _redraw = (_cursor.state == cursor.on)

    -- Clear cursor if needed
    if _redraw then
        cursor.clear(_cursor)
    end

    -- Insert the string
    local _len = raw_insert(_cursor, _str)

    -- Advance the cursor by the number of characters written
    cursor.advance(_cursor, _len, _redraw)

    -- Return length of written string
    return _len
end

---
--- Writes a string to the cursor's device and moves the cursor to the next line
---
--- Returns the length of the written string
---
--- @param _cursor shrine.cursor    Cursor
--- @param _str string              String to insert
---
--- @return integer count
---
function cursor.writeln(_cursor, _str)
    -- Redraw cursor flag
    local _redraw = (_cursor.state == cursor.on)

    -- Clear cursor if needed
    if _redraw then
        cursor.clear(_cursor)
    end

    -- Insert the string
    local _len = raw_insert(_cursor, _str)

    -- Move cursor to the next line
    cursor.nextline(_cursor, _redraw)

    -- Return length of written string
    return _len
end

return cursor