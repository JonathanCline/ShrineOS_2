---
---     ShrineOS
---
---     Keyboard Library
---     v0.0.1
---
---     Provides keyboard support such as named key key-code lookup.
---

--- @class KeyboardLib
--- @type KeyboardLib
local keyboard = {}

---
--- Keycode value
---
--- @class keycode: integer

---
--- Table containing named key's keycodes
---
--- @class NamedKeyCodes

---
--- Contains the key codes for all named keyss
---
--- @type NamedKeyCodes
---
local layout_qwerty =
{
    -- Alphabetical Keys

    a = 30, -- A = 30,
    b = 48, -- B = 48,
    c = 46, -- C = 46,
    d = 32, -- D = 32,
    e = 18, -- E = 18,
    f = 33, -- F = 33,
    g = 34, -- G = 34,
    h = 35, -- H = 35,
    i = 23, -- I = 23,
    j = 36, -- J = 36,
    k = 37, -- K = 37,
    l = 38, -- L = 38,
    m = 50, -- M = 50,
    n = 49, -- N = 49,
    o = 24, -- O = 24,
    p = 25, -- P = 25,
    q = 16, -- Q = 16,
    r = 19, -- R = 19,
    s = 31, -- S = 31,
    t = 20, -- T = 20,
    u = 22, -- U = 22,
    v = 47, -- V = 47,
    w = 17, -- W = 17,
    x = 45, -- X = 45,
    y = 21, -- Y = 21,
    z = 44, -- Z = 44,

    -- Symbolic Keys

    comma = 51,
    period = 52,
    slash = 53,
    backslash = 43,
    semicolon = 39,
    apostrophe = 40,
    minus = 12,         -- underscore = 12,
    equals = 13,        -- plus = 13,

    square_brace_left = 26,
    square_brace_right = 27,


    -- Number Keys

    n1 = 2,
    n2 = 3,
    n3 = 4,
    n4 = 5,
    n5 = 6,
    n6 = 7,
    n7 = 8,
    n8 = 9,
    n9 = 10,
    n0 = 11,


    -- Arrow keys

    left = 203,
    right = 205,
    up = 200,
    down = 208,


    -- Non-Printable Keys

    backspace = 14,
    tab = 14,
    enter = 28,
    space = 57,


    -- Control Keys

    left_shift = 42,
    right_shift = 54,

    left_control = 29,
    right_control = 157,

    caps_lock = 58
}

-- Set layout to qwerty by default
keyboard.key = layout_qwerty

--- @class ControlKeycodes

---
--- Set Containing the control keys
---
--- @type ControlKeycodes
---
keyboard.control_keys =
{
    [keyboard.key.left_shift] = true,
    [keyboard.key.right_shift] = true,

    [keyboard.key.left_control] = true,
    [keyboard.key.right_control] = true,
}

---
--- Checks if a key is a control key
---
--- @param _keycode integer Key code to check
--- @return boolean
---
function keyboard.isControl(_keycode)
    return keyboard.control_keys[_keycode] ~= nil
end




return keyboard