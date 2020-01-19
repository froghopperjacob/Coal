return function()
	local Class = BaseClass:new("Parser")
	
	Class.generateAST = function(self, tokens)
		local currentToken, currentIndex = tokens[1], 1
						
		local function eat(ty, data)
			if (currentToken["type"] == ty and currentToken["data"] == (data or currentToken["data"])) then
				currentIndex = currentIndex + 1
				currentToken = tokens[currentIndex]
			else
				if (data ~= nil) then
					error('Expected ' .. data .. ' on line ' .. currentToken["line"])
				else
					error('Expected type ' .. ty .. ' on line ' .. currentToken["line"])
				end
			end
		end
		
		function listStatement()
			eat("other", "{")
				
			if (currentToken["type"] == "statement") then
				eat("statement", "\n")
			end
			
			local run, elements = true, {}
			
			while (run) do
				if (currentToken["data"] == "}") then
					eat("other")
					
					run = false
				else
					table.insert(elements, assignStatement())
					
					if (currentToken["data"] == ",") then
						eat("other")
					end
					
					if (currentToken["type"] == "statement") then
						eat("statement", "\n")
					end
				end
			end
			
			return {
				["nodeType"] = "List",
				["elements"] = elements
			}
		end
		
		function arrayStatment()
			eat("other", "[")
			
			if (currentToken["type"] == "statement") then
				eat("statement", "\n")
			end
			
			local run, elements = true, {}
			
			while (run) do
				if (currentToken["data"] == "]") then
					eat("other")
					
					run = false
				else
					table.insert(elements, expression())
					
					if (currentToken["data"] == ",") then
						eat("other")
					end
					
					if (currentToken["type"] == "statement") then
						eat("statement", "\n")
					end
				end
			end
			
			return {
				["nodeType"] = "Array",
				["elements"] = elements
			}
		end
		
		local function factor()
			local token, ty, data = currentToken, currentToken["type"], currentToken["data"]
			
			if (ty == "operator") then
				if (data == "+" or data == "-") then
					eat("operator")
					
					return {
						["nodeType"] = "Unary",
						["type"] = token,
						["value"] = factor()
					}
				end
			elseif (ty == "number") then
				eat("number")
				
				return {
					["nodeType"] = "Number",
					["value"] = token
				}
			elseif (ty == "string") then
				eat("string")
				
				return {
					["nodeType"] = "String",
					["value"] = token
				}
			elseif (ty == "keyword") then				
				if (data == "new") then
					return createNewStatement()
				elseif (data == "function") then
					return createFunction()
				elseif (data == "null") then
					eat("keyword")
					
					return {
						["nodeType"] = "Null"
					}
				end
			elseif (ty == "iden") then
				local var = variableStatement()
				
				if (currentToken["data"] == "(") then
					return callFunction(var)
				else
					return var
				end
			elseif (ty == "boolean") then
				eat("boolean")
				
				return {
					["nodeType"] = "Boolean",
					["value"] = token
				}
			elseif (ty == "other") then
				if (data == "[") then
					return arrayStatment()
				elseif (data == "{") then
					return listStatement()
				end
			end
				
			return {
				["nodeType"] = "Empty"
			}
		end
		
		function term()
			local node = factor()
			local ty, data
						
			while (currentToken["type"] == "operator" and currentToken["data"] == "/" or currentToken["data"] == "*" or currentToken["data"] == "^" or currentToken["data"] == "%") do
				local token, data = currentToken, currentToken["data"]
				
				if (data == "*") then
					eat("operator")
				elseif (data == "/") then
					eat("operator")
				elseif (data == "^") then
					eat("operator")
				elseif (data == "%") then
					eat("operator")
				end
				
				node = {
					["nodeType"] = "BinOp",
					["left"] = node,
					["right"] = factor(),
					["value"] = token
				}
								
				wait()
			end
			
			return node
		end
		
		function createNewStatement()
			eat("keyword")
			
			local class, run, arguments = variableStatement(), true, {}
			
			eat("other", "(")
			
			while (run) do
				if (currentToken["data"] == ")") then
					eat("other")
			
					run = false
				else
					table.insert(arguments, expression())
					
					if (currentToken["data"] == ",") then
						eat("other", ",")
					end
				end
				
				wait()
			end
		
			return {
				["nodeType"] = "New",
				["variable"] = class,
				["arguments"] = arguments
			}
		end
		
		function addExpression()
			local node = term()
			
			while (currentToken["type"] == "operator" and currentToken["data"] == "+" or currentToken["data"] == "-") do
				local token, data = currentToken, currentToken["data"]
				
				if (data == "+") then
					eat("operator")
				elseif (data == "-") then
					eat("operator")
				end
				
				node = {
					["nodeType"] = "BinOp",
					["left"] = node,
					["right"] = term(),
					["value"] = token
				}
				
				wait()
			end
						
			return node
		end
		
		function compareExpression()
			local node = addExpression()
			
			while (currentToken["type"] == "compare") do
				local token, data = currentToken, currentToken["data"]
				
				eat("compare")
								
				node = {
					["nodeType"] = "Compare",
					["left"] = node,
					["right"] = addExpression(),
					["operator"] = token
				}
				
				wait()
			end
			
			return node
		end
		
		function expression()
			local node = compareExpression()
			
			while (currentToken["type"] == "compareop") do
				local token, data = currentToken, currentToken["data"]
				
				eat("compareop")
								
				node = {
					["nodeType"] = "CompareOperator",
					["left"] = node,
					["right"] = compareExpression(),
					["value"] = token
				}
				
				wait()
			end
			
			return node
		end
		
		function variableStatement(v)				
			local node = {
				["nodeType"] = "Variable",
				["value"] = v or currentToken,
			}
			
			if (v == nil) then
				eat("iden")
			end
			
			function getAccess(var)
				local nnode = nil
								
				if (currentToken["type"] == "other") then
					if (currentToken["data"] == "[") then
						eat("other")
						
						local data = expression()
						
						eat("other", "]")
						
						nnode = {
							["nodeType"] = "Access",
							["variable"] = var,
							["data"] = data
						}
					elseif (currentToken["data"] == ".") then
						eat("other")
						
						local nvar = {
							["nodeType"] = "Pass",
							["value"] = currentToken
						}
						
						eat("iden")
						
						nnode = {
							["nodeType"] = "Access",
							["variable"] = var,
							["data"] = nvar
						}
					end
				end
				
				if (nnode and currentToken["type"] == "other" and currentToken["data"] == "[" or currentToken["data"] == ".") then
					return getAccess(nnode)
				else
					return nnode
				end
			end
			
			local access = getAccess(node)
			
			if (access) then
				return access
			else
				return node
			end
		end
		
		function assignStatement(var, ty)
			local varStat = var or variableStatement()
			
			eat("assign")
			
			return {
				["nodeType"] = "Assign",
				["variable"] = varStat,
				["value"] = expression(),
				["type"] = ty
			}
		end
		
		function callFunction(var)
			local varStat = var or variableStatement()
									
			eat("other", "(")
			
			local run, arguments = true, { }
			
			while (run) do
				if (currentToken["data"] == ")") then
					run = false
					
					eat("other")
				else
					table.insert(arguments, expression())
					
					if (currentToken["data"] == ",") then
						eat("other")
					end
				end
			end
			
			if (currentToken["data"] == ".") then
				local var = variableStatement({
					["nodeType"] = "CallFunction",
					["arguments"] = arguments,
					["variable"] = varStat
				})
				
				if (currentToken["data"] == "=") then
					return assignStatement(var)
				else
					return var
				end
			else
				return {
					["nodeType"] = "CallFunction",
					["arguments"] = arguments,
					["variable"] = varStat
				}
			end
		end
		
		function classStatement()
			eat("keyword")
			
			local name, extends = currentToken, nil
			eat("iden")
			
			if (currentToken["data"] == "extends") then
				eat("keyword")
				
				extends = currentToken["data"]
				eat("iden")
			end
			
			eat("other", "{")
				
			if (currentToken["type"] == "statement") then
				eat("statement", "\n")
			end
			
			local run, statements = true, {}
			
			while (run) do
				if (currentToken["data"] == "}") then
					eat("other", "}")
			
					run = false
				else
					table.insert(statements, statement())
					
					eat("statement")
				end
			end
			
			return {
				["nodeType"] = "Class",
				["name"] = name,
				["statements"] = statements,
				["extends"] = extends
			}
		end
		
		function createFunction(ty)
			local token, run, arguments, statements = nil, true, {}, {}
			
			eat("keyword", "function")
				
			token = currentToken
			
			eat("iden")
			eat("other", "(")
				
			if (currentToken["data"] ~= ")") then
				while (run) do
					if (currentToken["data"] == ")") then
						run = false
						eat("other")
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
			
			return {
				["nodeType"] = "CreateFunction",
				["value"] = token,
				["arguments"] = arguments,
				["statements"] = statements,
				["type"] = ty
			}
		end
	
		function typeStatement()
			local node = {
				["scope"] = currentToken,
				["type"] = { }
			}
			
			eat("keyword")
			
			while (currentToken["type"] == "keyword" and currentToken["data"] == "static" or currentToken["data"] == "final") do
				table.insert(node["type"], currentToken)
				
				eat("keyword")
			end
			
			if (currentToken["type"] == "keyword" and currentToken["data"] == "function") then
				return createFunction(node)
			elseif (currentToken["type"] == "iden") then
				return assignStatement(variableStatement(), node)
			end
		end
			
		function returnStatement()
			eat("keyword")
						
			return {
				["nodeType"] = "Return",
				["expression"] = expression() 
			}
		end

		function statement()
			local ty, data = currentToken["type"], currentToken["data"]
			
			if (ty == "iden") then
				local var = variableStatement()
				
				if (currentToken["data"] == "=") then
					return assignStatement(var)
				elseif (currentToken["data"] == "(") then
					return callFunction(var)
				end
			elseif (ty == "keyword") then
				if (data == "for") then
					return createForStatement()
				elseif (data == "if") then
					return createIfStatement()
				elseif (data == "while") then
					return createWhileStatement()
				elseif (data == "class") then
					return classStatement()
				elseif (data == "public" or data == "private") then
					return typeStatement()
				elseif (data == "return") then
					return returnStatement()
				end	
			end
				
			return {
				["nodeType"] = "Empty"
			}
		end

		function createWhileStatement()
			local check, statements, run = nil, {}, true
			
			eat("keyword")
			eat("other", "(")
				
			check = expression()
			
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
			
			return {
				["nodeType"] = "While",
				["check"] = check,
				["statements"] = statements
			}
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
					eat("keyword")
					eat("other", "{")
					
					if (currentToken["type"] == "statement") then
						eat("statement", "\n")
					end
										
					nret["else"] = createStatements()
															
					arElse = true
				elseif (currentToken["data"] == "elseif") then					
					eat("keyword")
					eat("other", "(")
					
					local check = expression()
					
					eat("other", ")")
					eat("other", "{")
						
					if (currentToken["type"] == "statement") then
						eat("statement", "\n")
					end
										
					table.insert(nret["elseifs"], {
						["nodeType"] = "If",
						["check"] = check,
						["statements"] = createStatements()
					})
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
			
			check = expression()
						
			eat("other", ")")
			eat("other", "{")
				
			if (currentToken["type"] == "statement") then
				eat("statement", "\n")
			end
	
			ifs = createStatements()
					
			local ret = getAtStatements({ ["elseifs"] = {} })
			
			es = ret["else"]
			eifs = ret["elseifs"]
			
			return {
				["nodeType"] = "If",
				["check"] = check,
				["ifstatements"] = ifs,
				["elseifstatements"] = eifs,
				["elsestatements"] = es
			}
		end
			
		function createForStatement()
			local variable, check, iter, statements, run = nil, nil, nil, {}, true
			
			eat("keyword")
			eat("other", "(")
			
			variable = assignStatement()
			
			eat("statement")
						
			check = expression()
						
			eat("statement")
						
			iter = assignStatement()
						
			eat("other", ")")
			eat("other", "{")
				
			if (currentToken["type"] == "statement") then
				eat("statement", "\n")
			end
						
			while (run) do
				if (currentToken["data"] == "}") then
					eat("other")
			
					run = false
				else
					table.insert(statements, statement())
					
					eat("statement")
				end
			end
		
			return {
				["nodeType"] = "For",
				["variable"] = variable,
				["check"] = check,
				["iter"] = iter,
				["statements"] = statements 
			}
		end
		
		local function getStatements()
			local node = statement()
			local results = { node }
						
			while (currentToken["type"] == "statement" and currentIndex ~= #tokens) do
				eat("statement")
				
				table.insert(results, statement())
								
				wait()
			end
			
			return results
		end
								
		local root, nodes = {
			["nodeType"] = "Root",
			["children"] = { }
		}, getStatements()		
		
		for i = 1, #nodes do		
			table.insert(root.children, nodes[i])
		end
						
		return root
	end
	
	return Class
end
