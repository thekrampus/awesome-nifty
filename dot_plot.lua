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
   smoothing = 1  -- level of data interpolation
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

local function range(from, to, step)
   step = step or 1
   return function(_, lastvalue)
      local nextvalue = lastvalue + step
      if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
         step == 0
      then
         return nextvalue
      end
   end, nil, from - step
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
   for row in range(0, args.height) do
      canvas[row] = {}
      for col in range(0, args.height) do
         canvas[row][col] = null_utf8
      end
   end

   local y_scale = (args.y.max - args.y.min) / args.height

   canvas.set = function(self, x, y)
      print(string.format("Setting (%.1f, %.1f)...", x, y))
      x = math.floor(x)
      y = math.floor(y/y_scale*4)
      local col = math.floor(x/2)
      local x_i = 1 + (x % 2)
      local row = math.floor(y/4)
      local y_i = 4 - (y % 4)
      if not self[row] then
         self[row] = {}
      end
      self[row][col] = (self[row][col] or null_utf8) | pixel_map[y_i][x_i]
      print(string.format("Set (%d, %d) => %d, %d [%d, %d]", x, y, col, row, x_i, y_i))
   end

   canvas.render = function(self)
      local pad = math.max(tostring(args.y.max):len(), tostring(args.y.min):len())
      local pad_fmt = string.format("%%%dd", pad)

      local ret = ""
      for row in range(args.height - 1, 0, -1) do
         if args.y.ticks > 0 then
            if row%args.y.ticks == 0 then
               ret = ret .. pad_fmt:format(math.floor(row*y_scale))
            else
               ret = ret .. string.rep(' ', pad)
            end
         end
         for col in range(0, args.width) do
            ret = ret .. encode(self[row][col] or null_utf8)
         end
         ret = ret .. "\n"
      end
      return ret
   end

   return canvas
end

dot_plot.plot = function(data, args)
   -- merge arguments
   args = args or {}
   for k,v in pairs(def_args) do
      if not args[k] then
         args[k] = v
      end
   end

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

   return canvas:render()
end

return dot_plot
