local DEF = {
	{	--厨房
		type = "kitchen",
		name = STRINGS.M23M_ROOMS.KITCHEN.NAME,
		desc = STRINGS.M23M_ROOMS.KITCHEN.DESC,
		min_size = 32,
		max_size = 128,
		priority = 1,	--检查优先级, 必须为正数, 数字越大越优先, 0预留给了不属于任何类型的房间
		color = RGB(255, 255, 0),
		must_items = {
			{"cookpot", "portablecookpot"},		--普通锅或便携锅
			"icebox",		--冰箱
		},
	},
}




--------------------------------------------------

table.sort(DEF, function(a, b) return (a.priority or 1) > (b.priority or 1) end)
return DEF