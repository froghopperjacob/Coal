return function()
	local Class = BaseClass:new("Instance")
	
	local unpaired, useClass = { }, { }
	
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
	
	Class.Instance = function(self, ...)
		local args = { ... }
		
		if (check(args, { "string", "table" }, 2)) then
			local nin, par, tb = Instance.new(args[1]), nil, args[2]
						
			if (tb["className"] == "List") then				
				tb = tb.list
			end
			
			for name, value in pairs(tb) do				
				if (name == "Parent") then
					par = value
				else
					nin[name] = value
				end
			end
			
			if (par) then
				nin.Parent = par
			end
			
			table.insert(unpaired, nin)
			
			self:update(useClass)
			
			return nin
		end
	end
	
	Class.tieClass = function(self, scope, class)		
		useClass = class
		
		self:update(class)
	end
		
	Class.update = function(self, class)
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