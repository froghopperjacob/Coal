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
		["if"] = true, ["elseif"] = true, ["else"] = true, ["function"] = true, ["return"] = true, 
		["for"] = true, ["while"] = true, ["class"] = true, ["extends"] = true, ["new"] = true, 
		["public"] = true, ["private"] = true, ["final"] = true, ["static"] = true,
		["null"] = true
	}
	
	Class.builtins = {

	}
	
	local function gen(ty, data, line)
		return {
			["type"] = ty,
			["data"] = data,
			["line"] = line
		}
	end
	
	local function vdump(data, line)
		if (Class.keyWords[data]) then
			return gen("keyword", data, line)
		elseif (Class.builtins[data]) then
			return gen("builtin", data, line)
		else
			return gen("iden", data, line)
		end
	end
	
	local function ndump(data, line)
		return gen("number", data, line)
	end
	
	local function sdump(data, line)
		return gen("string", data, line)
	end
	
	local function cdump(data, line)
		return nil -- Ignore comments
	end
	
	local function odump(data, line)
		return gen("operator", data, line)
	end
	
	local function stdump(data, line)
		return gen("statement", data, line)
	end
	
	local function tdump(data, line)
		return gen("compare", data, line)
	end
	
	local function otdump(data, line)		
		return gen("other", data, line)
	end
	
	local function adump(data, line)
		return gen("assign", data, line)
	end
	
	local function bdump(data, line)
		return gen("boolean", data, line)
	end
	
	local function codump(data, line)
		return gen("compareop", data, line)
	end
	
	local function wsdump(data, line)
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
				
		local index = 1
		local codeSize = string.len(fcode)
		local finished = false
		
		local line = 1
		
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
						
						if (data == "\n") then
							line = line + 1
						end
						
						table.insert(tokens, func(data, line))
					end
				end
			end
		end
		
		return tokens
	end	
	
	return Class
end
