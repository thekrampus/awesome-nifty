--- Nifty utilities
local naughty = require("naughty")

local util = {}

local log_date_fmt = "%Y%m%d.%X"
local log_stat_fmt = "%8.3fs %8.1fkb"
local log_fmt = "%s %s: %s%s<%s>"
local log_width = 100

local function write_log(msg)
   print(msg)
end

-- Log a system message.
-- The message string in `msg` is formatted and timestamped.
-- The resulting log message is passed to `log_fn`, or printed to stdout by default
function util.log(msg, log_fn)
   log_fn = log_fn or write_log
   local caller = debug.getinfo(2)
   local caller_name = caller.name or tostring(caller.func) or "[function]"
   local timestamp = os.date(log_date_fmt)
   local stats = log_stat_fmt:format(os.clock(), collectgarbage("count"))
   local padding = string.rep(" ", log_width - (#caller_name + #msg + #stats + 5))
   local log_msg = log_fmt:format(timestamp, caller_name, msg, padding, stats)
   log_fn(log_msg)
end

-- Run a command and notify with output. Useful for debugging.
function util.run_and_notify(cmd)
   local outstr = util.pread(cmd .. " 2>&1")
   naughty.notify({title = cmd, text = outstr})
end

return util
