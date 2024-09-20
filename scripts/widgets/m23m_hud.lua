local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Templates = require "widgets/redux/templates"
local ViewSwitcher = require "widgets/m23m_view_switcher"


local HUD = Class(Widget, function(self, owner)
    Widget._ctor(self, "M23M_HUD")
	self.owner = owner
	self:SetScaleMode(SCALEMODE_PROPORTIONAL)
	--ROOTS
	self.top_root = self:AddChild(Widget("ROOT"))
	self.top_root:SetVAnchor(ANCHOR_TOP)
	self.top_root:SetHAnchor(ANCHOR_MIDDLE)
	self.top_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

	self.right_root = self:AddChild(Widget("ROOT"))
	self.right_root:SetVAnchor(ANCHOR_MIDDLE)
	self.right_root:SetHAnchor(ANCHOR_RIGHT)
	self.right_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

	--视图切换
	self.view_switcher = self:AddChild(ViewSwitcher(self.owner))
	-- local screen_w, screen_h = TheSim:GetScreenSize()
	local saved_pos = M23M_GetClientSaveData("drag_pos")
	self.view_switcher:SetPosition(saved_pos and saved_pos[1] or 1100, saved_pos and saved_pos[2] or 470)
	self.view_switcher:SetScale(0.75, 0.75)
end)


return HUD