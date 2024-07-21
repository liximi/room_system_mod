local function GetProbability(pt)
	local cur_room_type = TheRegionMgr:GetRoomTypeAtPoint(pt.x, pt.z)
	return M23M.WAREHOUSE_ROOMS[cur_room_type] or 0
end

AddComponentPostInit("upgradeable", function(self)
	local old_Upgrade = self.Upgrade
	function self:Upgrade(obj, upgrade_performer)
		local pt = self.inst:GetPosition()
		if obj and math.random() < GetProbability(pt) then
			local tool = SpawnPrefab(obj.prefab)
			local container = upgrade_performer and (upgrade_performer.components.inventory or upgrade_performer.components.container)
			if container then
				container:GiveItem(tool)
			else
				tool.Transform:SetPosition(pt:Get())
				if tool.components.inventoryitem ~= nil then
					tool.components.inventoryitem:InheritWorldWetnessAtTarget(self.inst)
					tool.components.inventoryitem:OnDropped(true)
				end
			end
		end
		return old_Upgrade(self, obj, upgrade_performer)
	end
end)