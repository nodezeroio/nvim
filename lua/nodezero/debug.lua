local M = {}
function M.inspect(obj, opts)
  print(vim.inspect(obj, opts))
end

function M.log(msg, level)
  local log_file = vim.fn.stdpath("log") .. "/nodezero-vim.log"
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local log_level = level or "INFO"
  local log_msg = string.format("[%s] [%s] %s\n", timestamp, log_level, msg)

  local file = io.open(log_file, "a")
  if file then
    file:write(log_msg)
    file:close()
  end
end

return M
