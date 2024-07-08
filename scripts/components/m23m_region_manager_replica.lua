--用于从主机同步数据到客机，为客机提供数据查询接口
local RegionSystem = Class(function (self, inst)
	self.inst = inst

	self.net_vars = {
		size_data = net_ushortarray(self.inst.GUID, "region_sys.size_data", "region_sys.size_data"),
	}

	self.inst:ListenForEvent("region_sys.size_data", function() self:OnGeneration() end)

	_G.TheRegionMgr = self
end)


function RegionSystem:GetTileCoordsAtPoint(x, z)
	return math.floor(x) + math.ceil(self.width/2), math.floor(z) + math.ceil(self.height/2)
end

function RegionSystem:GetPointAtTileCoords(x, y)
	return x - math.ceil(self.width/2) + 0.5, y - math.ceil(self.height/2) + 0.5
end

function RegionSystem:GetRoomTypeById(room_id)
	
end

function RegionSystem:GetAllRegionsInRoom(room_id)

end

function RegionSystem:GetRegionId(x, z)

end

function RegionSystem:GetRoomId(x, z)
	
end


function RegionSystem:IsInRoom(x, z, room_type)
	local region_x, region_y = self:GetTileCoordsAtPoint(x, z)
	return self._base.IsInRoom(self, region_x, region_y, room_type)
end

function RegionSystem:GetRoomType(x, z)
	local region_x, region_y = self:GetTileCoordsAtPoint(x, z)
	return self._base.GetRoomType(self, region_x, region_y)
end

function RegionSystem:GetRoomData(room_type)
	if type(room_type) ~= "string" then
		return
	end
	for i, v in ipairs(ROOM_DEF) do
		if v.type == room_type then
			return v
		end
	end
end


function RegionSystem:OnGeneration()
	local w, h, sw, sh = self.net_vars.size_data:value()

end


return RegionSystem