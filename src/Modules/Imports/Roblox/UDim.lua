return function()
	local class = BaseClass:new("UDim")
	
	local function check(args, checks, num)
		if (typeof(num) == "table") then
			local f = false
			
			for i = 1, #num do
				if (num[i] == #args) then
					f = true
				end
			end
			
			if (not f) then
				return error("Incorrect number of arguments provided. got " .. #args)
			end
		else
			if (#args < num) then
				return error("Incorrect number of arguments provided. Expected " .. num .. " got " .. #args)
			end
		end

		
		for i = 1, #args do
			local arg, check = args[i], checks[i]
			
			if (arg) then
				if (typeof(check) == "table") then
					local f = false
					
					for n = 1, #check do
						if (typeof(arg) == check[n]) then
							f = true
						end
					end
					
					if (not f) then
						return error("Incorrect argument type given at " .. i .. ". got " .. typeof(arg))
					end
				else
					if (typeof(arg) ~= check) then
						return error("Incorrect argument type given at " .. i .. ". Expected " .. check .. " got " .. typeof(arg))
					end
				end
			end
		end
		
		return true
	end
	
	class.UDim = function(self, ...)		
		local args = { ... }
		
		if (check(args, { "number", "number", "number", "number" }, { 2, 4 })) then
			if (#args == 2) then
				return UDim.new(unpack(args))
			else
				return UDim2.new(unpack(args))
			end
		end
	end
	
	return class
end