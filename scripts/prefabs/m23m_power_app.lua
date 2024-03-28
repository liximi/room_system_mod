require "prefabutil"

local assets = {
    Asset("IMAGE", "images/inventoryimages/m23m_power_app.tex"),
    Asset("ATLAS", "images/inventoryimages/m23m_power_app.xml"),
}

local prefabs = {}

--------------------------------------------------
-- m23m_power_app
--------------------------------------------------

local function OnHammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.SoundEmitter:KillSound("firesuppressor_idle")
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function OnTurnOn(inst, is_turnon)
    if is_turnon then
        print("Turn ON: "..tostring(inst))
    else
        print("Turn OFF: "..tostring(inst))
    end
end

local function OnSave(inst, data)

end

local function OnLoad(inst, data)
	inst.components.m23m_power_appliance:Register()
    if data ~= nil then

    end
end

local function OnBuilt(inst)
    --inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_craft")
    inst.AnimState:PlayAnimation("drill_pre")
    inst.AnimState:PushAnimation("drill_loop", true)
    inst.components.m23m_power_appliance:Register()
end

--------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("farm_plow")
    inst.AnimState:SetBuild("farm_plow")
    inst.AnimState:OverrideSymbol("soil01", "farm_soil", "soil01")
	inst.AnimState:PlayAnimation("drill_pre")
    inst.AnimState:SetMultColour(1, 0.5, 1, 1)

    inst:AddTag("structure")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)

	inst:AddComponent("m23m_power_appliance")
	inst.components.m23m_power_appliance:SetStandardDemand(2)
	inst.components.m23m_power_appliance:SetOnEfficiencyChangedFn(function(new_val, old_val)
		print("test -", new_val, old_val)
        if new_val > 0 and old_val == 0 then
            inst.AnimState:PushAnimation("drill_loop", true)
        elseif new_val <= 0 and old_val > 0 then
            inst.AnimState:PlayAnimation("drill_pre")
        end
	end)
    inst.components.m23m_power_appliance.on_turnon_fn = OnTurnOn
    inst.components.m23m_power_appliance:TurnOn()   --The 'TurnOn' should always be called after everything is ready

    MakeSnowCovered(inst)

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

RegisterInventoryItemAtlas("images/inventoryimages/m23m_power_app.xml", "m23m_power_app.tex")

return
Prefab("m23m_power_app", fn, assets, prefabs),
MakePlacer("m23m_power_app_placer", "farm_plow", "farm_plow", "idle_place", nil, true)