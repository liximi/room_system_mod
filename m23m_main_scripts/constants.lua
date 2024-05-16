--全局常量
_G.M23M = {
	RPC_NAMESPACE = "MOD_23_MARCH",
	SELECT_UNIT_BUTTON = MOUSEBUTTON_LEFT,		--选择地块的鼠标按键
	DISELECT_TILE_BUTTON = MOUSEBUTTON_RIGHT,	--取消选择地块的鼠标按键

	AREA_TYPE = {								--区域类型
		NONE = 0,
		CHOP = 1,
		MINE = 2,
	},

	KITCHEN_COOKTIME_MULT = GetModConfigData("kitchen_cooktime_mult"),
	PRIMITIVE_KITCHEN_COOKTIME_MULT = GetModConfigData("kitchen_cooktime_mult") * 0.25,
	ADVANCED_KITCHEN_COOKTIME_MULT = GetModConfigData("kitchen_cooktime_mult") * 1.5,
	LUXURIOUS_KITCHEN_COOKTIME_MULT = GetModConfigData("kitchen_cooktime_mult") * 1.2,
}