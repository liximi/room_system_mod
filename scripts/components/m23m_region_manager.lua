local REGION_SYS = require "region_system/region_system"
local ROOM_DEF = require "m23m_room_def"

local RegionSystem = Class(REGION_SYS, function (self, inst)
	self.inst = inst
	for _, data in ipairs(ROOM_DEF) do
		self:RegisterRoomType(data.type)
	end
end)


function RegionSystem:GetTileCoordsAtPoint(x, y)
	return math.floor(x) + math.ceil(self.width/2), math.floor(y) + math.ceil(self.height/2)
end

function RegionSystem:GetPointAtTileCoords(x, y)
	return x - math.ceil(self.width/2) + 0.5, y - math.ceil(self.height/2) + 0.5
end

function RegionSystem:OnUpdateKeyItemPosition(item_name, old_pos, new_pos)
	local old_x, old_y, new_x, new_y, old_region, new_region
	if old_pos then
		old_x, old_y = self:GetTileCoordsAtPoint(old_pos.x, old_pos.z)
		old_region = self:GetRegionId(old_x, old_y)
	end
	if new_pos then
		new_x, new_y = self:GetTileCoordsAtPoint(new_pos.x, new_pos.z)
		new_region = self:GetRegionId(new_x, new_y)
	end
	if old_region == new_region then
		return
	end

	local count
	if old_region ~= 0 then
		local items = self:GetDataInRegion(old_region, "items") or {}
		count = (items[item_name] or 0) - 1
		items[item_name] = count > 0 and count or nil
		self:SetDataToRegion(old_region, "items", items)
	end
	if new_region ~= 0 then
		local items = self:GetDataInRegion(new_region, "items") or {}
		count = (items[item_name] or 0) + 1
		items[item_name] = count
		self:SetDataToRegion(new_region, "items", items)
	end

	local old_room = self:GetRoomIdByRegion(old_region)
	local new_room = self:GetRoomIdByRegion(new_region)
	if old_room == new_room then
		return
	end

	self:UpdateRoomType({old_room or new_room, old_room and new_room or nil})
end

function RegionSystem:UpdateRoomType(rooms)		--roomID数组
	for _, room_id in ipairs(rooms) do
		if room_id ~= 0 then
			local success = false
			for _, data in ipairs(ROOM_DEF) do
				if self:CheckRoomSize(room_id, data.min_size, data.max_size) and self:CheckRoomMustItems(room_id, data.must_items) then
					self:SetRoomType(room_id, data.type)
					success = true
					break
				end
			end
			if not success then
				self:SetRoomType(room_id, "NONE")
			end
		end
	end
end

function RegionSystem:CheckRoomSize(room_id, min_size, max_size)
	local size = self:GetRoomSize(room_id)
	if min_size and min_size > size then
		return false
	end
	if max_size and max_size < size then
		return false
	end
	return true
end

function RegionSystem:CheckRoomMustItems(room_id, must_items)
	if not must_items then
		return true
	end
	local items_in_room  = {}
	local regions = self:GetAllRegionsInRoom(room_id)
	for _, region_id in ipairs(regions) do
		local region = self.regions[region_id]
		if region and region.items then
			for item, count in pairs(region.items) do
				items_in_room[item] = (items_in_room[item] or 0) + count
			end
		end
	end

	for _, items in ipairs(must_items) do
		if type(items) == "table" then
			local any_one = false
			for _, item in ipairs(items) do
				if items_in_room[item] then
					any_one = true
					break
				end
			end
			if not any_one then
				return false
			end
		else
			if not items_in_room[items] then
				return false
			end
		end
	end

	return true
end



return RegionSystem