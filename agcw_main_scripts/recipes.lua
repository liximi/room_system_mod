local AddRecipe2 = AddRecipe2

--自动开垦机
AddRecipe2("agcw_farm_plow_machine_item",
{Ingredient("cutstone", 1),},
TECH.MAGIC_TWO, {
	atlas = "images/inventoryimages/agcw_farm_plow_machine_item.xml",
	image = "agcw_farm_plow_machine_item.tex",
},
{CRAFTING_FILTERS.GARDENING.name})