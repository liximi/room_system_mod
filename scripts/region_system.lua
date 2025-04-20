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

local function get_tile_index(x, y, width)
	return (y - 1) * width + x
end

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

local function flood_fill(tiles, map_width, cur_x, cur_y, can_visit, on_visit, visited, prev_x, prev_y)
	local tile_index = get_tile_index(cur_x, cur_y, map_width)

	if tiles[tile_index] == nil then return end
	if not visited then visited = {} end
	if visited[tile_index] then return end
	visited[tile_index] = true
	if can_visit and not can_visit(cur_x, cur_y, prev_x, prev_y) then
		return
	end

	if on_visit then
		on_visit(cur_x, cur_y)
	end

	flood_fill(tiles, map_width, cur_x + 1, cur_y, can_visit, on_visit, visited, cur_x, cur_y)
	flood_fill(tiles, map_width, cur_x, cur_y + 1, can_visit, on_visit, visited, cur_x, cur_y)
	flood_fill(tiles, map_width, cur_x - 1, cur_y, can_visit, on_visit, visited, cur_x, cur_y)
	flood_fill(tiles, map_width, cur_x, cur_y - 1, can_visit, on_visit, visited, cur_x, cur_y)
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

--<param> tiles:传递整个地图的region属性的数组进来 </param>
local function get_edges(tiles, x, y, dir_x, dir_y, adjacent_dir_x, adjacent_dir_y, max_len, map_width, map_height)
	local edges = {}
	local new_start = true

	for i = 0, max_len - 1 do
		local cur_x, cur_y = x + dir_x * i, y + dir_y * i
		local index = get_tile_index(cur_x, cur_y, map_width)
		local self_region = tiles[index]
		assert(self_region ~= nil, string.format("get_edges: self_region is nil, cur_x:%s, cur_x:%s", tostring(cur_x), tostring(cur_y)))

		local adjacent_y = cur_y + adjacent_dir_y
		local adjacent_x = cur_x + adjacent_dir_x
		local target_region
		if adjacent_y <= map_height and adjacent_y >= 0 and adjacent_x <= map_width and adjacent_x >= 0 then
			local adjacent_index = get_tile_index(adjacent_x, adjacent_y, map_width)
			target_region = tiles[adjacent_index]
		end
		if self_region ~= 0 and target_region ~= nil and target_region ~= 0 then
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
_G.REGION_SYS_TILE_KEYS = {	--地块数据的key
	SPACE = 1,
	REGION = 2,
	IS_DOOR = 3,
}

local RegionSystem = {
	DIR = DIR,
	DIR_REVERSE = DIR_REVERSE,

	width = 0,
	height = 0,
	max_index = 0,
	section_width = 0,
	section_height = 0,
	tiles = {},
	-- 除了Generation, 永远不要修改tiles[y][x]的引用
	--[[tiles 地块数据，每个元素都是一个一维数组，起长度等于地图里的地块数量(width * height)
		key与REGION_SYS_TILE_KEYS里每个属性的值对应
		1: 该地块是否是可通过的空地, true表示为空, false/nil表示有墙体或其他阻碍物
		2: 切片分组ID, 整数, space为false的地块region固定为0
		3: 该地块是否是门
	]]
	regions = {},	--不记录ID为0的region, {tiles = {tile_index = true, ...}, tiles_count = int, passable_edges = {target_region_id = {edge_code, ...}}, room = int}
	rooms = {},		--不记录ID为0的房间, {regions = {array of region's id}, type = int(ROOM_TYPES)}
}


--#region 获取地块数据接口

--<param> key: 传递一个int, 建议使用REGION_SYS_TILE_KEYS枚举，如果为空，则用一个table返回所有属性，key为string，对应REGION_SYS_TILE_KEYS里的key </param>
--<return> 如果返回值为nil，说明没有获取到值 </return>
function RegionSystem:GetTile(x, y, key)
	if x > self.width then
		print("GetTile Error: x > self.width")
		return
	end
	if y > self.height then
		print("GetTile Error: y > self.height")
		return
	end
	if key ~= nil and not self.tiles[key] then
		print("GetTile Error: key not found")
		return
	end
	local index = (y - 1) * self.width + x
	if index > self.max_index then
		print("GetTile Error: index out of range")
		return
	end
	if key == nil then
		local result = {}
		for k, v in pairs(REGION_SYS_TILE_KEYS) do
			result[k] = self.tiles[v][index]
		end
		return result
	else
		return self.tiles[key][index]
	end
end

--<param> key: 传递一个int, 建议使用REGION_SYS_TILE_KEYS枚举，如果为空，则用一个table返回所有属性，key为string，对应REGION_SYS_TILE_KEYS里的key </param>
--<return> 如果返回值为nil，说明没有获取到值 </return>
function RegionSystem:GetTileByIndex(index, key)
	if key ~= nil and not self.tiles[key] then
		print("GetTile Error: key not found")
		return
	end
	if index > self.max_index then
		print("GetTile Error: index out of range")
		return
	end
	if key == nil then
		local result = {}
		for k, v in pairs(REGION_SYS_TILE_KEYS) do
			result[k] = self.tiles[v][index]
		end
		return result
	else
		return self.tiles[key][index]
	end
end

--<summary> 工具函数，只负责计算，不负责验证 </summary>
function RegionSystem:GetPositionByIndex(tile_index)
	local y = math.floor(math.max(0, tile_index - 1) / self.width) + 1
	local x = tile_index - (y - 1) * self.width
	return x, y
end

--<summary> 工具函数，只负责计算，不负责验证 </summary>
function RegionSystem:GetTileIndex(x, y)
	return (y - 1) * self.width + x
end

--#region 初始化、更新函数

function RegionSystem:Generation(width, height, section_width, section_height)
	self.width = width
	self.height = height
	self.max_index = width * height
	self.section_width = section_width or self.width
	self.section_height = section_height or self.height
	self.tiles = {}
	for k, v in pairs(REGION_SYS_TILE_KEYS) do
		self.tiles[v] = {}
	end
	for i = 1, height do
		for j = 1, width do
			table.insert(self.tiles[REGION_SYS_TILE_KEYS.SPACE], true)
			table.insert(self.tiles[REGION_SYS_TILE_KEYS.REGION], 0)
			table.insert(self.tiles[REGION_SYS_TILE_KEYS.IS_DOOR], false)
		end
	end
	--初始切片
	self:private_NewRoom(1)
	local region_id = 1
	for base_i = 1, self.height, self.section_height do
		for base_j = 1, self.width, self.section_width do
			local region_tiles = {}		--地块index数组
			local tiles_count = 0

			for i = 0, self.section_height - 1 do
				local y = base_i + i
				if y > self.height then break end
				for j = 0, self.section_width - 1 do
					local x = base_j + j
					if x > self.width then break end
					local index = self:GetTileIndex(x, y)
					self.tiles[REGION_SYS_TILE_KEYS.REGION][index] = region_id
					region_tiles[index] = true
					tiles_count = tiles_count + 1
				end
			end

			local region = self:private_NewRegion(region_id)
			region.tiles = region_tiles
			region.tiles_count = tiles_count
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
	local section_tiles = self:GetAllTilesInSection(x, y, REGION_SYS_TILE_KEYS.IS_DOOR)
	if not section_tiles then return end

	local function can_visit(cur_x, cur_y, prev_x, prev_y)
		if not self:IsPassable(cur_x, cur_y) then
			return false
		end
		if not prev_x or not prev_y then
			return true
		end
		if not self:IsPassable(prev_x, prev_y) then
			return false
		end
		return self:IsWater(cur_x, cur_y) == self:IsWater(prev_x, prev_y)
	end

	local region_index
	local doors = {}
	local function on_visit(cur_x, cur_y)
		local index = self:GetTileIndex(cur_x, cur_y)
		if section_tiles[index] then
			table.insert(doors, {cur_x, cur_y})
		end

		if not self.regions[region_index] then
			self:private_NewRegion(region_index)
		end
		self:private_AddTileToRegion(cur_x, cur_y, region_index)

		section_tiles[index] = nil
	end

	--泛洪算法更新region
	while not is_empty_table(section_tiles) do
		for tile_index, is_door in pairs(section_tiles) do
			local cur_x, cur_y = self:GetPositionByIndex(tile_index)
			if self:IsPassable(tile_index) then
				region_index = get_empty_num_index(self.regions) + 1
				flood_fill(section_tiles, self.width, cur_x, cur_y, can_visit, on_visit)
			else
				self:private_AddTileToRegion(cur_x, cur_y, 0)
				section_tiles[tile_index] = nil
			end
		end
	end

	--把门拆到独立的region里
	for _, door_pos in ipairs(doors) do
		region_index = get_empty_num_index(self.regions) + 1
		self:private_NewRegion(region_index)
		self:private_AddTileToRegion(door_pos[1], door_pos[2], region_index)
	end

	--更新section内的region与其他region相接的边缘
	self:RefreashSectionEdges(x, y)
end

--<param> x:section最小的x坐标 </param>
--<param> y:section最小的y坐标 </param>
function RegionSystem:RefreashSectionEdges(x, y)
	local base_x = math.floor((x-1) / self.section_width) * self.section_width + 1
	local base_y = math.floor((y-1) / self.section_height) * self.section_width + 1
	if not self:IsVaildPosition(base_x, base_y) then
		return
	end
	local section_height = math.min(self.section_height, self.height - base_y + 1)
	local section_width = math.min(self.section_width, self.width - base_x + 1)
	--section外边缘
	for region1, target_regions in pairs(get_edges(self.tiles[REGION_SYS_TILE_KEYS.REGION], base_x, base_y, 0, 1, -1, 0, section_height, self.width, self.height)) do
		for region2, edges in pairs(target_regions) do
			self.regions[region1].passable_edges[region2] = edges
			self.regions[region2].passable_edges[region1] = edges
		end
	end
	for region1, target_regions in pairs(get_edges(self.tiles[REGION_SYS_TILE_KEYS.REGION], base_x + section_width - 1, base_y, 0, 1, 1, 0, section_height, self.width, self.height)) do
		for region2, edges in pairs(target_regions) do
			self.regions[region1].passable_edges[region2] = edges
			self.regions[region2].passable_edges[region1] = edges
		end
	end
	for region1, target_regions in pairs(get_edges(self.tiles[REGION_SYS_TILE_KEYS.REGION], base_x, base_y, 1, 0, 0, -1, section_width, self.width, self.height)) do
		for region2, edges in pairs(target_regions) do
			self.regions[region1].passable_edges[region2] = edges
			self.regions[region2].passable_edges[region1] = edges
		end
	end
	for region1, target_regions in pairs (get_edges(self.tiles[REGION_SYS_TILE_KEYS.REGION], base_x, base_y + section_height - 1, 1, 0, 0, 1, section_width, self.width, self.height)) do
		for region2, edges in pairs(target_regions) do
			self.regions[region1].passable_edges[region2] = edges
			self.regions[region2].passable_edges[region1] = edges
		end
	end
	--section内的门
	for i = base_y, math.min(base_y + self.section_height - 1, self.height) do
		for j = base_x, math.min(base_x + self.section_width - 1, self.width) do
			if self:GetTile(j, i, REGION_SYS_TILE_KEYS.IS_DOOR) then
				for region1, target_regions in pairs(get_edges(self.tiles[REGION_SYS_TILE_KEYS.REGION], j, i, 0, 1, -1, 0, 1, self.width, self.height)) do
					for region2, edges in pairs(target_regions) do
						self.regions[region1].passable_edges[region2] = edges
						self.regions[region2].passable_edges[region1] = edges
					end
				end
				for region1, target_regions in pairs(get_edges(self.tiles[REGION_SYS_TILE_KEYS.REGION], j, i, 0, 1, 1, 0, 1, self.width, self.height)) do
					for region2, edges in pairs(target_regions) do
						self.regions[region1].passable_edges[region2] = edges
						self.regions[region2].passable_edges[region1] = edges
					end
				end
				for region1, target_regions in pairs(get_edges(self.tiles[REGION_SYS_TILE_KEYS.REGION], j, i, 1, 0, 0, -1, 1, self.width, self.height)) do
					for region2, edges in pairs(target_regions) do
						self.regions[region1].passable_edges[region2] = edges
						self.regions[region2].passable_edges[region1] = edges
					end
				end
				for region1, target_regions in pairs (get_edges(self.tiles[REGION_SYS_TILE_KEYS.REGION], j, i, 1, 0, 0, 1, 1, self.width, self.height)) do
					for region2, edges in pairs(target_regions) do
						self.regions[region1].passable_edges[region2] = edges
						self.regions[region2].passable_edges[region1] = edges
					end
				end
			end
		end
	end
end

--<summary> 遍历全部region, 刷新房间 </summary>
function RegionSystem:RefreashRooms()
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

--#endregion
--------------------------------------------------
--#region 地块状态判断

--<param> x: 地块x坐标，当y为nil时，会将x当作地块的index </param>
--<param> y: 地块y坐标 </param>
function RegionSystem:IsPassable(x, y)
	if y == nil then
		return self:GetTileByIndex(x, REGION_SYS_TILE_KEYS.SPACE) == true
	else
		return self:GetTile(x, y, REGION_SYS_TILE_KEYS.SPACE) == true
	end
end

function RegionSystem:IsWater(x, y)		--需要在子类中覆写该函数
end

function RegionSystem:IsDoorRegion(region_id)
	if not region_id then return false end
	local region = self.regions[region_id]
	if not region then return false end
	local tile_count = 0
	local is_door = false
	for tile_index, _ in pairs(region.tiles) do
		if tile_count >= 1 then
			return false
		end
		tile_count = tile_count + 1
		if self:GetTileByIndex(tile_index, REGION_SYS_TILE_KEYS.IS_DOOR) == true then
			is_door = true
		end
	end
	return is_door
end

function RegionSystem:IsInRoom(x, y, room_type)
	return room_type == self:GetRoomType(x, y)
end

--<summary> 检查坐标是否在地图内 </summary>
function RegionSystem:IsVaildPosition(x, y)
	if x > self.width or x <= 0 or y > self.height or y <= 0 then
		return false
	end
	return true
end

--#endregion
--------------------------------------------------
--#region 分区Section相关

function RegionSystem:GetSectionAABB(x, y)
	local base_x = math.floor((x-1) / self.section_width) * self.section_width + 1
	local base_y = math.floor((y-1) / self.section_height) * self.section_width + 1
	if not self:IsVaildPosition(base_x, base_y) then
		return
	end
	return base_x, base_y, math.min(base_x + self.section_width - 1, self.width), math.min(base_y + self.section_height - 1, self.height)
end

--<summary> 通过坐标获取该坐标所属的切片内的所有地块 </summary>
function RegionSystem:GetAllTilesInSection(x, y, key)
	local base_x = math.floor((x-1) / self.section_width) * self.section_width + 1
	local base_y = math.floor((y-1) / self.section_height) * self.section_width + 1
	if not self:IsVaildPosition(base_x, base_y) then
		return
	end
	local tiles = {}
	for i = base_y, math.min(base_y + self.section_height - 1, self.height) do
		for j = base_x, math.min(base_x + self.section_width - 1, self.width) do
			local index = self:GetTileIndex(j, i)
			tiles[index] = self:GetTileByIndex(index, key)
		end
	end

	return tiles
end

--#endregion
--------------------------------------------------
--#region 查询数据

function RegionSystem:GetRegionId(x, y)
	return self:GetTile(x, y, REGION_SYS_TILE_KEYS.REGION)
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

--<summary> 不要修改返回的表 </summary>
function RegionSystem:GetAllRegionsInRoom(room_id)
	if not room_id or not self.rooms[room_id] then
		return {}
	end
	return self.rooms[room_id].regions
end

--<summary> 性能很差 </summary>
function RegionSystem:GetAllTilesInRoom(room_id)
	local regions = self:GetAllRegionsInRoom(room_id)
	local tiles = {}
	for _, region_id in ipairs(regions) do
		local region = self.regions[region_id]
		if region then
			for tile_index, _ in pairs(region.tiles) do
				tiles[tile_index] = self:GetTileByIndex(tile_index)
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

function RegionSystem:GetDataInRegion(region_id, key)
	if not self.regions[region_id] or type(key) ~= "string" then
		return
	end
	return self.regions[region_id][key]
end

--#endregion
--------------------------------------------------
--#region 解码region边缘代码


function RegionSystem:DeCodeEdge(edge_code)
	local x, y, dir, length = decode_edge(edge_code)
	return {x = x, y = y, dir = dir, length = length}
end

--#endregion
--------------------------------------------------
--#region 添加/移除墙体和门

function RegionSystem:AddWalls(walls)	--{x, y}
	local space_datas = {}
	for i, pos in ipairs(walls) do
		local x, y = pos[1], pos[2]
		if self:GetTile(x, y, REGION_SYS_TILE_KEYS.SPACE) == true then
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
		local index = self:GetTileIndex(x, y)
		if self:GetTileByIndex(index, REGION_SYS_TILE_KEYS.SPACE) == false and self:GetTileByIndex(index, REGION_SYS_TILE_KEYS.IS_DOOR) == false then
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
		local index = self:GetTileIndex(x, y)
		if self:GetTileByIndex(index, REGION_SYS_TILE_KEYS.SPACE) == true then
			self.tiles[REGION_SYS_TILE_KEYS.IS_DOOR][index] = true
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
		local index = self:GetTileIndex(x, y)
		if self:GetTileByIndex(index, REGION_SYS_TILE_KEYS.SPACE) == false and self:GetTileByIndex(index, REGION_SYS_TILE_KEYS.IS_DOOR) == true then
			self.tiles[REGION_SYS_TILE_KEYS.IS_DOOR][index] = false
			table.insert(space_datas, {x, y, true})
		end
	end

	if #space_datas == 1 then
		self:private_SetSpace(space_datas[1][1], space_datas[1][2], space_datas[1][3])
	else
		self:private_SetSpaceBatch(space_datas)
	end
end

--#endregion
--------------------------------------------------
--#region 房间相关

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

function RegionSystem:SetDataToRegion(region_id, key, data)
	if not self.regions[region_id] or type(key) ~= "string" then
		return false
	end
	self.regions[region_id][key] = data
	return true
end

--#endregion
--------------------------------------------------
--#region 打印数据

function RegionSystem:Print(data_key, sub_key, only_one_section, x, y)
	data_key = data_key or REGION_SYS_TILE_KEYS.SPACE
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
			local index = self:GetTileIndex(j, i)
			local data = self:GetTileByIndex(index, data_key)
			if sub_key and type(data) == "table" then
				table.insert(line, tostring(data[sub_key]))
			else
				table.insert(line, tostring(data))
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

function RegionSystem:PrintRoomData()
	for id, data in pairs(self.rooms) do
		print(string.format("Room: %d, Type: %s", id, ROOM_TYPES[data.type]))
		print("  ", table.concat(data.regions, ", "))
	end
end

--#endregion
--------------------------------------------------
--#region 虚函数，有需要可以在子类中实现

-- function RegionSystem:RefreashRoomType(room_id) end	用于更新房间类型，在需要更新房间类型时被调用
-- function RegionSystem:OnChangeTileRegion(x, y, old_region_id, new_region_id, refreash_room) end	当地块所属的region发生变化时被调用
-- function RegionSystem:ListenForRegionEvent(event, ...) end	监听抛出的事件，参见private_PushEvent函数

--#endregion

--------------------------------------------------
-- 私有函数 Private Functions
--------------------------------------------------

function RegionSystem:private_SetSpace(x, y, space)
	local index = self:GetTileIndex(x, y)
	assert(index <= self.max_index, string.format("AddTileToRegion Error: index out of range, x:%s, y:%s", tostring(x), tostring(y)))
	self.tiles[REGION_SYS_TILE_KEYS.SPACE][index] = space == true
	self:RefreashSection(x, y)
	self:RefreashRooms()
	self:private_PushEvent("section_update_single", x, y)
end

function RegionSystem:private_SetSpaceBatch(datas)	-- {x, y, space}, private_SetSpace的批处理版本, 在需要更新的地块较多时性能较好
	local sections = {}		-- y = {x = true}
	for _, data in ipairs(datas) do
		local x, y = data[1], data[2]
		local index = self:GetTileIndex(x, y)
		assert(index <= self.max_index, string.format("AddTileToRegion Error: index out of range, x:%s, y:%s", tostring(x), tostring(y)))
		self.tiles[REGION_SYS_TILE_KEYS.SPACE][index] = data[3] == true
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
		tiles_count = 0,
		passable_edges = {},
		room = 0,
	}
	self.regions[region_id] = region
	return region
end

function RegionSystem:private_AddTileToRegion(x, y, region_id)
	local tile_index = self:GetTileIndex(x, y)
	assert(tile_index <= self.max_index, string.format("AddTileToRegion Error: index out of range, x:%s, y:%s", tostring(x), tostring(y)))
	local old_region_id = self:GetTileByIndex(tile_index, REGION_SYS_TILE_KEYS.REGION)
	local old_region = self.regions[old_region_id]
	local old_region_tiles = old_region and old_region.tiles
	if old_region_tiles then
		old_region_tiles[tile_index] = nil
		old_region.tiles_count = old_region.tiles_count - 1
		if is_empty_table(old_region_tiles) then
			self:private_DeleteRegion(old_region_id)
		end
	end

	if region_id ~= 0 then
		local region = self.regions[region_id]
		local region_tiles = region.tiles
		region_tiles[tile_index] = true
		region.tiles_count = region.tiles_count + 1
	end
	self.tiles[REGION_SYS_TILE_KEYS.REGION][tile_index] = region_id

	if self.OnChangeTileRegion then
		self:OnChangeTileRegion(x, y, old_region_id, region_id)
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