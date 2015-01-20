---
-- This file is intended to be used with cmder
-- http://bliker.github.io/cmder/
--
-- Replace your existing C:\bin\cmder\config\git.lua with this file
-- This will append the branch status to your prompt, e.g. [ahead 1, behind 2]
-- It basically takes the output of git status -sb and appends it (with coloring) to the cmder prompt (before the lambda)
---

---
-- Colors for git status
---
default = "\x1b[1;32;40m";
green = "\x1b[0;32;40m";
white = "\x1b[1;37;40m";
red = "\x1b[1;31;40m";

---
 -- Find out current branch
 -- @return {false|git branch name}
---
function get_branch_name()
    for line in io.popen("git branch 2>nul"):lines() do
        local m = line:match("%* (.+)$")
        if m then
            return m
        end
    end

    return false
end

---
 -- Get the remote state for the current branch
 -- @return {string}
---
function get_remote_state()
    local branch_status = io.popen("git status -sb 2>nul"):read("*l")
    local ahead_num = branch_status:match(".*%[.*ahead (%d+).*%]")
    local behind_num = branch_status:match(".*%[.*behind (%d+).*%]")
    local remote_state = { }
    
    if ahead_num or behind_num then
        table.insert(remote_state, white.." [")
        if ahead_num then
            table.insert(remote_state, "ahead "..green..ahead_num..white)
            if behind_num then
                table.insert(remote_state, ", ")
            end
        end
        if behind_num then
            table.insert(remote_state, "behind "..red..behind_num..white)
        end
        table.insert(remote_state, "]")
    end 

    return table.concat(remote_state)
end


---
 -- Get the color to use for the batch prompt
 -- @return {string}
---
function get_branch_color()
    local is_dirty = os.execute("git diff --quiet --ignore-submodules HEAD")    
    if is_dirty then
        return white
    else
        return red
    end
end

---
-- Filter function to register with clink
---
function git_prompt_filter()
    local branch = get_branch_name()
    if branch then
        local branch_color = get_branch_color()
        local remote_state = get_remote_state()
                
        clink.prompt.value = string.gsub(clink.prompt.value, "{git}", branch_color.."("..branch..")"..remote_state..default)
        
        return true
    end

    -- No git present or not in git file
    clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "")
    return false
end

clink.prompt.register_filter(git_prompt_filter, 50)
