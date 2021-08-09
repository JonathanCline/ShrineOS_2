---
---     ShrineOS
---
---     Views Library
---     v0.0.1
---
---     Provides C++20-like views
---

---
--- Views library
---
--- @class ViewsLib

--- @type ViewsLib
local views = {}

---
--- A table or table-like object
---
--- @class range: table

---
--- A wrapper around a range that doesn't modify said range but provides an interface into it
---
--- @class view
---
--- @field viewed range|view
---


---
--- Presents an underlying range as if it were in reverse order
---
--- @class reverse_view : view



--- @class reverse_view_t
--- @type reverse_view_t
views.reverse = {}

do
    local reverse = views.reverse

    local reverse_view_mt =
    {
        --- @param self reverse_view
        __len = function(self) return #self.viewed end,

        --- @param self reverse_view
        --- @param key integer
        __index = function(self, key)
            return self.viewed[#self - (tonumber(key) - 1)]
        end,

        --- @param self reverse_view
        --- @return iterator, reverse_view, nil
        __pairs = function(self)

            --- @param _table reverse_view
            --- @param _index integer
            --- @return integer, any
            local function _next(_table, _index)
                local _key = _index or 1
                _index = _key + 1
                return _key, _table[_key]
            end
            return _next, self, nil
        end,

        __newindex = function() error("cannot modify a viewed range") end,
    }

    ---
    --- Creates a new reverse view object
    ---
    --- @param _range range     Range to be viewed
    ---
    --- @return reverse_view
    ---
    function reverse.new(_range)
        local o = { viewed = _range }
        return setmetatable(o, reverse_view_mt)
    end

    local reverse_view_interface =
    {
        --- @param lhs range
        --- @param rhs reverse_view_t
        __shr = function(lhs, rhs)
            return reverse.new(lhs)
        end,

        --- @param self reverse_view_t
        --- @param _range range
        __call = function(self, _range)
            return self.new(_range)
        end
    }
    setmetatable(reverse, reverse_view_interface)

end

---
--- Creates a new reverse view
---
--- @param _range range
---
--- @return reverse_view
---
function views.reverse.new(_range)
    local _index = 1
    local _len = #_range
end




return views