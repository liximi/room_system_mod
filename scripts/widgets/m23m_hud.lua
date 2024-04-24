local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Templates = require "widgets/redux/templates"

local HUD = Class(Widget, function(self, owner)
    Widget._ctor(self, "IndustHUD")
	self.owner = owner
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)

	--ROOTS
	self.top_root = self:AddChild(Widget("ROOT"))
	self.top_root:SetVAnchor(ANCHOR_TOP)
	self.top_root:SetHAnchor(ANCHOR_MIDDLE)

	--区域编辑按钮
	-- self.edit_region_btn = self.top_root:AddChild(Templates.StandardButton(function () self:PopupAreaEditScreen() end,
	-- 	"区域编辑", {200, 50}))
	-- self.edit_region_btn:SetPosition(0, -120)

	self.rects = {}

	self:UpdateWhilePaused(false)
	self:StartUpdating()
end)


function HUD:PopupAreaEditScreen()
	ThePlayer:ShowPopUp(POPUPS.M23M_AREA_EDIT, true)
end


local max_tile_count = 100
function HUD:OnUpdate(dt)
	local pos = TheInput:GetWorldPosition()
	if TheRegionMgr and pos then
		local region_x, region_y = TheRegionMgr:GetRegionCoordsAtPoint(pos.x, pos.z)
		local room_id = TheRegionMgr:GetRoomId(region_x, region_y)
		local regions = TheRegionMgr:GetAllRegionsInRoom(room_id)
		local tiles = {}
		local tiles_num = 0
		for _, region_id in ipairs(regions) do
			local region = TheRegionMgr:GetRegion(region_id)
			if region then
				for _, tile in ipairs(region.tiles) do
					table.insert(tiles, tile)
					tiles_num = tiles_num + 1
					if tiles_num > max_tile_count then break end
				end
			end
			if tiles_num > max_tile_count then break end
		end
		if tiles_num <= max_tile_count then
			local delta_num = tiles_num - #self.rects
			if delta_num < 0 then
				for i = -1, delta_num, -1 do
					table.remove(self.rects):Remove()
				end
			elseif delta_num > 0 then
				for i = 1, delta_num, 1 do
					local rect = SpawnPrefab("m23m_rectangle")
					rect:SetSize(1, 1)
					table.insert(self.rects, rect)
				end
			end
			for i, tile in ipairs(tiles) do
				local rect = self.rects[i]
				if rect then
					local x, y = TheRegionMgr:GetPointOfTileCoords(tile.x, tile.y)
					rect.Transform:SetPosition(x, 0, y)
				end
			end
		else
			-- print("WARNING: 房间内的地块数量超出"..tostring(max_tile_count))
		end
	end
end


return HUD