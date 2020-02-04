--[[
  This behavior tree code was taken from our Zelda AI project for CMPS 148 at UCSC.
  It is for the most part unmodified, and comments are available for each function.
  Author: Kevin Cameron (mrunderhill89)
]]--

BT = {}
BT.__index = BT
BT.results = {success = "success"
					,fail = "fail"
					,wait = "wait"
					,error = "error"
					}
--[[
	Wrap function values to our results list so that we can use functions
	not tuned to our behavior tree
]]--
function BT:wrap(value)
	--If it's already a member of the results list, return it
	for k,v in pairs(BT.results) do
		if (value == k) then
			return v
		end
		if (value == v) then
			return v
		end
	end
	--If it's false, return fail
	if (value == false) then
		return BT.results.fail
	end
	--If it's anything else, return success
	return BT.results.success
end

--[[
	Creates a new behavior tree node.
	Lua makes it possible to change the type of a node
	just by replacing a function on a per-instance basis,
	making it easy to create new node types while only having to use
	one class. Just specify what run function you want the node to use, and 
	it should work just fine.
--]]
function BT:make(action)
	local instance = {}
	setmetatable(instance, BT)
	instance.children = {}
	--Ideally, actions should return a value from the results enum above and take a single table for arguments
	--Though you should be able to use void and boolean functions, as well.
	instance.run = action
	assert(type(instance.run) == "function", "Behavior tree node needs a run function, got "..type(instance.run).." instead.")
	return instance
end

--[[
	Adds a child to the behavior tree, and set the child's parent.
--]]
function BT:addChild(child)
	table.insert(self.children, child)
end

--[[
	Iterate through the node's children in a loop.
	Halt and return fail if any child fails.
	Otherwise, return success when done.
]]--
function BT:sequence(args)
	for k,v in ipairs(self.children) do
		if (BT:wrap(v:run(args)) == BT.results.fail) then
			return BT.results.fail
		end
	end
	return BT.results.success
end

--[[
	Iterate through the node's children in a loop.
	Halt and return success if any child succeeds.
	Otherwise, return fail when done.
]]--
function BT:select(args)
	for k,v in ipairs(self.children) do
		if (BT:wrap(v:run(args)) == BT.results.success) then
			return BT.results.success
		end
	end
	return BT.results.fail
end

--[[
	Time-sliced version of BT:sequence.
	Needs to be run multiple times (like in a loop) to be effective, but
	doesn't lock up the computer while running.
	
	When finished iterating, it will return either success or fail.
	If not finished, it will return wait.
	
	The index will NOT advance if the current child returns wait, which means
	a child node may be run more than once until it returns a definitive success or fail.
	This lets us chain together multiple time-sliced selectors or sequencers together.
]]--
function BT:slicesequence(args)
	if (self.current == nil) then
		self.current = 1
	else
		local child = self.children[self.current]
		if (child == nil) then
			self.current = 1
			return BT.results.success
		end
		local result = BT:wrap(child:run(args))
		if (result == BT.results.fail) then
			self.current = 1
			return BT.results.fail
		end
		if (result == BT.results.success) then
			self.current = self.current + 1
		end
	end
	return BT.results.wait
end

--[[
	Time-sliced version of BT:select.
	When finished iterating, it will return either success or fail.
	If not finished, it will return wait.
]]--
function BT:sliceselect(args)
	if (self.current == nil) then
		self.current = 1
	else
		local child = self.children[self.current]
		if (child == nil) then
			self.current = 1
			return BT.results.fail
		end
		local result = BT:wrap(child:run(args))
		if (result == BT.results.success) then
			self.current = 1
			return BT.results.success 
		end
		if (result == BT.results.fail) then
			self.current = self.current + 1
		end
	end
	return BT.results.wait
end

--[[
	Simply returns success if its child fails,
	or fail if the child succeeds. Any other result (like wait) is unmodified.
	
	Defaults to success if has no children or its child has
	no run function.
]]--
function BT:invert(args)
	if (self.children[1] == nil) then
		return BT.results.success 
	end
	local result = BT:wrap(self.children[1]:run(args))
	if (result == BT.results.success) then
		return BT.results.fail 
	end
	if (result == BT.results.fail) then
		return BT.results.success 
	end
	return result
end

--[[
	Continuously runs its child until it fails.
]]--
function BT:repeatUntilFail(args)
	while (BT:wrap(children[1]:run(args)) ~= BT.results.fail) do
	end
	return BT.results.success
end

--[[
	Continuously returns wait until its child fails.
	Effectively a time-sliced version of BT:repeatUntilFail.
]]--
function BT:waitUntilFail(args)
	if (BT:wrap(children[1]:run(args)) == BT.results.fail) then
			return BT.results.success
	end
	return BT.results.wait
end

function BT:limit(args)
    if (self.limit == nil) then
        self.limit = 1
        if (self.count == nil) then
        end
    end
end

--[[
	Testing routine for behavior trees
	Creates three action nodes, a sequencer, and a selector,
	then prints the resulting tree traversals
]]--
--[[
function printA(args)
	print("Child Node A")
end

function printB(args)
	print("Child Node B")
end

function printC(args)
	print("Child Node C")
end

function alwaysFail(args)
	print("Failure Node")
	return false
end

subA = BT:make(printA)
subB = BT:make(printB)
subC = BT:make(printC)
subF = BT:make(alwaysFail)
subNotA = BT:make(BT.invert)
subNotA:addChild(subA)
subNotF = BT:make(BT.invert)
subNotF:addChild(subF)

seq = BT:make(BT.sequence)
seq:addChild(subA)
seq:addChild(subB)
seq:addChild(subF)
seq:addChild(subC)

print("Sequencer:" .. seq:run() .. "\n")

sel = BT:make(BT.select)
sel:addChild(subF)
sel:addChild(subA)
sel:addChild(subB)
sel:addChild(subC)

print("Selector:" .. sel:run() .. "\n")

sliceseq = BT:make(BT.slicesequence)
sliceseq:addChild(subA)
sliceseq:addChild(subB)
sliceseq:addChild(subNotA)

local r = BT.results.wait
while (r == BT.results.wait) do
	r = sliceseq:run()
	print("Time-Sliced Sequence:" .. r)
end

print("\n")

slicesel = BT:make(BT.sliceselect)
slicesel:addChild(subF)
slicesel:addChild(subNotA)
slicesel:addChild(subNotF)

r = BT.results.wait
while (r == BT.results.wait) do
	r = slicesel:run()
	print("Time-Sliced Selector:" .. r)
end
]]--