local m23m_area = require "m23m_area"
local IsValidType = m23m_area.IsValidType
local GetTypeStringKey = m23m_area.GetTypeStringKey
local Area = m23m_area.Area
local AREA_TYPE = M23M.AREA_TYPE
local json = require "json"


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


function AreaManager:AddArea(tiles, area_type, doer)	--tiles: 由x和y组成的二维数组{x={y=true}}; area_type: AREA_TYPE.xxx
	local id = UUID()
	local area = Area(id, tiles, area_type, doer)
	self.areas[GetTypeStringKey(area.type)][id] = area
	self:RefreshClientData(area)
	return id, area
end

function AreaManager:RemoveArea(id, area_might_type, doer)	--area_might_type: AREA_TYPE.xxx
	local area = self:GetAreaById(id, area_might_type)
	if area and doer == area.owner then
		self.areas[GetTypeStringKey(area.type)][id] = nil
		self:RefreshClientData(area, true)
		Delete_UUID(id)
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

function AreaManager:SetAreaType(id, area_type)
	if not IsValidType(area_type) then
		return false, "invalid area_type"
	end
	local area = self:GetAreaById(id)
	if not area then
		return false, "not find area"
	end

	if area_type == area.type then
		return true
	end
	self.areas[GetTypeStringKey(area.type)][id] = nil
	area.type = area_type
	self.areas[GetTypeStringKey(area.type)][id] = area
	self:RefreshClientData(area)
	return true
end

function AreaManager:RefreshClientData(area, remove)	--Area Instance
	print("RefreshClientData", area, remove)
	local userids = {}
	for _, player in ipairs(AllPlayers) do
		if TheNet:IsDedicated() or (TheWorld.ismastersim and player ~= ThePlayer) then
			table.insert(userids, player.userid)
		end
	end

	if remove then
		SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].remove_area, userids, area:GetID())
	else
		local tiles = area:GetTiles()
		local _tiles = {}
		for x, zs in pairs(tiles) do
			for z, _ in pairs(zs) do
				table.insert(_tiles, {x, z})	--由于json.encode会改变表结构，因此需要重新处理表结构
			end
		end
		SendModRPCToClient(CLIENT_MOD_RPC[M23M.RPC_NAMESPACE].refresh_area_data, userids, area:GetID(), json.encode(_tiles), area:GetType())
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