--用于从主机同步数据到客机，为客机提供数据查询接口
local ROOM_TYPES = { "NONE", }
local ROOM_TYPES_REVERSE = {NONE = 1}

local ERR_ROOM_DATA_NOT_SYNCHRONIZED = "RegionSystem Error: Room Data Not Synchronized."
local ERR_NEGATIVE_MAP_SIZE_DATA = "RegionSystem ERRO: Negative Map Size Data."

local function decode_int_array(tilesstr)
	local result = {}
    for num in string.gmatch(tilesstr, "%d+") do
        table.insert(result, tonumber(num))
    end
	return result
end

--解析来自主机的 rooms 数据数组
local function decode_roomsdata(rooms_str)
	if type(rooms_str) ~= "string" then
		return {}
	end

	local roomsdata = decode_int_array(rooms_str)
	local rooms = {}
	local cur_head, len_of_arr = 1, #roomsdata
	while cur_head < len_of_arr do
		local room_id = roomsdata[cur_head]
		local room_type = roomsdata[cur_head + 1]
		local regions_count = roomsdata[cur_head + 2]
		local regions = {}
		for i = 1, regions_count do
			table.insert(regions, roomsdata[cur_head + 2 + i])
		end
		rooms[room_id] = {type = room_type, regions = regions}
		cur_head = cur_head + regions_count + 3
	end
	return rooms
end

--------------------------------------------------
-- RegionSystem 和主机的组件不同，没有继承region_system/region_system.lua
--------------------------------------------------


local RegionSystem = Class(function (self, inst)
	self.inst = inst
	for _, data in ipairs(M23M.ROOM_DEFS) do
		self:RegisterRoomType(data.type)
	end

	--#region 这些数据都从主机同步，不要在客机上修改
	self.width = 0
	self.height = 0
	self.section_width = 0
	self.section_height = 0
	self.tiles = {}		--{y1 = {x1 = region_id1, x2 = region_id2, ...}, y2 = {...}}
	self.regions = {}	--不记录ID为0的region, {tiles = {y={x=tile}}, room = int, tiles_count = int}
	self.rooms = {}		--不记录ID为0的房间, {regions = {array of region's id}, type = int(ROOM_TYPES)}
	--#endregion

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
--#region 查询数据

function RegionSystem:GetAllRegionsInRoom(room_id)	--不要修改返回的表
	if not room_id or not self.rooms[room_id] then
		return {}
	end
	return self.rooms[room_id].regions
end

function RegionSystem:GetRegionId(x, y)
	return self.tiles[y] and self.tiles[y][x] and self.tiles[y][x]
end

function RegionSystem:GetRoomId(x, y)
	local region_id = self:GetRegionId(x, y)
	if region_id == 0 then
		return 0
	end
	return region_id and self.regions[region_id].room
end

function RegionSystem:GetRoomTypeById(room_id)
	if not self.rooms[room_id] then
		return "NONE"
	end
	return ROOM_TYPES[self.rooms[room_id].type] or "NONE"
end

function RegionSystem:GetRoomType(x, y)
	local room_id = self:GetRoomId(x, y)
	if room_id then
		return self:GetRoomTypeById(room_id)
	end
	return "NONE"
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

function RegionSystem:GetSectionAABB(x, y)
	local base_x = math.floor((x-1) / self.section_width) * self.section_width + 1
	local base_y = math.floor((y-1) / self.section_height) * self.section_width + 1
	if not self.tiles[base_y] or not self.tiles[base_y][base_x] then
		return
	end
	return base_x, base_y, math.min(base_x + self.section_width - 1, self.width), math.min(base_y + self.section_height - 1, self.height)
end

function RegionSystem:GetRoomSize(room_id)
	local regions = self:GetAllRegionsInRoom(room_id)
	local size = 0
	for _, region_id in ipairs(regions) do
		local region = self.regions[region_id]
		if region then
			size = size + region.tiles_count
		end
	end
	return size
end

--#endregion
--------------------------------------------------
--#region 注册房间类型

function RegionSystem:RegisterRoomType(room_type)
	if type(room_type) == "string" then
		for _, _type in ipairs(ROOM_TYPES) do
			if _type == room_type then
				return
			end
		end
		table.insert(ROOM_TYPES, room_type)
		ROOM_TYPES_REVERSE[room_type] = #ROOM_TYPES
	end
end

--#endregion
--------------------------------------------------
--#region 网络通讯

function RegionSystem:ReceiveMapSizeData(width, height, section_width, section_height)
	assert(width > 0 and height > 0 and section_width > 0 and section_height > 0, ERR_NEGATIVE_MAP_SIZE_DATA)
	self.width = width
	self.height = height
	self.section_width = section_width
	self.section_height = section_height
end

function RegionSystem:ReceiveRoomsData(rooms_str, refresh_region)
	self.rooms = decode_roomsdata(rooms_str)
	if refresh_region then
		for room_id, data in pairs(self.rooms) do
			for _, region_id in ipairs(data.regions) do
				if not self.regions[region_id] then
					self.regions[region_id] = {tiles = {}, room = room_id, tiles_count = 0}
				else
					self.regions[region_id].room = room_id
				end
			end
		end
	end
end

--tiles的结构参见主机组件的 EncodeTiles 函数
function RegionSystem:ReceiveTileStream(tiles_str)
	if not self.start_time then
		self.start_time = os.clock()
	end
	local tiles = decode_int_array(tiles_str)
	for i = 1, #tiles, 2 do
		local region_id = tiles[i+1]
		local y = math.floor(tiles[i] / self.width) + 1
		local x = tiles[i] - (y - 1) * self.width

		if not self.tiles[y] then
			self.tiles[y] = {}
		end
		self.tiles[y][x] = region_id

		if region_id ~= 0 then
			local region = self.regions[region_id]
			assert(region ~= nil, ERR_ROOM_DATA_NOT_SYNCHRONIZED)
			if not region.tiles[y] then
				region.tiles[y] = {}
			end
			region.tiles[y][x] = true
			region.tiles_count = region.tiles_count + 1
		end
	end
	if #self.tiles >= self.height then
		print("Total Cost Time:", os.clock() - self.start_time)
	end
end

--{tiles = {要更新的地块数据}, rooms = {全部房间数据}}
function RegionSystem:ReceiveSectionUpdateData(data)
	self:ReceiveRoomsData(data.rooms, true)
	local tiles = decode_int_array(data.tiles)
	if type(tiles) ~= "table" then
		return
	end
	local empty_regions = {}
	for i = 1, #tiles, 2 do
		local y = math.floor(tiles[i] / self.width) + 1
		local x = tiles[i] - (y - 1) * self.width
		local tile_region = tiles[i+1]
		local old_tile_region = self.tiles[y][x]
		self.tiles[y][x] = tile_region
		if tile_region ~= old_tile_region and old_tile_region ~= 0 then
			local old_region = self.regions[old_tile_region]
			if old_region then
				if old_region.tiles[y] and old_region.tiles[y][x] then
					old_region.tiles[y][x] = nil
					old_region.tiles_count = old_region.tiles_count - 1
					if IsEmptyTable(old_region.tiles[y]) then
						old_region.tiles[y] = nil
					end
					if old_region.tiles_count <= 0 then
						empty_regions[old_tile_region] = true
					end
				end
			end

			if tile_region ~= 0 then
				local region = self.regions[tile_region]
				assert(region ~= nil, ERR_ROOM_DATA_NOT_SYNCHRONIZED)
				if not region.tiles[y] then
					region.tiles[y] = {}
				end
				region.tiles[y][x] = true
				region.tiles_count = region.tiles_count + 1
				if empty_regions[tile_region] then
					empty_regions[tile_region] = nil
				end
			end
		end
	end

	for region, _ in pairs(empty_regions) do
		self.regions[region] = nil
	end
end

function RegionSystem:ReceiveRoomsTypeUpdateData(data)
	if type(data) ~= "table" then
		return
	end
	for _, room in ipairs(data) do
		local room_id = room[1]
		local room_type = room[2]
		assert(self.rooms[room_id], ERR_ROOM_DATA_NOT_SYNCHRONIZED)
		self.rooms[room_id].type = room_type
	end
end

--#endregion


return RegionSystem