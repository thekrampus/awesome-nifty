--- Decorates clients with nifty borders. Adapted from meriadec/awesome-efficient
local cairo         = require("lgi").cairo
local gears         = require("gears")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local awful         = require("awful")

local smart_borders = {}

local def_color = "#c4c0c0"
local def_weight = 15
local def_string_weight = 4
local def_gutter = 20
local def_arrow = 120

local set_borders = function(c, firstRender)
   c.border_width = 0
   c.size_hints_honor = false

   local b_string_color = gears.color(beautiful.border_smart or def_color)
   local b_arrow_color = gears.color(beautiful.border_arrow_color or beautiful.border_smart or def_color)
   local b_weight = beautiful.border_weight or def_weight
   local b_string_weight = beautiful.border_string or def_string_weight
   local b_gutter = beautiful.border_gutter or def_gutter
   local b_arrow = beautiful.border_arrow or def_arrow

   local side = b_weight + b_gutter
   local total_width = c.width
   local total_height = c.height

   -- for some reasons, the client height/width are not the same at first
   -- render (when called by request title bar) and when resizing
   if firstRender then
      total_width = total_width + 2 * side
   else
      total_height = total_height - 2 * side
   end

   local imgTop = cairo.ImageSurface.create(cairo.Format.ARGB32, total_width, side)
   local crTop  = cairo.Context(imgTop)

   crTop:set_source(b_string_color)
   crTop:rectangle(0, b_weight / 2 - b_string_weight / 2, total_width, b_string_weight)
   crTop:fill()

   crTop:set_source(b_arrow_color)
   crTop:rectangle(0, 0, b_arrow, b_weight)
   crTop:rectangle(0, 0, b_weight, side)
   crTop:rectangle(total_width - b_arrow, 0, b_arrow, b_weight)
   crTop:rectangle(total_width - b_weight, 0, b_weight, side)
   crTop:fill()

   local imgBot = cairo.ImageSurface.create(cairo.Format.ARGB32, total_width, side)
   local crBot  = cairo.Context(imgBot)

   crBot:set_source(b_string_color)
   crBot:rectangle(0, side - b_weight / 2 - b_string_weight / 2, total_width, b_string_weight)
   crBot:fill()

   crBot:set_source(b_arrow_color)
   crBot:rectangle(0, b_gutter, b_arrow, b_weight)
   crBot:rectangle(0, 0, b_weight, side)
   crBot:rectangle(total_width - b_weight, 0, b_weight, side)
   crBot:rectangle(total_width - b_arrow, b_gutter, b_arrow, b_weight)
   crBot:fill()

   local imgLeft = cairo.ImageSurface.create(cairo.Format.ARGB32, side, total_height)
   local crLeft  = cairo.Context(imgLeft)

   crLeft:set_source(b_string_color)
   crLeft:rectangle(b_weight / 2 - b_string_weight / 2, 0, b_string_weight, total_height)
   crLeft:fill()

   crLeft:set_source(b_arrow_color)
   crLeft:rectangle(0, 0, b_weight, b_arrow - side)
   crLeft:rectangle(0, total_height - b_arrow + side, b_weight, b_arrow - side)
   crLeft:fill()

   local imgRight = cairo.ImageSurface.create(cairo.Format.ARGB32, side, total_height)
   local crRight  = cairo.Context(imgRight)

   crRight:set_source(b_string_color)
   crRight:rectangle(b_gutter + b_weight / 2 - b_string_weight / 2, 0, b_string_weight, total_height)
   crRight:fill()

   crRight:set_source(b_arrow_color)
   crRight:rectangle(b_gutter, 0, b_weight, b_arrow - side)
   crRight:rectangle(b_gutter, total_height - b_arrow + side, b_weight, b_arrow - side)
   crRight:fill()

   awful.titlebar(c, {
                     size = b_weight + b_gutter,
                     position = "top",
                     bg_normal = "transparent",
                     bg_focus = "transparent",
                     bgimage_focus = imgTop,
   }) : setup { layout = wibox.layout.align.horizontal, }

   awful.titlebar(c, {
                     size = b_weight + b_gutter,
                     position = "left",
                     bg_normal = "transparent",
                     bg_focus = "transparent",
                     bgimage_focus = imgLeft,
   }) : setup { layout = wibox.layout.align.horizontal, }

   awful.titlebar(c, {
                     size = b_weight + b_gutter,
                     position = "right",
                     bg_normal = "transparent",
                     bg_focus = "transparent",
                     bgimage_focus = imgRight,
   }) : setup { layout = wibox.layout.align.horizontal, }

   awful.titlebar(c, {
                     size = b_weight + b_gutter,
                     position = "bottom",
                     bg_normal = "transparent",
                     bg_focus = "transparent",
                     bgimage_focus = imgBot,
   }) : setup { layout = wibox.layout.align.horizontal, }
end

smart_borders.enable = function()
   client.connect_signal("request::titlebars", function(c) set_borders(c, true) end)
   client.connect_signal("property::size", set_borders)

   client.connect_signal("focus", set_borders)
end

return smart_borders
