return function()
	local Class = BaseClass:new("Vector2")
	
	local function check(args, checks, num)
		if (#args ~= num) then
			return error("Incorrect number of arguments provided. Expected " .. num .. " got " .. #args)
		end
		
		for i = 1, #args do
			local arg, check = args[i], checks[i]
			
			if (typeof(arg) ~= check) then
				return error("Incorrect argument type given at " .. i .. ". Expected " .. check .. " got " .. typeof(arg))
			end
		end
		
		return true
	end
	
	Class.Vector2 = function(self, ...)
		local args = { ... }
		
		if (check(args, { "number", "number" }, 2)) then
			return Vector2.new(...)
		end
	end
	
	return Class
end