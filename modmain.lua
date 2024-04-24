GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

PrefabFiles = {
    "m23m_power_source",
    "m23m_power_app",
    "test_box",
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

AddPrefabPostInit("forest_network", function(inst)
	if TheWorld.ismastersim then
        inst.M23M_AreaMgr = inst:AddComponent("m23m_area_manager")
        inst.M23M_PowerMgr = inst:AddComponent("m23m_power_manager")
        inst.M23M_RegionMgr = inst:AddComponent("m23m_region_manager")
        local map_w, map_h = TheWorld.Map:GetSize()
        inst.M23M_RegionMgr:Generation(map_w * 2, map_h * 2, 16, 16)
    else
        inst.M23M_AreaMgr_client = inst:AddComponent("m23m_area_manager_client")
	end
end)

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