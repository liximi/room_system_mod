local REGION_SYS = require "region_system/region_system"
local json = require "json"


--------------------------------------------------
-- RegionSystem
--------------------------------------------------


local RegionSystem = Class(REGION_SYS, function (self, inst)
	self.inst = inst
	for _, data in ipairs(M23M.ROOM_DEFS) do
		self:RegisterRoomType(data.type)
	end

	self.inst:ListenForEvent("onterraform", function(world, data)
		--data: {x:tilemap的坐标, y:tilemap的坐标, original_tile:int, tile:int}
		local pt_x, pt_z = _G.GetTileCenterPointByTileCoords(data.x, data.y)
		self:OnTerraform(pt_x, pt_z)
	end, TheWorld)

	self.inst:ListenForEvent("ms_playerjoined", function(world, player)
		if TheNet:IsDedicated() or (TheWorld.ismastersim and player ~= ThePlayer) then
			SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_init_size_data, player.userid, self.width, self.height, self.section_width, self.section_height)
			SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_init_rooms_data, player.userid, self:EncodeRooms())
			self:SendMapStreamToClient(player.userid)
		end
	end, TheWorld)

	_G.TheRegionMgr = self
end)


function RegionSystem:GetTileCoordsAtPoint(x, z)
	return math.floor(x) + math.ceil(self.width/2), math.floor(z) + math.ceil(self.height/2)
end

function RegionSystem:GetPointAtTileCoords(x, y)
	return x - math.ceil(self.width/2) + 0.5, y - math.ceil(self.height/2) + 0.5
end

function RegionSystem:GetRoomTypeAtPoint(x, z)
	local region_x, region_y = self:GetTileCoordsAtPoint(x, z)
	return self:GetRoomType(region_x, region_y)
end

function RegionSystem:GetRoomData(room_type)
	if type(room_type) ~= "string" then
		return
	end
	for i, v in ipairs(M23M.ROOM_DEFS) do
		if v.type == room_type then
			return v
		end
	end
end

function RegionSystem:ChangeItemRegion(item_name, old_region, new_region, refreash_room)
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

	if not refreash_room then
		return
	end

	local old_room = self:GetRoomIdByRegion(old_region)
	local new_room = self:GetRoomIdByRegion(new_region)
	if old_room == new_room then
		return
	end

	local changes = {}
	if old_room then
		local old_type = self.rooms[old_room] and self.rooms[old_room].type or 1
		self:RefreashRoomType(old_room)
		local new_type = self.rooms[old_room] and self.rooms[old_room].type or 1
		if new_type ~= old_type then
			table.insert(changes, {old_room, new_type})
		end
	end
	if new_room then
		local old_type = self.rooms[new_room] and self.rooms[new_room].type or 1
		self:RefreashRoomType(new_room)
		local new_type = self.rooms[new_room] and self.rooms[new_room].type or 1
		if new_type ~= old_type then
			table.insert(changes, {new_room, new_type})
		end
	end

	if not IsEmptyTable(changes) then
		local userids = {}
		for _, player in ipairs(AllPlayers) do
			if TheNet:IsDedicated() or (TheWorld.ismastersim and player ~= ThePlayer) then
				table.insert(userids, player.userid)
			end
		end
		SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_update_room_type, userids, json.encode(changes))
	end
end

function RegionSystem:OnChangeTileRegion(x, y, old_region, new_region, refreash_room)	--这个函数会被父类调用
	local world_x, world_z = self:GetPointAtTileCoords(x, y)
	for _, ent in ipairs(TheSim:FindEntities(world_x, 0, world_z, 0.75, {"m23m_room_key_item"})) do		-- 0.75 > sqrt(2)/2
		if ent.components.m23m_room_key_item then
			local ent_x, ent_y, ent_z = ent.Transform:GetWorldPosition()
			local region_x, region_y = self:GetTileCoordsAtPoint(ent_x, ent_z)
			if region_x == x and region_y == y then
				self:ChangeItemRegion(ent.prefab, old_region, new_region, refreash_room)
			end
		end
	end
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

	self:ChangeItemRegion(item_name, old_region, new_region, true)
end

function RegionSystem:OnTerraform(x, z)
	local rooms = {}
	local changes = {}
	for _z = z - 2, z + 1 do
		for _x = x - 2, x + 1 do
			local region_x, region_y = self:GetTileCoordsAtPoint(_x, _z)
			local room_id = self:GetRoomId(region_x, region_y)
			if not rooms[room_id] then
				rooms[room_id] = true
				local old_type = self.rooms[room_id] and self.rooms[room_id].type or 1
				self:RefreashRoomType(room_id)
				local new_type = self.rooms[room_id] and self.rooms[room_id].type or 1
				if new_type ~= old_type then
					table.insert(changes, {room_id, new_type})
				end
			end
		end
	end
	if not IsEmptyTable(changes) then
		local userids = {}
		for _, player in ipairs(AllPlayers) do
			if TheNet:IsDedicated() or (TheWorld.ismastersim and player ~= ThePlayer) then
				table.insert(userids, player.userid)
			end
		end
		SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_update_room_type, userids, json.encode(changes))
	end
end

function RegionSystem:RefreashRoomType(room_id)		--这个函数会被父类调用
	if room_id == 0 then
		return
	end

	local success = false
	for _, data in ipairs(M23M.ROOM_DEFS) do
		local size_ok = self:CheckRoomSize(room_id, data.min_size, data.max_size)
		local must_item_ok = self:CheckRoomMustItems(room_id, data.must_items)
		local tiles_ok = self:CheckRoomTiles(room_id, data.available_tiles)
		if size_ok and must_item_ok and tiles_ok then
			self:SetRoomType(room_id, data.type)
			success = true
			break
		end
	end
	if not success then
		self:SetRoomType(room_id, "NONE")
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

function RegionSystem:CheckRoomTiles(room_id, available_tiles)
	if not available_tiles then
		 return true
	end

	local world_tiles = {}
	local region_ids = self:GetAllRegionsInRoom(room_id)
	for _, region_id in ipairs(region_ids) do
		local region = self.regions[region_id]
		for _, tile in ipairs(region.tiles) do
			local world_x, world_z = self:GetPointAtTileCoords(tile.x, tile.y)
			local center_x, center_y, center_z = TheWorld.Map:GetTileCenterPoint(world_x, 0, world_z)
			if not world_tiles[center_z] then
				world_tiles[center_z] = {}
			end
			if not world_tiles[center_z][center_x] then
				local tile_id = TheWorld.Map:GetTileAtPoint(world_x, 0, world_z)
				if not available_tiles[INVERTED_WORLD_TILES[tile_id]] then
					return false
				end
				world_tiles[center_z][center_x] = tile_id
			end
		end
	end

	return true
end


--主要是向客户端同步数据

local function send_section_data_to_clients(self, x, y)
	local tiles = self:GetAllTilesInSection(x, y)
	local tiles_code = self:EncodeTiles(tiles)
	local rooms_code = self:EncodeRooms()
	local data_pack = string.format("{\"tiles\": %s, \"rooms\": %s}", tiles_code, rooms_code)
	local userids = {}
	for _, player in ipairs(AllPlayers) do
		if TheNet:IsDedicated() or (TheWorld.ismastersim and player ~= ThePlayer) then
			table.insert(userids, player.userid)
		end
	end
	SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_update_section_data, userids, data_pack)
end

local function check_should_send_rpc_to_clients()
	if TheNet:IsDedicated() then
		return true
	elseif TheWorld.ismastersim then
		for _, player in ipairs(AllPlayers) do
			if player ~= ThePlayer then
				return true
			end
		end
	end
	return false
end

local event_handlers = {
	section_update_single = function (self, x, y)
		if not check_should_send_rpc_to_clients() then return end
		send_section_data_to_clients(self, x, y)
	end,
	section_update_mult = function (self, sections)
		if not check_should_send_rpc_to_clients() then return end
		for y, xs in pairs(sections) do
			for x, _ in pairs(xs) do
				send_section_data_to_clients(self, x, y)
			end
		end
	end,
}
function RegionSystem:ListenForRegionEvent(event, ...)
	if event_handlers[event] then
		event_handlers[event](self, ...)
	end
end

--将tiles数据进行压缩，用于RPC传输
--压缩后为一个整数数组，每2个连续元素存储1个地块的数据:
--  地块坐标: (y - 1) * self.width + x
--  地块信息: 1 bit:space | 1 bit:is_door | 1 bit:is_water | 29 bit: region(max:536870911)

function RegionSystem:EncodeTiles(tiles_matrix)	--二维矩阵
	local tiles = {}
	for i, v in pairs(tiles_matrix) do
		for j, data in pairs(v) do
			local tile_pos = (data.y - 1) * self.width + data.x
			--2^32: 4294967296 | 2^31: 2147483648 | 2^30: 1073741824
			local tile_info = (data.is_water and 1 or 0) * 4294967296 + (data.is_door and 1 or 0) * 2147483648 + (data.space and 1 or 0) * 1073741824 + data.region
			table.insert(tiles, tile_pos)
			table.insert(tiles, tile_info)
		end
	end
	return json.encode(tiles)
end

--将rooms数据进行压缩，用于RPC传输
--压缩后为一个整数数组，每n个连续元素存储1个地块的数据
-- room_id, type, region_count, region_id[region_count]
function RegionSystem:EncodeRooms(rooms)
	local rooms_data = {}
	for room_id, data in pairs(rooms or self.rooms) do
		table.insert(rooms_data, room_id)
		table.insert(rooms_data, data.type)
		table.insert(rooms_data, #data.regions)
		for i, region_id in ipairs(data.regions) do
			table.insert(rooms_data, region_id)
		end
	end
	return json.encode(rooms_data)
end


function RegionSystem:SendMapStreamToClient(userid)
	for i = 1, self.height do
		local code = self:EncodeTiles({self.tiles[i]})
		SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_init_tiles_stream, userid, code)
	end
end


return RegionSystem