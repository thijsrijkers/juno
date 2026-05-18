-- plugins/guild.lua  – guild floating terminal (self-contained, no dependencies)
local function toggle_guild()
  local state = _G._guild_state or {}
  _G._guild_state = state

  local function is_open()
    return state.win and vim.api.nvim_win_is_valid(state.win)
  end

  -- toggle close
  if is_open() then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
    return
  end

  -- dimensions
  local width  = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.75)
  local row    = math.floor((vim.o.lines - height) / 2) - 1
  local col    = math.floor((vim.o.columns - width) / 2)

  -- reuse or create buffer
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    state.buf = vim.api.nvim_create_buf(false, true)
  end

  -- open floating window
  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative  = "editor",
    row       = row,
    col       = col,
    width     = width,
    height    = height,
    style     = "minimal",
    border    = "rounded",
    title     = " guild ",
    title_pos = "center",
  })

-- start guild process only once per session
if not state.job then
  local cmd = vim.fn.executable("guild-go") == 1 and "guild-go" or "guild"
  state.job = vim.fn.termopen(cmd, {
      on_exit = function()
        state.job = nil
        state.buf = nil
        if state.win and vim.api.nvim_win_is_valid(state.win) then
          vim.api.nvim_win_close(state.win, true)
          state.win = nil
        end
      end,
    })

    -- <C-q> hides the window without killing guild
    vim.keymap.set("t", "<C-q>", function()
      if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
        state.win = nil
      end
    end, { buffer = state.buf, noremap = true, silent = true })
  end

  vim.cmd("startinsert")
end

-- register keymap + which-key group immediately
vim.keymap.set("n", "<leader>gg", toggle_guild, { desc = "Toggle guild", noremap = true, silent = true })

vim.api.nvim_create_autocmd("User", {
  pattern  = "LazyDone",
  once     = true,
  callback = function()
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ { "<leader>g", group = "[G]uild" } })
    end
  end,
})

return {}
