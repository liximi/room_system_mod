--Actions
STRINGS.ACTIONS.M23M_POPUP_SCREEN = "查看"
STRINGS.ACTIONS.M23M_SHOW_UI_OVERRIDE = {	--AddAction接口会覆盖STRINGS.ACTIONS.M23M_POPUP_SCREEN，因此需要人为重新覆盖回去
	GENERIC = "查看",
}

-- Rooms
STRINGS.M23M_ROOM_MUST = "房间中放置下列物品："
STRINGS.M23M_ROOMS = {
	NONE = {
		NAME = "杂间/非房间",
		DESC = "平平无奇。"
	},
	WAREHOUSE = {
		NAME = "仓库",
		DESC = function() return string.format("升级仓库中的箱子时，有 %.1f%% 概率不消耗升级工具。", M23M.WAREHOUSE_FREE_UPGRDE_PROBABILITY * 100) end
	},
	KITCHEN = {
		NAME = "厨房",
		DESC = function() return string.format("烧烤和烹饪时间缩短 %d%%。", M23M.KITCHEN_COOKTIME_MULT * -100) end
	},
	PRIMITIVE_KITCHEN = {
		NAME = "简陋厨房",
		DESC = function() return string.format("烧烤和烹饪时间缩短 %d%%。", M23M.PRIMITIVE_KITCHEN_COOKTIME_MULT * -100) end
	},
	ADVANCED_KITCHEN = {
		NAME = "专业厨房",
		DESC = function() return string.format("烧烤和烹饪时间缩短 %d%%。", M23M.ADVANCED_KITCHEN_COOKTIME_MULT * -100) end
	},
	LUXURIOUS_KITCHEN = {
		NAME = "豪华厨房",
		DESC = function() return string.format("烧烤和烹饪时间缩短 %d%%。", M23M.LUXURIOUS_KITCHEN_COOKTIME_MULT * -100) end
	},
	BASIC_WORKSHOP = {
		NAME = "基础工作间",
		DESC = "加速制作过程。"
	},
	WORKSHOP = {
		NAME = "工作间",
		DESC = function() return string.format("加速制作过程，在工作间内制作物品时有 %.1f%% 概率使产物数量+1。", M23M.WORKSHOP_MULT_CRAFTING_PROBABILITY * 100) end
	},
	CHEMICAL_LABORATORY = {
		NAME = "化学实验室",
		DESC = function() return string.format("加速制作过程，在化学实验室间内制作物品时有 %.2f%% 概率使产物数量+1。", M23M.CHEMICAL_LABORATORY_MULT_CRAFTING_PROBABILITY * 100) end
	},
	BEDROOM = {
		NAME = "卧室",
		DESC = function() return string.format("睡觉时的生命值和san值回复速度变为 %0.1f%%。", M23M.BEDROOM_EXTRAL_MULT * 100) end
	},
}

--测试电源
STRINGS.NAMES.M23M_POWER_SOURCE = "测试电源"
STRINGS.RECIPE_DESC.M23M_POWER_SOURCE = ""
STRINGS.CHARACTERS.GENERIC.DESCRIBE.M23M_POWER_SOURCE = ""

--测试用电器
STRINGS.NAMES.M23M_POWER_APP = "测试用电器"
STRINGS.RECIPE_DESC.M23M_POWER_APP = ""
STRINGS.CHARACTERS.GENERIC.DESCRIBE.M23M_POWER_APP = ""