return function()
	local class = BaseClass:new("Array")
	
	class.Array = function(self, array)		
		self.array = array
						
		return self
	end
	
	class.length = function(self)
		return #self.array
	end
	
	class.append = function(self, x)
		table.insert(self.array, x)
	end
	
	class.insert = function(self, index, x)
		table.insert(self.array, index, x)
	end
	
	class.remove = function(self, index)
		table.remove(self.array, index)
	end
	
	class.delete = function(self, x)
		local ind
		
		for i, v in ipairs(self.array) do
			if (v == x and ind == nil) then
				ind = i
			end
		end
		
		table.remove(self.array, ind)
	end
	
	class.join = function(self, sep)
		local str, length = "", 0
		
		if (typeof(sep) == "table") then
			length = sep:length()
		else
			length = sep:len()
		end
		
		for _, v in ipairs(self.array) do
			str = str .. sep
		end
		
		return str:sub(1, -(length + 1))
	end
		
	class.pop = function(self, index)
		local ret = self.array[index or #self.array]
		
		self:remove(index)
		
		return ret
	end
	
	class.clear = function(self)
		self.array = { }
	end
	
	class.count = function(self, x)
		local times = 0
		
		for _, v in ipairs(self.array) do
			if (v == x) then
				times = times + 1
			end
		end
		
		return times
	end
	
	class.reverse = function(self)
		for i = 1, math.floor(#self.array / 2) do
			local j = #self.array - i + 1
			self.array[i], self.array[j] = self.array[j], self.array[i]
		end
	end
	
	class.clone = function(self) -- Shallow copy
		local n = { }
		
		for i, v in ipairs(self.array) do
			n[i] = v
		end
		
		return class(n)
	end
	
	class.__index = function(self, i)		
		return rawget(self, "array")[i]
	end
	
	return class
end