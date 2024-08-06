local Widget = require "widgets/widget"
local NineSlice = require "widgets/nineslice"
local ImageBtn = require "widgets/imagebutton"
local Text = require "widgets/text"

local RoomView = require "widgets/m23m_room_view"


local ViewSwitcher = Class(Widget, function(self, owner)
    Widget._ctor(self, "M23M_ViewSwitcher")
	self.owner = owner

	--ROOTS
	self.root = self:AddChild(Widget("ROOT"))

	--BG
	local bg_w = 195
	self.bg = self.root:AddChild(NineSlice("images/ui/nineslice1.xml"))
	self.bg:SetSize(bg_w, 20)
	self.bg:SetPosition(bg_w/2, 0)

	--icon
	self.icon = self:AddChild(Image("images/ui/room_icon.xml", "room_icon.tex"))
	self.icon:ScaleToSize(24, 24)
	self.icon:SetPosition(14, 0)

	--text
	self.text = self:AddChild(Text(UIFONT, 26, STRINGS.M23M_UI.ROOM_OVERVIEW))
	self.text:SetPosition(30 + self.text:GetRegionSize()/2, 0)

	--房间视图切换
	self.room_view_btn = self.root:AddChild(ImageBtn("images/global_redux.xml", "arrow2_right.tex", "arrow2_right_over.tex", "arrow_right_disabled.tex", "arrow2_right_over.tex", "arrow2_right_over.tex", {0.25, 0.25}))
	self.room_view_btn:SetFocusScale(0.3, 0.3, 0.3)
	self.room_view_btn:SetPosition(bg_w - 16, 0)
	self.room_view_btn:SetOnClick(function ()
		self:SwitchRoomView()
	end)

	--Sub-UI Anchor
	self.sub_ui_root = self.root:AddChild(Widget("ROOT"))
	self.sub_ui_root:SetPosition(bg_w, -30)
end)

function ViewSwitcher:SwitchRoomView()
	if self.room_view then
		self.room_view:Kill()
		self.room_view = nil
		ThePlayer.is_room_view_active = false
		self.room_view_btn:SetRotation(0)
	else
		self.room_view = self.sub_ui_root:AddChild(RoomView(self.owner))
		self.room_view:SetPosition(-self.room_view.bg_w, 0)
		ThePlayer.is_room_view_active = true
		self.room_view_btn:SetRotation(90)
	end
end

function ViewSwitcher:OnMouseButton(button, down, x, y)
	if button == MOUSEBUTTON_LEFT and down then
		local mousepos = TheInput:GetScreenPosition()
		local my_pos = self:GetWorldPosition()
		self.drag_offset = my_pos - mousepos
		self.draging = true
		self:StartUpdating()
    elseif button == MOUSEBUTTON_LEFT then
		self.draging = false
		self:StopUpdating()
	end
end

function ViewSwitcher:OnUpdate(dt)
	if self.draging then
		local mousepos = TheInput:GetScreenPosition()
		local pos = mousepos - self.parent:GetWorldPosition()
		local scale = self.parent:GetScale()
		local drag_x = (pos.x + self.drag_offset.x) / scale.x
		local drag_y = (pos.y + self.drag_offset.y) / scale.y
		self:SetPosition(drag_x, drag_y)
	end
end


return ViewSwitcher