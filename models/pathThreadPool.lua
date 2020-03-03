require 'love.system'
local processorCount = love.system.getProcessorCount( )

local threadPool = {}

local currentPoolIndex = 1

-- function doCalculate(pathFindObject)
--   local threadObject = getNextAvailableThreadObject()
--   threadObject.channelMain:push(pathFindObject)
-- end
--

local function initializePool(grid, finder)
  for i=1,processorCount do
    local thread = love.thread.newThread("models/pathThread.lua")
    local channelMain = love.thread.newChannel()
    local channelThread = love.thread.newChannel()
    table.insert(threadPool, {
      thread = thread,
      channelMain = channelMain,
      channelThread = channelThread
    })
    print(channelMain, channelThread)
    thread:start(channelMain, channelThread)
  end
end

local function getNextAvailableThreadObject()
  -- TODO: Actually check if thread is available. What to do if it's not?
  local threadObject = threadPool[currentPoolIndex]
  currentPoolIndex = currentPoolIndex + 1
  if currentPoolIndex > #threadPool then currentPoolIndex = 1 end
  return threadObject
end

local function getPathThread(fromX, fromY, toX, toY, searchNeighbours)
  local threadObject = getNextAvailableThreadObject()
  threadObject.channelMain:push({
    fromX = fromX,
    fromY = fromY,
    toX = toX,
    toY = toY,
    searchNeighbours = searchNeighbours
  })

  return threadObject
end
-- doCalculate(getNewPathFindObject())
-- doCalculate(getNewPathFindObject())
-- doCalculate(getNewPathFindObject())
-- doCalculate(getNewPathFindObject())

-- function love.update(dt)
--   for i=1,#threadPool do
--     local threadObject = threadPool[i]
--     local pathFindResult = threadObject.channelThread:pop()
--     if pathFindResult then
--       print("Result:", pathFindResult.result)
--     end
--   end
-- end

return {
  getPathThread = getPathThread,
  initializePool = initializePool
}
