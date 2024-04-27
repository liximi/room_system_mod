local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Templates = require "widgets/redux/templates"

local RoomView = require "widgets/m23m_room_view"


local HUD = Class(Widget, function(self, owner)
    Widget._ctor(self, "M23M_HUD")
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

	--房间视图切换
	self.room_view_switch_btn = self.top_root:AddChild(Templates.StandardButton(function() self:SwitchRoomView() end, "切换视图", {100, 50}))
	self.room_view_switch_btn:SetPosition(0, -120)
end)


function HUD:PopupAreaEditScreen()
	ThePlayer:ShowPopUp(POPUPS.M23M_AREA_EDIT, true)
end

function HUD:SwitchRoomView()
	if self.room_view then
		self.room_view:Kill()
		self.room_view = nil
	else
		self.room_view = RoomView(self.owner)
	end
end


return HUD