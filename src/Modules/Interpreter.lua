return function()
	local Class = BaseClass:new("Interpreter")
	
	local Array, List = import("Imports.Types.Array", "Imports.Types.List")
	
	Class.getId = function(self, name)
		self.id = self.id + 1
		
		return name .. ":" ..tostring(self.id)
	end
	
	Class.visitBinOp = function(self, node, scope)
		local ty = node["value"]["data"]
		
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
	
	Class.visitArray = function(self, node, scope)
		local elements = {}
		
		for i = 1, #node["elements"] do
			table.insert(elements, self:visit(node["elements"][i], scope))
		end
		
		return Array(elements)
	end
	
	Class.visitFor = function(self, node, scope)		
		local variableName = node["variable"]["value"]["data"]
				
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
		return tonumber(node["value"]["data"])
	end
	
	Class.visitString = function(self, node)
		return node["value"]["data"]:sub(1, -2):sub(2)
	end
	
	Class.visitReturn = function(self, node, scope)
		return self:visit(node["expression"], scope)
	end
	
	Class.visitList = function(self, node, scope)
		local elements = {}
		
		for i = 1, #node["elements"] do
			local variableName, data = node["elements"][i]["variable"]["value"]["data"], self:visit(node["elements"][i]["value"], scope)
			
			elements[variableName] = data
		end
		
		return List(elements)
	end
	
	Class.visitPass = function(self, node, scope)
		return node["value"]["data"]
	end
	
	Class.visitAccess = function(self, node, scope)
		local ac, accessor = self:visit(node["variable"], scope), self:visit(node["data"], scope)
												
		if (typeof(accessor) == "number") then			
			return ac[accessor + 1]
		else
			return ac[accessor]
		end
	end
	
	Class.visitCreateFunction = function(self, node, scope)		
		local func = function(...)
			local id, gargs = self:getId("FUNCTION"), { ... }
		
			self.scopes[id] = self:generateScope(id, scope["NAME"], scope["CLASS"])
			
			self.scopes[id]["BYPASS"] = true	
			
			for index = 1, #node["arguments"] do
				self.scopes[id][node["arguments"][index]] = gargs[index]
			end

			self.scopes[id]["BYPASS"] = false
			
			for index = 1, #node["statements"] do
				local ret = self:visit(node["statements"][index], self.scopes[id])
				
				if (node["statements"][index]["nodeType"] == "Return") then
					return ret
				end
			end
		end
		
		scope[node["value"]["data"]] = func
	
		if (node["type"] ~= nil) then
			if (node["type"]["sco"] == "private") then
				scope["PRIVATE"][node["value"]["data"]] = true
			end
			
			if (node["type"]["type"]) then
				for _, v in ipairs(node["type"]["type"]) do
					if (v["data"] == "final") then
						scope["FINAL"][node["value"]["data"]] = true
					elseif (v["data"] == "static") then
						scope["STATIC"][node["value"]["data"]] = true
					end
				end
			end
		end

		return func
	end

	Class.visitType = function(self, node, scope)
		return node["scope"], node["type"]
	end

	Class.visitNew = function(self, node, scope)
		local className = node["variable"]["value"]["data"]
		local class = self.classes[className]
				
		if (class) then
			local cClass = self:visit(class, scope)
			
			local sendargs, ret = {}, cClass
			
			for i = 1, #node["arguments"] do
				table.insert(sendargs, self:visit(node["arguments"][i], scope))
			end
		
			cClass["INIT"] = true
		
			if (rawget(cClass, "DATA")[className]) then
				ret = rawget(cClass, "DATA")[className](unpack(sendargs))
			end
		
			return ret
		else
			local sendargs = {}
			
			for i = 1, #node["arguments"] do
				table.insert(sendargs, self:visit(node["arguments"][i], scope))
			end
															
			return scope[className](unpack(sendargs))
		end
	end
	
	Class.visitCallFunction = function(self, node, scope)				
		local args, func, check = { }, self:visit(node["variable"], scope), nil
		
		--print(func, game:GetService("HttpService"):JSONEncode(node["variable"]))
	
		if (node["variable"]["nodeType"] == "Variable") then
			check = self.sendScope[node["variable"]["value"]["data"]] == true
		end
			
		if (node["variable"]["nodeType"] == "Access") then			
			local tb = { }
			
			local function get(ac)
				table.insert(tb, ac["variable"])
				
				if (ac["data"]["nodeType"] == "Access") then
					return get(ac["data"])
				end
								
				return self:visit(tb[#tb], scope)
			end
			
			table.insert(args, get(node["variable"]))
		end
				
		if (check) then			
			table.insert(args, scope)
		end
						
		for i = 1, #node["arguments"] do						
			table.insert(args, self:visit(node["arguments"][i], scope))
		end
								
		return func(unpack(args))
	end
	
	Class.visitClass = function(self, node, scope)
		local className = node["name"]["data"]
				
		self.scopes[className] = self:generateScope(className, scope["NAME"], className)
		self.scopes[className]["BYPASS"] = true
		self.scopes[className]["this"] = self.scopes[className]
		
		if (node["extends"]) then			
			local data = self:visit(self.classes[node["extends"]], self.scopes[className])
			
			self.scopes[className]["super"] = data
		end
		
		for index = 1, #node["statements"] do
			self:visit(node["statements"][index], self.scopes[className])
		end
		
		self.scopes[className]["BYPASS"] = false
		
		if (className == "Main" and self.scopes["GLOBAL"]["Main"] == nil) then
			self.scopes[className]["main"]()
		end
		
		if (self.scopes["GLOBAL"][className] == nil) then
			self.scopes["GLOBAL"][className] = self.scopes[className]
			self.classes[className] = node
		end
		
		return self.scopes[className]
	end
	
	Class.visitUnary = function(self, node, scope)
		local ty = node["value"]["data"]
				
		if (ty == "+") then
			return self:visit(node["expr"], scope)
		elseif (ty == "-") then							
			return -self:visit(node["expr"], scope)
		end
	end
	
	Class.visitAssign = function(self, node, scope)		
		local variableName, data = "", self:visit(node["value"], scope)
				
		if (node["variable"]["nodeType"] == "Variable") then
			variableName = node["variable"]["value"]["data"]
		end
						
		local function trySet(sco)						
			if (sco["PARENT"] ~= nil and sco["PARENT"] ~= "GLOBAL") then
				self.scopes[sco["PARENT"]][variableName] = data
						
				trySet(sco["PARENT"])
			end
		end
	
		if (node["type"] ~= nil) then
			local scop, ty = node["type"]["scope"], node["type"]["type"]
			
			if (scop["data"] == "public") then
				scope[variableName] = data
				
				trySet(scope)
			else
				scope[variableName] = data
			end
			
			for _, t in ipairs(ty) do
				if (t["data"] == "static") then
					scope["STATIC"][variableName] = true
				elseif (t["data"] == "final") then
					scope["FINAL"][variableName] = true
				end
			end
		else
			if (node["variable"]["nodeType"] == "Variable") then
				if (scope[variableName] == nil) then				
					scope["DATA"][variableName] = data
				else
					scope[variableName] = data
					
					trySet(scope)
				end
			elseif (node["variable"]["nodeType"] == "Access") then				
				self:visit(node["variable"]["variable"], scope)[self:visit(node["variable"]["data"], scope)] = data
			end
		end
			end

	Class.visitNull = function(self, node, scope)
		return nil
	end
	
	Class.visitVariable = function(self, node, scope)
		local variableName, value, retscope
		
		if (node["value"]["nodeType"] == nil) then
			variableName = node["value"]["data"]
			
			value, retscope = scope(variableName)
		else
			value = self:visit(node["value"], scope)
		end
				
		if (node["type"] == nil) then
			return value
		else
			if (node["type"]["scope"]["data"] == "private" and retscope["CLASS"] ~= scope["CLASS"]) then
				return error("Cannot retrieve a private variable in a different class")
			end
			
			if (node["type"]["type"]) then
				for _, v in ipairs(node["type"][""]) do
					if (v["data"] == "static") then
						if (retscope["INIT"] == true) then
							return error("Cannot use a static variable inside of a initiated class")
						end
					end
				end
			end
			
			return value
		end
	end
	
	Class.visitBoolean = function(self, node)
		if (node["value"]["data"] == "true") then
			return true
		else
			return false
		end
	end
	
	Class.visitCompare = function(self, node, scope)
		local op = node["operator"]["data"]
		
		if (op == "==" or op == "~=") then
			local l, r, lf, rf, lc, rc = self:visit(node["left"], scope), self:visit(node["right"], scope), nil, nil, nil, nil
			
			if (typeof(l) == "table") then
				lf = l["__equals"] or rawget(l, "__eq") or nil
				
				if (lf) then
					lc = lf(l, r)
				end
			end
			
			if (typeof(r) == "table") then
				rf = r["__equals"] or rawget(l, "__eq") or nil
				
				if (rf) then
					rc = rf(r, l)
				end
			end
			
			if (op == "==") then
				if (lc ~= nil and rc ~= nil) then
					return lc and rc
				elseif (lc ~= nil and rc == nil) then
					return lc
				elseif (lc == nil and rc ~= nil) then
					return rc
				end
				
				return l == r
			else
				if (lc ~= nil and rc ~= nil) then
					return not (lc and rc)
				elseif (lc ~= nil and rc == nil) then
					return not lc
				elseif (lc == nil and rc ~= nil) then
					return not rc
				end
				
				return l ~= r
			end
		elseif (op == ">" or op == "<") then
			local l, r, lf, rf, lc, rc = self:visit(node["left"], scope), self:visit(node["right"], scope), nil, nil, nil, nil
			
			if (typeof(l) == "table") then
				lf = l["__lessthan"] or rawget(l, "__lt") or nil
				
				if (lf) then
					if (op == ">") then
						lc = lf(r, l)
					else
						lc = lf(l, r)
					end
				end
			end
			
			if (typeof(r) == "table") then
				rf = r["__lessthan"] or rawget(l, "__lt") or nil
				
				if (rf) then
					if (op == ">") then
						rc = rf(r, l)
					else
						rc = rf(l, r)
					end
				end
			end
			
			if (op == ">") then
				if (lc ~= nil and rc ~= nil) then
					return lc and rc
				elseif (lc ~= nil and rc == nil) then
					return lc
				elseif (lc == nil and rc ~= nil) then
					return rc
				end
				
				return l > r
			else
				if (lc ~= nil and rc ~= nil) then
					return not (lc and rc)
				elseif (lc ~= nil and rc == nil) then
					return not lc
				elseif (lc == nil and rc ~= nil) then
					return not rc
				end
				
				return l < r
			end
		elseif (op == ">=" or op == "<=") then
			local l, r, lf, rf, lc, rc = self:visit(node["left"], scope), self:visit(node["right"], scope), nil, nil, nil, nil
			
			if (typeof(l) == "table") then
				lf = l["__lessequal"] or rawget(l, "__le") or nil
				
				if (lf) then
					if (op == ">=") then
						lc = lf(r, l)
					else
						lc = lf(l, r)
					end
				end
			end
			
			if (typeof(r) == "table") then
				rf = r["__lessequal"] or rawget(l, "__le") or nil
				
				if (rf) then
					if (op == ">=") then
						rc = rf(r, l)
					else
						rc = rf(l, r)
					end
				end
			end
			
			if (op == ">=") then
				if (lc ~= nil and rc ~= nil) then
					return lc and rc
				elseif (lc ~= nil and rc == nil) then
					return lc
				elseif (lc == nil and rc ~= nil) then
					return rc
				end
				
				return l >= r
			else
				if (lc ~= nil and rc ~= nil) then
					return not (lc and rc)
				elseif (lc ~= nil and rc == nil) then
					return not lc
				elseif (lc == nil and rc ~= nil) then
					return not rc
				end
				
				return l <= r
			end
		end
	end
	
	Class.visitCompareOperator = function(self, node, scope)
		if (node["value"]["data"] == "&&") then
			if (self:visit(node["left"], scope) == false) then
				return false
			elseif (self:visit(node["right"], scope)) then
				return true
			else
				return false
			end
		elseif (node["value"]["data"] == "||") then
			if (self:visit(node["left"], scope) or self:visit(node["right"], scope)) then
				return true
			else
				return false
			end
		end
	end
	
	Class.visitIf = function(self, node, scope)
		local check = self:visit(node["check"], scope)
				
		if (check) then
			for index = 1, #node["ifstatements"] do
				self:visit(node["ifstatements"][index], scope)
			end
			
			return true
		else			
			if (#node["elseifstatements"] > 0) then				
				local run = true
				
				for index = 1, #node["elseifstatements"] do
					if (run and self:visit(node["elseifstatements"][index], scope)) then
						run = false
					end
				end
				
				if (run and node["elsestatements"]) then
					for index = 1, #node["elsestatements"] do
						self:visit(node["elsestatements"][index], scope)
					end
				end
			elseif (node["elsestatements"] ~= nil) then				
				for index = 1, #node["elsestatements"] do
					self:visit(node["elsestatements"][index], scope)
				end
			end
		end
		
		return false
	end
	
	Class.visitEmpty = function(self, node)
		return nil
	end
	
	Class.generateScope = function(self, name, parent, class)		
		local function tryFind(scope, index)
			if (scope["DATA"][index] == nil) then
				if (rawget(scope, "PARENT") == nil) then
					return nil
				end
				
				return tryFind(self.scopes[scope["PARENT"]], index)
			end
			
			return scope["DATA"][index], scope
		end
	
		local function check(sc)
			if (sc["INIT"]) then
				return true
			end
			
			if (sc["PARENT"] ~= nil) then
				return check(self.scopes[sc["PARENT"]])
			else
				return false
			end
		end
			
			
		local init = false
		
		if (parent) then			
			init = check(self.scopes[parent])
		end
			
		return setmetatable({
			["PARENT"] = parent,
			["NAME"] = name,
			["DATA"] = { },
			["QUICK"] = { },
			["QUICKSCOPES"] = { },
			["FINAL"] = { },
			["STATIC"] = { },
			["PRIVATE"] = { },
			["CLASS"] = class,
			["BYPASS"] = false,
			["INIT"] = init
		}, {
			__index = function(self, index)				
				if (rawget(self, index)) then
					return rawget(self, index)
				elseif (self["DATA"][index]) then
					return self["DATA"][index]
				elseif (self["QUICK"][index]) then
					return self["QUICK"][index]
				else
					local ret, sc = tryFind(self, index)
					
					if (ret) then
						self["QUICK"][index] = ret
						self["QUICKSCOPES"][index] = sc
					end
					
					return ret
				end
			end,
			
			__newindex = function(self, index, value)						
				if (self["NAME"] ~= "GLOBAL" and self["BYPASS"] == false and index ~= "BYPASS") then
					if (self["FINAL"][index]) then
						return error("Setting a final variable is invalid.")
					end
					
					if (self["STATIC"][index] and self["INIT"]) then
						return error("Setting a static variable in a intialized class is invalid.")
					end
										
					if (self["STATIC"][index] == nil and not self["INIT"]) then
						return error("Setting a non static variable in a non intalized class is invalid.")
					end
				end
				
				self["DATA"][index] = value
			end,
			
			__call = function(self, index)
				if (rawget(self, index)) then
					return rawget(self, index), self
				elseif (self["DATA"][index]) then
					return self["DATA"][index], self
				elseif (self["QUICK"][index]) then
					return self["QUICK"][index], self["QUICKSCOPES"][index]
				else
					local ret, sc = tryFind(self, index)
					
					if (ret) then
						self["QUICK"][index] = ret
						self["QUICKSCOPES"][index] = sc
					end
					
					return ret, sc
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
	
	Class.interpret = function(self, AST, tokens, scope, sendScope)		
		self.AST = AST
		self.tokens = tokens
		self.id = 0
		
		self.scopes = {
			["GLOBAL"] = self:generateScope("GLOBAL")
		}
		self.sendScope = sendScope
		self.classes = {}
		
		for i, v in pairs(scope) do
			self.scopes["GLOBAL"][i] = v
		end
				
		self:visit(AST)
		
		return self.scopes["GLOBAL"], self.scopes
	end
	
	return Class
end
