local M = {}
local Svc = {}

function M.fetch_user(id)
  return { id = id }
end

function Svc:fetch_user(id)
  return M.fetch_user(id)
end

return M
