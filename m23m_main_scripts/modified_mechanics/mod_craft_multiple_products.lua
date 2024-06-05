local function GiveOrDropItem(inst, recipe, item, pt)
	if recipe.dropitem or not inst.components.inventory then
		local angle = (inst.Transform:GetRotation() + GetRandomMinMax(-65, 65)) * DEGREES
		local r = item:GetPhysicsRadius(0.5) + inst:GetPhysicsRadius(0.5) + 0.1
		item.Transform:SetPosition(pt.x + r * math.cos(angle), pt.y, pt.z - r * math.sin(angle))
		item.components.inventoryitem:OnDropped()
	else
	    inst.components.inventory:GiveItem(item, nil, pt)
	end
end

local function GetProbability(pt)
	local cur_room_type = TheRegionMgr:GetRoomType(pt.x, pt.z)
	return M23M.WORKSHOP_ROOMS[cur_room_type] or 0
end

local function builditem_eventhandler(inst, data)	--{ item = prod, recipe = recipe, skin = skin, prototyper = self.current_prototyper }
	if data.item and data.item.components.inventoryitem then
		local pt = inst:GetPosition()
		if math.random() < GetProbability(pt) then
			local addt_prod = SpawnPrefab(data.recipe.product)	--额外产出1个
			GiveOrDropItem(inst, data.recipe, addt_prod, pt)
		end
	end
end

AddComponentPostInit("builder", function(self)
	self.inst:ListenForEvent("builditem", builditem_eventhandler)
	local old_OnRemoveFromEntity = self.OnRemoveFromEntity
	function self:OnRemoveFromEntity()
		self.inst:RemoveEventCallback("builditem", builditem_eventhandler)
		if old_OnRemoveFromEntity then
			return old_OnRemoveFromEntity(self)
		end
	end
end)