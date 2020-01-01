return function()
	local Class = BaseClass:new("Lexer")
	
	local NUMBER1	= "^[%+%-]?%d+%.?%d*[eE][%+%-]?%d+"
	local NUMBER2	= "^[%+%-]?%d+%.?%d*"
	local NUMBER3	= "^0x[%da-fA-F]+"
	local NUMBER4	= "^%d+%.?%d*[eE][%+%-]?%d+"
	local NUMBER5	= "^%d+%.?%d*"
	local WSPACE 	= "^[ ]+"
	local IDEN		= "^[%a_][%w_]*"
	local STRING1	= "^(['\"])%1"							--Empty String
	local STRING2	= [[^(['"])(\*)%2%1]]
	local STRING3	= [[^(['"]).-[^\](\*)%2%1]]
	local STRING4	= "^(['\"]).-.*"						--Incompleted String
	local STRING5	= "^%[(=*)%[.-%]%1%]"					--Multiline-String
	local STRING6	= "^%[%[.-.*"							--Incompleted Multiline-String
	local CHAR1		= "^''"
	local CHAR2		= [[^'(\*)%1']]
	local CHAR3		= [[^'.-[^\](\*)%1']]
	local PREPRO	= "^#.-[^\\]\n"
	local MCOMMENT1	= "^%-%-%[(=*)%[.-%]%1%]"				--Completed Multiline-Comment
	local MCOMMENT2	= "^%-%-%[%[.-.*"						--Incompleted Multiline-Comment
	local SCOMMENT1	= "^%-%-.-\n"							--Completed Singleline-Comment
	local SCOMMENT2	= "^%-%-.-.*"							--Incompleted Singleline-Comment
	
	Class.format = function(self, code)
		local ncode = code:gsub("[\t]+", "")
		
		if (ncode:sub(ncode:len()) ~= ";") then
			ncode = ncode .. ";"
		end
		
		return ncode
	end
	
	Class.keyWords= {
		["if"] = true, ["elseif"] = true, ["else"] = true, ["function"] = true, ["return"] = true, ["for"] = true, ["while"] = true, ["let"] = true, ["var"] = true
	}
	
	Class.builtins = {
		["print"] = true
	}
	
	local function vdump(info)
		if (Class.keyWords[info]) then
			return {
				["type"] = "keyword",
				["data"] = info
			}
		elseif (Class.builtins[info]) then
			return {
				["type"] = "builtin",
				["data"] = info
			}
		else
			return {
				["type"] = "iden",
				["data"] = info
			}
		end
	end
	
	local function ndump(data)
		return {
			["type"] = "number",
			["data"] = data
		}
	end
	
	local function sdump(data)
		return {
			["type"] = "string",
			["data"] = data
		}
	end
	
	local function cdump(data)
		return {
			["type"] = "comment",
			["data"] = data
		}
	end
	
	local function odump(data)
		return {
			["type"] = "operator",
			["data"] = data
		}
	end
	
	local function stdump(data)
		return {
			["type"] = "statement",
			["data"] = data
		}
	end
	
	local function tdump(data)
		return {
			["type"] = "compare",
			["data"] = data
		}
	end
	
	local function otdump(data)		
		return {
			["type"] = "other",
			["data"] = data
		}
	end
	
	local function adump(data)
		return {
			["type"] = "assign",
			["data"] = data
		}
	end
	
	local function bdump(data)
		return {
			["type"] = "boolean",
			["data"] = data
		}
	end
	
	local function codump(data)
		return {
			["type"] = "compareop",
			["data"] = data
		}
	end
	
	local function wsdump(data)
		return nil
	end
	
	Class.matchFuncs = {
		{"^true",	bdump},			   -- Boolean
		{"^false",	bdump},
		
		{IDEN,      vdump},        -- Indentifiers
		{WSPACE,    wsdump},           -- Whitespace
		{NUMBER3,   ndump},            -- Numbers
		{NUMBER4,   ndump},
		{NUMBER5,   ndump},
		{STRING1,   sdump},            -- Strings
		{STRING2,   sdump},
		{STRING3,   sdump},
		{STRING4,   sdump},
		{STRING5,   sdump},            -- Multiline-Strings
		{STRING6,   sdump},            -- Multiline-Strings
		
		{MCOMMENT1, cdump},            -- Multiline-Comments
		{MCOMMENT2, cdump},			
		{SCOMMENT1, cdump},            -- Singleline-Comments
		{SCOMMENT2, cdump},
		
		{"^==",     tdump},            -- Compare Operators
		{"^~=",     tdump},
		{"^<=",     tdump},
		{"^>=",     tdump},
		{"^>",		tdump},
		{"^<",		tdump},
		
		{"^+", 		odump},			   -- Operators
		{"^-",		odump},
		{"^*",		odump},
		{"^/",		odump},
		{"^^",		odump},
		{"^%%",		odump},
		
		{"^=",		adump},			   -- Assign
		
		{"^;",		stdump},		   -- Statement
		{"^\n",		stdump},
		
		{"^&&",		codump},		   -- Compare Operators
		{"^||",		codump},
		
		{"^.",		otdump}			   -- Other
	}
	
	Class.getTokens = function(self, code)
		-- [[ Variables ]] --
		local fcode = Class:format(code)
		local tokens = {}

		print("Code Reformatted: ", fcode)
		
		local index = 1
		local codeSize = string.len(fcode)
		local finished = false
		
		while (not finished) do
			local found = false
			
			for i = 1, #Class.matchFuncs do
				if (not found) then
					local match = Class.matchFuncs[i]
					
					local pattern, func = match[1], match[2]
										
					local findnum = { string.find(fcode, pattern, index) }
					local num1, num2 = findnum[1], findnum[2]
					
					if (num1) then						
						local data = string.sub(fcode, num1, num2)
						
						index = (num2 + 1)
						
						finished = (index > codeSize)
						found = true
						
						table.insert(tokens, func(data, findnum))
					end
				end
			end
		end
		
		return tokens
	end	
	
	return Class
end