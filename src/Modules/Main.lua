return function()
	local Class = BaseClass:new("Main")
	
	local Lexer, Parser, Interpreter = require(script.Parent.Lexer), require(script.Parent.Parser), import("Interpreter")
		
	Class.Main = function(self, options)
		local defScope = {
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
				
				for i = 1, #toImport do
					local ret = import("Imports." .. tostring(toImport[i]))
																									
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
		
		self.options = options or {
			["Scope"] = defScope,
			["SendScope"] = defSendScope
		}
			
		if (self.options["Scope"] ~= defScope) then
			local nScope = defScope
			
			for i, v in pairs(self.options["Scope"]) do
				nScope[i] = v
			end
			
			self.options["Scope"] = nScope
		end
		
		if (self.options["SendScope"] ~= defSendScope) then
			local nSScope = defSendScope
			
			for i, v in pairs(self.options["SendScope"]) do
				nSScope[i] = v
			end
			
			self.options["SendScope"] = nSScope
		end
		
		return self
	end

	Class.interpretClass = function(self, class)
		return self:interpret(require(class))
	end
	
	Class.interpret = function(self, code)
		local LexerTimeStart, LexerTimeEnd,
			ParserTimeStart, ParserTimeEnd,
			InterpretTimeStart, InterpreterTimeEnd,
			ret, globalScope, sendScope, scopes = nil, nil, nil, nil, 0, 0, nil, self.options["Scope"], self.options["SendScope"], nil
		
		if (not self.options) then
			return error('Class not initalized')
		end
		
		if (not code) then
			return error('Incorrect number of arguments given')
		end
		
		if (not typeof(code) == 'string') then
			return error('Incorrect argument type given')
		end
		
		LexerTimeStart = tick()
		local tokens = Lexer(code)
		LexerTimeEnd = tick()
		
		ParserTimeStart = tick()
		local AST = Parser(tokens)
		ParserTimeEnd = tick()
		
		InterpretTimeStart = tick()			
		globalScope, scopes = Interpreter:interpret(AST, tokens, globalScope, sendScope)
		InterpreterTimeEnd = tick()
		
		return {
			["tokens"] = tokens,
			["AST"] = AST,
			
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
	
				["Interpreter"] = {
					["start"] = InterpretTimeStart,
					["end"] = InterpreterTimeEnd,
					["elapsed"] = InterpreterTimeEnd - InterpretTimeStart
				},
	
				["elapsed"] = (LexerTimeEnd - LexerTimeStart) + (ParserTimeEnd - ParserTimeEnd) + (InterpreterTimeEnd - InterpretTimeStart)
			}
		}
	end
	
	return Class
end