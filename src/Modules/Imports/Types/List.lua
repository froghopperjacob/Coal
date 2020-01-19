return function()
	local class = BaseClass:new("List")
	
	class.List = function(self, list)
		self.list = list	
			
		return self
	end
	
	class.__index = function(self, i)
		return rawget(self, "list")[i]
	end
	
	return class
end