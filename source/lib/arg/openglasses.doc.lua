error("cannot open documentation header")

---
--- Open glasses library
---
--- @class oc.openglasses

--- @type oc.openglasses
local openglasses = {}

---
--- Open glasses terminal component
---
--- @class oc.component.glasses : oc.component, oc.openglasses

---
--- Requests the given player to link with the terminal, if no player is given, this will link will everyone in a 64 block radius
---
--- @param _player? string
---
function openglasses.startLinking(_player) end

---
--- Removes all widgets from the glasses display
---
function openglasses.removeAll() end

---
--- Returns the terminal name
---
--- @return string
---
function openglasses.getTerminalName() end

---
--- Sets the terminal name
---
--- @param _name string
---
function openglasses.setTerminalName(_name) end

---
--- Returns a list of connected players
---
--- @return table
---
function openglasses.getConnectedPlayers() end

---
--- Creates a new box widget
---
--- @return oc.openglasses.box2D
---
function openglasses.addBox2D() end

---
--- Creates a new cube widget
---
--- @return oc.openglasses.cube3D
---
function openglasses.addCube3D() end




---
--- Widget identifier
---
--- @class oc.openglasses.widgetID : integer

---
--- Base widget type
---
---"https://github.com/StarChasers/OCGlasses/wiki/Widget_Methods_default#getID"
---
--- @class oc.openglasses.widget

--- @type oc.openglasses.widget
local widget = {}

---
---  Returns the ID of a widget
---
---  @return oc.openglasses.widgetID
---
function widget.getID() end

---
---  Deletes the widget
---
function widget.removeWidget() end



---
--- Base modifier value type
---
--- @class oc.openglasses.modifier

--- @type oc.openglasses.modifier
local _mBase = {}

--- @alias oc.openglasses.modifier.type string
---| '"color"'
---| '"rotate"'
---| '"scale"'
---| '"translate"'
---| '"auto_translate"'

---
--- Returns the type of the modifer
---
--- @return oc.openglasses.modifier.type type
---
function _mBase.type() end



---
--- Color modifier value type
---
--- @class oc.openglasses.color : oc.openglasses.modifier

--- @type oc.openglasses.color
local _mColor = {}

---
--- Sets the modifier color value
---
--- @param _r number
--- @param _g number
--- @param _b number
--- @param _a number
---
--- @overload fun(_r: number, _g: number, _b: number)
---
function _mColor.set(_r, _g, _b, _a) end

---
--- Returns the modifier color value
---
--- @return integer r, integer g, integer b, integer a
---
function _mColor.get() end



---
--- Translate modifier value type
---
--- @class oc.openglasses.translate : oc.openglasses.modifier

--- @type oc.openglasses.translate
local _mTranslate = {}

---
--- Sets the modifier translation value
---
--- @param _x number
--- @param _y number
--- @param _z number
---
function _mTranslate.set(_x, _y, _z) end

---
--- Returns the modifier translation value
---
--- @return integer x, integer y, integer z
---
function _mTranslate.get() end



---
--- Translate modifier value type
---
--- @class oc.openglasses.scale : oc.openglasses.modifier

--- @type oc.openglasses.scale
local _mScale = {}

---
--- Sets the modifier scale value
---
--- @param _x number
--- @param _y number
--- @param _z number
---
function _mScale.set(_x, _y, _z) end

---
--- Returns the modifier scale value
---
--- @return integer x, integer y, integer z
---
function _mScale.get() end








---
--- Returns the widget's modifiers table
---
--- @return table
---
function widget.modifiers() end

---
--- Adds color to the widget
---
--- @param _red     number
--- @param _green   number
--- @param _blue    number
--- @param _alpha   number
---
--- @return integer index
---
function widget.addColor(_red, _green, _blue, _alpha) end

---
--- Adds translation to the widget
---
--- @param _x       number
--- @param _y       number
--- @param _z       number
---
--- @return integer index
---
function widget.addTranslation(_x, _y, _z) end

---
--- Returns if the widget is visible or not
---
--- @return boolean
---
function widget.isVisible() end

---
--- Sets if a widget is visible or not
---
--- @param _visible boolean
---
function widget.setVisible(_visible) end


---
--- Base 2D widget type
---
---"https://github.com/StarChasers/OCGlasses/wiki/Widget_Methods_default#getID"
---
--- @class oc.openglasses.widget2D : oc.openglasses.widget

--- @type oc.openglasses.widget2D
local widget2d = {}

---
--- Sets widget size
---
--- @param _width  number
--- @param _height number
---
function widget2d.setSize(_width, _height) end


---
--- Allows alignment for overlay widgets to the center of the screen
---
--- @param _percentX    number
--- @param _percentY    number
---
--- @return integer index
---
function widget2d.addAutoTranslation(_percentX, _percentY) end

---
--- Holds a 2d widget's size
---
--- @class oc.openglasses.widget2D.size
---
--- @field width integer
--- @field height integer
---

---
--- Gets the size of the widget
---
--- @return oc.openglasses.widget2D.size
---
function widget2d.getSize() end



---
--- 2D Box widget
---
---"https://github.com/StarChasers/OCGlasses/wiki/Widget_Box2D"
---
--- @class oc.openglasses.box2D : oc.openglasses.widget2D

--- @type oc.openglasses.box2D
local box2D = {}



---
--- Base 3D widget type
---
--- @class oc.openglasses.widget3D : oc.openglasses.widget

--- @type oc.openglasses.widget3D
local widget3d = {}

---
--- Returns the coordinates of the block that enables rendering when looked at and
--- if its function is currently on or off
---
--- @return number x, number y, number z, boolean enabled
---
function widget3d.getLookingAt() end

---
--- Enables rendering only when a certain block is being looked at
---
--- @param _visible boolean
---
--- @overload fun(_x: number, _y: number, _z: number)
---
function widget3d.setLookingAt(_visible) end


---
--- Returns the distance within which the widget can be viewed
---
--- @return number
---
function widget3d.getViewDistance() end

---
--- Sets the distance within which the widget can be viewed
---
--- @param _distance number
---
function widget3d.setViewDistance(_distance) end

---
--- Returns if the widget is visible through blocks or not
---
--- @return boolean
---
function widget.isVisibleThroughObjects() end

---
--- Sets if a widget is visible through blocks or not
---
--- @param _visible boolean
---
function widget.setVisibleThroughObjects(_visible) end





---
--- 3D Cube widget
---
---"https://github.com/StarChasers/OCGlasses/wiki/Widget_Cube3D"
---
--- @class oc.openglasses.cube3D : oc.openglasses.widget3D

--- @type oc.openglasses.cube3D
local cube3D = {}

---
---
--- @return boolean
---
function cube3D.getLookingAt() end




---
--- @class oc.openglasses.event.equipped_glasses
--- @field event string        "glasses_on" or "equiped_glasses"
--- @field id    oc.address     glasses component
--- @field user  string         player name
---

---
--- @class oc.openglasses.event.unequiped_glasses
--- @field event string        "glasses_off" or "unequiped_glasses"
--- @field id    oc.address     glasses component
--- @field user  string         player name
---




