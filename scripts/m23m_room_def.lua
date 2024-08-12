local INDOOR_TILES = {
	--XXX = true,	--XXX填WORLD_TILES的Key
	SHELLBEACH = true,	--贝壳海滩地皮
	MONKEY_GROUND = true,	--月亮码头海滩地皮
	BEARD_RUG = true,		--胡须地毯
	WOODFLOOR = true,	--木地板
	COTL_GOLD = true,	--黄金地板
	COTL_BRICK = true,	--砖地板
	CHECKER = true,		--棋盘地板
	CARPET = true,		--地毯地板
	CARPET2 = true,		--茂盛地毯
	MOSAIC_GREY = true,	--灰色马赛克地板
	MOSAIC_RED = true,	--红色马赛克地板
	MOSAIC_BLUE = true,	--蓝色马赛克地板
}


local DEF = {
	{	--仓库
		type = "warehouse",
		name = STRINGS.M23M_ROOMS.WAREHOUSE.NAME,
		desc = STRINGS.M23M_ROOMS.WAREHOUSE.DESC,
		min_size = 16,
		max_size = 192,
		priority = 1,	--检查优先级, 必须为正数, 数字越大越优先, 0预留给了不属于任何类型的房间
		icon_atlas = "images/crafting_menu_icons.xml",
		icon_image = "filter_containers.tex",
		color = RGB(100, 100, 0),
		must_items = {
			{"treasurechest", "dragonflychest"},		--箱子/龙鳞箱
		},
	},
	{	--简陋厨房
		type = "primitive_kitchen",
		name = STRINGS.M23M_ROOMS.PRIMITIVE_KITCHEN.NAME,
		desc = STRINGS.M23M_ROOMS.PRIMITIVE_KITCHEN.DESC,
		min_size = 16,
		max_size = 64,
		priority = 11,
		icon_atlas = "images/crafting_menu_icons.xml",
		icon_image = "filter_cooking.tex",
		color = RGB(255, 255, 0),
		must_items = {
			{"cookpot", "portablecookpot"},		--普通锅或便携锅
		},
	},
	{	--厨房
		type = "kitchen",
		name = STRINGS.M23M_ROOMS.KITCHEN.NAME,
		desc = STRINGS.M23M_ROOMS.KITCHEN.DESC,
		min_size = 16,
		max_size = 128,
		priority = 12,
		icon_atlas = "images/crafting_menu_icons.xml",
		icon_image = "filter_cooking.tex",
		color = RGB(255, 255, 0),
		available_tiles = INDOOR_TILES,
		must_items = {
			{"cookpot", "portablecookpot"},		--普通锅或便携锅
			"icebox",		--冰箱
		},
	},
	{	--专业厨房
		type = "advanced_kitchen",
		name = STRINGS.M23M_ROOMS.ADVANCED_KITCHEN.NAME,
		desc = STRINGS.M23M_ROOMS.ADVANCED_KITCHEN.DESC,
		min_size = 16,
		max_size = 128,
		priority = 13,
		icon_atlas = "images/crafting_menu_icons.xml",
		icon_image = "filter_cooking.tex",
		color = RGB(255, 255, 0),
		available_tiles = INDOOR_TILES,
		must_items = {
			"portablecookpot",	--便携锅
			"icebox",			--冰箱
			"portableblender",	--便携研磨器
			"portablespicer"	--便携香料站
		},
	},
	{	--豪华厨房
		type = "luxurious_kitchen",
		name = STRINGS.M23M_ROOMS.LUXURIOUS_KITCHEN.NAME,
		desc = STRINGS.M23M_ROOMS.LUXURIOUS_KITCHEN.DESC,
		min_size = 16,
		max_size = 128,
		priority = 14,
		icon_atlas = "images/crafting_menu_icons.xml",
		icon_image = "filter_cooking.tex",
		color = RGB(255, 255, 0),
		available_tiles = INDOOR_TILES,
		must_items = {
			"cookpot",			--普通锅
			"wintersfeastoven",	--砖砌烤炉
			"icebox",			--冰箱
		},
	},
	{	--基础工作间
		type = "basic_workshop",
		name = STRINGS.M23M_ROOMS.BASIC_WORKSHOP.NAME,
		desc = STRINGS.M23M_ROOMS.BASIC_WORKSHOP.DESC,
		min_size = 16,
		max_size = 96,
		priority = 21,
		icon_atlas = "images/crafting_menu_icons.xml",
		icon_image = "filter_science.tex",
		color = RGB(0, 255, 0),
		must_items = {
			{"researchlab", "researchlab2", "researchlab3", "researchlab4"},	--科学机器/炼金引擎/暗影操控器/灵子分解仪
		},
	},
	{	--工作间
		type = "workshop",
		name = STRINGS.M23M_ROOMS.WORKSHOP.NAME,
		desc = STRINGS.M23M_ROOMS.WORKSHOP.DESC,
		min_size = 16,
		max_size = 128,
		priority = 22,
		icon_atlas = "images/crafting_menu_icons.xml",
		icon_image = "filter_science.tex",
		color = RGB(0, 255, 0),
		available_tiles = INDOOR_TILES,
		must_items = {
			"researchlab2",		--炼金引擎
			"researchlab3",		--暗影操控器
			"cartographydesk",	--制图桌
		},
	},
	{	--化学实验室
		type = "chemical_laboratory",
		name = STRINGS.M23M_ROOMS.CHEMICAL_LABORATORY.NAME,
		desc = STRINGS.M23M_ROOMS.CHEMICAL_LABORATORY.DESC,
		min_size = 16,
		max_size = 128,
		priority = 23,
		icon_atlas = "images/crafting_menu_icons.xml",
		icon_image = "filter_science.tex",
		color = RGB(0, 255, 0),
		available_tiles = INDOOR_TILES,
		must_items = {
			"madscience_lab",	--疯狂科学家实验室
		},
	},
	{	--卧室
		type = "bedroom",
		name = STRINGS.M23M_ROOMS.BEDROOM.NAME,
		desc = STRINGS.M23M_ROOMS.BEDROOM.DESC,
		min_size = 16,
		max_size = 96,
		priority = 31,
		icon_atlas = "images/crafting_menu_icons.xml",
		icon_image = "filter_health.tex",
		color = RGB(0, 50, 255),
		available_tiles = INDOOR_TILES,
		must_items = {
			{"tent", "portabletent"},	--帐篷/宿营帐篷
		},
	},
}


for i, v in ipairs(DEF) do
	AddM23MRoom(v)
end


-- 仓库类型的房间需要注册以实现其效果
function _G.RegisterWarehouseRoom(room_id, free_upgrade_probability)
	_G.M23M.WAREHOUSE_ROOMS[room_id] = free_upgrade_probability
end

-- 厨房类型的房间需要注册以实现其效果
function _G.RegisterKitchenRoom(room_id, cooktime_mult)
	_G.M23M.KITCHEN_ROOMS[room_id] = cooktime_mult
end

-- 工作间类型的房间需要注册以实现其效果
function _G.RegisterWorkShopRoom(room_id, mult_crafting_probability)
	_G.M23M.WORKSHOP_ROOMS[room_id] = mult_crafting_probability
end

--卧室类型的房间需要注册以实现其效果
function _G.RegisterBedroom(room_id, extra_vital_indicators_tick_mult)
	_G.M23M.BEDROOMS[room_id] = extra_vital_indicators_tick_mult
end


RegisterWarehouseRoom("warehouse", M23M.WAREHOUSE_FREE_UPGRDE_PROBABILITY)

RegisterKitchenRoom("primitive_kitchen", M23M.PRIMITIVE_KITCHEN_COOKTIME_MULT)
RegisterKitchenRoom("kitchen", M23M.KITCHEN_COOKTIME_MULT)
RegisterKitchenRoom("advanced_kitchen", M23M.ADVANCED_KITCHEN_COOKTIME_MULT)
RegisterKitchenRoom("luxurious_kitchen", M23M.LUXURIOUS_KITCHEN_COOKTIME_MULT)

RegisterWorkShopRoom("basic_workshop", M23M.BASIC_WORKSHOP_MULT_CRAFTING_PROBABILITY)
RegisterWorkShopRoom("workshop", M23M.WORKSHOP_MULT_CRAFTING_PROBABILITY)
RegisterWorkShopRoom("chemical_laboratory", M23M.CHEMICAL_LABORATORY_MULT_CRAFTING_PROBABILITY)

RegisterBedroom("bedroom", M23M.BEDROOM_EXTRAL_MULT)