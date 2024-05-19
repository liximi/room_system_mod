local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local RoomInfo = Class(Widget, function(self, owner, room_def)
	Widget._ctor(self, "M23M_RoomInfo")
	self.owner = owner
	self.room_def = room_def

	self.bg = self:AddChild(Image("images/frontend_redux.xml", "listitem_thick_normal.tex"))
	self.bg:SetScale(0.8, 0.5)
	local bg_w, bg_h = self.bg:GetSize()

	self.icon = self:AddChild(Image("images/ui/room_icon.xml", "room_icon.tex"))
	self.icon:SetScale(0.5, 0.5)
	if room_def and room_def.color then
		self.icon:SetTint(room_def.color[1], room_def.color[2], room_def.color[3], 1)
	end
	self.icon:SetPosition(32 - bg_w/2 * 0.8, 0)

	self.name_text = self:AddChild(Text(UIFONT, 28, room_def.name or STRINGS.M23M_ROOMS.NONE.NAME))
	self.name_text:SetPosition(64 - bg_w/2 * 0.8 + self.name_text:GetRegionSize()/2, 0)
end)


return RoomInfo