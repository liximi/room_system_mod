require "prefabutil"

local assets = {
    Asset("IMAGE", "images/inventoryimages/agcw_power_source.tex"),
    Asset("ATLAS", "images/inventoryimages/agcw_power_source.xml"),
}

local prefabs = {}

--------------------------------------------------
-- agcw_power_source
--------------------------------------------------

local function OnBuilt(inst)
    --inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_craft")
    -- inst.AnimState:PlayAnimation("drill_pre")
    -- inst.AnimState:PushAnimation("drill_loop", true)
    inst.components.agcw_power_source:Register()
end

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

local function OnTakeFuel(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
    if inst.components.agcw_power_source:IsTurnOn() and not inst.components.fueled.consuming then
        inst.components.fueled:StartConsuming()
        inst.components.agcw_power_source:RefreshOutput()
    end
end

local function OnFuelDepleted(inst)
    inst.components.agcw_power_source:RefreshOutput()
end

local function OnOutputChanged(inst, new_val, old_val)
    if new_val == 0 and old_val ~= 0 then
        inst.AnimState:PlayAnimation("drill_pre")
    elseif new_val ~= 0 and old_val == 0 then
        inst.AnimState:PushAnimation("drill_loop", true)
    end
end

local function OnTurnOn(inst, is_turnon)
    if is_turnon then
        if not inst.components.fueled:IsEmpty() then
            inst.components.fueled:StartConsuming()
        end
    else
        inst.components.fueled:StopConsuming()
    end
end

local function CalcCurrentOutput(inst)
    return inst.components.fueled:IsEmpty() and 0 or inst.components.agcw_power_source:GetStandardOutput()
end


--------------------------------------------------
-- Save & Load
--------------------------------------------------

local function OnSave(inst, data)

end

local function OnLoad(inst, data)
    inst.components.agcw_power_source:Register()
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
    inst.AnimState:SetMultColour(0.5, 1, 0.5, 1)

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

    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = 30         --最大燃料数量(默认燃烧速度1/s)
    inst.components.fueled.accepting = true     --是否可以添加燃料
    inst.components.fueled.bonusmult = 2        --每次添加燃料的时候奖励的倍数
    inst.components.fueled:SetTakeFuelFn(OnTakeFuel)        --补充燃料时调用
    inst.components.fueled:SetDepletedFn(OnFuelDepleted)    --燃料耗尽时调用

    inst:AddComponent("agcw_power_source")
    inst.components.agcw_power_source:SetStandardOutput(10)
    inst.components.agcw_power_source.on_turnon_fn = OnTurnOn
    inst.components.agcw_power_source.output_changed_fn = OnOutputChanged
    inst.components.agcw_power_source.calc_current_output_fn = CalcCurrentOutput
    inst.components.agcw_power_source:TurnOn()  --The 'TurnOn' should always be called after everything is ready

    MakeSnowCovered(inst)

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

RegisterInventoryItemAtlas("images/inventoryimages/agcw_power_source.xml", "agcw_power_source.tex")

return
Prefab("agcw_power_source", fn, assets, prefabs),
MakePlacer("agcw_power_source_placer", "farm_plow", "farm_plow", "idle_place", nil, true)