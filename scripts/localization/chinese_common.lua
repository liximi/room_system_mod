--Actions
STRINGS.ACTIONS.M23M_POPUP_SCREEN = "查看"
STRINGS.ACTIONS.M23M_SHOW_UI_OVERRIDE = {	--AddAction接口会覆盖STRINGS.ACTIONS.M23M_POPUP_SCREEN，因此需要人为重新覆盖回去
	GENERIC = "查看",
}

-- Rooms
STRINGS.M23M_ROOM_MUST = "房间中放置下列物品："
STRINGS.M23M_ROOMS = {
	NONE = {
		NAME = "杂间/户外",
		DESC = "平平无奇。"
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
}

--测试电源
STRINGS.NAMES.M23M_POWER_SOURCE = "测试电源"
STRINGS.RECIPE_DESC.M23M_POWER_SOURCE = ""
STRINGS.CHARACTERS.GENERIC.DESCRIBE.M23M_POWER_SOURCE = ""

--测试用电器
STRINGS.NAMES.M23M_POWER_APP = "测试用电器"
STRINGS.RECIPE_DESC.M23M_POWER_APP = ""
STRINGS.CHARACTERS.GENERIC.DESCRIBE.M23M_POWER_APP = ""