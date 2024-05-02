local RegionSytem = require "scripts.region_system.region_system"
RegionSytem:Generation(64, 64, 16, 16)

local waters = {}
for i = 40, 50 do
	for j = 40, 50 do
		table.insert(waters, {i, j})
	end
end
RegionSytem:AddWaters(waters)


local walls = {}
local doors = {}
for i = 1, 20 do
	table.insert(walls, {9, i})
end
for i = 1, 20 do
	table.insert(walls, {12, i})
end
for i = 1, 10 do
	table.insert(walls, {i, 21})
end
for i = 13, 22 do
	table.insert(walls, {i, 21})
end
for i = 1, 13 do
	table.insert(walls, {i, 15})
end
table.insert(doors, {11, 21})
table.insert(doors, {12, 21})

RegionSytem:AddWalls(walls)
RegionSytem:AddDoors(doors)

local waters = {}
for i = 40, 45 do
	for j = 40, 47 do
		table.insert(waters, {i, j})
	end
end
RegionSytem:RemoveWaters(waters)


RegionSytem:Print("region")

-- local region_id = RegionSytem:GetRegionId(11, 19)
-- local edges = RegionSytem:GetRegionPassableEdges(region_id)
-- if edges then
-- 	for region, _edges in pairs(edges) do
-- 		for i, edge_code in ipairs(_edges) do
-- 			local edge = RegionSytem:DeCodeEdge(edge_code)
-- 			print(region_id, "->", region, ":", edge_code, ":", edge.x, edge.y, RegionSytem.DIR_REVERSE[edge.dir], edge.length)
-- 		end
-- 	end
-- end

-- print("----------")
-- for region_id, data in pairs(RegionSytem.regions) do
-- 	print(string.format("region: %d, room: %d", region_id, data.room))
-- end

print("----------")
for room_id, data in pairs(RegionSytem.rooms) do
	print(string.format("room: %d, regions: %s", room_id, table.concat(data.regions, ",")))
end