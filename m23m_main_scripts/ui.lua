local Text = require "widgets/text"

AddClassPostConstruct("widgets/widget", function(self)
	local old_kill = self.Kill
	function self:Kill()
		if self.OnKill then
			self:OnKill()
		end
		old_kill(self)
	end
end)

local HUD = require "widgets/m23m_hud"
AddClassPostConstruct("widgets/controls", function(self)
	--添加新UI
	self.m23m_hud = self:AddChild(HUD(self.owner))
	self.m23m_hud:MoveToFront()

	if LiximiIsDevMode() then
		self.xp = self:AddChild(Text(UIFONT, 16, "x正"))
		self.xn = self:AddChild(Text(UIFONT, 16, "x负"))
		self.zp = self:AddChild(Text(UIFONT, 16, "z正"))
		self.zn = self:AddChild(Text(UIFONT, 16, "z负"))

		self.inst:DoPeriodicTask(FRAMES, function()
			local pos = ThePlayer:GetPosition()
			self.xp:SetPosition(TheSim:GetScreenPos((pos + Vector3(1.2, 0, 0)):Get()))
			self.xn:SetPosition(TheSim:GetScreenPos((pos + Vector3(-1.2, 0, 0)):Get()))
			self.zp:SetPosition(TheSim:GetScreenPos((pos + Vector3(0, 0, 1.2)):Get()))
			self.zn:SetPosition(TheSim:GetScreenPos((pos + Vector3(0, 0, -1.2)):Get()))
		end)
	end
end)


AddClassPostConstruct("widgets/hoverer", function(self)
	local old_OnUpdate = self.OnUpdate
	function self:OnUpdate()
		old_OnUpdate(self)
		local str = self.str
		local is_on_ui = TheInput:GetHUDEntityUnderMouse()
		if ThePlayer.is_room_view_active and not is_on_ui then
			local mouse_pos = TheInput:GetWorldPosition()
			if mouse_pos then
				local room_name = "Room Without Name"
				local room_type = TheRegionMgr:GetRoomTypeAtPoint(mouse_pos.x, mouse_pos.z)
				if room_type == "NONE" then
					room_name = STRINGS.M23M_ROOMS.NONE.NAME
				end
				local room_def = TheRegionMgr:GetRoomData(room_type)
				if room_def and type(room_def.name) == "string" then
					room_name = room_def.name
				end
				local added_str = STRINGS.M23M_UI.ROOM .. ": " .. room_name
				local x, y = TheRegionMgr:GetTileCoordsAtPoint(mouse_pos.x, mouse_pos.z)
				local room_id = TheRegionMgr:GetRoomId(x, y)
				local room_size = TheRegionMgr:GetRoomSize(room_id, M23M.TOO_LARGE_ROOM_SIZE)
				if room_size ~= nil then
					added_str = added_str .. "\n" .. STRINGS.M23M_UI.ROOM_SIZE .. room_size
					added_str = added_str .. "\n" .. STRINGS.M23M_UI.INCLUDED_TILES
					local tiles_type_include = TheRegionMgr:GetTilesTypeIncludeInRoom(room_id)
					for tile_type, _ in pairs(tiles_type_include) do
						local tile_name = GetTileItemName(tile_type)
						added_str = added_str .. "\n" .. tile_name
					end
					if IsEmptyTable(tiles_type_include) then
						added_str = added_str .. "\n" .. STRINGS.M23M_UI.NONE
					end
				else
					added_str = added_str .. "\n" .. STRINGS.M23M_UI.ROOM_TOO_LARGE
				end
				if str then
					str = str .. "\n" .. added_str
				else
					str = added_str
				end
			end
		end

		if str == nil then
			self.text:Hide()
		else
			if self.strFrames <= 0 then
				self.text:SetString(str)
				self.text:Show()
			end
		end

		local changed = self.str ~= str
		self.str = str
		if changed then
			local pos = TheInput:GetScreenPosition()
			self:UpdatePosition(pos.x, pos.y)
		end
	end
end)