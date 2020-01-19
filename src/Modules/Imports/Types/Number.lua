return function()
	local class = BaseClass:new("Number")
		
	class.Number = function(self, number)
		if (typeof(number) == "table" and number["className"]) then
			if (number["className"] == "Number") then
				self.number = number.number
			elseif (number["className"] == "String") then
				self.number = tonumber(number.string)
			end
		else
			if (typeof(number) == "number") then
				self.number = number
			else
				self.number = tonumber(number)
			end
		end

		return self
	end
	
	class.toString = function(self)
		return tostring(self.number)
	end
	
	class.equals = function(self, other)
		return self:__eq(other)
	end
	
	class.__tostring = function(self)
		return self:toString()
	end
	
	class.__eq = function(self, other)		
		if (typeof(other) == "table") then			
			return self.number == other.number
		else			
			return self.number == other
		end
	end
	
	class.__lt = function(self, other)
		if (typeof(self) == "table" and typeof(other) == "table") then
			return self.number < other.number
		elseif (typeof(self) == "table" and typeof(other) == "number") then
			return self.number < other
		elseif (typeof(self) == "number" and typeof(other) == "table") then
			return self < other.number
		end
	end
	
	class.__le = function(self, other)
		if (typeof(self) == "table" and typeof(other) == "table") then
			return self.number <= other.number
		elseif (typeof(self) == "table" and typeof(other) == "number") then
			return self.number <= other
		elseif (typeof(self) == "number" and typeof(other) == "table") then
			return self <= other.number
		end
	end
	
	class.__add = function(self, other)
		if (typeof(self) == "table" and typeof(other) == "table") then
			return self.number + other.number
		elseif (typeof(self) == "table" and typeof(other) == "number") then
			return self.number + other
		elseif (typeof(self) == "number" and typeof(other) == "table") then
			return self + other.number
		end
	end
	
	class.__sub = function(self, other)
		if (typeof(self) == "table" and typeof(other) == "table") then
			return self.number - other.number
		elseif (typeof(self) == "table" and typeof(other) == "number") then
			return self.number - other
		elseif (typeof(self) == "number" and typeof(other) == "table") then
			return self - other.number
		end
	end
	
	class.__mul = function(self, other)
		if (typeof(self) == "table" and typeof(other) == "table") then
			return self.number * other.number
		elseif (typeof(self) == "table" and typeof(other) == "number") then
			return self.number * other
		elseif (typeof(self) == "number" and typeof(other) == "table") then
			return self * other.number
		end
	end
	
	class.__div = function(self, other)
		if (typeof(self) == "table" and typeof(other) == "table") then
			return self.number / other.number
		elseif (typeof(self) == "table" and typeof(other) == "number") then
			return self.number / other
		elseif (typeof(self) == "number" and typeof(other) == "table") then
			return self / other.number
		end
	end
	
	class.__pow = function(self, other)
		if (typeof(self) == "table" and typeof(other) == "table") then
			return self.number ^ other.number
		elseif (typeof(self) == "table" and typeof(other) == "number") then
			return self.number ^ other
		elseif (typeof(self) == "number" and typeof(other) == "table") then
			return self ^ other.number
		end
	end
	
	class.__mod = function(self, other)
		if (typeof(self) == "table" and typeof(other) == "table") then
			return self.number % other.number
		elseif (typeof(self) == "table" and typeof(other) == "number") then
			return self.number % other
		elseif (typeof(self) == "number" and typeof(other) == "table") then
			return self % other.number
		end
	end
	
	class.__unm = function(self)
		return -self.number
	end
	
	return class
end