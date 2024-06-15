local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local RoomInfo = Class(Widget, function(self, room_def)
	Widget._ctor(self, "M23M_RoomInfo")
	self.room_def = room_def

	self.bg = self:AddChild(Image("images/frontend_redux.xml", "listitem_thick_normal.tex"))
	self.bg:SetScale(0.6, 0.4)
	local bg_w, bg_h = self.bg:GetSize()

	self.bg_hover = self.bg:AddChild(Image("images/frontend_redux.xml", "listitem_thick_hover.tex"))
	self.bg_hover:Hide()

	self.icon = self:AddChild(Image("images/ui/room_icon.xml", "room_icon.tex"))
	self.icon:SetScale(0.3, 0.3)
	self.icon:SetPosition(64*0.3 - bg_w/2 * 0.6, 0)

	self.name_text = self:AddChild(Text(UIFONT, 26, STRINGS.M23M_ROOMS.NONE.NAME))

	self:SetRoomDef(room_def)
end)


function RoomInfo:SetRoomDef(room_def)
	if type(room_def) ~= "table" then
		return
	end
	self.room_def = room_def
	if room_def.color then
		self.icon:SetTint(room_def.color[1], room_def.color[2], room_def.color[3], 1)
	end

	local bg_w = self.bg:GetSize()
		self.name_text:SetString(room_def.name or STRINGS.M23M_ROOMS.NONE.NAME)
		self.name_text:SetPosition(70 - bg_w/2 * 0.8 + self.name_text:GetRegionSize()/2, 0)
end

function RoomInfo:OnGainFocus()
	if self.enabled then
		self.bg_hover:Show()
	end
end

function RoomInfo:OnLoseFocus()
	self.bg_hover:Hide()
end

return RoomInfo