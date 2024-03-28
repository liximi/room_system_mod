local assets = {
    Asset("IMAGE", "images/inventoryimages/m23m_power_app.tex"),
    Asset("ATLAS", "images/inventoryimages/m23m_power_app.xml"),
	Asset("ANIM", "anim/test_box.zip"),
}

local prefabs = {}


local function OnHammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.SoundEmitter:KillSound("firesuppressor_idle")
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
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

    inst.AnimState:SetBank("test_box")
    inst.AnimState:SetBuild("test_box")
	inst.AnimState:PlayAnimation("idle")
	inst.Transform:SetEightFaced()

    inst:AddTag("structure")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)

    MakeSnowCovered(inst)

    return inst
end


STRINGS.NAMES.TEST_BOX = "测试立方体"
STRINGS.RECIPE_DESC.TEST_BOX = "测试立方体"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TEST_BOX = "测试立方体"

return
Prefab("test_box", fn, assets, prefabs),
MakePlacer("test_box_placer", "test_box", "test_box", "idle", nil, true, nil, nil, nil, "eight")