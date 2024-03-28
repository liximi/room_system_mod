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
	self.start_next_turn_bt = self.top_root:AddChild(Templates.StandardButton(function () self:PopupAreaEditScreen() end,
		"区域编辑", {200, 50}))
	self.start_next_turn_bt:SetPosition(0, -120)
end)


function HUD:PopupAreaEditScreen()
	ThePlayer:ShowPopUp(POPUPS.M23M_AREA_EDIT, true)
end

return HUD