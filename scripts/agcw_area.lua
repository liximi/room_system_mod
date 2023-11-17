local AREA_TYPE = AGCW.AREA_TYPE
local AREA_TYPE_IDX = {}
for k, v in pairs(AREA_TYPE) do
	AREA_TYPE_IDX[v] = k
end


local function IsValidType(area_type)
	return type(area_type) == "number" and AREA_TYPE_IDX[area_type] ~= nil
end

local function GetTypeStringKey(area_type)
	return type(area_type) == "number" and AREA_TYPE_IDX[area_type] or nil
end

------------------------------
-- Area
------------------------------

local Area = Class(function(self, id, tiles, area_type)
	self.id = id
	self.tiles = tiles or {}		--由x和y组成的二维数组{x={y=true}}
	self.type = IsValidType(area_type) and area_type or AREA_TYPE.NONE
end)

function Area:GetID()
	return self.id
end

function Area:GetTiles()
	return self.tiles
end

function Area:GetType()
	return self.type
end

function Area:GetTileCount()

end


return {
	IsValidType = IsValidType,
	GetTypeStringKey = GetTypeStringKey,
	Area = Area,
}