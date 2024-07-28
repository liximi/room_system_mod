local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local RoomInfo = Class(Widget, function(self, room_def)
	Widget._ctor(self, "M23M_RoomInfo")
	self.room_def = room_def

	local scale_w, scale_h = 0.55, 0.35
	self.bg = self:AddChild(Image("images/frontend_redux.xml", "listitem_thick_normal.tex"))
	self.bg:SetScale(scale_w, scale_h)
	local bg_w, bg_h = self.bg:GetSize()

	self.bg_hover = self.bg:AddChild(Image("images/frontend_redux.xml", "listitem_thick_hover.tex"))
	self.bg_hover:Hide()

	self.icon = self:AddChild(Image("images/ui/room_icon.xml", "room_icon.tex"))
	self.icon:ScaleToSize(16, 16)
	self.icon:SetPosition(16 - bg_w/2 * scale_w, 0)

	self.color_cube = self:AddChild(Image("images/ui/color_cube.xml", "color_cube.tex"))	--16*16
	-- self.color_cube:SetScale(icon_scale, icon_scale)
	self.color_cube:SetPosition(36 - bg_w/2 * scale_w, 0)

	self.name_text = self:AddChild(Text(UIFONT, 24, STRINGS.M23M_ROOMS.NONE.NAME))

	self:SetRoomDef(room_def)
end)


function RoomInfo:SetRoomDef(room_def)
	if type(room_def) ~= "table" then
		return
	end
	self.room_def = room_def

	if room_def.icon_atlas and room_def.icon_image then
		self.icon:SetTexture(room_def.icon_atlas, room_def.icon_image)
		self.icon:ScaleToSize(16, 16)
	end

	if room_def.color then
		self.color_cube:SetTint(room_def.color[1], room_def.color[2], room_def.color[3], 1)
	end

	local bg_w = self.bg:GetSize()
		self.name_text:SetString(room_def.name or STRINGS.M23M_ROOMS.NONE.NAME)
		self.name_text:SetPosition(88 - bg_w/2 * 0.8 + self.name_text:GetRegionSize()/2, 0)
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