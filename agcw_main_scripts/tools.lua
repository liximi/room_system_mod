function _G.GetRandomPointRound(pt, radius)
	local rad = math.random() * math.pi * 2
	local r = math.random() * radius
	local offset_x = math.cos(rad) * r
	local offset_z = -math.sin(rad) * r
	return pt + Vector3(offset_x, 0, offset_z)
end