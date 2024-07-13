--用于从主机同步数据到客机，为客机提供数据查询接口
local ROOM_DEF = require "m23m_room_def"
local ROOM_TYPES = { "NONE", }
local ROOM_TYPES_REVERSE = {NONE = 1}

--解析来自主机的 tile code
local function decode_tile_code(code)
	local tile = {}
	tile.region = code % 1073741824		--2^30
	code = (code - tile.region) / 1073741824
	tile.space = code % 2
	code = (code - tile.space) / 2
	tile.is_door = code % 2
	tile.is_water = (code - tile.is_door) / 2
	return tile
end

local function count_digits(n)
	local count = 0
	if n == 0 then
		return 1
	end
	while n > 0 do
		n = math.floor(n / 10)
		count = count + 1
	end
	return count
end

--------------------------------------------------
-- RegionSystem 和主机的组件不同，没有继承region_system/region_system.lua
--------------------------------------------------


local RegionSystem = Class(function (self, inst)
	self.inst = inst
	for _, data in ipairs(ROOM_DEF) do
		self:RegisterRoomType(data.type)
	end

	--#region 这些数据都从主机同步，不要在客机上修改
	self.width = 0
	self.height = 0
	self.section_width = 0
	self.section_height = 0
	self.tiles = {}
	--[[tiles 地块数据
		x
		y
		space: 该地块是否是可通过的空地, true表示为空, false表示有墙体或其他阻碍物
		region: 切片分组ID, 整数, space为false的地块region固定为0
		is_door: 该地块是否是门
		is_water: 该地块是否是水域
	]]
	self.regions = {}	--不记录ID为0的region, {tiles = {array of tile}, room = int}
	self.rooms = {}		--不记录ID为0的房间, {regions = {array of region's id}, type = int(ROOM_TYPES)}
	--#endregion

	_G.TheRegionMgr = self
end)


function RegionSystem:GetTileCoordsAtPoint(x, z)
	return math.floor(x) + math.ceil(self.width/2), math.floor(z) + math.ceil(self.height/2)
end

function RegionSystem:GetPointAtTileCoords(x, y)
	return x - math.ceil(self.width/2) + 0.5, y - math.ceil(self.height/2) + 0.5
end

function RegionSystem:GetAllRegionsInRoom(room_id)	--不要修改返回的表
	if not room_id or not self.rooms[room_id] then
		return {}
	end
	return self.rooms[room_id].regions
end

function RegionSystem:GetRegionId(x, y)
	return self.tiles[y] and self.tiles[y][x] and self.tiles[y][x].region
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
	for i, v in ipairs(ROOM_DEF) do
		if v.type == room_type then
			return v
		end
	end
end

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

function RegionSystem:GetSectionAABB(x, y)
	local base_x = math.floor((x-1) / self.section_width) * self.section_width + 1
	local base_y = math.floor((y-1) / self.section_height) * self.section_width + 1
	if not self.tiles[base_y] or not self.tiles[base_y][base_x] then
		return
	end
	return base_x, base_y, math.min(base_x + self.section_width - 1, self.width), math.min(base_y + self.section_height - 1, self.height)
end

function RegionSystem:Print(data_key, sub_key, only_one_section, x, y)
	data_key = data_key or "space"
	print(string.format("width: %d, height: %d", self.width, self.height))

	local max_line_number_len = count_digits(self.height)
	local start_x, start_y, w, h = 1, 1, self.width, self.height
	if only_one_section and x and y then
		start_x, start_y, w, h = self:GetSectionAABB(x, y)
		if not start_x then
			start_x, start_y, w, h = 1, 1, self.width, self.height
		end
		print(string.format("start_x: %d, start_y: %d", start_x, start_y))
	end
	for i = start_y, h do
		local line = {}
		for j = start_x, w do
			if sub_key then
				table.insert(line, tostring(self.tiles[i][j][data_key][sub_key]))
			else
				table.insert(line, tostring(self.tiles[i][j][data_key]))
			end
		end

		local line_number_len = count_digits(i)
		local space = ""
		local count = 0
		while count < max_line_number_len - line_number_len do
			count = count + 1
			space = space.." "
		end
		print(tostring(i)..space.." | "..table.concat(line, " "))
	end
end

--------------------------------------------------
-- 接受来自主机的数据
--------------------------------------------------

--tiles的结构参主机组件的 EncodeTiles 函数
function RegionSystem:ReceiveMapSizeData(width, height, section_width, section_height)
	assert(width > 0 and height > 0 and section_width > 0 and section_height > 0, "RegionSystem Error")
	self.width = width
	self.height = height
	self.section_width = section_width
	self.section_height = section_height
end

function RegionSystem:ReceiveRoomsData(roomsdata, refresh_region)
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

	self.rooms = rooms

	if refresh_region then
		for room_id, data in pairs(rooms) do
			for _, region_id in ipairs(data.regions) do
				if not self.regions[region_id] then
					self.regions[region_id] = {tiles = {}, room = room_id}
				else
					self.regions[region_id].room = room_id
				end
			end
		end
	end
end

function RegionSystem:ReceiveTileStream(tiles)
	for i = 1, #tiles, 2 do
		local tile = decode_tile_code(tiles[i+1])
		local y = math.floor(tiles[i] / self.width) + 1
		local x = tiles[i] - (y - 1) * self.width
		tile.y = y
		tile.x = x

		if not self.tiles[y] then
			self.tiles[y] = {}
		end
		self.tiles[y][x] = tile

		if tile.region ~= 0 then
			assert(self.regions[tile.region] ~= nil, "RegionSystem Error: Not Received Rooms Data")
			table.insert(self.regions[tile.region].tiles, tile)
		end
	end
end

return RegionSystem