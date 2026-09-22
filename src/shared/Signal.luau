--[[
	Minimal signal for module-to-module events on one machine.
]]

export type Connection = { Disconnect: (self: Connection) -> () }

export type Signal<T...> = {
	Connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
}

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	local handlers: { (T...) -> () } = {}
	local signal = {}

	function signal:Connect(handler: (T...) -> ()): Connection
		table.insert(handlers, handler)
		local connection = {}
		function connection:Disconnect()
			local index = table.find(handlers, handler)
			if index then
				table.remove(handlers, index)
			end
		end
		return connection
	end

	function signal:Fire(...: T...)
		for _, handler in table.clone(handlers) do
			task.spawn(handler, ...)
		end
	end

	return signal :: any
end

return Signal
