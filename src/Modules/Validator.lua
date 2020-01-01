return function()
	local Class = BaseClass:new("Validator")
	
	Class.validate = function(self, AST, tokens)
		return true
	end
	
	return Class
end