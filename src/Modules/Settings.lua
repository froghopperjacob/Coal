local ret = {
	["RegisterLimit"] = 256,
	["FieldsPerPush"] = 50,
	["Version"] = "0.0.1",
	
	["Opcodes"] = {
		"MOVE",
		"LOADK",
		"LOADBOOL",
		"LOADNIL",
		"GETUPVAL",
		"GETGLOBAL",
		"GETTABLE",
		"SETGLOBAL",
		"SETUPVAL",
		"SETTABLE",
		"NEWARR",
		"NEWDICT",
		"ADD",
		"SUB",
		"MUL",
		"DIV",
		"MOD",
		"POW",
		"BAND",
		"BOR",
		"BXOR",
		"BFLIP",
		"BLEFTSHIFT",
		"BRIGHTSHIFT",
		"UNM",
		"NOT",
		"JMP",
		"EQ",
		"LT",
		"LE",
		"TEST",
		"TESTSET",
		"CALL",
		"TAILCALL",
		"RETURN",
		"FORPREP",
		"FORLOOP",
		"TFORLOOP",
		"SETLIST",
		"CLOSE",
		"CLOSURE"
	}
}

for index, value in pairs(ret["Opcodes"]) do
	print(value, index)
	
	ret["Opcodes"][value] = index
end

return ret