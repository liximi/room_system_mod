require "prefabutil"

local assets = {}

local prefabs = {}

local brain = require "brains/agcw_soldierbrain"

local function KeepTargetFn(inst, target)
	if not inst.components.combat:CanTarget(target) or (target.sg ~= nil and target.sg:HasStateTag("transform"))
	and target:HasTag("player") then
		return false
	end
	return inst:IsNear(target, 30)
end

local function RetargetFn(inst)
    return FindEntity(inst, 30, function(target)
		if not inst.components.combat or not inst.components.combat:CanTarget(target) then
			return false
		end
		if target.sg == nil or not target.sg:HasStateTag("transform") then
			if target:HasTag("monster") then
				return true
			end
			if target.components.combat.target == inst then
				return true
			end
		end
		return false
	end)
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

    MakeTinyFlyingCharacterPhysics(inst, 1, .5)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBuild("wilson")
    inst.AnimState:SetBank("wilson")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")
    inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
    inst.AnimState:OverrideSymbol("fx_liquid", "wilson_fx", "fx_liquid")
    inst.AnimState:OverrideSymbol("shadow_hands", "shadow_hands", "shadow_hands")
    inst.AnimState:OverrideSymbol("snap_fx", "player_actions_fishing_ocean_new", "snap_fx")
    --Additional effects symbols for hit_darkness animation
    inst.AnimState:AddOverrideBuild("player_hit_darkness")
    inst.AnimState:AddOverrideBuild("player_receive_gift")
    inst.AnimState:AddOverrideBuild("player_actions_uniqueitem")
    inst.AnimState:AddOverrideBuild("player_wrap_bundle")
    inst.AnimState:AddOverrideBuild("player_lunge")
    inst.AnimState:AddOverrideBuild("player_attack_leap")
    inst.AnimState:AddOverrideBuild("player_superjump")
    inst.AnimState:AddOverrideBuild("player_multithrust")
    inst.AnimState:AddOverrideBuild("player_parryblock")
    inst.AnimState:AddOverrideBuild("player_emote_extra")
    inst.AnimState:AddOverrideBuild("player_boat_plank")
    inst.AnimState:AddOverrideBuild("player_boat_net")
    inst.AnimState:AddOverrideBuild("player_boat_sink")
    inst.AnimState:AddOverrideBuild("player_oar")
    inst.AnimState:AddOverrideBuild("player_actions_fishing_ocean_new")
    inst.AnimState:AddOverrideBuild("player_actions_farming")
    inst.AnimState:AddOverrideBuild("player_actions_cowbell")

    inst.DynamicShadow:SetSize(1.3, .6)

    inst.MiniMapEntity:SetIcon("wilson.png")
    inst.MiniMapEntity:SetPriority(10)
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    --Default to electrocute light values
    inst.Light:SetIntensity(.8)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.65)
    inst.Light:SetColour(255 / 255, 255 / 255, 236 / 255)
    inst.Light:Enable(false)

    inst.LightWatcher:SetLightThresh(.075)
    inst.LightWatcher:SetMinLightThresh(0.61) --for sanity.
    inst.LightWatcher:SetDarkThresh(.05)

    MakeCharacterPhysics(inst, 75, .5)

	inst:AddComponent("talker")
	inst.components.talker.offset = Vector3(0, -400, 0)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    ---------------------
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(true)
    inst.components.locomotor:SetTriggersCreep(false)

    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH)
    inst.components.health.nofadeout = true

    ------------------
    inst:AddComponent("hunger")
    inst.components.hunger:SetMax(60)
    inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE * 3)
    inst.components.hunger:SetKillRate(TUNING.WILSON_HEALTH / TUNING.STARVE_KILL_TIME)

    ------------------
    -- inst:AddComponent("sanity")
    -- inst.components.sanity:SetMax(TUNING.WILSON_SANITY)

    ------------------
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(20)
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat:SetAttackPeriod(1)
    inst.components.combat:SetRange(2)
	inst.components.combat:SetTarget(nil)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat:SetRetargetFunction(3, RetargetFn)


    ------------------
    MakeMediumBurnableCharacter(inst, "torso")
    inst.components.burnable:SetBurnTime(TUNING.PLAYER_BURN_TIME)
    inst.components.burnable.nocharring = true

    ------------------
    MakeLargeFreezableCharacter(inst, "torso")
    inst.components.freezable:SetResistance(4)
    inst.components.freezable:SetDefaultWearOffTime(TUNING.PLAYER_FREEZE_WEAR_OFF_TIME)

    ------------------
    inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:DoTaskInTime(0.5, function()
		if not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
			inst.components.inventory:Equip(SpawnPrefab("spear_wathgrithr"))
		end
	end)


	------------------
	inst:AddComponent("eater")

    ------------------
    -- inst:AddComponent("inspectable")

    ------------------
    -- inst:AddComponent("temperature")
    -- inst.components.temperature.usespawnlight = true

    ------------------
    -- inst:AddComponent("moisture")

    ------------------
    -- inst:AddComponent("rider")

	inst:SetStateGraph("agcw_SGsoldier")
    inst:SetBrain(brain)


    return inst
end

return Prefab("common_soldier", fn, assets, prefabs)
