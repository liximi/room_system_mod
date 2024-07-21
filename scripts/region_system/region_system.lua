local DIR = {
	X_POSITIVE = 1,
	Y_POSITIVE = 2,
	X_NEGATIVE = 3,
	Y_NEGATIVE = 4,
}
local DIR_REVERSE = {}
for dir, val in pairs(DIR) do
	DIR_REVERSE[val] = dir
end

local ROOM_TYPES = { "NONE", }
local ROOM_TYPES_REVERSE = {NONE = 1}

local function encode_edge(x, y, dir, length)	--x, y 坐标只留了12位(最大4095), 不支持负数, 不支持小数
	return x * 268435456 + y * 65536 + dir * 256 + length
end

local function decode_edge(code)
	local length = code % 256
	code = (code - length) / 256
	local dir = code % 256
	code = (code - dir) / 256
	local y = code % 4096
	local x = (code - y) / 4096
	return x, y, dir, length
end

local function flood_fill(tiles, cur_x, cur_y, can_visit, on_visit, visited, prev_x, prev_y)
	local cur_tile = tiles[cur_y] and tiles[cur_y][cur_x]

	if not cur_tile then return end
	if not visited then visited = {} end
	if visited[cur_tile] then return end
	visited[cur_tile] = true
	if can_visit and not can_visit(cur_x, cur_y,  prev_x, prev_y) then
		return
	end

	if on_visit then
		on_visit(cur_x, cur_y)
	end

	flood_fill(tiles, cur_x + 1, cur_y, can_visit, on_visit, visited, cur_x, cur_y)
	flood_fill(tiles, cur_x, cur_y + 1, can_visit, on_visit, visited, cur_x, cur_y)
	flood_fill(tiles, cur_x - 1, cur_y, can_visit, on_visit, visited, cur_x, cur_y)
	flood_fill(tiles, cur_x, cur_y - 1, can_visit, on_visit, visited, cur_x, cur_y)
end

local function flood_fill_region(regions, cur_region_id, can_visit, on_visit, visited)
	local cur_region = regions[cur_region_id]

	if not cur_region then return end
	if not visited then visited = {} end
	if visited[cur_region_id] then return end
	visited[cur_region_id] = true
	if can_visit and not can_visit(cur_region_id) then
		return
	end

	if on_visit then
		on_visit(cur_region_id)
	end

	for region_id, edges in pairs(cur_region.passable_edges) do
		flood_fill_region(regions, region_id, can_visit, on_visit, visited)
	end
end

local function get_edges(tiles, x, y, dir_x, dir_y, adjacent_dir_x, adjacent_dir_y, max_len)
	local edges = {}
	local new_start = true

	for i = 0, max_len - 1 do
		local cur_x, cur_y = x + dir_x * i, y + dir_y * i
		local tile = tiles[cur_y][cur_x]
		local adjacent_tile = tiles[cur_y + adjacent_dir_y] and tiles[cur_y + adjacent_dir_y][cur_x + adjacent_dir_x]
		local self_region = tile.region
		if self_region ~= 0 and adjacent_tile and adjacent_tile.region ~= 0 then
			local target_region = adjacent_tile.region
			if not edges[self_region] then
				edges[self_region] = {}
				new_start = true
			end
			if not edges[self_region][target_region] then
				edges[self_region][target_region] = {}
				new_start = true
			end
			if new_start then
				local dir = (dir_x ~= 0 and dir_y == 0) and DIR.X_POSITIVE or DIR.Y_POSITIVE
				table.insert(edges[self_region][target_region], {cur_x, cur_y, dir, 1})
				new_start = false
			else
				local cur_edge = edges[self_region][target_region][#edges[self_region][target_region]]
				cur_edge[4] = cur_edge[4] + 1
			end
		else
			new_start = true
		end
	end

	for region1, target_regions in pairs(edges) do
		for region2, _edges in pairs(target_regions) do
			for i, edge in ipairs(_edges) do
				_edges[i] = encode_edge(edge[1], edge[2], edge[3], edge[4])
			end
		end
	end
	return edges
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

local function is_empty_table(tab)
	for k, v in pairs(tab) do
		return false
	end
	return true
end

local function get_empty_num_index(tab)
	local index = 0
	for i, _ in ipairs(tab) do
		index = i
	end
	return index
end

--------------------------------------------------
-- RegionSystem
--------------------------------------------------

local RegionSystem = {
	DIR = DIR,
	DIR_REVERSE = DIR_REVERSE,

	width = 0,
	height = 0,
	section_width = 0,
	section_height = 0,
	tiles = {},
	-- 除了Generation, 永远不要修改tiles[y][x]的引用
	--[[tiles 地块数据
		x
		y
		space: 该地块是否是可通过的空地, true表示为空, false表示有墙体或其他阻碍物
		region: 切片分组ID, 整数, space为false的地块region固定为0
		is_door: 该地块是否是门
		is_water: 该地块是否是水域
	]]
	regions = {},	--不记录ID为0的region, {tiles = {array of tile}, passable_edges = {target_region_id = edge_code}, room = int}
	rooms = {},		--不记录ID为0的房间, {regions = {array of region's id}, type = int(ROOM_TYPES)}
}


function RegionSystem:Generation(width, height, section_width, section_height)
	self.width = width
	self.height = height
	self.section_width = section_width or self.width
	self.section_height = section_height or self.height
	self.tiles = {}
	for i = 1, height do
		self.tiles[i] = {}
		for j = 1, width do
			self.tiles[i][j] = { x = j, y = i, space = true }
		end
	end
	--初始切片
	self:private_NewRoom(1)
	local region_id = 1
	for base_i = 1, self.height, self.section_height do
		for base_j = 1, self.width, self.section_width do
			local region_tiles = {}

			for i = 0, self.section_height - 1 do
				local y = base_i + i
				if self.tiles[y]  == nil then break end
				for j = 0, self.section_width - 1 do
					local x = base_j + j
					if self.tiles[y][x]  == nil then break end
					self.tiles[y][x].region = region_id
					table.insert(region_tiles, self.tiles[y][x])
				end
			end

			local region = self:private_NewRegion(region_id)
			while not region do
				region_id = region_id + 1
				region = self:private_NewRegion(region_id)
			end
			region.tiles = region_tiles
			self:private_AddRegionToRoom(region_id, 1)
			region_id = region_id + 1
		end
	end
	--刷新边缘缓存
	for base_i = 1, self.height, self.section_height do
		for base_j = 1, self.width, self.section_width do
			self:RefreashSectionEdges(base_j, base_i)
		end
	end
end

function RegionSystem:RefreashSection(x, y)
	local section_tiles, base_x, base_y = self:GetAllTilesInSection(x, y)

	if not section_tiles then return end

	local function can_visit(cur_x, cur_y, prev_x, prev_y)
		cur_x, cur_y = base_x + cur_x - 1, base_y + cur_y - 1
		if not self:IsPassable(cur_x, cur_y) then
			return false
		end
		if not prev_x or not prev_y then
			return true
		end
		prev_x, prev_y = base_x + prev_x - 1, base_y + prev_y - 1
		if not self:IsPassable(prev_x, prev_y) then
			return false
		end
		return self:IsWater(cur_x, cur_y) == self:IsWater(prev_x, prev_y)
	end

	local region_index
	local doors = {}
	local function on_visit(cur_x, cur_y)
		local cur_tile = section_tiles[cur_y][cur_x]

		if cur_tile.is_door then
			table.insert(doors, {base_x + cur_x - 1, base_y + cur_y - 1})
		end

		if not self.regions[region_index] then
			self:private_NewRegion(region_index)
		end
		self:private_AddTileToRegion(cur_tile, region_index)

		section_tiles[cur_y][cur_x] = nil
		if is_empty_table(section_tiles[cur_y]) then section_tiles[cur_y] = nil end
	end

	--泛洪算法更新region
	while not is_empty_table(section_tiles) do
		for _y, xs in pairs(section_tiles) do
			for _x in pairs(xs) do
				if self:IsPassable(base_x + _x - 1, base_y + _y - 1) then
					region_index = get_empty_num_index(self.regions) + 1
					flood_fill(section_tiles, _x, _y, can_visit, on_visit)
				else
					self:private_AddTileToRegion(self.tiles[base_y + _y - 1][base_x + _x - 1], 0)
					section_tiles[_y][_x] = nil
					if is_empty_table(section_tiles[_y]) then section_tiles[_y] = nil end
				end
			end
		end
	end

	--把门拆到独立的region里
	for _, door_pos in ipairs(doors) do
		local cur_tile = self.tiles[door_pos[2]][door_pos[1]]
		region_index = get_empty_num_index(self.regions) + 1
		self:private_NewRegion(region_index)
		self:private_AddTileToRegion(cur_tile, region_index)
	end

	--更新section内的region与其他region相接的边缘
	self:RefreashSectionEdges(x, y)
end

function RegionSystem:RefreashSectionEdges(x, y)
	local base_x = math.floor((x-1) / self.section_width) * self.section_width + 1
	local base_y = math.floor((y-1) / self.section_height) * self.section_width + 1
	if not self.tiles[base_y] or not self.tiles[base_y][base_x] then
		return
	end
	local section_height = math.min(self.section_height, self.height - base_y + 1)
	local section_width = math.min(self.section_width, self.width - base_x + 1)
	--section外边缘
	for region1, target_regions in pairs(get_edges(self.tiles, base_x, base_y, 0, 1, -1, 0, section_height)) do
		for region2, edges in pairs(target_regions) do
			self.regions[region1].passable_edges[region2] = edges
			self.regions[region2].passable_edges[region1] = edges
		end
	end
	for region1, target_regions in pairs(get_edges(self.tiles, base_x + section_width - 1, base_y, 0, 1, 1, 0, section_height)) do
		for region2, edges in pairs(target_regions) do
			self.regions[region1].passable_edges[region2] = edges
			self.regions[region2].passable_edges[region1] = edges
		end
	end
	for region1, target_regions in pairs(get_edges(self.tiles, base_x, base_y, 1, 0, 0, -1, section_width)) do
		for region2, edges in pairs(target_regions) do
			self.regions[region1].passable_edges[region2] = edges
			self.regions[region2].passable_edges[region1] = edges
		end
	end
	for region1, target_regions in pairs (get_edges(self.tiles, base_x, base_y + section_height - 1, 1, 0, 0, 1, section_width)) do
		for region2, edges in pairs(target_regions) do
			self.regions[region1].passable_edges[region2] = edges
			self.regions[region2].passable_edges[region1] = edges
		end
	end
	--section内的门
	for i = base_y, math.min(base_y + self.section_height - 1, self.height) do
		for j = base_x, math.min(base_x + self.section_width - 1, self.width) do
			local tile = self.tiles[i][j]
			if tile.is_door then
				for region1, target_regions in pairs(get_edges(self.tiles, j, i, 0, 1, -1, 0, 1)) do
					for region2, edges in pairs(target_regions) do
						self.regions[region1].passable_edges[region2] = edges
						self.regions[region2].passable_edges[region1] = edges
					end
				end
				for region1, target_regions in pairs(get_edges(self.tiles, j, i, 0, 1, 1, 0, 1)) do
					for region2, edges in pairs(target_regions) do
						self.regions[region1].passable_edges[region2] = edges
						self.regions[region2].passable_edges[region1] = edges
					end
				end
				for region1, target_regions in pairs(get_edges(self.tiles, j, i, 1, 0, 0, -1, 1)) do
					for region2, edges in pairs(target_regions) do
						self.regions[region1].passable_edges[region2] = edges
						self.regions[region2].passable_edges[region1] = edges
					end
				end
				for region1, target_regions in pairs (get_edges(self.tiles, j, i, 1, 0, 0, 1, 1)) do
					for region2, edges in pairs(target_regions) do
						self.regions[region1].passable_edges[region2] = edges
						self.regions[region2].passable_edges[region1] = edges
					end
				end
			end
		end
	end
end

function RegionSystem:RefreashRooms()	--遍历全部region, 刷新房间
	local groups = {}
	local regions_need_process = {}
	for region_id, region in pairs(self.regions) do
		if region.room == 0 then
			regions_need_process[region_id] = region
		end
	end

	local function can_visit(region_id)
		return not self:IsDoorRegion(region_id)
	end
	local visited = {}
	local function on_visit(region_id)
		table.insert(groups[#groups], region_id)
		visited[region_id] = true
	end

	for region_id, region in pairs(regions_need_process) do
		if not visited[region_id] then
			table.insert(groups, {region_id})
			if not self:IsDoorRegion(region_id) then
				flood_fill_region(self.regions, region_id, can_visit, on_visit)
			end
		end
	end

	for _, group in ipairs(groups) do
		local new_room_id = get_empty_num_index(self.rooms) + 1
		self:private_NewRoom(new_room_id)
		for _, region_id in ipairs(group) do
			self:private_AddRegionToRoom(region_id, new_room_id)
		end
		if self.RefreashRoomType then
			self:RefreashRoomType(new_room_id)
		end
	end
end

function RegionSystem:IsPassable(x, y)
	return self.tiles[y] and self.tiles[y][x] and self.tiles[y][x].space
end

function RegionSystem:IsWater(x, y)
	return self.tiles[y] and self.tiles[y][x] and self.tiles[y][x].is_water == true
end

function RegionSystem:IsDoorRegion(region_id)
	if not region_id then return false end
	local region = self.regions[region_id]
	if not region then return false end
	if #region.tiles == 1 then
		return region.tiles[1].is_door == true
	end
	return false
end

function RegionSystem:GetSectionAABB(x, y)
	local base_x = math.floor((x-1) / self.section_width) * self.section_width + 1
	local base_y = math.floor((y-1) / self.section_height) * self.section_width + 1
	if not self.tiles[base_y] or not self.tiles[base_y][base_x] then
		return
	end
	return base_x, base_y, math.min(base_x + self.section_width - 1, self.width), math.min(base_y + self.section_height - 1, self.height)
end

function RegionSystem:GetAllTilesInSection(x, y)	--通过坐标获取该坐标所属的切片内的所有地块
	local base_x = math.floor((x-1) / self.section_width) * self.section_width + 1
	local base_y = math.floor((y-1) / self.section_height) * self.section_width + 1
	if not self.tiles[base_y] or not self.tiles[base_y][base_x] then
		return
	end
	local tiles = {}
	for i = base_y, math.min(base_y + self.section_height - 1, self.height) do
		local _y = i - base_y + 1
		tiles[_y] = {}
		for j = base_x, math.min(base_x + self.section_width - 1, self.width) do
			tiles[_y][j - base_x + 1] = self.tiles[i][j]
		end
	end

	return tiles, base_x, base_y
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

function RegionSystem:GetRoomIdByRegion(region_id)
	if region_id == 0 then
		return 0
	end
	return region_id and self.regions[region_id] and self.regions[region_id].room
end

function RegionSystem:GetAllRegionsInRoom(room_id)	--不要修改返回的表
	if not room_id or not self.rooms[room_id] then
		return {}
	end
	return self.rooms[room_id].regions
end

function RegionSystem:GetAllTilesInRoom(room_id)	--性能很差
	local regions = self:GetAllRegionsInRoom(room_id)
	local tiles = {}
	for _, region_id in ipairs(regions) do
		local region = self.regions[region_id]
		if region then
			for _, tile in ipairs(region.tiles) do
				table.insert(tiles, tile)
			end
		end
	end
	return tiles
end

function RegionSystem:GetRegion(region_id)
	return region_id and self.regions[region_id]
end

function RegionSystem:GetRegionPassableEdges(region_id)
	if not region_id or not self.regions[region_id] then
		return
	end
	return self.regions[region_id].passable_edges
end

function RegionSystem:DeCodeEdge(edge_code)
	local x, y, dir, length = decode_edge(edge_code)
	return {x = x, y = y, dir = dir, length = length}
end

function RegionSystem:AddWalls(walls)	--{x, y}
	local space_datas = {}
	for i, pos in ipairs(walls) do
		local x, y = pos[1], pos[2]
		if self.tiles[y] and self.tiles[y][x] and self.tiles[y][x].space then
			table.insert(space_datas, {x, y, false})
		end
	end

	if #space_datas == 1 then
		self:private_SetSpace(space_datas[1][1], space_datas[1][2], space_datas[1][3])
	else
		self:private_SetSpaceBatch(space_datas)
	end
end

function RegionSystem:RemoveWalls(walls)	--{x, y}
	local space_datas = {}
	for i, pos in ipairs(walls) do
		local x, y = pos[1], pos[2]
		if self.tiles[y] and self.tiles[y][x] and not self.tiles[y][x].space and not self.tiles[y][x].is_door then
			table.insert(space_datas, {x, y, true})
		end
	end

	if #space_datas == 1 then
		self:private_SetSpace(space_datas[1][1], space_datas[1][2], space_datas[1][3])
	else
		self:private_SetSpaceBatch(space_datas)
	end
end

function RegionSystem:AddDoors(doors)	--{x, y}
	local space_datas = {}
	for i, pos in ipairs(doors) do
		local x, y = pos[1], pos[2]
		if self.tiles[y] and self.tiles[y][x] and self.tiles[y][x].space then
			self.tiles[y][x].is_door = true
			table.insert(space_datas, {x, y, false})
		end
	end

	if #space_datas == 1 then
		self:private_SetSpace(space_datas[1][1], space_datas[1][2], space_datas[1][3])
	else
		self:private_SetSpaceBatch(space_datas)
	end
end

function RegionSystem:RemoveDoors(doors)	--{x, y}
	local space_datas = {}
	for i, pos in ipairs(doors) do
		local x, y = pos[1], pos[2]
		if self.tiles[y] and self.tiles[y][x] and not self.tiles[y][x].space and self.tiles[y][x].is_door then
			self.tiles[y][x].is_door = nil
			table.insert(space_datas, {x, y, true})
		end
	end

	if #space_datas == 1 then
		self:private_SetSpace(space_datas[1][1], space_datas[1][2], space_datas[1][3])
	else
		self:private_SetSpaceBatch(space_datas)
	end
end

function RegionSystem:AddWaters(waters)	 --{x, y}
	local sections = {}		-- y = {x = true}
	for i, pos in ipairs(waters) do
		local x, y = pos[1], pos[2]
		if self.tiles[y] and self.tiles[y][x] then
			self.tiles[y][x].is_water = true
		end

		local base_x, base_y = self:GetSectionAABB(pos[1], pos[2])
		if base_x then
			if not sections[base_y] then
				sections[base_y] = {}
			end
			sections[base_y][base_x] = true
		end
	end

	for y, xs in pairs(sections) do
		for x, _ in pairs(xs) do
			self:RefreashSection(x, y)
		end
	end
	self:RefreashRooms()
	self:private_PushEvent("section_update_mult", sections)
end

function RegionSystem:RemoveWaters(waters)	--{x. y}
	local sections = {}		-- y = {x = true}
	for i, pos in ipairs(waters) do
		local x, y = pos[1], pos[2]
		if self.tiles[y] and self.tiles[y][x] and self.tiles[y][x].is_water then
			self.tiles[y][x].is_water = nil
		end

		local base_x, base_y = self:GetSectionAABB(pos[1], pos[2])
		if base_x then
			if not sections[base_y] then
				sections[base_y] = {}
			end
			sections[base_y][base_x] = true
		end
	end

	for y, xs in pairs(sections) do
		for x, _ in pairs(xs) do
			self:RefreashSection(x, y)
		end
	end
	self:RefreashRooms()
	self:private_PushEvent("section_update_mult", sections)
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

function RegionSystem:SetRoomType(room_id, type)	--type是房间字符串id
	if not self.rooms[room_id] then
		return false, 0
	end
	if not ROOM_TYPES_REVERSE[type] then
		return false, 1
	end
	self.rooms[room_id].type = ROOM_TYPES_REVERSE[type]
	return true
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

function RegionSystem:IsInRoom(x, y, room_type)
	return room_type == self:GetRoomType(x, y)
end

function RegionSystem:GetRoomSize(room_id)
	local regions = self:GetAllRegionsInRoom(room_id)
	local size = 0
	for _, region_id in ipairs(regions) do
		local region = self.regions[region_id]
		if region then
			size = size + #region.tiles
		end
	end
	return size
end

function RegionSystem:SetDataToRegion(region_id, key, data)
	if not self.regions[region_id] or type(key) ~= "string" then
		return false
	end
	self.regions[region_id][key] = data
	return true
end

function RegionSystem:GetDataInRegion(region_id, key)
	if not self.regions[region_id] or type(key) ~= "string" then
		return
	end
	return self.regions[region_id][key]
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


-- function RegionSystem:RefreashRoomType(room_id) end
-- function RegionSystem:OnChangeTileRegion(x, y, old_region_id, new_region_id, refreash_room) end
-- function RegionSystem:ListenForRegionEvent(event, ...) end

--------------------------------------------------
-- 私有函数 Private Functions
--------------------------------------------------

function RegionSystem:private_SetSpace(x, y, space)
	self.tiles[y][x].space = space and true or nil
	self:RefreashSection(x, y)
	self:RefreashRooms()
	self:private_PushEvent("section_update_single", x, y)
end

function RegionSystem:private_SetSpaceBatch(datas)	-- {x, y, space}, private_SetSpace的批处理版本, 在需要更新的地块较多时性能较好
	local sections = {}		-- y = {x = true}
	for _, data in ipairs(datas) do
		self.tiles[data[2]][data[1]].space = data[3]
		local base_x, base_y = self:GetSectionAABB(data[1], data[2])
		if base_x then
			if not sections[base_y] then
				sections[base_y] = {}
			end
			sections[base_y][base_x] = true
		end
	end

	for y, xs in pairs(sections) do
		for x, _ in pairs(xs) do
			self:RefreashSection(x, y)
		end
	end
	self:RefreashRooms()
	self:private_PushEvent("section_update_mult", sections)
end

function RegionSystem:private_NewRegion(region_id)
	if self.regions[region_id] then
		return false
	end
	local region = {
		tiles = {},
		passable_edges = {},
		room = 0,
	}
	self.regions[region_id] = region
	return region
end

function RegionSystem:private_AddTileToRegion(tile, region_id)
	local old_region_id = tile.region
	local old_region_tiles = self.regions[old_region_id] and self.regions[old_region_id].tiles
	if old_region_tiles then
		for i, _tile in ipairs(old_region_tiles) do
			if _tile == tile then
				table.remove(old_region_tiles, i)
				break
			end
		end
		if #old_region_tiles == 0 then
			self:private_DeleteRegion(old_region_id)
		end
	end

	if region_id ~= 0 then
		table.insert(self.regions[region_id].tiles, tile)
	end
	tile.region = region_id

	if self.OnChangeTileRegion then
		self:OnChangeTileRegion(tile.x, tile.y, old_region_id, region_id)
	end
end

function RegionSystem:private_DeleteRegion(region_id)
	if not self.regions[region_id] then
		return
	end
	for region, edges in pairs(self.regions[region_id].passable_edges) do
		if self.regions[region] then
			self.regions[region].passable_edges[region_id] = nil
		end
	end
	local room_id = self.regions[region_id].room or 0
	local room = self.rooms[room_id]
	if room then
		for i, region in ipairs(room.regions) do
			if region == region_id then
				table.remove(room.regions, i)
				if #room.regions == 0 then
					self.rooms[room_id] = nil
				end
				break
			end
		end
	end
	self.regions[region_id] = nil
end

function RegionSystem:private_NewRoom(room_id)
	if self.rooms[room_id] then
		return false
	end
	local room = {
		regions = {},
		type = ROOM_TYPES.NONE
	}
	self.rooms[room_id] = room
	return room
end

function RegionSystem:private_AddRegionToRoom(region_id, room_id)
	if not region_id or not room_id then
		return
	end
	local old_room_id = self.regions[region_id].room
	if old_room_id == room_id then
		return
	end

	self.regions[region_id].room = room_id
	if self.rooms[old_room_id] then
		for i, region in ipairs(self.rooms[old_room_id].regions) do
			if region == region_id then
				table.remove(self.rooms[old_room_id].regions, i)
				break
			end
		end
		if #self.rooms[old_room_id].regions == 0 then	--移除没有region的房间
			self.rooms[old_room_id] = nil
		end
	end
	if self.rooms[room_id] then
		table.insert(self.rooms[room_id].regions, region_id)
	end
end

--[[Events List:
	section_update_single: x, y
	section_update_mult: sections={y1={x1, x2, ...}, y2={...}}
	rooms_type_update: changes={{room_id, new_room_type}, ...}
]]
function RegionSystem:private_PushEvent(event, ...)
	if self.ListenForRegionEvent then
		self:ListenForRegionEvent(event, ...)
	end
end


return RegionSystem