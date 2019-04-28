--- Make a plot out of dots! Tight!

local dot_plot = {}

local def_args = {
   width = 40,    -- width in characters
   height = 15,   -- height in characters
   y = {
      max = 100,  -- maximum of y-axis
      min = 0,    -- minimum of y-axis
      ticks = 3   -- ticks every 3 rows (0 to disable)
   },
   smoothing = 1, -- level of data interpolation
   verbose = 0    -- level of plotting data to output (0 or 1)
}

local null_glyph = "⠀"
local null_utf8 = 0x2800

local pixel_map = {
   { 0x01, 0x08 },
   { 0x02, 0x10 },
   { 0x04, 0x20 },
   { 0x40, 0x80 }
}

--- courtesy https://stackoverflow.com/a/26071044
local bytemarkers = { {0x7FF,192}, {0xFFFF,224}, {0x1FFFFF,240} }
local function encode(decimal)
   if decimal<128 then return string.char(decimal) end
   local charbytes = {}
   for bytes,vals in ipairs(bytemarkers) do
      if decimal<=vals[1] then
         for b=bytes+1,2,-1 do
            local mod = decimal%64
            decimal = (decimal-mod)/64
            charbytes[b] = string.char(128+mod)
         end
         charbytes[1] = string.char(vals[2]+decimal)
         break
      end
   end
   return table.concat(charbytes)
end

local function interpolate(a, b, res)
   local mid = {
      x = (a.x + b.x) / 2,
      y = (a.y + b.y) / 2
   }
   if res > 1 then
      --- Surely there's something I'm just not getting...
      -- return interpolate(a, mid, res-1), mid, interpolate(mid, b, res-1)
      local ret = interpolate(a, mid, res-1)
      ret[#ret+1] = mid
      for _, v in pairs(interpolate(mid, b, res-1)) do
         ret[#ret+1] = v
      end
      return ret
   else
      -- return mid
      return {mid}
   end
end

local function new_canvas(args)
   local canvas = {}

   --- transformation from cartesian space to screen-space to dot-space
   -- (x,y): cartesian point
   -- <x,y>: screen point
   -- col,row [x_i,y_i]: dot point
   -- <x> <- floor( ( (x - x_min) * 2 * c_width ) / (x_max - x_min) )
   -- <y> <- floor( ( (y - y_min) * 4 * c_height ) / (y_max - y_min) )
   -- col <- floor( <x> / 2 )
   -- row <- floor( <y> / 4 )
   -- x_i <- 1 + ( <x> % 2 )
   -- y_i <- 4 - ( <y> % 4 )

   local scale = {
      x = (2 * args.width) / (args.x.max - args.x.min),
      y = (4 * args.height) / (args.y.max - args.y.min)
   }

   canvas.set = function(self, x, y)
      if args.verbose >= 2 then
         print(string.format("Setting (%.1f, %.1f)...", x, y))
      end
      local px = {
         x = math.floor((x - args.x.min) * scale.x),
         y = math.floor((y - args.y.min) * scale.y)
      }
      local col = math.floor(px.x / 2)
      local row = math.floor(px.y / 4)
      local x_i = 1 + (px.x % 2)
      local y_i = 4 - (px.y % 4)
      if not self[row] then
         self[row] = {}
      end
      self[row][col] = (self[row][col] or null_utf8) | pixel_map[y_i][x_i]
      if args.verbose >= 2 then
         print(string.format("Set (%d, %d) => %d, %d [%d, %d]", px.x, px.y, col, row, x_i, y_i))
      end
   end

   canvas.render = function(self)
      local pad = math.max(tostring(args.y.max):len(), tostring(args.y.min):len())
      local pad_fmt = string.format("%%%dd", pad)

      local ret = ""
      for row=(args.height - 1), 0, -1 do
         -- render padding & y-axis ticks
         if args.y.ticks > 0 then
            if row%args.y.ticks == 0 then
               ret = ret .. pad_fmt:format(math.floor((row*4)/scale.y + args.y.min))
            else
               ret = ret .. string.rep(' ', pad)
            end
         end

         -- render plot
         for col=0, (args.width - 1) do
            ret = ret .. encode(self[row][col] or null_utf8)
         end

         -- new line, unless this is the last line
         if row > 0 then
            ret = ret .. "\n"
         end
      end

      -- render x-axis ticks
      if args.x.ticks > 0 then
         ret = ret .. "\n" .. string.format('%%%dd', pad+1):format(0)
         local xpad_fmt = string.format("%%%dd", args.x.ticks)
         for col=args.x.ticks, (args.width - 1), args.x.ticks do
            ret = ret .. xpad_fmt:format(math.floor((col*2) / scale.x + args.x.min))
         end
      end

      return ret
   end

   return canvas
end

local function getkeys(tbl)
   local keys = {}
   local n = 0

   for k,_ in pairs(tbl) do
      n = n+1
      keys[n] = k
   end

   return keys
end


local function infer_args(data, args)
   local xdata = getkeys(data)

   -- width defaults to data length / 2
   args.width = args.width or math.ceil(#xdata / 2)

   -- height defaults to 1 character
   args.height = args.height or 1

   -- smoothing defaults to 1 iteration
   args.smoothing = args.smoothing or 1

   -- verbosity defaults to 0 (none)
   args.verbose = args.verbose or 0

   -- if y-axis settings aren't given, populate them
   args.y = args.y or {}

   -- y-axis ticks default to every 3 rows
   args.y.ticks = args.y.ticks or 3

   -- y-axis max/min default to inferred based on data
   args.y.max = args.y.max or math.ceil(math.max(unpack(data)) + 0.01)
   args.y.min = args.y.min or math.floor(math.min(unpack(data)))

   -- if x-axis settings aren't given, populate them
   args.x = args.x or {}

   -- x-axis ticks default to 0 (off)
   args.x.ticks = args.x.ticks or 0

   -- y-axis max/min default to inferred based on data
   args.x.max = args.x.max or math.ceil(math.max(unpack(xdata)))
   args.x.min = args.x.min or math.floor(math.min(unpack(xdata)))

   -- if verbose, print arguments
   if args.verbose >= 1 then
      local pretty = require('pl.pretty')
      print("args = " .. pretty.write(args))
   end
   return args
end

-- Plot the given data using dots
--
-- @param data  The data to plot
-- @param args  Arguments for plotting, as follows:
--     - width: width of the plot, in characters. Default: half of number of data points, rounded up
--     - height: height of the plot, in characters. Default: 1
--     - smoothing: level of smoothing to apply. Default: 1
--     - verbose: level of debug output. Default: 0 (off)
--     - x, y: table of axis arguments, as follows:
--         - max: upper bound of axis. Default: upper bound of data
--         - min: lower bound of axis. Default: lower bound of data
--         - ticks: Axis tick period. Default: 3 rows for y, 0 (off) for x
dot_plot.plot = function(data, args)
   -- merge arguments
   args = infer_args(data, args or {})

   -- draw to canvas
   local canvas = new_canvas(args)
   local prev = false
   for x, y in ipairs(data) do
      if prev and args.smoothing > 0 then
         for _, pt in pairs(interpolate(prev, {x=x, y=y}, args.smoothing)) do
            canvas:set(pt.x, pt.y)
         end
      end
      canvas:set(x, y)
      prev = {x=x, y=y}
   end

   if args.verbose >= 3 then
      local pretty = require('pl.pretty')
      print("canvas = " .. pretty.write(canvas))
   end

   return canvas:render()
end

return dot_plot
