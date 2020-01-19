return function()
	-- TODO: Formats, split, 
	
	local class = BaseClass:new("String")
	
	local Array = import("Imports.Types.Array")
		
	class.String = function(self, str)				
		self.string = tostring(str) or ""
				
		return self
	end
	
	class.charAt = function(self, index)
		return class(self.string:sub(index, -(self.string:len() - (index - 1))))
	end
	
	class.concat = function(self, str)
		return class(self.string .. str)
	end
	
	class.length = function(self)
		return class(self.string:len())
	end
	
	class.substring = function(self, n1, n2)
		return class(self.string:sub(n1 + 1, n2))
	end
	
	class.toLowerCase = function(self)
		return class(self.string:lower())
	end
	
	class.toUpperCase = function(self)
		return class(self.string:upper())
	end
	
	class.trim = function(self)
		return class(self:gsub("^%s*(.-)%s*$", "%1"))
	end
	
	class.startsWith = function(self, prefix, offset)
		local uStr = self.string
	
		if (offset) then
			uStr = self:substring(offset)
		end
		
		return uStr:sub(1, prefix:length()) == prefix
	end
	
	class.endsWith = function(self, suffix)
		return self.string:sub(suffix:length()) == suffix
	end
	
	class.contains = function(self, str)
		return self.string:find(str) ~= nil
	end
	
	class.equals = function(self, other)
		return self:__eq(other)
	end
	
	class.toArray = function(self)
		local chars = { }
		
		self.string:gsub(".", function(c)
			table.insert(chars, c)
		end)
		
		return Array(chars)
	end
	
	class.__eq = function(self, other)					
		if (typeof(other) == "table") then			
			return self.string == other.string
		else			
			return self.string == other
		end
	end
	
	class.__add = function(self, other)
		if (typeof(self) == "table" and typeof(other) == "table") then
			return self.string .. other.string
		elseif (typeof(self) == "table" and typeof(other) == "string") then
			return self.string .. other
		elseif (typeof(self) == "string" and typeof(other) == "table") then
			return self .. other
		end
		
		return class(self.string .. other.string)
	end
	
	class.__tostring = function(self)			
		return self.string or ""
	end
	
	return class
end