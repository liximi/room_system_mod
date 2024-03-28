local m23m_area = require "m23m_area"
local IsValidType = m23m_area.IsValidType
local GetTypeStringKey = m23m_area.GetTypeStringKey
local Area = m23m_area.Area
local AREA_TYPE = M23M.AREA_TYPE


------------------------------
-- AreaManager
------------------------------

local AreaManager = Class(function(self, inst)
    self.inst = inst

	self.areas = {}
	for k, v in pairs(AREA_TYPE) do
		self.areas[k] = {}
	end
end)


function AreaManager:AddArea(tiles, area_type)	--tiles: 由x和y组成的二维数组{x={y=true}}; area_type: AREA_TYPE.xxx
	SendModRPCToServer(MOD_RPC[M23M.RPC_NAMESPACE].add_area, tiles, area_type)
end

function AreaManager:RemoveArea(id, area_might_type)	--area_might_type: AREA_TYPE.xxx
	SendModRPCToServer(MOD_RPC[M23M.RPC_NAMESPACE].remove_area, id, area_might_type)
end

function AreaManager:SetAreaType(id, area_type)
	if not IsValidType(area_type) then
		return
	end
	SendModRPCToServer(MOD_RPC[M23M.RPC_NAMESPACE].change_area_type, id, area_type)
end

function AreaManager:RefreshClientData(id, tiles, area_type, remove)
	print("RefreshClientData", id, tiles, area_type, remove)
	local area = self:GetAreaById(id, area_type)
	if not area then return end
	local key = GetTypeStringKey(area:GetType())
	if remove then
		self.areas[key][id] = nil
	else
		if tiles then
			area.tiles = tiles
		end
		if area_type then
			area.type = area_type
		end
	end
end

function AreaManager:GetAreaById(id, area_might_type)	--area_might_type: AREA_TYPE.xxx
	if IsValidType(area_might_type) then
		local area = self.areas[GetTypeStringKey(area_might_type)][id]
		if area then return area end
	end
	for area_type, areas in pairs(self.areas) do
		if areas[id] then
			return areas[id]
		end
	end
end

function AreaManager:GetIdByTile(tile, area_might_type)	--tile: {[1] = x, [2] = y}
	if IsValidType(area_might_type) then
		for id, area in pairs(self.areas[GetTypeStringKey(area_might_type)]) do
			local tiles = area:GetTiles()
			if tiles[tile[1]] and tiles[tile[1]][tile[2]] then
				return id
			end
		end
	end
	for area_type, areas in pairs(self.areas) do
		for id, area in pairs(areas) do
			local tiles = area:GetTiles()
			if tiles[tile[1]] and tiles[tile[1]][tile[2]] then
				return id
			end
		end
	end
end

function AreaManager:GetAreaByTile(tile, area_might_type)
	if IsValidType(area_might_type) then
		for id, area in pairs(self.areas[GetTypeStringKey(area_might_type)]) do
			local tiles = area:GetTiles()
			if tiles[tile[1]] and tiles[tile[1]][tile[2]] then
				return area
			end
		end
	end
	for area_type, areas in pairs(self.areas) do
		for id, area in pairs(areas) do
			local tiles = area:GetTiles()
			if tiles[tile[1]] and tiles[tile[1]][tile[2]] then
				return area
			end
		end
	end
end


--TODO

function AreaManager:AddTiles(id, tiles)

end

function AreaManager:RemoveTiles(id, tiles)
	
end


function AreaManager:GetDebugString()
	local s = ""
	for area_type, areas in pairs(self.areas) do
		for id, area in pairs(areas) do
			s = s .. "id: " .. id .. "  type: " .. tostring(area:GetType()) .. "\n    "
			local tiles = area:GetTiles()
			for x, zs in pairs(tiles) do
				for z, _ in pairs(zs) do
					s = s .. "{".. tostring(x) .. ", " .. tostring(z) .. "}"
				end
			end
			s = s .. "\n"
		end
	end
	return s
end


return AreaManager