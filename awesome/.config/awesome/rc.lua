-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
local bling = require("bling")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")
local scratch = require("scratch")
local cpu_widget = require("awesome-wm-widgets.cpu-widget.cpu-widget")
local volume_widget = require("awesome-wm-widgets.volume-widget.volume")

require("main.error-handling")

local main = {
    layouts = {bling.layout.mstab, bling.layout.centered, awful.layout.suit.spiral, awful.layout.suit.magnifier}
}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

-- gaps
beautiful.useless_gap = 5

-- This is used later as the default terminal and editor to run.
terminal = "kitty"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
-- awful.layout.layouts = {awful.layout.suit.tile, awful.layout.suit.floating, awful.layout.suit.spiral,
--                         awful.layout.suit.magnifier}
-- -- }}}
awful.layout.layouts =
    {bling.layout.mstab, bling.layout.centered, awful.layout.suit.spiral, awful.layout.suit.magnifier}
-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {{"hotkeys", function()
    hotkeys_popup.show_help(nil, awful.screen.focused())
end}, {"manual", terminal .. " -e man awesome"}, {"edit config", editor_cmd .. " " .. awesome.conffile},
                 {"restart", awesome.restart}, {"quit", function()
    awesome.quit()
end}}

mymainmenu = awful.menu({
    items = {{"awesome", myawesomemenu, beautiful.awesome_icon}, {"open terminal", terminal}}
})

mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mymainmenu
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(awful.button({}, 1, function(t)
    t:view_only()
end), awful.button({modkey}, 1, function(t)
    if client.focus then
        client.focus:move_to_tag(t)
    end
end), awful.button({}, 3, awful.tag.viewtoggle), awful.button({modkey}, 3, function(t)
    if client.focus then
        client.focus:toggle_tag(t)
    end
end), awful.button({}, 4, function(t)
    awful.tag.viewnext(t.screen)
end), awful.button({}, 5, function(t)
    awful.tag.viewprev(t.screen)
end))

local tasklist_buttons = gears.table.join(awful.button({}, 1, function(c)
    if c == client.focus then
        c.minimized = true
    else
        c:emit_signal("request::activate", "tasklist", {
            raise = true
        })
    end
end), awful.button({}, 3, function()
    awful.menu.client_list({
        theme = {
            width = 250
        }
    })
end), awful.button({}, 4, function()
    awful.client.focus.byidx(1)
end), awful.button({}, 5, function()
    awful.client.focus.byidx(-1)
end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({"1", "2", "3", "4", "5", "6", "7", "8", "9"}, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(awful.button({}, 1, function()
        awful.layout.inc(1)
    end), awful.button({}, 3, function()
        awful.layout.inc(-1)
    end), awful.button({}, 4, function()
        awful.layout.inc(1)
    end), awful.button({}, 5, function()
        awful.layout.inc(-1)
    end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox[[]]
    s.mywibox = awful.wibar({
        position = "top",
        screen = s
    })

    -- Add widgets to the wibox
    s.mywibox:setup{
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            cpu_widget(),
            volume_widget(),
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox
        }
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(awful.button({}, 3, function()
    mymainmenu:toggle()
end), awful.button({}, 4, awful.tag.viewnext), awful.button({}, 5, awful.tag.viewprev)))
-- }}}

local function tab()
    awful.client.focus.history.previous()
    if client.focus then
        client.focus:raise()
    end
end

local function restore()
    local c = awful.client.restore()
    -- Focus restored client
    if c then
        c:emit_signal("request::activate", "key.unminimize", {
            raise = true
        })
    end
end

ezconfig = require('ezconfig')
ezconfig.modkey = 'Mod4'
ezconfig.altkey = 'Mod1'
globalkeys = ezconfig.keytable.join({
    ['<XF86AudioRaiseVolume>'] = volume_widget.raise,
    ['<XF86AudioLowerVolume>'] = volume_widget.lower,
    ['<XF86AudioMute>'] = volume_widget.toggle,
    ['M-<Left>'] = awful.tag.viewprev,
    ['M-<Right>'] = awful.tag.viewnext,
    ['M-<Escape>'] = awful.tag.history.restore,
    ['M-j'] = {awful.client.focus.byidx, 1},
    ['M-k'] = {awful.client.focus.byidx, -1},
    ['M-S-j'] = {awful.client.swap.byidx, 1},
    ['M-S-k'] = {awful.client.swap.byidx, -1},
    ['M-C-j'] = {awful.screen.focus_relative, 1},
    ['M-C-k'] = {awful.screen.focus_relative, -1},
    ['M-u'] = awful.client.urgent.jumpto,
    ['M-l'] = {awful.tag.incmwfact, 0.05},
    ['M-h'] = {awful.tag.incmwfact, -0.05},
    ['M-S-l'] = {awful.tag.incnmaster, -1, nil, true},
    ['M-S-h'] = {awful.tag.incnmaster, 1, nil, true},
    ['M-C-l'] = {awful.tag.incncol, -1, nil, true},
    ['M-C-h'] = {awful.tag.incncol, 1, nil, true},
    ['M-<Tab>'] = tab,
    ['M-<Return>'] = {awful.spawn, terminal},
    ['M-p'] = {awful.spawn, "rofi -show run"},
    ['M-/'] = {awful.spawn, "rofi -show window"},
    ['M-C-r'] = awesome.restart,
    ['M-['] = {scratch.toggle, "kitty --class quake", {
        instance = "quake"
    }},
    ['M-space'] = {awful.layout.inc, 1},
    ['M-S-space'] = {awful.layout.inc, -1},
    ['M-n'] = restore

})

clientkeys = gears.table.join(
    
awful.key({modkey}, "w", function(c)
        c:kill()
    end, {
        description = "close",
        group = "client"
    }), 


    awful.key({modkey}, "t", awful.client.floating.toggle, {
        description = "toggle floating",
        group = "client"
    }), 
    
    awful.key({modkey, "Control"}, "Return", function(c)
        c:swap(awful.client.getmaster())
    end, {
        description = "move to master",
        group = "client"
    }), 


    awful.key({modkey}, "o", function(c)
        c:move_to_screen()
    end, {
        description = "move to screen",
        group = "client"
    }), 


    awful.key({modkey}, "n", function(c)
        -- The client currently has the input focus, so it cannot be
        -- minimized, since minimized clients can't have the focus.
        c.minimized = true
    end, {
        description = "minimize",
        group = "client"
    }), 


    awful.key({modkey}, "f", function(c)
        c.maximized = not c.maximized
        c:raise()
    end, {
        description = "(un)maximize",
        group = "client"
    }), 
    
    awful.key({modkey, "Control"}, "m", function(c)
        c.maximized_vertical = not c.maximized_vertical
        c:raise()
    end, {
        description = "(un)maximize vertically",
        group = "client"
    }), 
    
    awful.key({modkey, "Shift"}, "m", function(c)
        c.maximized_horizontal = not c.maximized_horizontal
        c:raise()
    end, {
        description = "(un)maximize horizontally",
        group = "client"
    })
)



-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys, 
    awful.key({modkey}, "#" .. i + 9, function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
            tag:view_only()
        end
    end, {
        description = "view tag #" .. i,
        group = "tag"
    }), awful.key({modkey, "Control"}, "#" .. i + 9, function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
            awful.tag.viewtoggle(tag)
        end
    end, {
        description = "toggle tag #" .. i,
        group = "tag"
    }), awful.key({modkey, "Shift"}, "#" .. i + 9, function()
        if client.focus then
            local tag = client.focus.screen.tags[i]
            if tag then
                client.focus:move_to_tag(tag)
            end
        end
    end, {
        description = "move focused client to tag #" .. i,
        group = "tag"
    }), awful.key({modkey, "Control", "Shift"}, "#" .. i + 9, function()
        if client.focus then
            local tag = client.focus.screen.tags[i]
            if tag then
                client.focus:toggle_tag(tag)
            end
        end
    end, {
        description = "toggle focused client on tag #" .. i,
        group = "tag"
    }))
end

clientbuttons = gears.table.join(
    
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end), 
    
    awful.button({modkey}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end), 
    
    awful.button({modkey}, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {{
    rule = {},
    properties = {
        maximized_vertical = false,
        maximized_horizontal = false
    },
    callback = awful.client.setslave
}, {
    rule = {
        class = "Plasma-desktop"
    },
    properties = {
        floating = true
    },
    callback = function(c)
        c:geometry({
            width = 600,
            height = 500
        })
    end
}, {
    rule_and = {
        type = {"notification"},
        class = {"plasmashell"}
    },
    properties = {
        floating = true,
        border_width = 0,
        placement = awful.placement.centered,
        focusable = false
    }
}, {
    rule_any = {
        role = {"pop-up", "task_dialog"},
        name = {"win7"},
        class = {"plasmashell", "Plasma", "krunner", "Kmix", "Klipper", "Plasmoidviewer"}
    },
    properties = {
        floating = true,
        border_width = 0
    }
}, {
    rule = {
        instance = "quake"
    },
    properties = {
        floating = true
    },
    callback = function(c)
        awful.placement.centered(c, nil)
    end
}, {
    rule = {},
    properties = {
        border_width = beautiful.border_width,
        border_color = beautiful.border_normal,
        focus = awful.client.focus.filter,
        raise = true,
        keys = clientkeys,
        buttons = clientbuttons,
        screen = awful.screen.preferred,
        placement = awful.placement.no_overlap + awful.placement.no_offscreen
    }

}, {
    rule_any = {
        instance = {"DTA", -- Firefox addon DownThemAll.
        "copyq", -- Includes session name in class.
        "pinentry"},
        class = {"Arandr", "Blueman-manager", "Gpick", "Kruler", "MessageWin", -- kalarm.
        "Sxiv", "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
        "Wpa_gui", "veromix", "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {"Event Tester" -- xev.
        },
        role = {"AlarmWindow", -- Thunderbird's calendar.
        "ConfigManager", -- Thunderbird's about:config.
        "pop-up" -- e.g. Google Chrome's (detached) Developer Tools.
        }
    },
    properties = {
        floating = true
    }
}, {
    rule_any = {
        type = {"normal"}
    },
    properties = {
        titlebars_enabled = false
    },
    {
        rule_any = {
            type = {"dialog"}
        },
        properties = {
            titlebars_enabled = true
        }
    }
}}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(awful.button({}, 1, function()
        c:emit_signal("request::activate", "titlebar", {
            raise = true
        })
        awful.mouse.client.move(c)
    end), awful.button({}, 3, function()
        c:emit_signal("request::activate", "titlebar", {
            raise = true
        })
        awful.mouse.client.resize(c)
    end))

    awful.titlebar(c):setup{
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {
        raise = false
    })
end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)
-- }}}
-- autostart
-- awful.spawn.with_shell("picom -b")
-- awful.spawn.with_shell("nitrogen --restore")
