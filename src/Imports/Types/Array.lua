return function(...)
	local array = { ... }
	
	return setmetatable({
		["length"] = function()
			return #array
		end,
		
		["append"] = function(i)
			array[#array + 1] = i
		end,
		
		["insert"] = function(index, i)
			table.insert(array, index, i)
		end,
		
		["remove"] = function(index)
			table.remove(array, index)
		end,
		
		["getDefault"] = function(index, o)
			if (array[index] == nil) then
				return o
			end
			
			return array[index]
		end,
		
		["delete"] = function(i)
			local find
			
			for i, v in ipairs(array) do
				if (v == x and find == nil) then
					find = i
				end
			end
			
			table.remove(array, find)
		end,
		
		["join"] = function(sep)
			local str, length = "", 0
			
			if (typeof(sep) == "table") then
				length = sep.length()
			else
				length = sep:len()
			end
			
			for _, v in ipairs(array) do
				str = str .. sep
			end
			
			return str:sub(1, -(length + 1))
		end,
		
		["pop"] = function(index)
			return table.remove(array, index or #array)
		end,
		
		["forEach"] = function(func)
			for index, value in pairs(array) do
				func(index, value)
			end
		end,
		
		["clear"] = function()
			array = { }
		end,
		
		["count"] = function(x)
			local times = 0
			
			for _, v in ipairs(array) do
				if (v == x) then
					times = times + 1
				end
			end
			
			return times
		end,
		
		["reverse"] = function()
			for i = 1, math.floor(#array / 2) do
				local j = #array - i + 1
				
				array[i], array[j] = array[j], array[i]
			end
		end,
		
		["clone"] = function() -- Shallow copy
			return require(script)(unpack(array))
		end
	}, {
		__index = function(self, key)
			if (rawget(self, key)) then
				return rawget(self, key)
			end
			
			return array[key]
		end,	
		
		__newindex = function(self, index, value)
			rawset(array, index, value)
		end
	})
end