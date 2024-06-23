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


local ROOM_DEF = require "m23m_room_def"
local function CheckPosition(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("m23m_room_key_item")
    end
end
for _, data in pairs(ROOM_DEF) do
	if type(data.must_items) == "table" then
		for _, items in ipairs(data.must_items) do
			if type(items) == "table" then
				for _, item in ipairs(items) do
					AddPrefabPostInit(item, CheckPosition)
				end
			else
				AddPrefabPostInit(items, CheckPosition)
			end
		end
	end
end