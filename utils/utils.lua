-- Check if inner is within outer, 1 = first corner, 2 = second corner of rectangle
local function withinBounds(inner1x, inner1y, inner2x, inner2y, outer1x, outer1y, outer2x, outer2y, margin)
  margin = margin or 0
  return inner1x > outer1x-margin and
    inner1y > outer1y-margin and
    inner2x < outer2x+margin and
    inner2y < outer2y+margin
end
--if x1 > l-drawMargin and x2 < l+w+drawMargin and y1 > t-drawMargin and y2 < t+h+drawMargin then
--

return {
  withinBounds = withinBounds
}
