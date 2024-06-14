local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local NineSlice = require "widgets/nineslice"
local TrueScrollList = require "widgets/truescrolllist"
local RoomInfo = require "widgets/m23m_room_info_panel"
local ROOM_DEF = require "m23m_room_def"


local RoomView = Class(Widget, function(self, owner)
    Widget._ctor(self, "M23M_RoomView")
	self.owner = owner

	self.cur_room_id = nil
	self.cur_room_type = "NONE"
	-- self.cur_room_color = RGB(128, 128, 128)
	self.cur_region_ids = {}
	self.temp_open_tiles = {}		--用于存储已经访问过但是还没有继续拓展的地块
	self.temp_visited_tiles = {}	--用于存储已经访问过的地块
	self.rects = {}

	self.is_showing_region = false
	self.color_alpha = 0.5

	--UI
	-- self.root = self:AddChild(Widget("ROOT"))

	local bg_w, bg_h = 220, 300
	self.bg = self:AddChild(NineSlice("images/ui/nineslice1.xml"))
	self.bg:SetSize(bg_w, bg_h)
	self.bg:SetPosition(bg_w/2, -bg_h/2)

	--scrollbar_xoffset控制滚动条水平方向的位置，为0时贴着列表右边缘，scrollbar_yoffset是用来控制滚动条长度的
	local list_w, list_h, scrollbar_xoffset, scrollbar_yoffset = bg_w - 20, bg_h, 10, -50
	local function create_widgets_fn(context, parent, scroll_list)
		local widgets = {}
		local SPACING = 36
		local NUM_ROWS = math.floor(list_h / SPACING) + 2
		local y_offset = (NUM_ROWS * 0.5 - 0.35) * SPACING

		for i = 1, NUM_ROWS do
			local room_info = parent:AddChild(RoomInfo())
			room_info:SetOnGainFocus(function()
				self.list:OnWidgetFocus(room_info)
			end)
			room_info:SetPosition(0, y_offset - i * SPACING)
			table.insert(widgets, room_info)
		end

		return widgets, 1, SPACING, NUM_ROWS-2, 0.7
	end

	local function update_fn(context, list_widget, data, data_index)
		if not data then
			list_widget:Hide()
		else
			list_widget:SetRoomDef(data)
			list_widget:Show()
		end
	end

	self.list = self:AddChild(TrueScrollList({}, create_widgets_fn, update_fn, -list_w/2, -list_h/2, list_w, list_h, scrollbar_xoffset, scrollbar_yoffset))
	self.list:SetItemsData(ROOM_DEF)
	self.list.bg:Kill()
	self.list.bg = nil
	self.list:SetPosition(bg_w/2 - scrollbar_xoffset - 5, -bg_h/2 + 2)


	self.room_name_text = self:AddChild(Text(UIFONT, 28, STRINGS.M23M_ROOMS.NONE.NAME))
	self.room_name_text:SetPosition(0, -bg_h - 20)

	self.room_desc_text = self:AddChild(Text(UIFONT, 24, STRINGS.M23M_ROOMS.NONE.DESC))
	self.room_desc_text:SetPosition(0, -bg_h - 40)


	self:StartUpdating()
end)


function RoomView:OnKill()
	self:HideAllTiles()
end


function RoomView:OnGainFocus()
	TheCamera:SetControllable(false)
end


function RoomView:OnLoseFocus()
	TheCamera:SetControllable(true)
end


function RoomView:SetCurrentRoomId(room_id, start_pos)
	if room_id == self.cur_room_id then
		return
	end
	self.cur_room_id = room_id
	self.cur_room_type = TheRegionMgr:GetRoomTypeById(room_id)
	self.cur_room_color = nil

	if self.cur_room_type == "NONE" then
		self.room_name_text:SetString(STRINGS.M23M_ROOMS.NONE.NAME)
		self.room_desc_text:SetString(STRINGS.M23M_ROOMS.NONE.DESC)
	else
		local room_name = ""
		local room_desc = ""
		for _, room_data in ipairs(ROOM_DEF) do
			if room_data.type == self.cur_room_type then
				self.cur_room_color = room_data.color
				room_name = room_data.name
				room_desc = FunctionOrValue(room_data.desc)
			end
		end
		self.room_name_text:SetString(room_name)
		self.room_desc_text:SetString(room_desc)
	end

	start_pos.x = math.floor(start_pos.x)
	start_pos.y = 0
	start_pos.z = math.floor(start_pos.z)
	self.temp_open_tiles = {EncodePos(start_pos)}
	self:StartShowRoomTiles()
end


function RoomView:StartShowRoomTiles()
	self:HideAllTiles()
	if not self.cur_room_id then
		return
	end
	for _, region_id in ipairs(TheRegionMgr:GetAllRegionsInRoom(self.cur_room_id)) do
		self.cur_region_ids[region_id] = true
	end

	self.is_showing_tile = true
end


function RoomView:HideAllTiles()
	for _, rect in ipairs(self.rects) do
		rect:Remove()
	end
	self.rects = {}
	self.cur_region_ids = {}
end

local max_show_num = 1156 * 2
function RoomView:ShowTile()
	if #self.temp_open_tiles == 0 or #self.rects >= max_show_num then
		self.is_showing_tile = false
		self.temp_open_tiles = {}
		self.temp_visited_tiles = {}
		return
	end

	local cur_pos_code = table.remove(self.temp_open_tiles, 1)
	if self.temp_visited_tiles[cur_pos_code] then
		return
	end

	self.temp_visited_tiles[cur_pos_code] = true
	local cur_pos = Vector3(DecodePos(cur_pos_code))
	local region_id = TheRegionMgr:GetRegionId(TheRegionMgr:GetTileCoordsAtPoint(cur_pos.x, cur_pos.z))
	if not self.cur_region_ids[region_id] then
		return
	end

	local rect = SpawnPrefab("m23m_rectangle")
	rect:SetSize(1, 1)
	rect.Transform:SetPosition(cur_pos.x + 0.5, 0, cur_pos.z + 0.5)
	if self.cur_room_color then
		rect.AnimState:SetMultColour(self.cur_room_color[1], self.cur_room_color[2], self.cur_room_color[3], self.color_alpha)
	end
	table.insert(self.rects, rect)

	local next_pos1 = Vector3(cur_pos.x + 1, 0, cur_pos.z)
	local next_pos2 = Vector3(cur_pos.x, 0, cur_pos.z + 1)
	local next_pos3 = Vector3(cur_pos.x - 1, 0, cur_pos.z)
	local next_pos4 = Vector3(cur_pos.x, 0, cur_pos.z - 1)

	local next_pos1_code = EncodePos(next_pos1)
	local next_pos2_code = EncodePos(next_pos2)
	local next_pos3_code = EncodePos(next_pos3)
	local next_pos4_code = EncodePos(next_pos4)

	if not self.temp_visited_tiles[next_pos1_code] then
		table.insert(self.temp_open_tiles, next_pos1_code)
	end
	if not self.temp_visited_tiles[next_pos2_code] then
		table.insert(self.temp_open_tiles, next_pos2_code)
	end
	if not self.temp_visited_tiles[next_pos3_code] then
		table.insert(self.temp_open_tiles, next_pos3_code)
	end
	if not self.temp_visited_tiles[next_pos4_code] then
		table.insert(self.temp_open_tiles, next_pos4_code)
	end
end


function RoomView:OnUpdate(dt)
	local pos = TheInput:GetWorldPosition()
	if TheRegionMgr and pos then
		local region_x, region_y = TheRegionMgr:GetTileCoordsAtPoint(pos.x, pos.z)
		local room_id = TheRegionMgr:GetRoomId(region_x, region_y)
		self:SetCurrentRoomId(room_id, pos)
	end

	if self.is_showing_tile then
		for i = 1, 136 do
			self:ShowTile()
			if not self.is_showing_tile then
				break
			end
		end
	end
end


return RoomView