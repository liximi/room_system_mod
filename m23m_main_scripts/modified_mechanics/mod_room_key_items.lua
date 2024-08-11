local WALLS = {
    "wall_stone",
    "wall_stone_2",
    "wall_wood",
    "wall_hay",
    "wall_ruins",
    "wall_ruins_2",
    "wall_moonrock",
    "wall_dreadstone",
    "wall_scrap",
    "fence",
}

local DOORS = {
    "fence_gate",
}


local function init_wall(inst)
    local pos = inst:GetPosition()
    local x, y = TheRegionMgr:GetTileCoordsAtPoint(pos.x, pos.z)
    -- print("Add Wall", inst.prefab, pos, "tile coords:", x, y)
    TheRegionMgr:AddWalls({{x, y}})
end
local function on_remove_wall(inst)
    local pos = inst:GetPosition()
    local x, y = TheRegionMgr:GetTileCoordsAtPoint(pos.x, pos.z)
    -- print("Remove Wall", inst.prefab, pos, "tile coords:", x, y)
    TheRegionMgr:RemoveWalls({{x, y}})
end
for _, wall in ipairs(WALLS) do
    AddPrefabPostInit(wall, function(inst)
        if TheWorld.ismastersim then
            inst:DoTaskInTime(0, init_wall)
            inst:ListenForEvent("onremove", on_remove_wall)
        end
    end)
end


local function init_door(inst)
    local pos = inst:GetPosition()
    local x, y = TheRegionMgr:GetTileCoordsAtPoint(pos.x, pos.z)
    -- print("Add Door", inst.prefab, pos, "tile coords:", x, y)
    TheRegionMgr:AddDoors({{x, y}})
end
local function on_remove_door(inst)
    local pos = inst:GetPosition()
    local x, y = TheRegionMgr:GetTileCoordsAtPoint(pos.x, pos.z)
    -- print("Remove Door", inst.prefab, pos, "tile coords:", x, y)
    TheRegionMgr:RemoveDoors({{x, y}})
end
for _, door in ipairs(DOORS) do
    AddPrefabPostInit(door, function(inst)
        if TheWorld.ismastersim then
            inst:DoTaskInTime(0, init_door)
            inst:ListenForEvent("onremove", on_remove_door)
        end
    end)
end


--------------------------------------------------


local function CheckPosition(inst)
    if TheWorld.ismastersim then
        if not inst.components.m23m_room_key_item then
            inst:AddComponent("m23m_room_key_item")
        end
    end
end

local function check_color_data_structure(val)
	if type(val) ~= "table" or (#val ~= 3 and #val ~= 4) then
		return false
	end
	for i, v in ipairs(val) do
		if not (type(v) == "number" and v >= 0 and v <= 1) then
			return false
		end
	end
	return true
end

local function check_tiles_data_structure(val)
	if type(val) ~= "table" then
		return false
	end
	for k, v in pairs(val) do
		if type(k) ~= "string" or not WORLD_TILES[k] or not v then
			return false
		end
	end
	return true
end

local function check_mustitems_data_structure(val)	--只能是string数组, 只能嵌套两层, 不能为空表
	if type(val) ~= "table" or #val == 0 then
		return false
	end
	for i, v in ipairs(val) do
		if type(v) == "table" then
			if #v == 0 then
				return false
			end
			for j, vv in ipairs(v) do
				if type(vv) ~= "string" then
					return false
				end
			end
		elseif type(v) ~= "string" then
			return false
		end
	end
	return true
end

local key_items = {}

--需要在主机和客机都调用
function _G.AddM23MRoom(room_data)
	if type(room_data) ~= "table" or type(room_data.type) ~= "string" then
		print("RegionSystem Error: Add Room Failed! Invalid Room Data Structure.")
		return
	end

	local max_priority = 0
	for i, v in ipairs(M23M.ROOM_DEFS) do
		if v.type == room_data.type then
			print(string.format("RegionSystem Error: Add Room(%s) Failed! Room Existed.", room_data.type))
			return
		end
		if v.priority > max_priority then
			max_priority = v.priority
		end
	end
	local room_def = {
		type = room_data.type,
		name = (type(room_data.name) == "string" or type(room_data.name) == "function") and room_data.name or STRINGS.M23M_ROOMS.NO_NAME.NAME,
		desc = (type(room_data.desc) == "string" or type(room_data.desc) == "function") and room_data.desc or STRINGS.M23M_ROOMS.NO_NAME.DESC,
		min_size = type(room_data.min_size) == "number" and math.ceil(room_data.min_size) or 16,
		max_size = type(room_data.max_size) == "number" and math.ceil(room_data.max_size) or 128,
		priority = type(room_data.priority) == "number" and math.ceil(room_data.priority) or max_priority + 1,
		color = check_color_data_structure(room_data.color) and room_data.color or {math.random(), math.random(), math.random(), 1},
		available_tiles = check_tiles_data_structure(room_data.available_tiles) and room_data.available_tiles or nil,
	}

	if type(room_data.icon_atlas) == "string" and type(room_data.icon_image) == "string" then
		room_def.icon_atlas = room_data.icon_atlas
		room_def.icon_image = room_data.icon_image
	end

	if check_mustitems_data_structure(room_data.must_items) then
		room_def.must_items = room_data.must_items
	else
		print(string.format("RegionSystem Error: Add Room(%s) Failed! Data Structure of must_items is Wrong or must_items is nil.", room_data.type))
		return
	end
	table.insert(M23M.ROOM_DEFS, room_def)
	table.sort(M23M.ROOM_DEFS, function(a, b) return (a.priority or 1) > (b.priority or 1) end)

    if type(room_def.must_items) == "table" then
		for _, items in ipairs(room_def.must_items) do
			if type(items) == "table" then
				for _, item in ipairs(items) do
                    if not key_items[item] then
                        AddPrefabPostInit(item, CheckPosition)
                        key_items[item] = true
                    end
				end
			elseif not key_items[items] then
                AddPrefabPostInit(items, CheckPosition)
                key_items[items] = true
            end
		end
	end

	if TheRegionMgr then
		TheRegionMgr:RegisterRoomType(room_def.type)
	end
	print(string.format("RegionSystem Info: Add Room(%s) Success!", room_data.type))
	return true
end

--注册房间
if M23M.ENABLE_DEFAULT_ROOMS then
	require "m23m_room_def"
end