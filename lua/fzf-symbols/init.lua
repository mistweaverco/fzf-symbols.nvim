local M = {}
local fzf = require("fzf-lua")
local utils = require("fzf-symbols.utils")

local SYMBOL_CACHE = {
  emoji = {},
  gitmoji = {},
}

M.setup = function() end

--Function to get the emoji from the cache or fetch it from the source
--@param sources table: A table of sources to fetch the emoji from
M.open = function(sources)
  if not sources or #sources == 0 then
    sources = { "emoji", "gitmoji" }
  end
  for _, source in ipairs(sources) do
    if not SYMBOL_CACHE[source] or vim.tbl_isempty(SYMBOL_CACHE[source]) then
      local plugin_path = utils.get_plugin_root_dir()
      local file_path = string.format("%s/sources/%s.json", plugin_path, source)
      if not vim.fn.filereadable(file_path) then
        vim.notify("File not found: " .. file_path, vim.log.levels.ERROR)
        return
      end
      local file = io.open(file_path, "r")
      if not file then
        vim.notify("Failed to open file: " .. file_path, vim.log.levels.ERROR)
        return
      end
      local content = file:read("*a")
      file:close()
      SYMBOL_CACHE[source] = vim.fn.json_decode(content)
    end
  end

  local symbols = {}
  local symbols_description = {}
  for _, source in ipairs(sources) do
    for _, symbol in ipairs(SYMBOL_CACHE[source]) do
      symbols[symbol[1] .. " " .. symbol[2]] = symbol[1]
      table.insert(symbols_description, symbol[1] .. " " .. symbol[2])
    end
  end

  fzf.fzf_exec(symbols_description, {
    fzf_opts = {
      ["--no-multi"] = true,
      ["--preview"] = "echo {}",
      ["--preview-window"] = "up:1",
    },
    actions = {
      ["default"] = function(selected)
        vim.api.nvim_put({ symbols[selected[1]] }, "c", true, true)
      end,
    },
  })
end

return M
