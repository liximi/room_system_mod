local DEF = {
	{	--简陋厨房
		type = "primitive_kitchen",
		name = STRINGS.M23M_ROOMS.PRIMITIVE_KITCHEN.NAME,
		desc = STRINGS.M23M_ROOMS.PRIMITIVE_KITCHEN.DESC,
		min_size = 16,
		max_size = 64,
		priority = 1,	--检查优先级, 必须为正数, 数字越大越优先, 0预留给了不属于任何类型的房间
		color = RGB(255, 255, 0),
		must_items = {
			{"cookpot", "portablecookpot"},		--普通锅或便携锅
		},
	},
	{	--厨房
		type = "kitchen",
		name = STRINGS.M23M_ROOMS.KITCHEN.NAME,
		desc = STRINGS.M23M_ROOMS.KITCHEN.DESC,
		min_size = 32,
		max_size = 128,
		priority = 2,	--检查优先级, 必须为正数, 数字越大越优先, 0预留给了不属于任何类型的房间
		color = RGB(255, 255, 0),
		must_items = {
			{"cookpot", "portablecookpot"},		--普通锅或便携锅
			"icebox",		--冰箱
		},
	},
	{	--专业厨房
	type = "advanced_kitchen",
	name = STRINGS.M23M_ROOMS.ADVANCED_KITCHEN.NAME,
	desc = STRINGS.M23M_ROOMS.ADVANCED_KITCHEN.DESC,
	min_size = 32,
	max_size = 128,
	priority = 2,	--检查优先级, 必须为正数, 数字越大越优先, 0预留给了不属于任何类型的房间
	color = RGB(255, 255, 0),
	must_items = {
		"portablecookpot",	--便携锅
		"icebox",			--冰箱
		"portableblender",	--便携研磨器
		"portablespicer"	--便携香料站
	},
},
}




--------------------------------------------------

table.sort(DEF, function(a, b) return (a.priority or 1) > (b.priority or 1) end)
return DEF