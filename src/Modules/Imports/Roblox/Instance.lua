return function()
	local Class = BaseClass:new("Instance")
	
	local instances, unpaired, useClass = { }, { }, nil
	
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
	
	Class.Instance = function(self, scope, ...)
		local args = { ... }
		
		if (check(args, { "string", "table" }, 2)) then
			local nin = Instance.new(args[1])
			
			for name, value in pairs(args[2]) do
				nin[name] = value
			end
			
			table.insert(instances, nin)
			table.insert(unpaired, nin)
			
			Class.update(useClass)
			
			return nin
		end
	end
	
	Class.tieClass = function(scope, class)		
		useClass = class
		
		Class.update(class)
	end
		
	Class.update = function(class)
		for name, value in pairs(class) do			
			if (typeof(value) == "function") then				
				for _, instance in pairs(unpaired) do					
					if (instance[name] ~= nil) then														
						instance[name]:Connect(function(...)							
							value(instance, ...)
						end)
					end
				end
				
				unpaired = { }
			end
		end
	end
		
	return Class
end