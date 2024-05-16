local cooking = require("cooking")

-- [stewer]

local function stewer_AddCookTimeMultiplier(self, name, mult, condition)	--condition是函数，接受当前的实例作为参数，返回true/false
    if not (type(name) == "string" and type(mult) == "number") then
        return false
    end
    self.extra_cooktime_multipliers[name] = {cond = condition, val = mult}
    return true
end

local function stewer_RemoveCookTimeMultiplier(self, name)
    if type(name) ~= "string" then
        return
    end
    self.extra_cooktime_multipliers[name] = nil
end

local function stewer_CalcExtraCookTimeMult(self)
	local extra_cooktimemult = 1
	for name, data in pairs(self.extra_cooktime_multipliers) do
		if not data.cond or data.cond(self.inst) then
			extra_cooktimemult = extra_cooktimemult + data.val
		end
	end
	return math.max(0, extra_cooktimemult)
end


-- 从stewer组件中复制出来的，只修改了StartCooking函数里计算cooktime的算法
local function dospoil(inst, self)
    self.task = nil
    self.targettime = nil
    self.spoiltime = nil

    if self.onspoil ~= nil then
        self.onspoil(inst)
    end
end
local function dostew(inst, self)
    self.task = nil
    self.targettime = nil
    self.spoiltime = nil

    if self.ondonecooking ~= nil then
        self.ondonecooking(inst)
    end

    if self.product == self.spoiledproduct then
        if self.onspoil ~= nil then
            self.onspoil(inst)
        end
    elseif self.product ~= nil then
        local recipe = cooking.GetRecipe(inst.prefab, self.product)
        local prep_perishtime = (recipe ~= nil and (recipe.cookpot_perishtime or recipe.perishtime)) or 0
        if prep_perishtime > 0 then
			local prod_spoil = self.product_spoilage or 1
			self.spoiltime = prep_perishtime * prod_spoil
			self.targettime =  GetTime() + self.spoiltime
			self.task = self.inst:DoTaskInTime(self.spoiltime, dospoil, self)
		end
    end

    self.done = true
end
local function stewer_StartCooking(self, doer)
    if self.targettime == nil and self.inst.components.container ~= nil then
		self.chef_id = (doer ~= nil and doer.player_classified ~= nil) and doer.userid
		self.ingredient_prefabs = {}

        self.done = nil
        self.spoiltime = nil

        if self.onstartcooking ~= nil then
            self.onstartcooking(self.inst)
        end

		for k, v in pairs (self.inst.components.container.slots) do
			table.insert(self.ingredient_prefabs, v.prefab)
		end

        local cooktime = 1
        self.product, cooktime = cooking.CalculateRecipe(self.inst.prefab, self.ingredient_prefabs)
        local productperishtime = cooking.GetRecipe(self.inst.prefab, self.product).perishtime or 0

        if productperishtime > 0 then
			local spoilage_total = 0
			local spoilage_n = 0
			for k, v in pairs (self.inst.components.container.slots) do
				if v.components.perishable ~= nil then
					spoilage_n = spoilage_n + 1
					spoilage_total = spoilage_total + v.components.perishable:GetPercent()
				end
			end
            self.product_spoilage =
                (spoilage_n <= 0 and 1) or
                (self.keepspoilage and spoilage_total / spoilage_n) or
                1 - (1 - spoilage_total / spoilage_n) * .5
		else
			self.product_spoilage = nil
		end

        cooktime = TUNING.BASE_COOK_TIME * cooktime * self.cooktimemult * self:CalcExtraCookTimeMult()
        self.targettime = GetTime() + cooktime
        if self.task ~= nil then
            self.task:Cancel()
        end
        self.task = self.inst:DoTaskInTime(cooktime, dostew, self)

        self.inst.components.container:Close()
        self.inst.components.container:DestroyContents()
        self.inst.components.container.canbeopened = false
    end
end


AddComponentPostInit("stewer", function(self)
    self.extra_cooktime_multipliers = {}
    self.AddCookTimeMultiplier = stewer_AddCookTimeMultiplier
    self.RemoveCookTimeMultiplier = stewer_RemoveCookTimeMultiplier
	self.CalcExtraCookTimeMult = stewer_CalcExtraCookTimeMult
	self.StartCooking = stewer_StartCooking
end)


local cookpots = {
    "cookpot",
    "portablecookpot",
    "archive_cookpot",
}

local function kitchen_mult_cond(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheRegionMgr:IsInRoom(x, z, "kitchen")
end

local function primitive_kitchen_mult_cond(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheRegionMgr:IsInRoom(x, z, "primitive_kitchen")
end

local function adv_kitchen_mult_cond(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheRegionMgr:IsInRoom(x, z, "advanced_kitchen")
end

local function luxu_kitchen_mult_cond(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheRegionMgr:IsInRoom(x, z, "luxurious_itchen")
end

local function cookpot_postinit(inst)
    if not inst.components.stewer then
        return
    end
    inst.components.stewer:AddCookTimeMultiplier("M23M_KITCHEN_MULT", M23M.KITCHEN_COOKTIME_MULT, kitchen_mult_cond)
    inst.components.stewer:AddCookTimeMultiplier("M23M_PRIMITIVE_KITCHEN_MULT", M23M.PRIMITIVE_KITCHEN_COOKTIME_MULT, primitive_kitchen_mult_cond)
    inst.components.stewer:AddCookTimeMultiplier("M23M_ADVANCED_KITCHEN_MULT", M23M.ADVANCED_KITCHEN_COOKTIME_MULT, adv_kitchen_mult_cond)
    inst.components.stewer:AddCookTimeMultiplier("M23M_LUXURIOUS_KITCHEN_MULT", M23M.LUXURIOUS_KITCHEN_COOKTIME_MULT, luxu_kitchen_mult_cond)
end

for _, pref in ipairs(cookpots) do
	AddPrefabPostInit(pref, cookpot_postinit)
end