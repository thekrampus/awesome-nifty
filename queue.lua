--- Fixed-size queue implemented as a circular buffer

local queue = {}

--- Create a new fixed-size queue
-- @param capacity The limit on the number of items that may be added
--                 to the queue. Once this limit is hit, adding a new
--                 item will drop the oldest in the queue.
function queue:new(capacity)
   return setmetatable(
      {
         _data = {},
         _capacity = capacity,
         _head = 0
      }, {
         __index = function(t, k)
            if type(k) == "number" then
               return t:get(k)
            else
               return self[k]
            end
         end
   })
end

--- Return the number of items in the queue.
function queue:getn()
   return #self._data
end

--- Fetch an item in the queue by index.
-- You can also index the queue itself. If no item exists at the
-- given index, returns nil.
-- @param i The integer index in the queue, starting at 1.
-- @return The element at index `i`, or nil.
function queue:get(i)
   local q_i = (self._head - i) % self._capacity
   return self._data[q_i+1]
end

--- Add a new item to the head of the queue.
-- When the queue has reached capacity, this will remove the oldest
-- queued item.
-- @param item The item to be added.
function queue:put(item)
   self._data[self._head+1] = item
   self._head = (self._head + 1) % self._capacity
end

--- Queue iterator.
-- Iterates over the queue, from newest to oldest.
-- Note: modification of the queue during iteration can lead to
-- undefined behavior.
-- @return An iterator over the elements of this queue.
function queue:elements()
   local start
   local idx = (self._head - 1) % self._capacity
   local function it(t)
      if idx == start then
         return nil
      end
      start = start or idx
      local value = t[idx+1]
      idx = (idx - 1) % self._capacity
      return value
   end
   return it, self._data
end

--- Build an array representation of the queue.
-- @return A new array with the elements of the queue.
function queue:as_array()
   local arr = {}
   for el in self:elements() do
      arr[#arr+1] = el
   end
   return arr
end

function queue:to_string()
   return string.format('{ %s }', table.concat(self:as_array(), ', '))
end

return queue
