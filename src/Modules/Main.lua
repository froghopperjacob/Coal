return function()
	local Class = BaseClass:new("Main")
	
	local Lexer, Parser, Validator, Interpreter = import("Lexer", "Parser", "Validator", "Interpreter")
	
	Class.Main = function(self, options)
		local defScope = {
			["import"] = function(scope, ...)
				local toImport = { ... }
				
				for i = 1, #toImport do					
					local ret = import("Imports." .. toImport[i])
										
					scope[ret["className"]] = ret
				end
			end	
		}
		
		local defSendScope = {
			
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
	
	Class.interpret = function(self, code)
		local LexerTimeStart, LexerTimeEnd,
			ParserTimeStart, ParserTimeEnd,
			ValidatorTimeStart, ValidatorTimeEnd,
			InterpretTimeStart, InterpreterTimeEnd,
			ret, globalScope, sendScope, scopes = nil, nil, nil, nil, nil, nil, 0, 0, nil, self.options["Scope"], self.options["SendScope"], nil
		
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
		local tokens = Lexer:getTokens(code)
		LexerTimeEnd = tick()
		
		ParserTimeStart = tick()
		local AST = Parser:generateAST(tokens)
		ParserTimeEnd = tick()
		
		ValidatorTimeStart = tick()
		local valid, err = Validator:validate(AST, tokens)
		ValidatorTimeEnd = tick()
		
		if (valid) then
			InterpretTimeStart = tick()			
			globalScope, scopes = Interpreter:interpret(AST, tokens, globalScope, sendScope)
			InterpreterTimeEnd = tick()
		end
		
		return {
			["tokens"] = tokens,
			["AST"] = AST,
			
			["valid"] = valid,
			["error"] = err or "",
			
			["globalScope"] = globalScope,
			["scopes"] = scopes,
			
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
		
				["Validator"] = {
					["start"] = ValidatorTimeStart,
					["end"] = ValidatorTimeEnd,
					["elapsed"] = ValidatorTimeEnd - ValidatorTimeStart
				},
	
				["Interpreter"] = {
					["start"] = InterpretTimeStart,
					["end"] = InterpreterTimeEnd,
					["elapsed"] = InterpreterTimeEnd - InterpretTimeStart
				},
			}
		}
	end
	
	return Class
end
