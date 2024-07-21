GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

PrefabFiles = {
    "m23m_power_source",
    "m23m_power_app",
    "m23m_rectangle",
}

Assets = {
	Asset("ATLAS", "images/ui/fx_multselect.xml"),
	Asset("IMAGE", "images/ui/fx_multselect.tex"),
    Asset("ATLAS", "images/ui/nineslice1.xml"),
	Asset("IMAGE", "images/ui/nineslice1.tex"),
    Asset("ATLAS", "images/ui/room_icon.xml"),
	Asset("IMAGE", "images/ui/room_icon.tex"),
}


--[Localization]
local mod_loc_files = { 	--本mod的所有本地化文件名(不含语种前缀)
    "common",				--无法归类或没必要归类的文本
    "ui",             		--界面相关文本
}
local user_setting_lan = GetModConfigData("language")       --读取Mod语言自定义设置
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
modimport "m23m_main_scripts/constants"
--[Tools]
modimport "m23m_main_scripts/tools"
--[Containers]
modimport "m23m_main_scripts/containers"
--[RPCs]
modimport "m23m_main_scripts/rpcs"
--[Controller]
modimport "m23m_main_scripts/controller"
--[UI]
modimport "m23m_main_scripts/ui"
--[Actions]
modimport "m23m_main_scripts/actions"
--[StateGraphs]
modimport "m23m_main_scripts/stategraphs.lua"
--[Recipes]
modimport "m23m_main_scripts/recipes"

--[replica组件注册]
-- AddReplicableComponent("m23m_region_manager")

--注册地图图标
-- AddMinimapAtlas("images/minimap/xxx_mini.xml")


--添加注册房间的全局函数
require "m23m_room_def"


--------------------------------------------------
-- [本MOD针对游戏本体的修改内容]
--------------------------------------------------

local mod_files = {
    "mod_world_network",
    "mod_room_key_items",
    "mod_camera",
    "mod_cooktime",
    "mod_craft_multiple_products",
    "mod_bedroom_mechanic",
    "mod_upgradeable",
}

for _, file in ipairs(mod_files) do
    modimport("m23m_main_scripts/modified_mechanics/"..file)
end