--// Initialization

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

--// Functions

function Connection:Disconnect()
	for Index, Connection in next, self.Signal.Connections do
		if Connection == self then
			table.remove(self.Signal.Connections, Index)
			break
		end
	end
	
	self.Function = nil
	self.Signal = nil
end

function Connection:Fire(...)
	self.Function(...)
end

function Connection.new(BoundSignal, Function)
	local self = setmetatable({}, Connection)
	
	self.Function = Function
	self.Signal = BoundSignal
	
	table.insert(self.Signal.Connections, self)
	
	return self
end

function Signal:Connect(Function)
	local NewConnection = Connection.new(self, Function)
	
	if self.StoreFireNew then
		for _, Arguments in next, self.FireStore do
			spawn(function()
				Function(unpack(Arguments))
			end)
		end
	end
	
	return NewConnection
end

function Signal:Wait()
	table.insert(self.YieldedThreads, (coroutine.running()))
	
	return coroutine.yield()
end

function Signal:Fire(...)
	if self.StoreFireNew then
		table.insert(self.FireStore, {...})
	end
	
	for ThreadId = #self.YieldedThreads, 1, -1 do
		coroutine.resume(self.YieldedThreads[ThreadId], ...)
		table.remove(self.YieldedThreads, ThreadId)
	end
	
	for _, BoundConnection in next, self.Connections do
		local Success, Error = ypcall(Connection.Fire, BoundConnection, ...)
		
		if not Success then
			warn("Error detected in function bound to sSignal. Errata follows.")
			warn(Error)
			print(debug.traceback())
		end
	end
end

function Signal.new(StoreFireNew)
	local self = setmetatable({}, Signal)
	
	self.Connections = {}
	self.YieldedThreads = {}
	
	self.StoreFireNew = StoreFireNew
	self.FireStore = (self.StoreFireNew and {}) or nil
	
	return self
end

return Signal
