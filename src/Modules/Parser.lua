return function()
	local Class = BaseClass:new("Parser")
	local Node = BaseClass:new("Node")
	
	local Root = BaseClass:new("Root")
	local Number = BaseClass:new("Number")
	local Assign = BaseClass:new("Assign")
	local Variable = BaseClass:new("Variable")
	local Unary = BaseClass:new("Unary")
	local Empty = BaseClass:new("Empty")
	local CallFunction = BaseClass:new("CallFunction")
	local String = BaseClass:new("String")
	local CreateFunction = BaseClass:new("CreateFunction")
	local Return = BaseClass:new("Return")
	local If = BaseClass:new("If")
	local Compare = BaseClass:new("Compare")
	local CompareOperator = BaseClass:new("CompareOperator")
	local Boolean = BaseClass:new("Boolean")
	local For = BaseClass:new("For")
	local While = BaseClass:new("While")
	
	-- Default Node --
	Node.Node = function(self, left, right, token)
		self.nodeType = "Node"
		
		self.left = left
		self.right = right
		self.token = token
		
		return self
	end
	
	-- Empty --
	Empty.Empty = function(self)
		self.nodeType = "Empty"
		
		return self
	end
	
	-- While --
	While.While = function(self, check, statements)
		self.nodeType = "While"
		
		self.check = check
		self.statements = statements
		
		return self
	end
	
	-- For --
	For.For = function(self, variable, check, iter, statements)
		self.nodeType = "For"
		
		self.variable = variable
		self.check = check
		self.iter = iter
		self.statements = statements
		
		return self
	end
	
	-- CompareOperator --
	CompareOperator.CompareOperator = function(self, left, right, token)
		self.nodeType = "CompareOperator"
		
		self.left = left
		self.right = right
		self.token = token
		
		return self
	end
	
	-- Compare --
	Compare.Compare = function(self, left, right, token)
		self.nodeType = "Compare"
		
		self.left = left
		self.right = right
		self.token = token
		
		return self
	end
	
	-- Boolean --
	Boolean.Boolean = function(self, token)
		self.nodeType = "Boolean"
		
		self.token = token
		self.data = token["data"]
		
		return self
	end
	
	-- CallFunction --
	CallFunction.CallFunction = function(self, token, arguments)
		self.nodeType = "CallFunction"
		
		self.arguments = arguments
		self.token = token
		
		return self
	end
	
	-- If Statement --
	If.If = function(self, check, ifs, eifs, es)
		self.nodeType = "If"
		
		self.check = check
		
		self.ifStatmenets = ifs
		self.elseifStatements = eifs
		self.elseStatements = es
		
		return self
	end
	
	-- Return --
	Return.Return = function(self, expression)
		self.nodeType = "Return"
		
		self.expression = expression
		
		return self
	end
	
	-- String --
	String.String = function(self, token)
		self.nodeType = "String"
		
		self.token = token
		self.data = token["data"]
	
		return self
	end
	
	-- Create Function --
	CreateFunction.CreateFunction = function(self, token, arguments, statements)
		self.nodeType = "CreateFunction"
		
		self.token = token
		self.arguments = arguments
		
		self.statements = statements
		
		return self
	end
		
	-- Root --
	Root.Root = function(self)
		self.nodeType = "Root"
		
		self.children = {}
		
		return self
	end
	
	-- Number Node --
	Number.Number = function(self, token)
		self.nodeType = "Number"
		
		self.token = token
		self.data = token["data"]
		
		return self
	end
	
	-- Unary Node --
	Unary.Unary = function(self, token, expr)
		self.nodeType = "Unary"
		
		self.token = token
		self.expr = expr
		
		return self
	end
	
	-- Assign a variable --
	Assign.Assign = function(self, left, right, token, typ)
		self.nodeType = "Assign"
		
		self.left = left
		self.right = right
		self.token = token
		self.type = typ
		
		return self
	end
	
	-- Variable Node --
	Variable.Variable = function(self, token)
		self.nodeType = "Variable"
		
		self.token = token
		self.data = token["data"]
		
		return self
	end
	
	Class.generateAST = function(self, tokens)
		local currentIndex = 1
		local currentToken = tokens[1]
		local root = Root()
		
		local function eat(tokenType, tokenData)
			if (currentToken["type"] == tokenType and currentToken["data"] == (tokenData or currentToken["data"])) then
				currentIndex = currentIndex + 1
				
				currentToken = tokens[currentIndex]
			else
				error("Invalid Syntax")
			end
		end
		
		local function variableStatement()
			local node = Variable(currentToken)
					
			eat("iden")
			
			return node
		end
		
		local function booleanStatement()
			local node = Boolean(currentToken)
			
			eat("boolean")
			
			return node
		end
		
		local function factor()
			local token = currentToken
			
			if (token["type"] == "operator" and token["data"] == "+") then
				eat("operator", "+")
				
				return Unary(token, factor())
			elseif (token["type"] == "operator" and token["data"] == "-") then
				eat("operator", "-")
				
				return Unary(token, factor())
			elseif (token["type"] == "number") then
				eat("number")
				
				return Number(token)
			elseif (token["type"] == "string") then
				eat("string")
				
				return String(token)
			elseif (token["type"] == "iden") then
				if (tokens[currentIndex + 1]["data"] == "(") then
					return callFunction()
				else
					return variableStatement()
				end
			elseif (token["type"] == "boolean") then
				return booleanStatement()
			else
				return Empty()
			end
		end
		
		local function term()
			local node = factor()
						
			while (currentToken["type"] == "operator" and currentToken["data"] == "/" or currentToken["data"] == "*" or currentToken["data"] == "^" or currentToken["data"] == "%") do
				local token = currentToken
				
				if (token["data"] == "*") then
					eat("operator", "*")
				elseif (token["data"] == "/") then
					eat("operator", "/")
				elseif (token["data"] == "^") then
					eat("operator", "^")
				elseif (token["data"] == "%") then
					eat("operator", "%")
				end
				
				node = Node(node, factor(), token)
				
				wait()
			end
			
			return node
		end
		
		local function expression()
			local node = term()
			
			while (currentToken["type"] == "operator" and currentToken["data"] == "+" or currentToken["data"] == "-") do
				local token = currentToken
				
				if (token["data"] == "+") then
					eat("operator", "+")
				elseif (token["data"] == "-") then
					eat("operator", "-")
				end
				
				node = Node(node, term(), token)
				
				wait()
			end
						
			return node
		end
		
		local function assignStatement()
			local typ = {
				["type"] = "keyword",
				["data"] = "edit"
			}
			
			if (currentToken["type"] == "keyword") then
				typ = currentToken
				
				eat("keyword")
			end
			
			local left, token, right = variableStatement(), currentToken, nil
						
			eat("assign")
			
			right = expression()
			
			return Assign(left, right, token, typ)
		end
		
		function callFunction()
			local token, run, arguments = currentToken, true, { }
			
			eat(currentToken["type"])
			eat("other", "(")
				
			while (run) do
				if (currentToken["data"] == ")") then
					eat("other", ")")
			
					run = false
				else
					table.insert(arguments, expression())
					
					if (currentToken["data"] == ",") then
						eat("other", ",")
					end
				end
				
				wait()
			end
		
			return CallFunction(token, arguments)
		end
	
		local function createReturn()					
			eat("keyword", "return")
			
			return Return(expression())
		end
	
		local function statementInfo()
			local token, node = currentToken, nil
						
			if (token["data"] == "function") then
				node = createFunction()
			elseif (token["data"] == "return") then
				node = createReturn()
			elseif (token["data"] == "if") then
				node = createIfStatement()
			elseif (token["data"] == "for") then
				node = createForStatement()
			elseif (token["data"] == "while") then
				node = createWhileStatement()
			elseif (token["data"] == "let") then
				node = assignStatement()
			elseif (token["data"] == "var") then
				node = assignStatement()
			else
				return error("Syntax Error")
			end
			
			return node
		end
		
		local function statement()
			local node
						
			if (currentToken["type"] == "iden") then
				if (tokens[currentIndex + 1]["data"] == "=") then
					node = assignStatement()
				elseif (tokens[currentIndex + 1]["data"] == "(") then
					node = callFunction()
				end
			elseif (currentToken["type"] == "builtin") then
				node = callFunction()
			elseif (currentToken["type"] == "keyword") then
				node = statementInfo()
			else
				node = Empty()
			end
			
			return node
		end
		
		local function getStatements()
			local node = statement()
			local results = { node }
						
			while (currentToken["type"] == "statement" and currentIndex ~= #tokens) do				
				eat("statement")
				
				table.insert(results, statement())
				
				wait()
			end
			
			if (currentToken["type"] == "iden") then
				return error("Syntax Error")
			end
			
			return results
		end
		
		local function getCheck()
			local left, compare, right, node = expression(), nil, nil, nil
						
			if (currentToken["type"] ~= "compare") then
				return Compare(left, Boolean({
					["type"] = "boolean",
					["data"] = "true"
				}), {
					["type"] = "compare",
					["data"] = "=="
				})
			end
			
			compare = currentToken
			eat("compare")
			
			right = expression()
			
			if (currentToken["type"] == "compareop") then
				local token = currentToken
				
				eat("compareop")
				
				return CompareOperator(Compare(left, right, compare), getCheck(), token)
			else
				return Compare(left, right, compare)
			end
		end
		
		function createWhileStatement()
			local check, statements, run = nil, {}, true
			
			eat("keyword")
			eat("other", "(")
				
			check = getCheck()
			
			eat("other", ")")
			eat("other", "{")
				
			if (currentToken["type"] == "statement") then
				eat("statement", "\n")
			end
						
			while (run) do
				if (currentToken["data"] == "}") then
					eat("other", "}")
			
					run = false
				else
					table.insert(statements, statement())
					
					eat("statement")
				end
			end
			
			return While(check, statements)
		end
		
		function createIfStatement()
			local check, ifs, eifs, es, arElse = nil, nil, nil, nil, false
			
			local function createStatements()
				local run, stats = true, {}
				
				while (run) do
					if (currentToken["data"] == "}") then
						eat("other", "}")
				
						run = false
					else
						table.insert(stats, statement())
						
						eat("statement")
					end
				end
				
				return stats
			end
		
			function getAtStatements(ret)
				local nret = ret
				
				if (currentToken["data"] == "else") then
					if (arElse) then
						return error("Syntax Error")
					end
					
					eat("keyword")
					eat("other", "{")
					
					if (currentToken["type"] == "statement") then
						eat("statement", "\n")
					end
										
					nret["else"] = createStatements()
										
					arElse = true
				elseif (currentToken["data"] == "elseif") then
					if (arElse) then
						return error("Syntax Error")
					end
					
					eat("keyword")
					eat("other", "(")
					
					local check = getCheck()
					
					eat("other", ")")
					eat("other", "{")
						
					if (currentToken["type"] == "statement") then
						eat("statement", "\n")
					end
					
					table.insert(nret["elseifs"], If(check, createStatements()))
				else
					arElse = true
				end
			
				if (not arElse) then
					nret = getAtStatements(nret)
				end
				
				return nret
			end
			
			eat("keyword", "if")
			eat("other", "(")
			
			check = getCheck()
			
			eat("other", ")")
			eat("other", "{")
				
			if (currentToken["type"] == "statement") then
				eat("statement", "\n")
			end
	
			ifs = createStatements()
		
			local ret = getAtStatements({ ["elseifs"] = {} })
			
			es = ret["else"]
			eifs = ret["elseifs"]
			
			return If(check, ifs, eifs, es)
		end
			
		function createForStatement()
			local variable, check, iter, statements, run = nil, nil, nil, {}, true
			
			eat("keyword")
			eat("other", "(")
			
			variable = assignStatement()
			
			eat("statement")
						
			check = getCheck()
			
			eat("statement")
						
			iter = assignStatement()
						
			eat("other", ")")
			eat("other", "{")
				
			if (currentToken["type"] == "statement") then
				eat("statement", "\n")
			end
						
			while (run) do
				if (currentToken["data"] == "}") then
					eat("other", "}")
			
					run = false
				else
					table.insert(statements, statement())
					
					eat("statement")
				end
			end
			
			return For(variable, check, iter, statements)
		end
	
		function createFunction()
			local token, run, arguments, statements = nil, true, {}, {}
			
			eat("keyword", "function")
				
			token = currentToken
			
			eat("iden")
			eat("other", "(")
				
			if (currentToken["data"] ~= ")") then
				while (run) do
					if (currentToken["data"] == ")") then
						run = false
						eat("other", ")")
					else
						table.insert(arguments, currentToken["data"])
						
						eat("iden")
					
						if (currentToken["data"] == ",") then
							eat("other", ",")
						end
					end
					
					wait()
				end
			else
				eat("other", ")")
			end
		
			eat("other", "{")
								
			if (currentToken["type"] == "statement") then
				eat("statement", "\n")
			end
							
			run = true
				
			while (run) do
				if (currentToken["data"] == "}") then
					eat("other", "}")
			
					run = false
				else
					table.insert(statements, statement())
					
					eat("statement")
				end
			end
			
			return CreateFunction(token, arguments, statements)
		end
		
		local nodes = getStatements()		
		
		for i = 1, #nodes do						
			table.insert(root.children, nodes[i])
		end
		
		return root
	end
	
	return Class
end