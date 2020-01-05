return function()
	local Class = BaseClass:new("Vector3")
	
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
	
	Class.Vector3 = function(self, scope, ...)
		local args = { ... }
		
		if (typeof(args[1]) == "EnumItem") then
			if (tostring(args[1]):find("NormalId")) then
				return Vector3.FromNormalId(args[1])
			elseif (tostring(args[1]):find("Axis")) then
				return Vector3.FromAxis(args[1])
			else
				return error("Incorrect Enum given")
			end
		else
			if (check(args, { "number", "number", "number" }, 3)) then
				return Vector3.new(...)
			end
		end
	end
	
	return Class
end