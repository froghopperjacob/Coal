local options
local Settings, Lexer, Parser, Bytecode, VM = require(script.Parent.Settings), require(script.Parent.Lexer), require(script.Parent.Parser), require(script.Parent.Bytecode), require(script.Parent.VM)

return {
	["Setup"] = function(self, goptions)
		local defaultScope = {
			["import"] = function(scope, ...)		
				local toImport = { ... }
								
				local function set(ret, str)
					if (ret["className"]) then						
						scope[ret["className"]] = ret
					else
						local split = { }
						
						for directory in string.gmatch(str, "[%w-%*]+") do
							table.insert(split, directory)
						end
						
						scope[split[#split]] = self:interpret(ret)
					end
				end
				
				for i = 1, #toImport do -- todo first
					local ret = require("Imports." .. tostring(toImport[i]))
																									
					if (typeof(ret) ~= "table" or ret["className"]) then
						set(ret, tostring(toImport[i]))
					else						
						for n = 1, #ret do
							set(ret[n], tostring(toImport[i]))										
						end
					end
				end
			end
		}
			
		local defSendScope = {
			["import"] = true
		}
		
		options = goptions or {
			["Scope"] = defaultScope,
			["SendScope"] = defSendScope
		}
			
		if (options["Scope"] ~= defaultScope) then
			local nScope = defaultScope
			
			for i, v in pairs(options["Scope"]) do
				nScope[i] = v
			end
			
			options["Scope"] = nScope
		end
		
		if (options["SendScope"] ~= defSendScope) then
			local nSScope = defSendScope
			
			for i, v in pairs(options["SendScope"]) do
				nSScope[i] = v
			end
			
			options["SendScope"] = nSScope
		end
		
		return self
	end,
	
	["version"] = Settings["Version"],
	
	["interpretClass"] = function(self, class, rbytecode)
		return self:interpret(require(class), class.Name, rbytecode)
	end,
	
	["interpret"] = function(self, code, className, rbytecode)
		local LexerTimeStart, LexerTimeEnd,
			ParserTimeStart, ParserTimeEnd,
			BytecodeTimeStart, BytecodeTimeEnd,
			VMTimeStart, VMTimeEnd,
			ret, globalScope, sendScope, scopes, tokens, AST, bytecode = 0, 0, 0, 0, 0, 0, nil, nil, nil, options["Scope"], options["SendScope"], nil, nil, nil, nil
		
		if (not options) then
			return error('No options have been given')
		end

		if (rbytecode == nil or rbytecode == false) then
			LexerTimeStart = tick()
			tokens = Lexer(code)
			LexerTimeEnd = tick()
			
			ParserTimeStart = tick()
			AST = Parser(tokens)
			ParserTimeEnd = tick()
			
			BytecodeTimeStart = tick()
			bytecode = Bytecode(AST, className)
			BytecodeTimeEnd = tick()
			
			print(game:GetService("HttpService"):JSONEncode(bytecode))
						
			VMTimeStart = tick()
			scopes = VM(bytecode, globalScope)
			VMTimeEnd = tick()
		else
			VMTimeStart = tick()
			scopes = VM(code, globalScope)
			VMTimeEnd = tick()
		end
		
		return {
			["tokens"] = tokens,
			["AST"] = AST,
			["bytecode"] = bytecode,
			
			["globalScope"] = globalScope,
			["scopes"] = scopes,
			
			["code"] = code,
			
			["times"] = {
				["Lexer"] = {
					["start"] = LexerTimeStart,
					["end"] = LexerTimeEnd,
					["elapsed"] = LexerTimeEnd - LexerTimeStart
				},
			
				["Parser"] = {
					["start"] = ParserTimeStart,
					["end"] = ParserTimeEnd,
					["elapsed"] = ParserTimeEnd - ParserTimeStart
				},
	
				["Bytecode"] = {
					["start"] = BytecodeTimeStart,
					["end"] = BytecodeTimeEnd,
					["elapsed"] = BytecodeTimeEnd - BytecodeTimeStart
				},
				
				["VM"] = {
					["start"] = VMTimeStart,
					["end"] = VMTimeEnd,
					["elapsed"] = VMTimeEnd - VMTimeStart
				},
	
				["elapsed"] = (LexerTimeEnd - LexerTimeStart) + (ParserTimeEnd - ParserTimeEnd) + (BytecodeTimeEnd - BytecodeTimeStart) + (VMTimeEnd - VMTimeStart)
			}
		}
	end
}