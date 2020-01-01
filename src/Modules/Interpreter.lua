return function()
	local Class = BaseClass:new("Interpreter")
	
	Class.getId = function(self, name)
		self.id = self.id + 1
		
		return name .. ":" ..tostring(self.id)
	end
	
	Class.visitNode = function(self, node, scope)
		local ty = node["token"]["data"]
		
		if (ty ==  "+") then
			return self:visit(node["left"], scope) + self:visit(node["right"], scope)
		elseif (ty == "-") then
			return self:visit(node["left"], scope) - self:visit(node["right"], scope)
		elseif (ty == "*") then
			return self:visit(node["left"], scope) * self:visit(node["right"], scope)
		elseif (ty == "/") then
			return self:visit(node["left"], scope) / self:visit(node["right"], scope)
		elseif (ty == "^") then
			return self:visit(node["left"], scope) ^ self:visit(node["right"], scope)
		elseif (ty == "%") then
			return self:visit(node["left"], scope) % self:visit(node["right"], scope)
		end
	end
	
	Class.visitFor = function(self, node, scope)
		local variableName = node["variable"]["left"]["data"]
				
		self:visit(node["variable"], scope)
		
		while (self:visit(node["check"], scope)) do
			for index = 1, #node["statements"] do
				self:visit(node["statements"][index], scope)
			end
			
			self:visit(node["iter"], scope)
			
			wait()
		end
	end
	
	Class.visitWhile = function(self, node, scope)
		while (self:visit(node["check"], scope)) do
			for index = 1, #node["statements"] do
				self:visit(node["statements"][index], scope)
			end
			
			wait()
		end
	end
	
	Class.visitNumber = function(self, node)
		return tonumber(node["data"])
	end
	
	Class.visitString = function(self, node)
		return node["data"]:sub(1, -2):sub(2)
	end
	
	Class.visitReturn = function(self, node, scope)
		return self:visit(node["expression"], scope)
	end
	
	Class.visitCreateFunction = function(self, node, scope)
		-- [[ TODO custom scopes ]] --
		
		local func = function(...)
			local id, gargs = self:getId("FUNCTION"), { ... }
		
			self.scopes[id] = self:generateScope(id, scope["NAME"])
						
			for index = 1, #node["arguments"] do
				self.scopes[id][node["arguments"][index]] = gargs[index]
			end
			
			for index = 1, #node["statements"] do
				local ret = self:visit(node["statements"][index], self.scopes[id])
				
				if (node["statements"][index]["nodeType"] == "Return") then
					return ret
				end
			end
		end
	
		scope[node["token"]["data"]] = func
 
		return func
	end
	
	Class.visitCallFunction = function(self, node, scope)
		-- [[ Todo add default langauge functions and stop the hack im using ]] --
		local args = { }
				
		for i = 1, #node["arguments"] do
			table.insert(args, self:visit(node["arguments"][i], scope))
		end
		
		return scope[node["token"]["data"]](unpack(args))
	end
	
	Class.visitUnary = function(self, node, scope)
		local ty = node["token"]["data"]
				
		if (ty == "+") then
			return self:visit(node["expr"], scope)
		elseif (ty == "-") then							
			return -self:visit(node["expr"], scope)
		end
	end
	
	Class.visitAssign = function(self, node, scope)
		local variableName, data = node["left"]["data"], self:visit(node["right"], scope)
		
		local function trySet(sco)			
			if (sco["PARENT"] ~= nil) then
				self.scopes[sco["PARENT"]][variableName] = data
			
				trySet(sco)
			end
		end
		
		if (node["type"]["data"] == "edit") then
			if (not scope[variableName]) then
				return error("Syntax Error")
			end
			
			scope[variableName] = data
			
			trySet(scope)
		elseif (node["type"]["data"] == "var") then
			scope[variableName] = data
			
			trySet(scope)
		elseif (node["type"]["data"] == "let") then
			scope[variableName] = data
		end
	end
	
	Class.visitVariable = function(self, node, scope)
		local variableName, value = node["data"], nil
		
		value = scope[variableName]
		
		if (value == nil) then
			return error(variableName .. " hasn't been set yet")
		else 
			return value
		end
	end
	
	Class.visitBoolean = function(self, node)
		if (node["data"] == "true") then
			return true
		else
			return false
		end
	end
	
	Class.visitCompare = function(self, node, scope)
		if (node["token"]["data"] == "==") then
			return self:visit(node["left"], scope) == self:visit(node["right"], scope)
		elseif (node["token"]["data"] == "~=") then
			return self:visit(node["left"], scope) ~= self:visit(node["right"], scope)
		elseif (node["token"]["data"] == ">") then
			return self:visit(node["left"], scope) > self:visit(node["right"], scope)
		elseif (node["token"]["data"] == "<") then
			return self:visit(node["left"], scope) < self:visit(node["right"], scope)
		elseif (node["token"]["data"] == ">=") then
			return self:visit(node["left"], scope) >= self:visit(node["right"], scope)
		elseif (node["token"]["data"] == "<=") then
			return self:visit(node["left"], scope) <= self:visit(node["right"], scope)
		end
	end
	
	Class.visitCompareOperator = function(self, node, scope)
		if (node["token"]["data"] == "&&") then
			if (self:visit(node["left"], scope) == false) then
				return false
			elseif (self:visit(node["right"], scope)) then
				return true
			else
				return false
			end
		elseif (node["token"]["data"] == "||") then
			if (self:visit(node["left"], scope) or self:visit(node["right"], scope)) then
				return true
			else
				return false
			end
		end
	end
	
	Class.visitIf = function(self, node, scope)
		local check = self:visit(node["check"])
		
		if (check) then
			for index = 1, #node["ifStatmenets"] do
				self:visit(node["ifStatmenets"][index], scope)
			end
			
			return true
		else
			if (#node["elseifStatements"] > 0) then
				local run = true
				
				for index = 1, #node["elseifStatements"] do
					if (run and self:visit(node["elseifStatements"][index], scope)) then
						run = false
					end
				end
				
				if (run and node["elseStatements"]) then
					for index = 1, #node["elseStatements"] do
						self:visit(node["elseStatements"][index], scope)
					end
				end
			elseif (node["elseStatements"]) then
				for index = 1, #node["elseStatements"] do
					self:visit(node["elseStatements"][index], scope)
				end
			end
		end
		
		return false
	end
	
	Class.visitEmpty = function(self, node)
		return nil
	end
	
	Class.generateScope = function(self, name, parent)
		local function tryFind(scope, index)			
			if (not rawget(scope, index)) then
				if (scope["PARENT"] == nil) then
					return nil
				end
				
				return tryFind(self.scopes[scope["PARENT"]], index)
			end
			
			return rawget(scope, index)
		end
			
		return setmetatable({
			["PARENT"] = parent,
			["NAME"] = name
		}, {
			__index = function(self, index)
				if (index == "PARENT" or index == "NAME") then
					return rawget(self, index)
				else
					return tryFind(self, index)
				end
			end
		})
	end
	
	Class.visitRoot = function(self, node)		
		for index = 1, #node["children"] do
			self:visit(node["children"][index], self.scopes["GLOBAL"])
		end
	end
	
	Class.visit = function(self, node, scope)			
		return self["visit" .. node["nodeType"]](self, node, scope)
	end
	
	Class.interpret = function(self, AST, tokens, scope)		
		self.AST = AST
		self.tokens = tokens
		self.id = 0
		
		self.scopes = {
			["GLOBAL"] = self:generateScope("GLOBAL")
		}
		
		for i, v in pairs(scope) do
			self.scopes["GLOBAL"][i] = v
		end
		
		self:visit(AST)
		
		return self.scopes["GLOBAL"], self.scopes
	end
	
	return Class
end