local Widget = require "widgets/widget"
local NineSlice = require "widgets/nineslice"
local ImageBtn = require "widgets/imagebutton"
local Templates = require "widgets/redux/templates"

local RoomView = require "widgets/m23m_room_view"


local ViewSwitcher = Class(Widget, function(self, owner)
    Widget._ctor(self, "M23M_ViewSwitcher")
	self.owner = owner

	--ROOTS
	self.root = self:AddChild(Widget("ROOT"))

	--BG
	self.bg = self.root:AddChild(NineSlice("images/ui/nineslice1.xml"))
	self.bg:SetSize(128, 24)
	self.bg:SetPosition(64, 0)

	--Drag Btn
	-- self.drag_btn = self.root:AddChild(ImageBtn("images/hud.xml", "cursor01.tex", "cursor02.tex", nil, "cursor02.tex", "cursor02.tex"))
	self.drag_btn = self.root:AddChild(ImageBtn("images/hud.xml", "equip_slot_hud.tex"))
	self.drag_btn:SetNormalScale(0.65, 0.65, 0.65)
	self.drag_btn:SetFocusScale(0.75, 0.75, 0.75)
	self.drag_btn:SetPosition(0, 20)

	--Sub-UI Anchor
	self.sub_ui_root = self.root:AddChild(Widget("ROOT"))
	self.sub_ui_root:SetPosition(0, -45)

	--View Btn List

	--房间视图切换
	self.room_view_btn = self.root:AddChild(Templates.StandardButton(function() self:SwitchRoomView() end, "Room", {32, 32}))
	self.room_view_btn:SetPosition(32, 0)
end)

function ViewSwitcher:SwitchRoomView()
	if self.room_view then
		self.room_view:Kill()
		self.room_view = nil
	else
		self.room_view = self.sub_ui_root:AddChild(RoomView(self.owner))
	end
end


return ViewSwitcher