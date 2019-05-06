--- Synchronization tools
-- awesome wm is single-threaded, but aynchrous timers and callbacks
-- create a lot of situations where order of execution can't be
-- guaranteed. This library provides some synchronization tools.

local gears = require('gears')

local sync = {
   mutex = {},
   barrier = {}
}

local WAIT_POLL_PERIOD_S = 0.5

------------------------------------------------------------
--- Local tools

local function construct(class)
   local new = setmetatable({}, class)
   class.__index = class

   return new
end

local function default_timeout_cb()
   print("Error: timed out waiting for synchronization!")
   return false
end

--- Wait for a condition to be true, then call a callback
-- @param cond A function returning a boolean. Will stop waiting when
--             this function returns `true`.
-- @param callback A function to call once `cond` returns `true`.
-- @param timeout_s Optional time in seconds to wait before giving up
--                  with an error.
-- @param timeout_cb Optional callback to call when timeout is
--                   reached.
local function wait_for_cond(cond, callback, timeout_s, timeout_cb)
   local start_time = os.time()
   timeout_cb = timeout_cb or default_timeout_cb
   local function timer_cb()
      if cond() then
         callback()
         return false
      else
         if timeout_s and os.time() >= start_time + timeout_s then
            return timeout_cb()
         else
            return true
         end
      end
   end

   -- Call once initially; if it returns true, actually start the timer
   if timer_cb() then
      gears.timer.start_new(
         WAIT_POLL_PERIOD_S,
         timer_cb
      )
   end
end

------------------------------------------------------------
--- Mutex

--- Construct a new mutual exclusion object (mutex)
function sync.mutex:new()
   local new = construct(self)
   new._lock = false
   return new
end

--- Try to acquire the mutex lock.
-- @return True if the lock could be acquired, false otherwise.
function sync.mutex:try_lock()
   local initial = self._lock
   self._lock = true
   return not initial
end

--- Release the mutex lock on this buffer.
-- @return True if this "thread" held the lock, false otherwise.
function sync.mutex:release()
   local initial = self._lock
   self._lock = false
   return initial
end

--- Asynchronously acquire this lock, then call a callback.
-- @param callback A function to call once the lock is acquired.
-- @param timeout_s Optional time in seconds to wait before giving up.
-- @param timeout_cb Optional callback to call when timeout is
--                   reached.
function sync.mutex:with_lock(callback, timeout_s, timeout_cb)
   local cond = function() return self:try_lock() end
   wait_for_cond(cond, callback, timeout_s, timeout_cb)
end

------------------------------------------------------------
--- Barrier

--- Signal that this barrier is closed until this thread finishes.
function sync.barrier:start()
   self._n_sync = self._n_sync + 1
end

--- Signal that this thread has finished.
function sync.barrier:finish()
   self._n_sync = self._n_sync - 1
end

--- Call a callback once this barrier is open.
-- @param callback A function to call once the barrier is open.
-- @param timeout_s Optional time in seconds to wait before giving up.
-- @param timeout_cb Optional callback to call when timeout is
--                   reached.
function sync.barrier:when_open(callback, timeout_s, timeout_cb)
   local cond = function() return (self._n_sync <= 0) end
   wait_for_cond(cond, callback, timeout_s, timeout_cb)
end

--- Construct a new dynamic synchronization barrier.
-- This isn't really a barrier but it kinda acts like one.
function sync.barrier:new()
   local new = construct(self)
   new._n_sync = 0
   return new
end

return sync
