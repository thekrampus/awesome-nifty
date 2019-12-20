--- More robust handling for multi-screen setups
local screens = {}

--- Map of mnemonics to screens
screens._map = {}
setmetatable(screens._map, { __index = function() return screen.primary end })
for s in screen do
   screens._map[s.index] = s
end

screens.get = function(id)
   if type(id) == "screen" then
      return id
   else
      return screens._map[id]
   end
end

screens.set = function(mnemonic, s)
   if type(s) ~= "screen" then
      if type(s) == "number" and s == math.floor(s) then
         s = screen[s]
      else
         s = screens.get(s)
      end
   end
   screens._map[mnemonic] = s
end

return screens
