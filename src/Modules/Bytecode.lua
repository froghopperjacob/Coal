local Settings = require(script.Parent.Settings)
local opcodes = Settings["Opcodes"]

return function(AST, fileName)
	local function createChunk(name, lineStart, lineEnd, parameters)
		return {
			["name"] = name,
			["line"] = lineStart,
			["lastLine"] = lineEnd,
			["nUpvalues"] = 0,
			["parameters"] = parameters,
			["version"] = Settings["Version"],
			["constants"] = { },
			["instructions"] = { },
			["protos"] = { },
			
			-- Track registers
			
			["registerCounter"] = 0,
			["registers"] = { }
		}
	end
	
	local function addInstruction(chunk, instruction, a1, a2, a3)
		table.insert(chunk["instructions"], { instruction, a1, a2, a3})
	end
	
	local function isConstantAdd(tab)
		if (tab[1] == "constant") then
			tab[2] = tab[2] + Settings["RegisterLimit"]
			
			return tab
		end
		
		return tab
	end
	
	local function increaseRegister(chunk)
		chunk["registerCounter"] = chunk["registerCounter"] + 1
	end
	
	local function findConstant(chunk, ty, value)
		for index, tab in pairs(chunk["constants"]) do			
			if (tab["type"] == ty and tab["value"] == value) then
				return index
			end
		end
		
		return nil
	end
	
	local function createConstant(chunk, ty, value)
		local newValue = value
		
		if (ty == "number") then
			newValue = tonumber(value)
		elseif (ty == "bool") then
			newValue = (value == "true")
		end
		
		local find = findConstant(chunk, ty, newValue)
				
		if (find) then
			return { "constant", find }, true
		else
			local constantNumber = #chunk["constants"] + 1
			
			chunk["constants"][constantNumber] = { 
				["type"] = ty, 
				["value"] = newValue 
			}
			
			return { "constant", constantNumber }, false
		end
	end
	
	local nodeTypes = {
		["visit"] = function(self, node, chunk)					
			return self[node["nodeType"]](self, node, chunk)
		end,
		
		["Root"] = function(self, node, chunk)			
			for index = 1, #node["children"] do
				self:visit(node["children"][index], chunk)
			end
					
			addInstruction(chunk, opcodes["RETURN"], 0, 1)
					
			return chunk
		end,
		
		["Empty"] = function(self, node, chunk)
			return nil
		end,
		
		["BinOp"] = function(self, node, chunk)
			local left, right, value = self:visit(node["left"], chunk), self:visit(node["right"], chunk), node["value"]["data"]
						
			if (left[1] == "constant" and right[1] == "constant") then
				if (value == "+") then
					if (type(left) == "string" or type(right) == "string") then
						return createConstant(chunk, "number", chunk["constants"][left[2]]["value"] .. chunk["constants"][right[2]]["value"])
					else						
						return createConstant(chunk, "number", chunk["constants"][left[2]]["value"] + chunk["constants"][right[2]]["value"])
					end
				elseif (value == "-") then
					return createConstant(chunk, "number", chunk["constants"][left[2]]["value"] - chunk["constants"][right[2]]["value"])
				elseif (value == "*") then
					return createConstant(chunk, "number", chunk["constants"][left[2]]["value"] * chunk["constants"][right[2]]["value"])
				elseif (value == "/") then
					return createConstant(chunk, "number", chunk["constants"][left[2]]["value"] / chunk["constants"][right[2]]["value"])
				elseif (value == "**") then
					return createConstant(chunk, "number", chunk["constants"][left[2]]["value"] ^ chunk["constants"][right[2]]["value"])
				elseif (value == "%") then
					return createConstant(chunk, "number", chunk["constants"][left[2]]["value"] % chunk["constants"][right[2]]["value"])
				elseif (value == "&") then
					return createConstant(chunk, "number", bit32.band(chunk["constants"][left[2]]["value"], chunk["constants"][right[2]]["value"]))
				elseif (value == ">>") then
					return createConstant(chunk, "number", bit32.rshift(chunk["constants"][left[2]]["value"], chunk["constants"][right[2]]["value"]))
				elseif (value == "<<") then
					return createConstant(chunk, "number", bit32.lshift(chunk["constants"][left[2]]["value"], chunk["constants"][right[2]]["value"]))
				elseif (value == "|") then
					return createConstant(chunk, "number", bit32.bor(chunk["constants"][left[2]]["value"], chunk["constants"][right[2]]["value"]))
				elseif (value == "^") then
					return createConstant(chunk, "number", bit32.bxor(chunk["constants"][left[2]]["value"], chunk["constants"][right[2]]["value"]))
				end
			else
				increaseRegister(chunk)
				
				if (value == "+") then
					addInstruction(chunk, opcodes["ADD"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == "-") then
					addInstruction(chunk, opcodes["SUB"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == "*") then
					addInstruction(chunk, opcodes["MUL"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == "/") then
					addInstruction(chunk, opcodes["MUL"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == "**") then
					addInstruction(chunk, opcodes["POW"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == "%") then
					addInstruction(chunk, opcodes["MOD"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == "&") then
					addInstruction(chunk, opcodes["BAND"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == ">>") then
					addInstruction(chunk, opcodes["BRIGHTSHIFT"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == "<<") then
					addInstruction(chunk, opcodes["BLEFTSHIFT"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == "|") then
					addInstruction(chunk, opcodes["BOR"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				elseif (value == "^") then
					addInstruction(chunk, opcodes["BXOR"], chunk["registerCounter"], isConstantAdd(left)[2], isConstantAdd(right)[2])
				end
				
				return { "variable", chunk["registerCounter"] }
			end
		end,
		
		["Unary"] = function(self, node, chunk)
			local value = self:visit(node["value"], chunk)
						
			if (value[1] == "constant") then
				if (node["type"]["data"] == "-") then
					return createConstant(chunk, "number", -chunk["constants"][value[2]]["value"])
				elseif (node["type"]["data"] == "~") then
					return createConstant(chunk, "number", bit32.bnot(chunk["constants"][value[2]]["value"]))
				else
					return { "boolean", not value[2] }
				end
			else
				increaseRegister(chunk)
				
				if (node["type"]["data"] == "-") then
					addInstruction(chunk, opcodes["UNM"], chunk["registerCounter"], value[2])
				elseif (node["type"]["data"] == "~") then
					addInstruction(chunk, opcodes["BFLIP"], chunk["registerCounter"], value[2])
				else
					addInstruction(chunk, opcodes["LOADBOOL"], chunk["registerCounter"], value[2] == true and 1 or 0, 0)
				end
				
				return { "variable", chunk["registerCounter"] }
			end
		end,
		
		["Constant"] = function(self, node, chunk)
			return createConstant(chunk, node["type"], node["value"]["data"])
		end,
		
		["Boolean"] = function(self, node, chunk)
			return { "boolean", node["value"]["data"] == "true" }
		end,
		
		["Variable"] = function(self, node, chunk)			
			if (chunk["registers"][node["value"]["data"]] == nil) then
				if (node["local"]) then
					increaseRegister(chunk)
					
					chunk["registers"][node["value"]["data"]] = chunk["registerCounter"]
					
					return { "variable", chunk["registers"][node["value"]["data"]] }, false
				else
					local const = createConstant(chunk, "string", node["value"]["data"])
			
					if (node["local"] == nil) then
						increaseRegister(chunk)
												
						addInstruction(chunk, opcodes["GETGLOBAL"], chunk["registerCounter"], const[2])
						
						return { "variable", chunk["registerCounter"] }, false
					end
					
					return const
				end
			end
			
			return { "variable", chunk["registers"][node["value"]["data"]] }, true
		end,
		
		["Compare"] = function(self, node, chunk) --TODO
			local left, right = self:visit(node["left"], chunk), self:visit(node["right"], chunk)
			
			if (node["operator"] == "==" or node["operator"] == "!=") then
				addInstruction(chunk, opcodes["EQ"], node["operator"] == "==" and 1 or 0, isConstantAdd(left)[2], isConstantAdd(right)[2])
			elseif (node["operator"] == ">" or node["operator"] == "<") then
				addInstruction(chunk, opcodes["LT"], node["operator"] == "<" and 1 or 0, isConstantAdd(left)[2], isConstantAdd(right)[2])
			else -- >= <=
				addInstruction(chunk, opcodes["LE"], node["operator"] == "<=" and 1 or 0, isConstantAdd(left)[2], isConstantAdd(right)[2])
			end
			
			return { "compare" }
		end,
		
		["Dictionary"] = function(self, node, chunk)
			
		end,
		
		["Array"] = function(self, node, chunk)
			increaseRegister(chunk)
			
			local arrayRegister = chunk["registerCounter"]
			
			addInstruction(chunk, opcodes["NEWARR"], arrayRegister)
			
			if (#node["elements"] > 0) then
				for index, value in pairs(node["elements"]) do
					local tab, found = self:visit(value, chunk)
					
					increaseRegister(chunk)
					
					if (found) then
						addInstruction(chunk, opcodes["MOVE"], chunk["registerCounter"], tab[2])
					else
						if (tab[1] == "constant") then
							addInstruction(chunk, opcodes["LOADK"], chunk["registerCounter"], tab[2])
						elseif (tab[1] == "boolean") then
							addInstruction(chunk, opcodes["LOADBOOL"], chunk["registerCounter"], tab[2] and 1 or 0, 0)
						elseif (tab[1] == "variable") then
							local edit = chunk["instructions"][#chunk["instructions"]]
												
							edit[2] = chunk["registerCounter"]
							chunk["registerCounter"] = chunk["registerCounter"] - 1
						end
					end
					
					local C
					
					if (index < 50) then
						C = arrayRegister + 1
					elseif (index % Settings["FieldsPerPush"] == 0) then
						C = arrayRegister + index
					else
						C = arrayRegister + math.floor(index / Settings["FieldsPerPush"]) * 50
					end
					
					if (index % Settings["FieldsPerPush"] == 0 or index == #node["elements"]) then
						addInstruction(chunk, opcodes["SETLIST"], index + arrayRegister, 
							index == #node["elements"] and index + arrayRegister - #node["elements"] or index + arrayRegister, C)
					end
				end
			end
			
 			return { "variable", arrayRegister }
		end,
				
		["CallFunction"] = function(self, node, chunk)
			local func = self:visit(node["variable"], chunk)
						
			if (#node["arguments"] > 0) then
				for _, tab in pairs(node["arguments"]) do					
					local tab, found = self:visit(tab, chunk)
					
					increaseRegister(chunk)
					
					if (found) then
						addInstruction(chunk, opcodes["MOVE"], chunk["registerCounter"], tab[2])
					else
						if (tab[1] == "constant") then
							addInstruction(chunk, opcodes["LOADK"], chunk["registerCounter"], tab[2])
						elseif (tab[1] == "boolean") then
							addInstruction(chunk, opcodes["LOADBOOL"], chunk["registerCounter"], tab[2] and 1 or 0, 0)
						elseif (tab[1] == "variable") then
							local edit = chunk["instructions"][#chunk["instructions"]]
												
							edit[2] = chunk["registerCounter"]
							chunk["registerCounter"] = chunk["registerCounter"] - 1
						end
					end
				end
			end
			
			increaseRegister(chunk)
									
			addInstruction(chunk, opcodes["CALL"], chunk["registerCounter"], func[2], #node["arguments"] + 1)
			
			return { "variable", chunk["registerCounter"] }
		end,
		
		["Access"] = function(self, node, chunk)
			local left, right = self:visit(node["variable"], chunk), self:visit(node["data"], chunk)
			
			increaseRegister(chunk)
									
			addInstruction(chunk, opcodes["GETTABLE"], chunk["registerCounter"], left[2], isConstantAdd(right)[2])
			
			return { "table", chunk["registerCounter"] }
		end,
		
		["Assign"] = function(self, node, chunk)
			if (node["type"]) then
				node["variable"]["local"] = true
			else
				node["variable"]["local"] = false
			end
			
			local var, edit = self:visit(node["variable"], chunk), nil
			
			if (node["value"]["nodeType"] == "CallFunction") then
				node["value"]["return"] = var[2]
			end
			
			if (var[1] == "table") then
				edit = chunk["instructions"][#chunk["instructions"]]
			end
			
			local set, setInto = self:visit(node["value"], chunk), var[2]
									
			if (node["type"] == nil) then
				increaseRegister(chunk)
				
				setInto = chunk["registerCounter"]
			end
			
			if (set[1] == "constant") then
				addInstruction(chunk, opcodes["LOADK"], setInto, set[2])
			elseif (set[1] == "boolean") then
				addInstruction(chunk, opcodes["LOADBOOL"], setInto, set[2] and 1 or 0, 0)
			elseif (set[1] == "variable") then
				local edit = chunk["instructions"][#chunk["instructions"]]
				
				edit[2] = setInto
				chunk["registerCounter"] = chunk["registerCounter"] - 1
			elseif (set[1] == "compare") then
				
			end
			
			if (var[1] == "table") then
				local A, B, C = edit[2], edit[3], edit[4]
								
				edit[1] = opcodes["SETTABLE"]
				edit[2] = B
				edit[3] = C
				edit[4] = isConstantAdd(set)[2]
								
				chunk["registerCounter"] = chunk["registerCounter"] - 1
			end

			if (node["type"] == nil and var[1] ~= "table") then
				addInstruction(chunk, opcodes["SETGLOBAL"], var[2], setInto)
				
				chunk["registerCounter"] = chunk["registerCounter"] - 1
			end
		end
	}
	
	return nodeTypes:visit(AST, createChunk(fileName or tostring(math.random()), 0, 0, 0))
end