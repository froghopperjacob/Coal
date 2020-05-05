local Settings = require(script.Parent.Settings)
local opcodes = Settings["Opcodes"]
local Types = script.Parent.Parent.Imports.Types

local Array, Dictionary = require(Types.Array), require(Types.Dictionary)

local function wrap(chunk, env, upvalues)	
	local instructions = chunk["instructions"]
	local constants = chunk["constants"]
	local protos = chunk["protos"]
	
	return function(...)
		local programCounter, top = 1, -1
		
		local gStack, lupvals = { }, { }
		local stack =  setmetatable({ }, {
			__index		= gStack;
			__newindex	= function(_, key, value)
				if (key > top) then
					top	= key;
				end;

				gStack[key]	= value;
			end;
		})
			
		local function getCOrR(x)
			if (x > Settings["RegisterLimit"]) then
				return constants[x - Settings["RegisterLimit"]]["value"]
			end
			
			return stack[x]
		end
			
		local function loop()
			while programCounter <= #instructions do
				local instruction = instructions[programCounter]
				local op, A, B, C = instruction[1], instruction[2], instruction[3], instruction[4]
				programCounter = programCounter + 1
												
				if (op == opcodes["MOVE"]) then
					stack[A] = stack[B]
				elseif (op == opcodes["LOADK"]) then					
					stack[A] = constants[B]["value"]
				elseif (op == opcodes["LOADBOOL"]) then
					stack[A] = B == 1
					
					if (C ~= 0) then
						programCounter = programCounter + 1
					end
				elseif (op == opcodes["LOADNIL"]) then
					for i = A, B do
						stack[i] = nil
					end
				elseif (op == opcodes["GETUPVAL"]) then
					stack[A] = upvalues[B]
				elseif (op == opcodes["GETGLOBAL"]) then
					stack[A] = env[constants[B]["value"]]
				elseif (op == opcodes["GETTABLE"]) then
					stack[A] = stack[B][getCOrR(C)]
				elseif (op == opcodes["SETGLOBAL"]) then
					env[constants[B]["value"]] = stack[A]
				elseif (op == opcodes["SETUPPVAL"]) then
					upvalues[B] = stack[A]
				elseif (op == opcodes["SETTABLE"]) then
					stack[A][getCOrR(B)] = getCOrR(C)
				elseif (op == opcodes["NEWARR"]) then
					stack[A] = Array()
				elseif (op == opcodes["NEWDICT"]) then
					stack[A] = Dictionary()
				elseif (op == opcodes["ADD"]) then										
					stack[A] = getCOrR(B) + getCOrR(C)
				elseif (op == opcodes["SUB"]) then
					stack[A] = getCOrR(B) - getCOrR(C)
				elseif (op == opcodes["MUL"]) then
					stack[A] = getCOrR(B) * getCOrR(C)
				elseif (op == opcodes["DIV"]) then
					stack[A] = getCOrR(B) / getCOrR(C)
				elseif (op == opcodes["MOD"]) then
					stack[A] = getCOrR(B) % getCOrR(C)
				elseif (op == opcodes["POW"]) then
					stack[A] = getCOrR(B) ^ getCOrR(C)
				elseif (op == opcodes["BAND"]) then
					stack[A] = bit32.band(getCOrR(B), getCOrR(C))
				elseif (op == opcodes["BOR"]) then
					stack[A] = bit32.bor(getCOrR(B), getCOrR(C))
				elseif (op == opcodes["BXOR"]) then
					stack[A] = bit32.bxor(getCOrR(B), getCOrR(C))
				elseif (op == opcodes["BLEFTSHIFT"]) then
					stack[A] = bit32.lshift(getCOrR(B), getCOrR(C))
				elseif (op == opcodes["BRIGHTSHIFT"]) then
					stack[A] = bit32.rshift(getCOrR(B), getCOrR(C))
				elseif (op == opcodes["BFLIP"]) then
					stack[A] = bit32.bnot(getCOrR(B))
				elseif (op == opcodes["UNM"]) then
					stack[A] = -stack[B]
				elseif (op == opcodes["NOT"]) then
					stack[A] = not stack[B]
				elseif (op == opcodes["JMP"]) then
					programCounter = programCounter + A
				elseif (op == opcodes["EQ"]) then
					if ((getCOrR(B) == getCOrR(C)) ~= (A ~= 0)) then
						programCounter = programCounter + 1
					end
				elseif (op == opcodes["LT"]) then
					if ((getCOrR(B) < getCOrR(C)) ~= (A ~= 0)) then
						programCounter = programCounter + 1
					end
				elseif (op == opcodes["LE"]) then
					if ((getCOrR(B) <= getCOrR(C)) ~= (A ~= 0)) then
						programCounter = programCounter + 1
					end
				elseif (op == opcodes["TEST"]) then					
					if (C == 0) then
						if (stack[A]) then
							programCounter = programCounter + 1
						end
					elseif (stack[A]) then
						
					else
						programCounter = programCounter + 1
					end
				elseif (op == opcodes["TESTSET"]) then					
					if (C == 0) then
						if (stack[B]) then
							programCounter = programCounter + 1
						else
							stack[A] = stack[B]
						end
					elseif (stack[B]) then
						stack[A] = stack[B]
					else
						programCounter = programCounter + 1
					end
				elseif (op == opcodes["CALL"]) then
					local args, result, limit, edx = { }, nil, nil, nil
									
					if (C ~= 1) then
						if (C ~= 0) then
							limit = B + C - 1
						else
							limit = top
						end
						
						edx = 0
						
						for i = B + 1, limit do
							edx = edx + 1
							
							args[edx] = stack[i]
						end
												
						result = stack[B](unpack(args, 1, limit - B))
					else
						result = stack[B]()
					end
										
					top = B - 1
					
					if (A ~= 0) then
						stack[A] = result
					end
				elseif (op == opcodes["SETLIST"]) then
					local offset = C * Settings["FieldsPerPush"]
					local tab = stack[A]
					
					print(tab)
					
					if (B == 0) then
						B = top - A
					end
					
					for i = 1, B do
						tab[offset + i] = stack[A + i]
					end
				elseif (op == opcodes["RETURN"]) then
					local edx, output, limit
					
					if (B == 1) then
						return
					elseif (B == 0) then
						limit = top
					else
						limit = A + B - 2
					end
					
					edx, output = 0, { }
					
					for idx = A, limit do
						edx = edx + 1
						
						output[edx] = stack[idx]
					end
					
					return output, edx
				end
			end
		end
		
		local args = { ... }
		
		for i = 0, #args - 1 do
			stack[i] = args[i + 1];
		end
		
		loop()
		
		--[[local A, B, C = pcall(loop)
				
		if (A) then
			if (B and C > 0) then
				return unpack(B, 1, C)
			end
			
			return
		else
			error(B .. "|" .. programCounter - 1)
		end]]
	end
end

return function(mainChunk, env)
	return wrap(mainChunk, env)()
end