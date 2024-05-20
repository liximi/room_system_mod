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