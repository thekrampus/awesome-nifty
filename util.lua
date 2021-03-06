--- Nifty utilities
local awful = require("awful")
local naughty = require("naughty")

local util = {}

local log_date_fmt = "%Y%m%d.%X"
local log_stat_fmt = "%8.3fs %8.1fkb"
local log_fmt = "%s %s: %s%s<%s>"
local log_width = 100

local toggle_fmt = "bash -c 'kill $(pgrep %s) || %s'"

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
   local function callback(out, err, _, code)
      local title = (code == 0) and cmd or cmd .. " (" .. tostring(code) .. ")"
      local text = (#err == 0) and out or "stdout:\n" .. out .. "\nstderr:\n" .. err
      naughty.notify{title=title, text=text}
   end

   awful.spawn.easy_async(cmd, callback)
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
      ret = ret .. indent .. tostring(k) .. "::" .. type(v) .. " = "
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

-- Yields a function to spawn the given program
function util.spawner(app)
   return function(opts)
      local opts = opts or {}
      awful.spawn(app, opts.sn_rules or true, opts.callback)
   end
end

--- Yields a function that toggles a given program.
-- First, this checks if an instance of the program is running.
-- If so, it kills all instances. Otherwise, it spawns a new instance.
-- Beware that the first whitespace-delimited token in the app string is
-- assumed to be the program name, so complex commands may not work the way
-- you think they do.
function util.toggler(app)
   local appname = app:match("[^%s]+")
   if not appname then return end

   local cb = function(sn_rules, callback, out, _, _, code)
      if code ~= 0 then
         awful.spawn(app, sn_rules or true, callback)
      else
         awful.spawn('kill ' .. out)
      end
   end

   return function(sn_rules, callback)
      awful.spawn.easy_async('pgrep ' .. appname,
                             function(...) cb(sn_rules, callback, ...) end
      )
   end
end

--- Yields a function that spawns a "watcher" terminal window.
-- This watcher window is a floating, sticky, on-top terminal window calling
-- `watch` with the given command. Useful for lots of things.
-- Takes a table of optional arguments:
-- @param cmd  The shell command to watch
-- @param opts A table of optional arguments
-- @param opts.terminal The terminal to open, defaults to the global value
-- @param opts.rules    Rules for spawning the client
-- @param opts.geometry Geometry to apply to the client on spawn
-- @param opts.interval Refresh interval for `watch`
function util.watcher(cmd, opts)
   local opts = opts or {}

   local terminal = opts.terminal or terminal or "xterm"

   local rules = opts.rules or {}
   rules.sticky = true
   rules.floating = true
   rules.ontop = true

   local callback = nil
   if opts.geometry then
      callback = function(c) c:geometry(opts.geometry) end
   end

   local interval = opts.interval or 0.5

   local watch_cmd = terminal .. " -e ewatch -n" .. interval .. " " .. cmd

   return function()
      awful.spawn(watch_cmd, rules, callback)
   end
end

--- Deep copy of a table
function util.copy_table(t)
   local copy = {}
   for k, v in pairs(t) do
      if type(v) == "table" then
         copy[k] = util.copy_table(v)
      else
         copy[k] = v
      end
   end
   return copy
end

--- Merge values from `b` into `a`.
-- All values in `a` will be preserved. If a value exists in `b` and
-- not in `a`, it will be copied to `a`.
function util.merge_tables(a, b)
   local merged = util.copy_table(a)
   for k, v in pairs(b) do
      if a[k] == nil then
         merged[k] = v
      elseif type(a[k]) == "table" and type(v) == "table" then
         merged[k] = util.merge_tables(a[k], v)
      end
   end

   return merged
end

--- A version of `merge_tables` that merges in-place rather than
-- creating a copy.
function util.merge_in_place(a, b)
   for k, v in pairs(b) do
      if a[k] == nil then
         a[k] = v
      elseif type(a[k]) == "table" and type(v) == "table" then
         a[k] = util.merge_in_place(a[k], v)
      end
   end
   return a
end

return util
