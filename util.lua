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

--- Log a system message.
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

--- Run a command and notify with output. Useful for debugging.
function util.run_and_notify(cmd)
   local outstr = util.pread(cmd .. " 2>&1")
   naughty.notify({title = cmd, text = outstr})
end

--- Recursively concat a table into a single formatted string.
function util.tcat(t, depth, max_depth)
   if type(t) ~= "table" then
      return tostring(t)
   end

   depth = depth or 0
   max_depth = max_depth or 4

   local indent = string.rep("  ", depth)

   if depth > max_depth then
      return indent .. "[...]\n"
   end

   local ret = ""
   for k,v in pairs(t) do
      ret = ret .. indent .. tostring(k) .. ": "
      if type(v) == "table" then
         ret = ret .. "{\n" .. util.tcat(v, depth+1) .. indent .. "}\n"
      else
         ret = ret .. tostring(v) .. "\n"
      end
   end
   return ret
end

--- Sanitize a string for Pango markup
function util.sanitize(raw_string)
   return raw_string
      :gsub("&", "&amp;")
      :gsub("<", "&lt;")
      :gsub(">", "&gt;")
      :gsub("'", "&apos;")
      :gsub("\"", "&quot;")
end

--- Format a formatting string using the given table as a reference.
-- Any instance of "${big_key.key}" will be replaced with the sanitized value
-- of tab.key if it exists, or the empty string otherwise.
function util.format(fmt, tab, big_key)
   for match, key in fmt:gmatch("(%${" .. big_key .. "%.(.-)})") do
      fmt = fmt:gsub(match, tab[key] and util.sanitize(tab[key]) or "")
   end
   return fmt
end

return util
