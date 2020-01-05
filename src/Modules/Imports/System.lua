return function()
	local Class = BaseClass:new("System")
	
	Class.out = BaseClass:new("SystemOut")
	
	Class.out.print = function(scope, ...)		
		print(...)
	end
	
	Class.out.warn = function(scope, ...)
		warn(...)
	end
	
	Class.out.error = function(scope, ...)
		error(...)
	end
		
	return Class
end