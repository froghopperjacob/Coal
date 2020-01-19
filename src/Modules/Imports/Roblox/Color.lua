return function()
	local Class = BaseClass:new("Color")
	local RGB, HSV, HSL = BaseClass:new("RGBColor"), BaseClass:new("HSVColor"), BaseClass:new("HSLColor")
	
	local function check(args, checks, num)
		if (typeof(num) == "table") then
			local f = false
			
			for i = 1, #num do
				if (num[i] == #args) then
					f = true
				end
			end
			
			if (not f) then
				return error("Incorrect number of arguments provided. got " .. #args)
			end
		else
			if (#args < num) then
				return error("Incorrect number of arguments provided. Expected " .. num .. " got " .. #args)
			end
		end

		
		for i = 1, #args do
			local arg, check = args[i], checks[i]
			
			if (typeof(check) == "table") then
				local f = false
				
				for n = 1, #check do
					if (typeof(arg) == check[n]) then
						f = true
					end
				end
				
				if (not f) then
					return error("Incorrect argument type given at " .. i .. ". got " .. typeof(arg))
				end
			else
				if (typeof(arg) ~= check) then
					return error("Incorrect argument type given at " .. i .. ". Expected " .. check .. " got " .. typeof(arg))
				end
			end
		end
		
		return true
	end
	
	Class.Color = function(self, ...)
		local args = { ... }
				
		if (check(args, { "number", { "string", "number" }, "number", "number", "number" }, { 2, 4, 5 })) then			
			if (args[1] == 2) then
				return HSV(args[2], args[3], args[4], args[5])
			elseif (args[1] == 3) then
				return HSL(args[2], args[3], args[4], args[5])
			elseif (args[1] == 4) then				
				local cl = BrickColor.new(args[2]).Color
				
				return RGB(cl.r * 255, cl.g * 255, cl.b * 255)
			else				
				return RGB(args[2], args[3], args[4], args[5])
			end
		end
	end
	
	RGB.RGBColor = function(self, r, g, b, a)
		self.r = r
		self.g = g
		self.b = b
		self.a = a or 0
				
		return self
	end
	
	RGB.toColor = function(self)
		return Color3.fromRGB(self.r, self.g, self.b)
	end
	
	RGB.toHSV = function(self)
		local r, g, b, a = self.r, self.g, self.b, self.a
		local sr, sg, sb = r / 255, g / 255, b / 255
		local max, min = math.max(sr, sg, sb), math.min(sr, sg, sb)
		local h, s, v = nil, nil, max
		
		local dis = max - min
		
		if (max == 0) then
			s = 0
		else
			s = dis / max
		end
		
		if (max == min) then
			h = 0
		else
			if (max == sr) then
				h = (sg - sb) / dis
				
				if (sg < sb) then
					h = h + 6
				end
			elseif (max == sg) then
				h = (sb - sr) / dis + 2
			elseif (max == sb) then
				h = (sr - sg) / dis + 4
			end
			
			h = h / 6
		end
		
		return HSV(h, s, v, a)
	end
	
	RGB.toHSL = function(self)
		local r, g, b, a = self.r, self.g, self.b, self.a
		local max, min = math.max(r, g, b), math.min(r, g, b)
		local h, s, l = nil, nil, (max + min) / 2
		
		if (max == min) then
			h, s = 0, 0
		else
			local dis, s = max - min, nil
			
			if (l > 0.5) then
				s = dis / (2 - max - min)
			else
				s = dis / (max + min)
			end
			
			if (max == r) then
				h = (g - b) / dis
				
				if (g < b) then
					h = h + 6
				end
			elseif (max == g) then
				h = (b - r) / dis + 2
			elseif (max == b) then
				h = (r - g) / dis + 4
			end
			
			h = h / 6
		end
		
		return HSL(h, s, l, a)
	end
	
	HSV.HSVColor = function(self, h, s, v, a)
		self.h = h
		self.s = s
		self.v = v
		self.a = a or 0
		
		return self
	end
	
	HSV.toColor = function(self)
		return Color3.fromHSV(self.h, self.s, self.v)
	end
	
	HSV.toRGB = function(self)
		local h, s, v, a = self.h, self.s, self.v, self.a
		local r, g, b
		
		local i = math.floor(h + 6)
		local f, p = h * 6 - i, v * (1 - s)
		local q, t = v * (1 - f * s), v * (1 - (1 - f) * s)
		
		i = i % 6
		
		if (i == 0) then 
			r, g, b = v, t, p
		elseif (i == 1) then 
			r, g, b = q, v, p
		elseif (i == 2) then 
			r, g, b = p, v, t
		elseif (i == 3) then 
			r, g, b = p, q, v
		elseif (i == 4) then 
			r, g, b = t, p, v
		elseif (i == 5) then 
			r, g, b = v, p, q
		end
		
		return RGB(r, g, b, a)
	end
	
	HSV.toHSL = function(self)
		return self:toRGB():toHSL() -- im lazy okay
	end
	
	HSL.HSLColor = function(self, h, s, l, a)
		self.h = h
		self.s = s
		self.l = l
		self.a = a
		
		return self
	end
	
	HSL.toColor = function(self)
		return self:toRGB():toColor()
	end
	
	HSL.toRGB = function(self)
		local h, s, l, a = self.h, self.s, self.l, self.a
		local r, g, b
		
		if (s == 0) then
			r, g, b = 1, 1, 1
		else
			local function hue2rgb(p, q, t)
				if (t < 0) then
					t = t + 1
				end
				
				if (t > 1) then
					t = t - 1
				end
				
				if (t < 1/6) then
					return p + (q - p) * 6 * t
				end
				
				if (t < 1/2) then
					return q
				end
				
				if (t < 2/3) then
					return p + (q - p) * (2/3 - t) * 6
				end
				
				return p
			end
			
			local q
			
			if (l < 0.5) then
				q = l * (1 + s)
			else
				q = l + s - l * s
			end
			
			local p = 2 * l - q
			
			r = hue2rgb(p, q, h + 1/3)
			g = hue2rgb(p, q, h)
			b = hue2rgb(p, q, h + 1/3)
		end
		
		return RGB(r * 255, g * 255, b * 255, a)
	end
	
	HSL.toHSV = function(self)
		return self:toRGB():toHSV() -- im lazy okay
	end
	
	return Class
end