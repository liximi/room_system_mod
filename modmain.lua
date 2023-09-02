GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

PrefabFiles = {
    "agcw_common_soldier",
	"agcw_farm_plow_machine",	--自动犁地机
}

Assets = {

}


--[Localization]
local mod_loc_files = { 	--本mod的所有本地化文件名(不含语种前缀)
    "common",				--无法归类或没必要归类的文本
    "ui",             		--界面相关文本
}
local user_setting_lan = GetModConfigData("Language")       --读取Mod语言自定义设置
local loc = require "languages/loc"
local lan = loc and loc.GetLanguage and loc.GetLanguage()   --读取玩家的客户端语言设置
local prefix = ""
if user_setting_lan == "CHINESE" then
    prefix = "chinese"
elseif user_setting_lan == "ENGLISH" then
    prefix = "english"
else
    if lan == LANGUAGE.CHINESE_S or lan == LANGUAGE.CHINESE_S_RAIL then
        prefix = "chinese"
    else
        prefix = "english"
    end
end
--[开发中强制中文]
prefix = "chinese"
for _, f_name in ipairs(mod_loc_files) do
    modimport("scripts/localization/"..prefix.."_"..f_name)	--加载所有本地化文件
end

--[Constants]
modimport "agcw_main_scripts/constants"

--[Tools]
modimport "agcw_main_scripts/tools"

--[Containers]
modimport "agcw_main_scripts/containers"

--[RPCs]
modimport "agcw_main_scripts/rpcs"

--[UI]
modimport "agcw_main_scripts/ui"

--[Recipes]
modimport "agcw_main_scripts/recipes"

--[replica组件注册]
AddReplicableComponent("agcw_enemy_spawner")



--注册地图图标
-- AddMinimapAtlas("images/minimap/well_mini.xml")


-------------------------
-- [针对本MOD的全局修改逻辑]
-------------------------

AddPrefabPostInit("forest_network", function(inst)
	if TheWorld.ismastersim then
		inst:AddComponent("agcw_enemy_spawner")
	end
end)