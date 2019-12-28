-- Check if inner is within outer, 1 = first corner, 2 = second corner of rectangle
local function withinBounds(inner1x, inner1y, inner2x, inner2y, outer1x, outer1y, outer2x, outer2y, margin)
  margin = margin or 0
  return inner1x > outer1x-margin and
    inner1y > outer1y-margin and
    inner2x < outer2x+margin and
    inner2y < outer2y+margin
end

local function traverseTree(node, getChildrenFunc, callbackFunc)
  callbackFunc(node)
  local children = getChildrenFunc(node)
  if children then
    for _, child in ipairs(children) do
      traverseTree(child, getChildrenFunc, callbackFunc)
    end
  end
end

return {
  withinBounds = withinBounds,
  traverseTree = traverseTree
}
