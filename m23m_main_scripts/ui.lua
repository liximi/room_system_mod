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

	local mod_version = env.modinfo.version
	if mod_version == "dev" then
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
				local room_name
				local room_type = TheRegionMgr:GetRoomTypeAtPoint(mouse_pos.x, mouse_pos.z)
				if room_type == "NONE" then
					room_name = STRINGS.M23M_ROOMS.NONE.NAME
				end
				local room_def = TheRegionMgr:GetRoomData(room_type)
				if room_def and type(room_def.name) == "string" then
					room_name = room_def.name
				end
				if room_name then
					if str then
						str = str .. "\n" .. STRINGS.M23M_UI.ROOM .. ": " .. room_name
					else
						str = STRINGS.M23M_UI.ROOM .. ": " .. room_name
					end
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