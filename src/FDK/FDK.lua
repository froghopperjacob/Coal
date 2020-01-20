--[[
	Main module for FDK package management.
	Licenced under the terms at: https://www.apache.org/licenses/LICENSE-2.0.txt
--]]
local BaseClass
local packages

-- This is here checking if its Lemur and where the packages/baseclass are
packages = script.Parent.Parent.Modules
BaseClass = require(script.Parent.BaseClass)

if (BaseClass == nil or packages == nil) then
	return error("[FDK - Structure] Failed to get BaseClass or packages")
end

local FDK = BaseClass:new("Flaming Development Toolkit")
local external = FDK:lock()

--[[
	Function: Checks the object against any types given. cleans code up
	Arguments: object - check against, ... - types
]]
local function checkTypes(object, ...)
	local typeOfObject = typeof(object)

	for _, check in pairs({ ... }) do
		if (typeOfObject == check) then
			return true
		end
	end

	return false
end

--[[
	Function: Creates a new class from the class name
	Arguments: self - FDK, importString - what is wanted to be imported
]]
FDK.import = function(self, ...)
	local strings, returns = { ... }, { }

	for index, importString in ipairs(strings) do
		if (not checkTypes(importString, "string") or string.len(importString) == 0) then
			return error("[FDK - PACKAGE MANAGER] Expected string, got " .. typeof(importString))
		end

		if (importString == "FDK") then
			returns[index] = external
		elseif (importString == "BaseClass" or importString == "Class") then
			returns[index] = BaseClass
		else
			local currentIndex, splitImportString, toRequire, found =
				packages, { }, nil, false

			for directory in string.gmatch(importString, "[%w-%*]+") do
				table.insert(splitImportString, directory)
			end

			for _, directory in pairs(splitImportString) do				
				if (directory == "*") then					
					local strs, str = { }, ""
					
					for i = 1, #splitImportString do
						local s = splitImportString[i]
						
						if (s ~= "*" and i ~= 1) then
							str = str .. "." .. s
						elseif (s ~= "*") then
							str = str .. s
						end
					end
										
					for _, file in pairs(currentIndex:GetChildren()) do						
						if (file.ClassName == "Folder") then
							table.insert(strs, str .. "." .. file.Name .. ".*")
						else
							table.insert(strs, str .. "." .. file.Name)
						end
					end
										
					local reT, send = { self:import(unpack(strs)) }, { }
										
					local function flatten(arr)
						for i, v in ipairs(arr) do
							if (typeof(v) == "table" and v["className"] == nil) then
								flatten(v)
							else
								send[i] = v
							end
						end
					end
					
					flatten(reT)
													
					returns[index] = send
										
					found = true
				else
					if (currentIndex:FindFirstChild(directory)) then
						currentIndex = currentIndex[directory]
					else
						return error("[FDK - PACKAGE MANAGER] Package " .. directory .. " does not exist.")
					end
				end
			end

			if (currentIndex:IsA("NumberValue") or currentIndex:IsA("IntValue")) then
				toRequire = currentIndex.Value
			elseif (currentIndex:IsA("ModuleScript")) then
				toRequire = currentIndex
			end

			if (toRequire == nil and found == false) then
				return error("[FDK - PACKAGE MANAGER] Package does not exist.")
			end

			if (found == false) then
				local class = require(toRequire)
	
				if (not checkTypes(class, "table", "function", "string")) then
					return error("[FDK - PACKAGE MANAGER] Expected function, table, or string got "
						.. typeof(class) .. " while initalizing class module.")
				end
					
				if (typeof(class) == "string") then
					returns[index] = class
				else
					self:wrapEnvironment(class)
	
					returns[index] = class()
				end
			end
		end
	end

	return unpack(returns)
end

--[[
	Function: Wraps the provided enviroment with useful FDK functions
	Arguments: self - FDK, value - table/function given for the enviroment
]]
FDK.wrapEnvironment = function(self, value)
	local useValue = (value == nil and self or value)

	local functionEnviorment

	if (checkTypes(useValue, "function")) then
		functionEnviorment = getfenv(useValue)
	elseif (checkTypes(useValue, "table")) then
		functionEnviorment = useValue
	end

	if (functionEnviorment == nil) then
		return error("[FDK - PACKAGE MANAGER] Expected function or table, got " .. typeof(functionEnviorment) .. ".")
	end

	functionEnviorment.import = function(...)
		return self:import(...)
	end

	functionEnviorment.BaseClass = BaseClass
	functionEnviorment.new = FDK.new

	--Legacy Support
	functionEnviorment.Class = BaseClass
	functionEnviorment.New = FDK.new
	--Legacy Support
end

--Legacy Support
FDK.WrapEnv = FDK.wrapEnvironment
FDK.Import = FDK.import
--Legacy Support

_G.FDK = external

return external