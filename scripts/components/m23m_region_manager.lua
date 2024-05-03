local REGION_SYS = require "region_system/region_system"

local RegionSystem = Class(REGION_SYS, function (self, inst)
	self.inst = inst
end)


function RegionSystem:GetTileCoordsAtPoint(x, y)
	return math.floor(x) + math.ceil(self.width/2), math.floor(y) + math.ceil(self.height/2)
end

function RegionSystem:GetPointAtTileCoords(x, y)
	return x - math.ceil(self.width/2) + 0.5, y - math.ceil(self.height/2) + 0.5
end


return RegionSystem