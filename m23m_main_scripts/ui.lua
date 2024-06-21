local json = require "json"
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

	self.xp = self:AddChild(Text(UIFONT, 22, "X正"))
    self.xn = self:AddChild(Text(UIFONT, 22, "X负"))
    self.zp = self:AddChild(Text(UIFONT, 22, "Z正"))
    self.zn = self:AddChild(Text(UIFONT, 22, "Z负"))

    self.inst:DoPeriodicTask(FRAMES, function ()
        local pos = ThePlayer:GetPosition()
        self.xp:SetPosition(TheSim:GetScreenPos((pos+Vector3(2,0,0)):Get()))
        self.xn:SetPosition(TheSim:GetScreenPos((pos+Vector3(-2,0,0)):Get()))
        self.zp:SetPosition(TheSim:GetScreenPos((pos+Vector3(0,0,2)):Get()))
        self.zn:SetPosition(TheSim:GetScreenPos((pos+Vector3(0,0,-2)):Get()))
    end)
end)

--<编辑区域Screen>
local AreaEditScreen = require "screens/m23m_area_edit_screen"
AddClassPostConstruct("screens/playerhud", function(self)
	function self:Open_M23M_AreaEditScreen(data)
		self:Close_M23M_AreaEditScreen()
		self.m23m_area_edit_screen = AreaEditScreen(self.owner, data)
		self:OpenScreenUnderPause(self.m23m_area_edit_screen)
		return true
	end

	function self:Close_M23M_AreaEditScreen()
		if self.m23m_area_edit_screen ~= nil then
			if self.m23m_area_edit_screen.inst:IsValid() then
				TheFrontEnd:PopScreen(self.m23m_area_edit_screen)
			end
			self.m23m_area_edit_screen = nil
		end
	end
end)

local popup_area_edit = AddPopup("M23M_AREA_EDIT")
popup_area_edit.fn = function(inst, show, data)
	if type(data) == "string" then
		data = json.decode(data)
	end
    if inst.HUD then
        if not show then
            inst.HUD:Close_M23M_AreaEditScreen()
        elseif not inst.HUD:Open_M23M_AreaEditScreen(data) then
            POPUPS.M23M_AREA_EDIT:Close(inst)
        end
    end
end

-- require "widgets.hoverer"
-- 向鼠标悬浮文本中加入当前房间的信息, 直接复制了原本的OnUpdate进行修改
local SHOW_DELAY = 0
AddClassPostConstruct("widgets/hoverer",function(self)
    self.OnUpdate = function (self)
		if self.owner.components.playercontroller == nil or not self.owner.components.playercontroller:UsingMouse() then
			if self.shown then
				self:Hide()
			end
			return
		elseif not self.shown then
			if not self.forcehide then
				self:Show()
			else
				return
			end
		end

		local str = nil
		local colour = nil
		if not self.isFE then
			str = self.owner.HUD.controls:GetTooltip() or self.owner.components.playercontroller:GetHoverTextOverride()
			self.text:SetPosition(self.owner.HUD.controls:GetTooltipPos() or self.default_text_pos)
			if self.owner.HUD.controls:GetTooltip() ~= nil then
				colour = self.owner.HUD.controls:GetTooltipColour()
			end
		else
			str = self.owner:GetTooltip()
			self.text:SetPosition(self.owner:GetTooltipPos() or self.default_text_pos)
		end

		local secondarystr = nil
		local lmb = nil
		if str == nil and not self.isFE and self.owner:IsActionsVisible() then
			lmb = self.owner.components.playercontroller:GetLeftMouseAction()
			if lmb ~= nil then
				local overriden
				str, overriden = lmb:GetActionString()

				if lmb.action.show_primary_input_left then
					str = TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PRIMARY) .. " " .. str
				end

				if colour == nil then
					if lmb.target ~= nil then
						if lmb.invobject ~= nil and not (lmb.invobject:HasTag("weapon") or lmb.invobject:HasTag("tool")) then
							colour = lmb.invobject:GetIsWet() and WET_TEXT_COLOUR or NORMAL_TEXT_COLOUR
						else
							colour = lmb.target:GetIsWet() and WET_TEXT_COLOUR or NORMAL_TEXT_COLOUR
						end
					elseif lmb.invobject ~= nil then
						colour = lmb.invobject:GetIsWet() and WET_TEXT_COLOUR or NORMAL_TEXT_COLOUR
					end
				end

				if not overriden and lmb.target ~= nil and lmb.invobject == nil and lmb.target ~= lmb.doer then
					local name = lmb.target:GetDisplayName()
					if name ~= nil then
						local adjective = lmb.target:GetAdjective()
						str = str.." "..(adjective ~= nil and (adjective.." "..name) or name)

						if lmb.target.replica.stackable ~= nil and lmb.target.replica.stackable:IsStack() then
							str = str.." x"..tostring(lmb.target.replica.stackable:StackSize())
						end

						--NOTE: This won't work on clients. Leaving it here anyway.
						if lmb.target.components.inspectable ~= nil and lmb.target.components.inspectable.recordview and lmb.target.prefab ~= nil then
							ProfileStatsSet(lmb.target.prefab.."_seen", true)
						end
					end
				end
			end
			local aoetargeting = self.owner.components.playercontroller:IsAOETargeting()
			local rmb = self.owner.components.playercontroller:GetRightMouseAction()
			if rmb ~= nil then
				if rmb.action.show_secondary_input_right then
					secondarystr = rmb:GetActionString() .. " " .. TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_SECONDARY)
				elseif rmb.action ~= ACTIONS.CASTAOE then
					secondarystr = TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_SECONDARY)..": "..rmb:GetActionString()
				elseif aoetargeting and str == nil then
					str = rmb:GetActionString()
				end
			end
			if aoetargeting and secondarystr == nil then
				secondarystr = TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_SECONDARY)..": "..STRINGS.UI.HUD.CANCEL
			end
		end

		---- MOD
		if ThePlayer.is_room_view_active then
			local mouse_pos = TheInput:GetWorldPosition()
			if mouse_pos then
				local room_name
				local room_type = TheRegionMgr:GetRoomType(mouse_pos.x, mouse_pos.z)
				if room_type == "NONE" then
					room_name = STRINGS.M23M_ROOMS.NONE.NAME
				end
				local room_def = TheRegionMgr:GetRoomData(room_type)
				if room_def and type(room_def.name) == "string" then
					room_name = room_def.name
				end
				if room_name then
					if str then
						str = str .. "\n" .. STRINGS.M23M_UI.ROOM ..": ".. room_name
					else
						str = "\n" .. STRINGS.M23M_UI.ROOM ..": ".. room_name
					end
				end
			end
		end
		----

		if str == nil then
			self.text:Hide()
		elseif self.str ~= self.lastStr then
			self.lastStr = self.str
			self.strFrames = SHOW_DELAY
		else
			self.strFrames = self.strFrames - 1
			if self.strFrames <= 0 then
				if lmb ~= nil and lmb.target ~= nil and lmb.target:HasTag("player") then
					self.text:SetColour(unpack(lmb.target.playercolour))
				else
					self.text:SetColour(unpack(colour or NORMAL_TEXT_COLOUR))
				end
				self.text:SetString(str)
				self.text:Show()
			end
		end

		if secondarystr ~= nil then
			self.secondarytext:SetString(secondarystr)
			self.secondarytext:Show()
		else
			self.secondarytext:Hide()
		end

		local changed = self.str ~= str or self.secondarystr ~= secondarystr
		self.str = str
		self.secondarystr = secondarystr
		if changed then
			local pos = TheInput:GetScreenPosition()
			self:UpdatePosition(pos.x, pos.y)
		end
    end
end)
