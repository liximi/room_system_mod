local AddRecipe2 = AddRecipe2

--自动开垦机
AddRecipe2("agcw_farm_plow_machine_item",
{Ingredient("cutstone", 1),},
TECH.MAGIC_TWO, {
	atlas = "images/inventoryimages/agcw_farm_plow_machine_item.xml",
	image = "agcw_farm_plow_machine_item.tex",
},
{CRAFTING_FILTERS.GARDENING.name})

--测试电源
AddRecipe2("agcw_power_source",
{Ingredient("cutstone", 1),},
TECH.SCIENCE_TWO, {
	atlas = "images/inventoryimages/agcw_power_source.xml",
	image = "agcw_power_source.tex",
	placer = "agcw_power_source_placer",
},
{CRAFTING_FILTERS.PROTOTYPERS.name})

--测试用电器
AddRecipe2("agcw_power_app",
{Ingredient("cutstone", 1),},
TECH.SCIENCE_TWO, {
	atlas = "images/inventoryimages/agcw_power_app.xml",
	image = "agcw_power_app.tex",
	placer = "agcw_power_app_placer",
},
{CRAFTING_FILTERS.PROTOTYPERS.name})