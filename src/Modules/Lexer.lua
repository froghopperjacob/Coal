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

local keyWords= {
	["if"] = true, ["elseif"] = true, ["else"] = true, ["function"] = true, ["return"] = true, 
	["for"] = true, ["while"] = true, ["class"] = true, ["extends"] = true, ["new"] = true, 
	["public"] = true, ["private"] = true, ["final"] = true, ["static"] = true,
	["null"] = true, ["local"] = true -- temp
}

local function format(code)
	local ncode = code:gsub("[\t]+", "")
	
	if (ncode:sub(ncode:len()) ~= ";") then
		ncode = ncode .. ";"
	end
	
	return ncode
end


local function vdump(data, line)
	if (keyWords[data]) then
		return {
			["type"] = "keyword",
			["data"] = data,
			["line"] = line
		}	
	else
		return {
			["type"] = "iden",
			["data"] = data,
			["line"] = line
		}
	end
end

local function ndump(data, line)
	return {
		["type"] = "number",
		["data"] = data,
		["line"] = line
	}
end

local function sdump(data, line)
	return {
		["type"] = "string",
		["data"] = data,
		["line"] = line
	}
end

local function odump(data, line)
	return {
		["type"] = "operator",
		["data"] = data,
		["line"] = line
	}
end

local function stdump(data, line)
	return {
		["type"] = "statement",
		["data"] = data,
		["line"] = line
	}
end

local function tdump(data, line)
	return {
		["type"] = "compare",
		["data"] = data,
		["line"] = line
	}
end

local function otdump(data, line)
	return {
		["type"] = "other",
		["data"] = data,
		["line"] = line
	}	
end

local function adump(data, line)
	return {
		["type"] = "assign",
		["data"] = data,
		["line"] = line
	}
end

local function bdump(data, line)
	return {
		["type"] = "boolean",
		["data"] = data,
		["line"] = line
	}
end

local function codump(data, line)
	return {
		["type"] = "compareop",
		["data"] = data,
		["line"] = line
	}
end

local function nodump(data, line)
	return {
		["type"] = "notop",
		["data"] = data,
		["line"] = line
	}
end

local function wsdump(data, line)
	return nil -- Whitespace is ignored
end

local function cdump(data, line)
	return nil -- Ignore comments
end

local matchFuncs = {
	{"^true",	bdump},			   -- Boolean
	{"^false",	bdump},
	
	{IDEN,      vdump},        	   -- Indentifiers
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

	{"^+", 		odump},			   -- Operators
	{"^-",		odump},
	{"^*%*",	odump},
	{"^*",		odump},
	{"^/",		odump},
	{"^%%",		odump},
	{"^&",		odump},
	{"^|",		odump},
	{"^^",		odump},
	{"^~",		odump},
	{"^<<",		odump},
	{"^>>",		odump},

	{"^==",     tdump},            -- Compare Operators
	{"^!=",     tdump},
	{"^<=",     tdump},
	{"^>=",     tdump},
	{"^>",		tdump},
	{"^<",		tdump},
	
	{"^&&",		codump},		   -- Compare Operators
	{"^||",		codump},
	
	{"^=",		adump},			   -- Assign
	
	{"^;",		stdump},		   -- Statement
	{"^\n",		stdump},
	
	{"^!",		nodump},		   -- Not
	
	{"^.",		otdump}			   -- Other
}

return function(code)
	-- [[ Variables ]] --
	local fcode = format(code)
	local tokens = {}
						
	local index = 1
	local codeSize = string.len(fcode)
	local finished = false
	
	local line = 1
	
	while (not finished) do		
		local found = false
		
		for _, match in pairs(matchFuncs) do
			if (not found) then				
				local pattern, func = match[1], match[2]
									
				local num1, num2 = string.find(fcode, pattern, index)
				
				if (num1) then
					local data = string.sub(fcode, num1, num2)
					
					index = (num2 + 1)
															
					finished = (index > codeSize)
					found = true
					
					if (data == "\n") then
						line = line + 1
					end
					
					tokens[#tokens + 1] = func(data, line)
				end
			end
		end
	end
	
	return tokens
end