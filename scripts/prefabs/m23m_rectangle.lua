local assets = {
	Asset("ANIM", "anim/m23m_rectangle.zip"),
}

local TEXTURE_SIZE = 6.83 * (128 / 1024)		--贴图对应地皮长度
local function SetSize(inst, w, h)	--x, z
	inst.AnimState:SetScale(w/TEXTURE_SIZE, h/TEXTURE_SIZE)
end

local function rectangle_fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.AnimState:SetBank("m23m_rectangle")
	inst.AnimState:SetBuild("m23m_rectangle")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetMultColour(1, 1, 1, 0.25)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)

	inst:AddTag("NOCLICK")
	inst:AddTag("NOBLOCK")
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.SetSize = SetSize

    return inst
end

return Prefab("m23m_rectangle", rectangle_fn, assets)