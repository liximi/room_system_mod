require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
--require "behaviours/choptree"
require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"
local BrainCommon = require "brains/braincommon"

local SEE_DIST = 30			--视野范围
local MAX_CHASE_TIME = 10	--最大追踪时间
local MAX_CHASE_DIST = 30	--最大追踪距离
local LEASH_MAX_DIST = 30		--约束距离
local LEASH_RETURN_DIST = 20	--返回约束距离
local MAX_WANDER_DIST = 30		--最大闲逛距离
local RUN_AWAY_DIST = 5			--躲避距离
local STOP_RUN_AWAY_DIST = 8	--停止躲避距离

local function FindFoodAction(inst)
    if inst.sg:HasStateTag("busy") then return end

    if inst.components.inventory ~= nil and inst.components.eater ~= nil then
        local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        if target ~= nil then
            return BufferedAction(inst, target, ACTIONS.EAT)
        end
    end

    local target = FindEntity(inst, SEE_DIST, function(item)
		return item:GetTimeAlive() >= 8
		and item.prefab ~= "mandrake"
		and item.components.edible ~= nil
		and item:IsOnPassablePoint()
		and inst.components.eater:CanEat(item)
	end)
    if target ~= nil then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end

    target = FindEntity(inst, SEE_DIST, function(item)
		return item.components.shelf ~= nil
		and item.components.shelf.itemonshelf ~= nil
		and item.components.shelf.cantakeitem
		and item.components.shelf.itemonshelf.components.edible ~= nil
		and item:IsOnPassablePoint()
		and inst.components.eater:CanEat(item.components.shelf.itemonshelf)
        end
    )
    if target ~= nil then
        return BufferedAction(inst, target, ACTIONS.TAKEITEM)
    end
end

local function GetHomePos(inst)
	return ThePlayer and ThePlayer:GetPosition()
end

--------------------------------------------------
-- Brain
--------------------------------------------------


local SoldierBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function SoldierBrain:OnStart()
    local root = PriorityNode({
		ChattyNode(self.inst, "PIG_TALK_FIGHT",
			WhileNode(function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end,
				"AttackMomentarily",
				ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)
			)
		),
		ChattyNode(self.inst, "PIG_TALK_FIGHT",
         	WhileNode(function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end,
				"Dodge",
             	RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
			)
		),
		WhileNode(function() return self.inst.components.hunger:GetPercent() < 0.5 end,
			"IsHungry",
			ChattyNode(self.inst, "PIG_TALK_FIND_MEAT",
				DoAction(self.inst, FindFoodAction)
			)
		),
		Leash(self.inst, GetHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),
		Wander(self.inst, GetHomePos, MAX_WANDER_DIST)
	}, 0.5)

    self.bt = BT(self.inst, root)
end


return SoldierBrain