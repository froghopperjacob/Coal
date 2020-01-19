return function()
	local class = BaseClass:new("Boolean")
		
	class.Boolean = function(self, boolean)
		if (typeof(boolean) == "table" and boolean["className"]) then
			if (boolean["className"] == "String") then
				if (boolean["string"] == "true") then
					self.boolean = true
				else
					self.boolean = false
				end
			elseif (boolean["className"] == "Number") then
				if (boolean["number"] == 1) then
					self.boolean = true
				else
					self.boolean = false
				end
			end
		else
			if (typeof(boolean) == "string") then
				if (boolean == "true") then
					self.boolean = true
				else
					self.boolean = false
				end
			elseif (typeof(boolean) == "number") then
				if (boolean == 1) then
					self.boolean = true
				else
					self.boolean = false
				end
			else
				self.boolean = boolean
			end
		end

		return self
	end
	
	class.equals = function(self, other)
		return self:__eq(other)
	end
	
	class.toString = function(self)
		return self.boolean == true and "true" or "false"
	end
	
	class.__tostring = function(self)
		return self:toString()
	end
	
	class.__eq = function(self, other)
		if (typeof(other) == "table") then
			return self.boolean == other.boolean
		else
			return self.boolean == other
		end
	end
	
	return class
end