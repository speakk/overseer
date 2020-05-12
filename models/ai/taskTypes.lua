local tasksDir = "models/ai/tasks"
return functional.reduce(love.filesystem.getDirectoryItems(tasksDir), function(result, fileName)
  local name = string.gsub(fileName, ".lua", "")
  result[name] = require(string.gsub(tasksDir .. "/" .. name, "/", "."))
  return result
end, {})


