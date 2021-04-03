local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")

local Heartbeat = RunService.Heartbeat

local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"

local Connections = {}
Connections.__index = Connections

local ActiveSignals = {}

function Signal.new(SignalName)
	assert(typeof(SignalName) == "string" or not SignalName,"Invalid value type for SignalName")
	local self = setmetatable({
		["functions"] = {};
		["LastSignaled"] = tick();
		["ID"] = "__" .. Http:GenerateGUID();
		["Active"] = true;

	},Signal)
	if SignalName then
		self["Name"] = SignalName
	end
	ActiveSignals[self.ID] = self
	return self
end

function Signal.Get(id)
	assert(typeof(id) == "string","Invalid value type for id")
	local self = ActiveSignals[id]
	if not self then
		for _,signal in pairs(ActiveSignals) do
			if signal["Name"] == id then
				self = signal
				break
			end
		end
	end
	return self
end

function Signal.WaitFor(id,length)
	assert(typeof(id) == "string","Invalid value type for id")
	assert(typeof(length) == "number" or not length,"Invalid value type for id")
	length = length or 5
	
	local signal
	local StartTime = tick()
	while (not signal) and tick()-StartTime <= length and Heartbeat:Wait() do
		local self = ActiveSignals[id]
		if not self then
			for _,signal in pairs(ActiveSignals) do
				if signal["Name"] == id then
					self = signal
					break
				end
			end
		end
		if self then
			return self
		end
	end
end

local function Connect(self,callback)
	assert(typeof(callback) == "function","Invalid argument type for callback")
	local ID = "__" .. Http:GenerateGUID()
	self.functions[ID] = callback
	local connection = setmetatable({["Signal"] = self.ID},Connections)
	connection.ID = ID
	return connection
end

function Signal:Connect(callback)
	return Connect(self,callback)
end


local function Fire(self,...)
	self.LastSignaled = tick()
	if ActiveSignals[self.ID].Active then
		for _,funct in pairs(self.functions) do
			coroutine.wrap(funct)(...)
		end
	end
end

function Signal:Fire(...)
	Fire(self,...)
end

local function WaitForSignal(self)
	local LastSignalTick = tonumber(self.LastSignaled)
	while true do
		Heartbeat:Wait()
		if LastSignalTick ~= self.LastSignaled then
			return LastSignalTick-self.LastSignaled
		end
	end
end

function Signal:Wait()
	WaitForSignal(self)
end


function Signal:Destroy()
	ActiveSignals[self.ID].Active = false
end

function Connections:Disconnect()
	ActiveSignals[self.Signal].functions[self.ID] = nil
end


return Signal