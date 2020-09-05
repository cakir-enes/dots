local awful = require("awful")

local _M = {}

function _M.get()
    local layouts = {
        awful.layout.suit.tile, 
        awful.layout.suit.floating,
        awful.layout.suit.spiral,
        awful.layout.suit.magnifier
    }

    return layouts
end

return setmetatable({}, {__call = function(_, ...) return _M.get(...) end })