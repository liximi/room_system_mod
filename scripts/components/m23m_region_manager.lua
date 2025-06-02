local REGION_SYS = require "region_system"
local json = require "json"


--------------------------------------------------
-- RegionSystem
--------------------------------------------------


local RegionSystem = Class(REGION_SYS, function (self, inst)
	self.inst = inst
	for _, data in ipairs(M23M.ROOM_DEFS) do
		self:RegisterRoomType(data.type)
	end

	--给客户端准备的缓存数据，理论上是一个连续数组
	--key: section的起始坐标对应的index
	--value: {main_region: integer 地块数量最多的region, other_regions: string 使用EncodeTiles处理后的数据 其他地块对应的region}
	self.section_data_cache = {}

	self.inst:ListenForEvent("onterraform", function(world, data)
		--data: {x:tilemap的坐标, y:tilemap的坐标, original_tile:int, tile:int}
		local pt_x, pt_z = _G.GetTileCenterPointByTileCoords(data.x, data.y)
		self:OnTerraform(pt_x, pt_z)
	end, TheWorld)

	self.inst:ListenForEvent("ms_playerjoined", function(world, player)
		self:SendAllDatasToPlayer(player)
	end, TheWorld)

	_G.TheRegionMgr = self
end)

--#region 坐标转换接口

function RegionSystem:GetTileCoordsAtPoint(x, z)
	return math.floor(x) + math.ceil(self.width/2), math.floor(z) + math.ceil(self.height/2)
end

function RegionSystem:GetPointAtTileCoords(x, y)
	return x - math.ceil(self.width/2) + 0.5, y - math.ceil(self.height/2) + 0.5
end

--#endregion
--------------------------------------------------
--#region 封装接口

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

--#endregion 
--------------------------------------------------
--#region 基类必需的函数覆写实现

function RegionSystem:IsWater(x, y)
	local _x, _z = self:GetPointAtTileCoords(x, y)
	return TheWorld.Map:IsOceanTileAtPoint(_x, 0, _z)
end

--#endregion
--------------------------------------------------
--#region 地皮、物品更新接口

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
		for tile_index, _ in pairs(region.tiles) do
			local x, y = self:GetPositionByIndex(tile_index)
			local world_x, world_z = self:GetPointAtTileCoords(x, y)
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

--#endregion
--------------------------------------------------
--#region 网络通讯

local function send_section_data_to_clients(self, x, y)
	local tiles = self:GetAllTilesInSection(x, y, REGION_SYS_TILE_KEYS.REGION)
	local tiles_code = self:EncodeTiles(tiles)
	local rooms_code = self:EncodeRooms()
	local data_pack = string.format("{\"tiles\": \"%s\", \"rooms\": \"%s\"}", tiles_code, rooms_code)
	local userids = {}
	for _, player in ipairs(AllPlayers) do
		if TheNet:IsDedicated() or (TheWorld.ismastersim and player ~= ThePlayer) then
			table.insert(userids, player.userid)
		end
	end
	if #userids > 0 then
		SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_update_section_data, userids, data_pack)
	end
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
		self:RefreashSectionDataCache(x, y)
		send_section_data_to_clients(self, x, y)
	end,
	section_update_mult = function (self, sections)
		if not check_should_send_rpc_to_clients() then return end
		if sections == nil then
			for y = 1, self.height, self.section_height do
				for x = 1, self.width, self.section_width do
					self:RefreashSectionDataCache(x, y)
					send_section_data_to_clients(self, x, y)
				end
			end
		else
			for y, xs in pairs(sections) do
				for x, _ in pairs(xs) do
					self:RefreashSectionDataCache(x, y)
					send_section_data_to_clients(self, x, y)
				end
			end
		end
	end,
}
function RegionSystem:ListenForRegionEvent(event, ...)
	if event_handlers[event] then
		event_handlers[event](self, ...)
	end
end

--通过section内任意地块坐标获取section的ID
function RegionSystem:GetSectionID(x, y)
	local section_x = math.floor(x / self.section_width) + 1
	local section_y = math.floor(y / self.section_height) + 1
	return section_x + (section_y - 1) * self.section_count_x
end

--通过section的ID获取section的起始坐标
function RegionSystem:GetSectionStartingPos(section_id)
	local section_y = math.ceil(section_id / self.section_count_x)
	local section_x = section_id - (section_y - 1) * self.section_count_x
	return (section_x - 1) * self.section_width, (section_y - 1) * self.section_height
end

function RegionSystem:RefreashSectionDataCache(x, y)
	local section_id = self:GetSectionID(x, y)
	if not self.section_data_cache[section_id] then
		self.section_data_cache[section_id] = {
			main_region = 0,
			other_regions = "",
		}
	end
	local section_data = self.section_data_cache[section_id]
	local tiles = self:GetAllTilesInSection(x, y, REGION_SYS_TILE_KEYS.REGION)
	local temp_regions = {}		--region_id = tiles_count
	local temp_main_region_id = 0
	local temp_max_count = 0
	for tile_index, region_id in pairs(tiles) do
		temp_regions[region_id] = temp_regions[region_id] and temp_regions[region_id] + 1 or 1
		if temp_main_region_id ~= region_id then
			if temp_regions[region_id] > temp_max_count then
				temp_main_region_id = region_id
				temp_max_count = temp_regions[region_id]
			end
		else
			temp_max_count = temp_regions[region_id]
		end
	end

	section_data.main_region = temp_main_region_id
	temp_regions[temp_main_region_id] = nil
	section_data.other_regions = ""

	for tile_index, region_id in pairs(tiles) do
		if region_id == temp_main_region_id then
			tiles[tile_index] = nil
		end
	end
	section_data.other_regions = self:EncodeTiles(tiles)
end

--将tiles数据进行压缩，用于RPC传输
--压缩后为一个整数数组，每2个连续元素存储1个地块的数据:
--  地块坐标: (y - 1) * self.width + x
--  地块region信息: max 4294967296-1

function RegionSystem:EncodeTiles(tiles)
	local _tiles = {}
	for tile_index, region_id in pairs(tiles) do
		table.insert(_tiles, tile_index)
		table.insert(_tiles, region_id)
	end
	return table.concat(_tiles, ",")
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
	return table.concat(rooms_data, ",")
end

--发送全地图的地块信息，会跳过region为0的地块，以减少网络传输耗时
function RegionSystem:SendMapStreamToClient(userid)
	local start_clock = os.clock()
	SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_init_data, userid, self:EncodeSectionCache())
	print(string.format("[M23M] SendMapStreamToClient: %.4fs", os.clock() - start_clock))
end

--将section的缓存数据进行压缩，用于RPC传输
--每个section数据之间用|分隔
--section按照其id排序
--每个section数据的格式为: 第一个整数表示main_region，后面的整数都是other_regions
--int,int,int,...|int,int,int,...|...
function RegionSystem:EncodeSectionCache()
	local temp_data = {}
	for section_index, cache in ipairs(self.section_data_cache) do
		table.insert(temp_data, tostring(cache.main_region)..","..cache.other_regions)
	end
	return table.concat(temp_data, "|")
end


function RegionSystem:SendAllDatasToPlayer(player)
	if TheNet:IsDedicated() or (TheWorld.ismastersim and player ~= ThePlayer) then
		SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_init_size_data, player.userid, self.width, self.height, self.section_width, self.section_height)
		SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].region_system_init_rooms_data, player.userid, self:EncodeRooms())
		self:SendMapStreamToClient(player.userid)
	end
end


--#endregion


return RegionSystem