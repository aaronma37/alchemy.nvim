local ts_utils = require("nvim-treesitter.ts_utils")
local gui_purple = "#5f00d7"
local cterm_purple = "57"
local gui_green = "#5fd787"
local cterm_green = "78"
local gui_red = "red"
local cterm_red = "red"
local term_buf = nil
local vis_buf2 = nil
local queued_job = nil
local current_job = nil
local complete = false
local detected_error = nil
local current_status_line = nil
local current_stage_idx = nil
local anim_state = 1

local start_cmds = {}
local requested_commands = {
  stages = {},
}
local cmd_list = {}
local command_status = {
  stages = {}
}

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
  local success = true
  local p1 = {}
  table.insert(p1, "       ")
  table.insert(p1, "    ▏  ▕")
  table.insert(p1, "    ▏﹏▕")
  table.insert(p1, "   /.  .\\")
  table.insert(p1, "  / .·˙  \\")
  table.insert(p1, "  \\  .   /")
  table.insert(p1, "   ▔▔▔▔▔▔")
  local img = {}

  local p2 = {}
  table.insert(p2, "        ")
  table.insert(p2, "    ▏  ▕")
  table.insert(p2, "    ▏~~▕")
  table.insert(p2, "   /  . \\")
  table.insert(p2, "  / .    \\")
  table.insert(p2, "  \\  .   /")
  table.insert(p2, "   ▔▔▔▔▔▔")

  local p3 = {}
  table.insert(p3, "      ")
  table.insert(p3, "    ▏  ▕")
  table.insert(p3, "    ▏~~▕")
  table.insert(p3, "   /  · \\")
  table.insert(p3, "  / ·    \\")
  table.insert(p3, "  \\  · . /")
  table.insert(p3, "   ▔▔▔▔▔▔")

  local p4 = {}
  table.insert(p4, "       ")
  table.insert(p4, "    ▏  ▕")
  table.insert(p4, "    ▏~~▕")
  table.insert(p4, "   /  ˙ \\")
  table.insert(p4, "  / ˙    \\")
  table.insert(p4, "  \\  ˙ · /")
  table.insert(p4, "   ▔▔▔▔▔▔")

  local p5 = {}
  table.insert(p5, "       ")
  table.insert(p5, "    ▏  ▕")
  table.insert(p5, "    ▏~~▕")
  table.insert(p5, "   /.   \\")
  table.insert(p5, "  /  .   \\")
  table.insert(p5, "  \\   .˙ /")
  table.insert(p5, "   ▔▔▔▔▔▔")

  local p6 = {}
  table.insert(p6, "       ")
  table.insert(p6, "    ▏  ▕")
  table.insert(p6, "    ▏~~▕")
  table.insert(p6, "   /·   \\")
  table.insert(p6, "  /  · . \\")
  table.insert(p6, "  \\   ·  /")
  table.insert(p6, "   ▔▔▔▔▔▔")

  local p7 = {}
  table.insert(p7, "       ")
  table.insert(p7, "    ▏  ▕")
  table.insert(p7, "    ▏~~▕")
  table.insert(p7, "   /˙   \\")
  table.insert(p7, "  /  ˙ · \\")
  table.insert(p7, "  \\   ˙  /")
  table.insert(p7, "   ▔▔▔▔▔▔")

  local p8 = {}
  table.insert(p8, "       ")
  table.insert(p8, "    ▏  ▕")
  table.insert(p8, "    ▏~~▕")
  table.insert(p8, "   / .  \\")
  table.insert(p8, "  /   .˙ \\")
  table.insert(p8, "  \\ .    /")
  table.insert(p8, "   ▔▔▔▔▔▔")

  local p9 = {}
  table.insert(p9, "        ")
  table.insert(p9, "    ▏  ▕")
  table.insert(p9, "    ▏~~▕")
  table.insert(p9, "   / ·  \\")
  table.insert(p9, "  /   ·  \\")
  table.insert(p9, "  \\ ·    /")
  table.insert(p9, "   ▔▔▔▔▔▔")

  local p10 = {}
  table.insert(p10, "       ")
  table.insert(p10, "    ▏  ▕")
  table.insert(p10, "    ▏~~▕")
  table.insert(p10, "   / ˙  \\")
  table.insert(p10, "  /   ˙  \\")
  table.insert(p10, "  \\ ˙    /")
  table.insert(p10, "   ▔▔▔▔▔▔")

  table.insert(img, p2)
  table.insert(img, p3)
  table.insert(img, p4)
  table.insert(img, p5)
  table.insert(img, p6)
  table.insert(img, p7)
  table.insert(img, p8)
  table.insert(img, p9)
  table.insert(img, p10)

  for _, v in ipairs(img[anim_state]) do
    table.insert(prnt, v)
  end
  anim_state = anim_state + 1
  if anim_state > #img then
    anim_state = 1
  end



  -- Current job
  if current_stage_idx then
    table.insert(prnt, " [" .. current_stage_idx .. "/" .. #requested_commands['stages'] .."] Current stage - " .. requested_commands['stages'][current_stage_idx]["name"])
  else
    table.insert(prnt, " [" .. current_stage_idx .. "/" .. #requested_commands['stages'] .."] Current stage - ")
  end

  -- Current job
  if current_job then
    table.insert(prnt, " [" .. #requested_commands['stages'][current_stage_idx]['cmds'] - #cmd_list .. "/" .. #requested_commands['stages'][current_stage_idx]['cmds'] .."] Current job - " .. current_job)
  else
    table.insert(prnt, " [" .. #requested_commands['stages'][current_stage_idx]['cmds'] - #cmd_list .. "/" .. #requested_commands['stages'][current_stage_idx]['cmds'] .."] Current job -")
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
  for stage_idx, stage in ipairs(requested_commands['stages']) do
    table.insert(job_str_t, "")
    table.insert(job_str_t, " --- " .. stage['name'] .." --- ")
    for idx, cmd in ipairs(requested_commands['stages'][current_stage_idx]['cmds']) do
      local job_name = cmd[1]
      if command_status['stages'][stage_idx][job_name]["status"] == "fail" then
        success = false
      end
      if current_stage_idx >= stage_idx and job_name == current_job then
        table.insert(job_str_t, "-->" .. job_name .. ": " .. command_status['stages'][stage_idx][job_name]["status"])
      else
        table.insert(job_str_t, "   " .. job_name .. ": " .. command_status['stages'][stage_idx][job_name]["status"])
      end
      if command_status['stages'][stage_idx][job_name]["short_diagnostics"] ~= nil then
        table.insert(job_str_t, "\t\t\t\t\t" ..  command_status['stages'][stage_idx][job_name]["short_diagnostics"])
      end
    end
  end

  vim.api.nvim_buf_set_lines(buffer, -2, -1, true, prnt)
  vim.api.nvim_buf_set_lines(buffer, -2, -1, true, job_str_t)

  vim.api.nvim_buf_add_highlight(buffer, -1, "Identifier", 6, 0, 25)
  vim.api.nvim_buf_add_highlight(buffer, -1, "Identifier", 5, 0, 12)
  vim.api.nvim_buf_add_highlight(buffer, -1, "Identifier", 4, 0, 12)
  vim.api.nvim_buf_add_highlight(buffer, -1, "Identifier", 3, 0, 12)
  vim.api.nvim_buf_add_highlight(buffer, -1, "Identifier", 2, 7, 9)
  vim.api.nvim_buf_add_highlight(buffer, -1, "Identifier", 1, 7, 9)
  vim.api.nvim_buf_add_highlight(buffer, -1, "Identifier", 0, 5, 7)

  local gui_col = gui_purple
  local cterm_col = cterm_purple
  if complete then
    gui_col = gui_green
    cterm_col = cterm_green
  end
  if success == false then
    gui_col = gui_red
    cterm_col = cterm_red
  end
  vim.api.nvim_command('highlight Identifier guifg='.. gui_col ..' ctermfg=' .. cterm_col)
end

local function parse_current_status_line(last_line_str)
  current_status_line = last_line_str
end

local function parse_changes(identifier)
  if command_status['stages'][current_stage_idx][current_job] == nil then
    return false
  end

  if command_status['stages'][current_stage_idx][current_job]["short_diagnostics"] == nil and string.find(identifier, "error: ") then
    command_status['stages'][current_stage_idx][current_job]["short_diagnostics"] = identifier
  end

  if (string.find(identifier, current_job .. "=> success") or string.find(identifier, "PASSED") ) and not string.find(identifier, "echo") and not string.find(identifier, "; fi;") then
    command_status['stages'][current_stage_idx][current_job]["status"] = "success"
    command_status['stages'][current_stage_idx][current_job]["short_diagnostics"] = nil
    current_job = nil
    return true
  elseif string.find(identifier, current_job .. "=> fail") and not string.find(identifier, "echo") and not string.find(identifier, "; fi;") then
    command_status['stages'][current_stage_idx][current_job]["status"] = "fail"
    for idx, cmd in ipairs(requested_commands['stages'][current_stage_idx]['cmds']) do
      if cmd[1] == current_job then
        table.insert(requested_commands['stages'][current_stage_idx]['cmds'], 1, table.remove(requested_commands['stages'][current_stage_idx]['cmds'], idx))
        break
      end
    end
    current_job = nil
    return true
  end
  return false
end

local function start_stage()
  if #requested_commands['stages'] == 0 then
    return 
  end
  if current_stage_idx == nil then
    current_stage_idx = 1
  elseif current_stage_idx <= #requested_commands['stages'] then
    current_stage_idx = current_stage_idx + 1
  else
    return
  end

  command_status['stages'][current_stage_idx] = {}
  for _,v in ipairs(requested_commands['stages'][current_stage_idx]['cmds']) do
    command_status['stages'][current_stage_idx][v[1]] = {}
    command_status['stages'][current_stage_idx][v[1]]["status"] = "..."
    command_status['stages'][current_stage_idx][v[1]]["short_diagnostics"] = nil
    table.insert(cmd_list, v)
  end
  queued_job = table.remove(cmd_list, 1)
end

local function initialize_status()
  command_status['stages'] = {}
  for stage_idx,v in ipairs(requested_commands['stages']) do
    command_status['stages'][stage_idx] = {}
    for cmd_idx, cmd in ipairs(v['cmds']) do
    command_status['stages'][stage_idx][cmd[1]] = {}
    command_status['stages'][stage_idx][cmd[1]]["status"] = "..."
    command_status['stages'][stage_idx][cmd[1]]["short_diagnostics"] = nil
    end
  end
end

local function is_complete()
  for k,v in pairs(command_status['stages'][current_stage_idx]) do
    if v["status"] == "..." then
      return false
    end
  end
  if current_stage_idx >= #requested_commands['stages'] then
    complete = true
    return true
  end
  print("COMPLETEA")
  start_stage()
  return false
end

local function send_job(cmd)
  local cmd_msg = "if " .. cmd[2] .. "; then echo " .. cmd[1] .. "\"=> success\"; else echo " .. cmd[1] .. "\"=> fail\"; fi;"
  vim.api.nvim_command('FloatermSend --name=alchemy_term ' .. cmd_msg)
  current_job = cmd[1]
  detected_error = nil
end

local function test()
    if term_buf == nil then
      vim.api.nvim_command('FloatermNew --name=alchemy_term')
      term_buf = vim.api.nvim_win_get_buf(0)
      vim.api.nvim_command('FloatermHide --name=alchemy_term')
      for _, start_cmd in ipairs(start_cmds) do
        local cmd_msg = "FloatermSend --name=alchemy_term " .. start_cmd
      end
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
      vim.api.nvim_command('<ESC> <C-W> <C-W>')
    end

    cmd_list = {}
    current_stage_idx = nil
    initialize_status()
    start_stage()

    complete = false
    print_to_buffer(vis_buf2, command_status)


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
  for _,v in ipairs(user_config.stages) do
    local stage_cmds = {}
    for _,v in ipairs(v.cmds) do
      table.insert(stage_cmds, v)
    end
    local new_stage = {}
    new_stage["cmds"] = stage_cmds
    new_stage["name"] = v.name
    table.insert(requested_commands["stages"], new_stage)
  end
  for _,v in ipairs(user_config.start_cmds) do
    table.insert(start_cmds, v)
  end
end



return {test = test,
        setup = setup,
        }
