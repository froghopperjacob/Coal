return function()
	local Class = BaseClass:new("Main")
	
	local Lexer, Parser, Validator, Interpreter = import("Lexer", "Parser", "Validator", "Interpreter")
	
	Class.Main = function(self, options)
		self.options = options or {}
		
		return self
	end
	
	Class.interpret = function(self, code)
		local LexerTimeStart, LexerTimeEnd,
			ParserTimeStart, ParserTimeEnd,
			ValidatorTimeStart, ValidatorTimeEnd,
			InterpretTimeStart, InterpreterTimeEnd,
			ret, globalScope, scopes = nil, nil, nil, nil, nil, nil, 0, 0, nil, self.options["Scope"] or {}, nil
		
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
			globalScope, scopes = Interpreter:interpret(AST, tokens, globalScope)
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