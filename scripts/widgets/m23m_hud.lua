local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Templates = require "widgets/redux/templates"
local ViewSwitcher = require "widgets/m23m_view_switcher"


local HUD = Class(Widget, function(self, owner)
    Widget._ctor(self, "M23M_HUD")
	self.owner = owner

	--ROOTS
	self.top_root = self:AddChild(Widget("ROOT"))
	self.top_root:SetVAnchor(ANCHOR_TOP)
	self.top_root:SetHAnchor(ANCHOR_MIDDLE)
	self.top_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

	self.right_root = self:AddChild(Widget("ROOT"))
	self.right_root:SetVAnchor(ANCHOR_MIDDLE)
	self.right_root:SetHAnchor(ANCHOR_RIGHT)
	self.right_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

	--区域编辑按钮
	-- self.edit_region_btn = self.top_root:AddChild(Templates.StandardButton(function () self:PopupAreaEditScreen() end,
	-- 	"区域编辑", {200, 50}))
	-- self.edit_region_btn:SetPosition(0, -120)

	--视图切换
	self.view_switcher = self.right_root:AddChild(ViewSwitcher(self.owner))
	self.view_switcher:SetPosition(-200, 100)
end)


function HUD:PopupAreaEditScreen()
	ThePlayer:ShowPopUp(POPUPS.M23M_AREA_EDIT, true)
end


return HUD