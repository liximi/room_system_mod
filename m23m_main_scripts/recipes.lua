local AddRecipe2 = AddRecipe2

--测试电源
AddRecipe2("m23m_power_source",
{Ingredient("cutstone", 1),},
TECH.SCIENCE_TWO, {
	atlas = "images/inventoryimages/m23m_power_source.xml",
	image = "m23m_power_source.tex",
	placer = "m23m_power_source_placer",
},
{CRAFTING_FILTERS.PROTOTYPERS.name})

--测试用电器
AddRecipe2("m23m_power_app",
{Ingredient("cutstone", 1),},
TECH.SCIENCE_TWO, {
	atlas = "images/inventoryimages/m23m_power_app.xml",
	image = "m23m_power_app.tex",
	placer = "m23m_power_app_placer",
},
{CRAFTING_FILTERS.PROTOTYPERS.name})

--测试立方体
AddRecipe2("test_box",
{Ingredient("cutstone", 1),},
TECH.SCIENCE_TWO, {
	atlas = "images/inventoryimages/m23m_power_app.xml",
	image = "m23m_power_app.tex",
	placer = "test_box_placer",
	min_spacing = 1,
},
{CRAFTING_FILTERS.PROTOTYPERS.name})