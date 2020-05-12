-- create a table for the module
local luabt = {}

-- define the create function
function luabt.create(node)
  -- execution node
  if type(node) == "function" then
    --return node
    return function(treeDt)
      local running, result = node(treeDt)
      print("Function node returning", running, result) -- DEBUG
      if not running and result == nil then
        error("No result returned from node")
      else
        return running, result
      end
    end
    -- control flow node
  elseif type(node) == "table" then
    if not node.children or #node.children == 0 then error("No children for tree") end
    local children = {}

    if not (#node.children == #table.keys(node.children)) then error("Possibly nil in children definition") end

    -- recursively construct child nodes
    for index, child in ipairs(node.children) do
      children[index] = luabt.create(child, treeDt)
      if not children[index] then error "No child" end
    end

    if node.type == "negate" then
      -- return a negate decorator node
      return function(treeDt)
        print("negate") -- DEBUG
        child = children[1]
        running, success = child(treeDt)
        if running then
          return true
        else
          return false, not success
        end
      end
    elseif node.type == "doUntil" then
      -- WTF indentation what is going on
      return function(treeDt)
        print("until") -- DEBUG
        child = children[1]
        running, success = child(treeDt)
        if running or not success then
          return true
        else
          return false, true
        end
      end
    elseif node.type == "sequence" then
      -- return a sequence control flow node
      return function(treeDt)
        print("sequence") -- DEBUG
        for index, child in ipairs(children) do
          --print("index, child", index, child)
          running, success = child(treeDt)
          if running then
            return true -- child running
          elseif success == false then
            return false, false -- child not running, failed
          end
        end
        return false, true -- not running, all children succeeded
      end
    elseif node.type == "sequence*" then
      -- return a sequence control flow node with memory
      local states = {}
      return function(treeDt)
        print("sequence*") -- DEBUG
        for index, child in ipairs(children) do
          if states[index] == nil then
            running, states[index] = child(treeDt)
            if running then
              return true -- child running
            elseif states[index] == false then
              -- child failed, clear states and return the failure
              states = {}
              return false, false
            end
          end
        end
        -- all children succeeded, clear states and return success
        states = {}
        return false, true
      end
    elseif node.type == "selector" then
      -- return a selector control flow node
      return function(treeDt)
        print("selector") -- DEBUG
        for index, child in ipairs(children) do
          running, success = child(treeDt)
          if running then
            return true -- child running
          elseif success == true then
            return false, true -- child not running, succeeded
          end
        end
        return false, false -- not running, all children failed
      end
    elseif node.type == "selector*" then
      -- return a selector control flow node with memory
      local states = {}
      return function(treeDt)
        print("selector*") -- DEBUG
        for index, child in ipairs(children) do
          if states[index] == nil then
            running, states[index] = child(treeDt)
            if running then
              return true -- child running
            elseif states[index] == true then
              -- child suceeded, clear states and return the success
              states = {}
              return false, true -- child not running, succeeded
            end
          end
        end
        -- all children failed, clear states and return failure
        states = {}
        return false, false
      end
    elseif node.type then
      error("Node type not recognized " .. tostring(node.type))
    end
  else
    error("Empty node?")
  end
end

-- return the module
return luabt
