local ts_utils = require("nvim-treesitter.ts_utils")
local term_buf = nil
local vis_buf2 = nil
local queued_job = nil
local current_job = nil
local complete = false
local detected_error = nil
local current_status_line = nil

local requested_commands = {}
local cmd_list = {}
local command_status = {}

-- =====================
-- Global variables
-- =====================
local M = {}


-- ==============
-- Functions
-- ==============

local function print_to_buffer(buffer)
  vim.api.nvim_buf_set_lines(buffer, 0, vim.api.nvim_buf_line_count(buffer), false, {})
  local prnt = {}
  local job_str_t = {}

  -- Current job
  if current_job then
    table.insert(prnt, " [" .. #requested_commands - #cmd_list .. "/" .. #requested_commands .."] Current job - " .. current_job)
  else
    table.insert(prnt, " [" .. #requested_commands - #cmd_list .. "/" .. #requested_commands .."] Current job - ")
  end

  -- Current status line
  if current_status_line then
    table.insert(prnt, current_status_line)
  else
    table.insert(prnt, "")
  end

  while #prnt < 5 do
    table.insert(prnt, "")
  end

  -- Job list
  table.insert(job_str_t, " --- Jobs --- ")
  for idx, cmd in ipairs(requested_commands) do
    local job_name = cmd[1]
    if job_name == current_job then
      table.insert(job_str_t, "-->" .. job_name .. " => " .. command_status[job_name]["status"])
    else
      table.insert(job_str_t, "   " .. job_name .. " => " .. command_status[job_name]["status"])
    end
    if command_status[job_name]["short_diagnostics"] ~= nil then
      table.insert(job_str_t, "\t\t\t\t\t" ..  command_status[job_name]["short_diagnostics"])
    end
  end
  vim.api.nvim_buf_set_lines(buffer, -2, -1, true, prnt)
  vim.api.nvim_buf_set_lines(buffer, -2, -1, true, job_str_t)
end

local function parse_current_status_line(last_line_str)
  current_status_line = last_line_str
end

local function parse_changes(identifier)
  if command_status[current_job] == nil then
    return false
  end

  if command_status[current_job]["short_diagnostics"] == nil and string.find(identifier, "error: ") then
    command_status[current_job]["short_diagnostics"] = identifier
  end

  if string.find(identifier, current_job .. "=> success") and not string.find(identifier, "echo") and not string.find(identifier, "; fi;") then
    command_status[current_job]["status"] = "success"
    command_status[current_job]["short_diagnostics"] = nil
    current_job = nil
    return true
  elseif string.find(identifier, current_job .. "=> fail") and not string.find(identifier, "echo") and not string.find(identifier, "; fi;") then
    command_status[current_job]["status"] = "fail"
    for idx, cmd in ipairs(requested_commands) do
      if cmd[1] == current_job then
        table.insert(requested_commands, 1, table.remove(requested_commands, idx))
        break
      end
    end
    current_job = nil
    return true
  end
  return false
end

local function is_complete()
  for k,v in pairs(command_status) do
    if v["status"] == "..." then
      return false
    end
  end

  complete = true
  return true
end

local function send_job(cmd)
  local cmd_msg = "if " .. cmd[2] .. "; then echo " .. cmd[1] .. "\"=> success\"; else echo " .. cmd[1] .. "\"=> fail\"; fi;"
  vim.api.nvim_command('FloatermSend --name=alchemy_term ' .. cmd_msg)
  current_job = cmd[1]
  detected_error = nil
end

local function test()
    if term_buf == nil then
      vim.api.nvim_command('FloatermNew --name=alchemy_term --cwd=/home/aaron/code/EdgeAI')
      term_buf = vim.api.nvim_win_get_buf(0)
      vim.api.nvim_command('FloatermHide --name=alchemy_term')
      vim.api.nvim_command('FloatermSend --name=alchemy_term shieldup')
      vim.api.nvim_command('FloatermSend --name=alchemy_term source ~/data/shield_setup_rc')
    end
    vim.api.nvim_command('FloatermSend --name=alchemy_term clear')

    if vis_buf2 == nil then
      vis_buf2 = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_command('bo vs' .. tostring(vis_buf2))
      -- vim.api.nvim_command('terminal')
      vim.api.nvim_command('set buftype=nofile')
      vim.api.nvim_command('set nowrap')
      vim.fn.matchadd("SuccessGroup", "success")
      vim.api.nvim_command('highlight SuccessGroup guifg=green ctermfg=green')

      vim.fn.matchadd("FailGroup", "fail")
      vim.fn.matchadd("FailGroup", "error")
      vim.api.nvim_command('highlight FailGroup guifg=red ctermfg=red')

      -- vim.api.nvim_command('set modifiable')
      vim.api.nvim_command('set nonumber')
      vis_buf2 = vim.api.nvim_win_get_buf(0)
    end

    cmd_list = {}
    command_status = {}
    for _,v in ipairs(requested_commands) do
      command_status[v[1]] = {}
      command_status[v[1]]["status"] = "..."
      command_status[v[1]]["short_diagnostics"] = nil
      table.insert(cmd_list, v)
    end

    complete = false
    print_to_buffer(vis_buf2, command_status)


    queued_job = table.remove(cmd_list, 1)

    vim.api.nvim_buf_attach(term_buf, false, {
      on_lines=function(...)
        local _, _, _, starting_line, _, ending_line, _ = ...
        local last_line_d = vim.api.nvim_buf_get_lines(term_buf, ending_line - 2, ending_line, false)
        local last_line_str = string.sub(table.concat(last_line_d), 0, 1000)
        -- parse_current_status_line(last_line_str)
        current_status_line = last_line_str
        for i = starting_line, ending_line do
          local val = vim.api.nvim_buf_get_lines(term_buf, i, i + 1, false)
          local identifier = string.sub(table.concat(val), 0, 1000)
          parse_changes(identifier)
          print(current_job)
          if queued_job == nil and current_job == nil then
            current_status_line = nil
            if next(cmd_list) ~= nil then
              queued_job = table.remove(cmd_list, 1)
            end
          end
        end

        return is_complete()
      end})


    local timer = vim.loop.new_timer()
    timer:start(500, 200, vim.schedule_wrap(function()
      print_to_buffer(vis_buf2, command_status)
      if queued_job ~= nil then
        send_job(queued_job)
        print("sending", queued_job[1])
        queued_job = nil
      end
      if complete == true then
        timer:close()
        print("Complete")
      end
    end))

end

function M.attach(bufnr, lang) end

function M.detach(bufnr) end

local function setup(user_config)
  for _,v in ipairs(user_config.cmds) do
    requested_commands[v[1]] = v[2]
    table.insert(requested_commands, v)
  end
end



return {test = test,
        setup = setup,
        }
