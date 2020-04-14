local function intersection(a, b)
  local result = {}

  for _, item in ipairs(a) do
    if table.index_of(b, item) then
      table.insert(result, item)
    end
  end
  
  return result
end

return {
  intersection = intersection
}
