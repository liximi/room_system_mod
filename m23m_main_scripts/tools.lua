function _G.GetRandomPointRound(pt, radius)
	local rad = math.random() * math.pi * 2
	local r = math.random() * radius
	local offset_x = math.cos(rad) * r
	local offset_z = -math.sin(rad) * r
	return pt + Vector3(offset_x, 0, offset_z)
end

--[[检查一个坐标是否在给定的四边形内, 函数内没有做数据结构的检查, 请在调用前确保参数正确
    pos: {x = number, y = number}
    quad: table 按连续的顺序存入4个顶点的坐标({x = number, y = number})
]]
function _G.IsPointInsideConvexQuad(pos, quad)
    local side = nil
    for i = 1, 4 do
        local x1, y1 = quad[i].x, quad[i].y
        local next = i % 4 + 1
        local x2, y2 = quad[next].x, quad[next].y
        local curr_side = (x2 - x1) * (pos.y - y1) - (y2 - y1) * (pos.x - x1)
        if side == nil then
            side = curr_side
        elseif side * curr_side < 0 then
            return false
        end
    end
    return true
end

--[[获取一定半径内的所有地块的坐标]]
local tile_size = 4
function _G.GetTiles(x, z, radius)
	if radius == 0 then return {} end
	local tiles = {}
	local org = Vector3(x, 0, z)
	local org_tile_center = Vector3(TheWorld.Map:GetTileCenterPoint(x, 0, z))
	local org_offset = org - org_tile_center
	local top_count = math.ceil((org_offset.z + radius) / tile_size)
	local bottom_count = math.floor((org_offset.z - radius) / tile_size)
	local right_count = math.ceil((org_offset.x + radius) / tile_size)
	local left_count = math.floor((org_offset.x - radius) / tile_size)
	local radiusq = radius * radius

	for i = math.ceil(org_tile_center.x+left_count*tile_size), math.floor(org_tile_center.x+right_count*tile_size), 4 do
		for j = math.ceil(org_tile_center.z+bottom_count*tile_size), math.floor(org_tile_center.z+top_count*tile_size), 4 do
			local cur_pos = Vector3(i, 0, j)
			if org:DistSq(cur_pos) <= radiusq then
				table.insert(tiles, cur_pos)
			end
		end
	end

	return tiles
end

local hex_letters = {"A", "B", "C", "D", "E", "F"}
local function HexToString(hex)
	hex = math.floor(hex)
	if hex < 10 then
		return hex
	else
		return hex_letters[hex - 9]
	end
end
local spawned_uuids = {}
function _G.UUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local random = math.random
	local uuid
	while true do
		uuid = template:gsub("[xy]", function(c)
			local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
			return HexToString(v)
		end)
		if not spawned_uuids[uuid] then
			spawned_uuids[uuid] = true
			break
		end
	end
    return uuid
end

function _G.Delete_UUID(id)
	if type(id) == "string" then
		spawned_uuids[id] = nil
	end
end