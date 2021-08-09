---
---     ShrineOS
---
---     Terminal Library
---     v0.0.1
---
---     Provides basic terminal IO support.
---

--- @class TerminalLib
--- @type TerminalLib
local terminal = {}

local computer = require("computer")
local component = require("component")
local keyboard = require("keyboard")
local unicode = require("unicode")
local event = require("event")



-- Find best GPU and screen components

local gpu = component.list("gpu")()
local screen = component.list("screen")()



-- TODO : Handle missing GPU +/ Screen components without throwing an error

-- Handle missing GPU +/ Screen components
if not gpu or not screen then
    error("cannot open terminal library on system without GPU + Screen components")
    return
end

-- Bind screen to GPU, this should be handled elsewhere but will work for now

--- @type oc.component.gpu
gpu = component.proxy(gpu)
gpu.bind(screen, true)

---
--- Represents an area on the screen
---
--- @class Viewport

---
--- The viewport for the terminal output
---
--- @type Viewport
---
local viewport =
{
    x = 1,
    y = 1,
    w = 1,
    h = 1
}

-- Set viewport bounds
viewport.w, viewport.h = gpu.getViewport()


local cursor = require("cursor")
terminal.cursor = cursor.new(gpu, viewport)

-- Find keyboards
local keyboards = {}
for i, v in ipairs(component.invoke(screen, "getKeyboards")) do
    keyboards[v] = screen
end


---
--- Shifts the displayed lines up
---
--- @param _lines? integer How many times the display should be shifted up, defaults to 1
---
function terminal.shift(_lines)
	_lines = _lines or 1

	-- Make sure cursor isn't drawn
	cursor.clear(terminal.cursor)

	-- Copy displayed area
	gpu.copy(viewport.x, _lines, viewport.w, viewport.h - _lines, 0, -_lines)
    gpu.fill(viewport.x, viewport.h - (_lines), viewport.w, _lines, " ")

	-- Move cursor position
	cursor.shift(terminal.cursor, 0, -_lines)
end

---
--- Blocks until a printable key is pressed
--- Returns nil if interrupted or a non-printable key was pressed
---
--- @return string|nil
---
function terminal.raw_pull()
    local _printchar
    local _keycode

    while true do
        -- Wait until next signal
        local _signal = table.pack(computer.pullSignal(0.5))

        -- Check for non-timeout signal
        if _signal[1] then
            if _signal[1] == "key_down" and keyboards[_signal[2]] then
                _printchar = _signal[3]
                _keycode = _signal[4]
                goto got_signal
            elseif _signal[1] == "exit" or _signal[1] == "shutdown" then
                goto got_signal
            end
        end

		-- Toggle cursor
		cursor.toggle(terminal.cursor)

	end
    ::got_signal::

    -- Clear cursor if it's currently drawn
	cursor.clear(terminal.cursor)
    return unicode.char(_printchar), _keycode
end


terminal.preinputLen = 0
terminal.input = ""

local function clear_input_line()
    local _rx, _ry = cursor.relative(terminal.cursor)
	local _ax, _ay = cursor.absolute(terminal.cursor)

	gpu.fill(_ax + terminal.preinputLen, _ay, _rx, 1, " ")
    cursor.seek(terminal.cursor, terminal.preinputLen, _ry)
end

function terminal.clearinput()
    clear_input_line()
    terminal.input = ""
    terminal.preinputLen = 0
end

---
---
---
--- @return string, keycode
---
function terminal.pull()
    local _char, _key = terminal.raw_pull()
    if _char then
        if _key == keyboard.key.enter then
            clear_input_line()
            terminal.println(terminal.input)
            terminal.input = ""
        elseif _key == keyboard.key.backspace then
            if unicode.len(terminal.input) > 1 then
                clear_input_line()
                terminal.input = unicode.sub(terminal.input, 1, unicode.len(terminal.input) - 1)
                terminal.print(terminal.input)
            else
                clear_input_line()
                terminal.input = ""
                terminal.print(terminal.input)
            end
        elseif not keyboard.isControl(_key) then
            clear_input_line()
            terminal.input = terminal.input .. _char
            terminal.print(terminal.input)
        end
    end
	return _char, _key
end

---
--- Reads the next line inputted into the terminal by the user, will block untill enter is pressed
---
--- @return string
---
function terminal.readln()
    terminal.preinputLen = terminal.cursor.x
    while true do
        local _char, _key = terminal.raw_pull()
        if _char then
            if _key == keyboard.key.enter then
                clear_input_line()
                terminal.println(terminal.input)
                local o = terminal.input
                terminal.input = ""
                return o
            elseif _key == keyboard.key.backspace then
                if unicode.len(terminal.input) > 1 then
                    clear_input_line()
                    terminal.input = unicode.sub(terminal.input, 1, unicode.len(terminal.input) - 1)
                    terminal.print(terminal.input)
                else
                    clear_input_line()
                    terminal.input = ""
                    terminal.print(terminal.input)
                end
            elseif not keyboard.isControl(_key) then
                clear_input_line()
                terminal.input = terminal.input .. _char
                terminal.print(terminal.input)
            end
        end
    end
end

---
--- Clears the terminal and resets the _cursor
---
---
function terminal.clear()
	gpu.fill(viewport.x, viewport.y, viewport.w, viewport.h, " ")
	cursor.reset(terminal.cursor)
end

local function shift_check()
    local _, _ay = cursor.absolute(terminal.cursor)
    if _ay >= terminal.cursor.viewport.h then
        terminal.shift()
    end
end

---
--- Prints the arguements to the terminal without advancing the cursor
--- Arguements must be strings, numbers, or have a __tostring meta-method
---
---	Returns the number of characters written
---
--- @return integer
---
function terminal.insert(...)
    shift_check()
    -- Print the string
    local _args = table.pack(...)
    for i, v in ipairs(_args) do
        _args[i] = tostring(v)
    end

	local _str = table.concat(_args, " ")
	return cursor.insert(terminal.cursor, _str)
end

---
--- Prints the arguements to the terminal and advances the cursor
--- Arguements must be strings, numbers, or have a __tostring meta-method
---
---	Returns the number of characters written
---
--- @return integer
---
function terminal.print(...)
    shift_check()

    -- Print the string
    local _args = table.pack(...)
    for i, v in ipairs(_args) do
        _args[i] = tostring(v)
    end

	local _str = table.concat(_args, " ")
	return cursor.write(terminal.cursor, _str)
end

---
--- Prints the arguements to the terminal and appends a newline
--- Arguements must be strings, numbers, or have a __tostring meta-method
---
---	Returns the number of characters written
---
--- @return integer
---
function terminal.println(...)
    shift_check()

	-- Print the string
    local _args = table.pack(...)
    for i, v in ipairs(_args) do
        _args[i] = tostring(v)
    end

	local _str = table.concat(_args, " ")
	return cursor.writeln(terminal.cursor, _str)
end

print = terminal.println

return terminal