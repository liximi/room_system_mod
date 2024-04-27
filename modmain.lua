GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

PrefabFiles = {
    "m23m_power_source",
    "m23m_power_app",
    "test_box",
    "m23m_rectangle",
}

Assets = {
	Asset("ATLAS", "images/ui/fx_multselect.xml"),
	Asset("IMAGE", "images/ui/fx_multselect.tex"),
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

--[Recipes]
modimport "m23m_main_scripts/recipes"

--[replica组件注册]


--注册地图图标
-- AddMinimapAtlas("images/minimap/well_mini.xml")


--------------------------------------------------
-- [针对本MOD的全局修改逻辑]
--------------------------------------------------

global("TheRegionMgr")
AddPrefabPostInit("forest_network", function(inst)
	if TheWorld.ismastersim then
        inst.M23M_AreaMgr = inst:AddComponent("m23m_area_manager")
        inst.M23M_PowerMgr = inst:AddComponent("m23m_power_manager")
        inst.M23M_RegionMgr = inst:AddComponent("m23m_region_manager")
        local map_w, map_h = TheWorld.Map:GetSize()
        inst.M23M_RegionMgr:Generation(map_w * 4, map_h * 4, 34, 34)    --因为墙体每个只占1格，所以整个地图的尺寸必须是这么多，section尺寸过小会导致性能问题
        _G.TheRegionMgr = inst.M23M_RegionMgr
    else
        inst.M23M_AreaMgr_client = inst:AddComponent("m23m_area_manager_client")
	end
end)

local WALLS = {
    "wall_stone",
    "wall_stone_2",
    "wall_wood",
    "wall_hay",
    "wall_ruins",
    "wall_ruins_2",
    "wall_moonrock",
    "wall_dreadstone",
    "wall_scrap",
    "fence",
}

local function init_wall(inst)
    local pos = inst:GetPosition()
    local x, y = TheWorld.net.M23M_RegionMgr:GetRegionCoordsAtPoint(pos.x, pos.z)
    -- print("Add Wall", inst.prefab, pos, "tile coords:", x, y)
    TheWorld.net.M23M_RegionMgr:AddWalls({{x, y}})
end
local function on_remove_wall(inst)
    local pos = inst:GetPosition()
    local x, y = TheWorld.net.M23M_RegionMgr:GetRegionCoordsAtPoint(pos.x, pos.z)
    -- print("Remove Wall", inst.prefab, pos, "tile coords:", x, y)
    TheWorld.net.M23M_RegionMgr:RemoveWalls({{x, y}})
end
for _, wall in ipairs(WALLS) do
    AddPrefabPostInit(wall, function(inst)
        if TheWorld.ismastersim then
            inst:DoTaskInTime(0, init_wall)
            inst:ListenForEvent("onremove", on_remove_wall)
        end
    end)
end


local DOORS = {
    "fence_gate",
}

local function init_door(inst)
    local pos = inst:GetPosition()
    local x, y = TheWorld.net.M23M_RegionMgr:GetRegionCoordsAtPoint(pos.x, pos.z)
    -- print("Add Door", inst.prefab, pos, "tile coords:", x, y)
    TheWorld.net.M23M_RegionMgr:AddDoors({{x, y}})
end
local function on_remove_door(inst)
    local pos = inst:GetPosition()
    local x, y = TheWorld.net.M23M_RegionMgr:GetRegionCoordsAtPoint(pos.x, pos.z)
    -- print("Remove Door", inst.prefab, pos, "tile coords:", x, y)
    TheWorld.net.M23M_RegionMgr:RemoveDoors({{x, y}})
end
for _, door in ipairs(DOORS) do
    AddPrefabPostInit(door, function(inst)
        if TheWorld.ismastersim then
            inst:DoTaskInTime(0, init_door)
            inst:ListenForEvent("onremove", on_remove_door)
        end
    end)
end



-- [Camera]
-- 视角锁定(通过设置摄像机的lock_heading_target属性为true来锁定视角)
AddGlobalClassPostConstruct("cameras/followcamera", "FollowCamera", function(self)
    local old_SetHeadingTarget = self.SetHeadingTarget
    self.SetHeadingTarget = function(_self, r)
        if self:IsHeadingTargetLocked() then
            return old_SetHeadingTarget(_self, self.headingtarget)
        else
            return old_SetHeadingTarget(_self, r)
        end
    end
    self.LockHeadingTarget = function(_self, lock_name)
        self.headingtarget_locks = self.headingtarget_locks or {}
        self.headingtarget_locks[lock_name] = true
    end
    self.UnLockHeadingTarget = function(_self, lock_name)
        if type(self.headingtarget_locks) == "table" then
            self.headingtarget_locks[lock_name] = nil
        end
    end
    self.IsHeadingTargetLocked = function(_self)
        if type(self.headingtarget_locks) == "table" then
            for lock, _ in pairs(self.headingtarget_locks) do
                return true
            end
        end
        return false
    end

    self:SetHeadingTarget(0)

    self.ZoomIn = function(step)
        self.distancetarget = math.max(self.mindist, self.distancetarget - self.zoomstep)
        self.time_since_zoom = 0
    end

    self.ZoomOut = function(step)
        self.distancetarget = math.min(self.maxdist, self.distancetarget + self.zoomstep)
        self.time_since_zoom = 0
    end
end)