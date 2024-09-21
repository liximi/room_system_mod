local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local NineSlice = require "widgets/nineslice"
local TrueScrollList = require "widgets/truescrolllist"
local RoomInfo = require "widgets/m23m_room_info_panel"

local GroundTiles = require("worldtiledefs")

local COLOR1 = RGB(225, 225, 180)
local COLOR2 = RGB(240, 230, 130)
local COLOR3 = RGB(150, 140, 65)
local FONT_SIZE1, FONT_SIZE2, FONT_SIZE3, FONT_SIZE4 = 24, 22, 18, 16
local TIP_MARGIN = 2.5	--Tip内文本的边距
local TIP_SEGMENT_SPACING = 4	--Tip内文本的段间距
local MAX_TILE_SHOWN = 1156 * 2	--在地图上最大显示的地块数量
local MAX_TILE_NUM_SPAWN_PER_FRAME = 100	--每帧生成方片实体的数量


local RoomView = Class(Widget, function(self, owner)
    Widget._ctor(self, "M23M_RoomView")
	self.owner = owner

	self.cur_room_id = nil			--地图上鼠标下面的房间
	self.cur_room_type = "NONE"		--地图上鼠标下面的房间
	-- self.cur_room_color = RGB(128, 128, 128)	--地图上鼠标下面的房间
	self.cur_region_ids = {}		--地图上鼠标下面的房间
	self.temp_open_tiles = {}		--用于存储已经访问过但是还没有继续拓展的地块
	self.temp_visited_tiles = {}	--用于存储已经访问过的地块
	self.rects = {}

	self.is_showing_region = false
	self.color_alpha = 0.5

	--UI
	self.bg_w, self.bg_h = 195, 280
	self.bg = self:AddChild(NineSlice("images/ui/nineslice1.xml"))
	self.bg:SetSize(self.bg_w, self.bg_h)
	self.bg:SetPosition(self.bg_w/2, -self.bg_h/2)

	--scrollbar_xoffset控制滚动条水平方向的位置，为0时贴着列表右边缘
	--scrollbar_yoffset是用来控制滚动条长度的
	local list_w, list_h, scrollbar_xoffset, scrollbar_yoffset = self.bg_w - 10, self.bg_h - 4, 6, -50
	local function create_widgets_fn(context, parent, scroll_list)
		local widgets = {}
		local SPACING = 34
		local NUM_ROWS = math.floor(list_h / SPACING) + 2
		local y_offset = (NUM_ROWS * 0.5 - 0.5) * SPACING

		for i = 1, NUM_ROWS do
			local room_info = parent:AddChild(RoomInfo())
			room_info:SetOnGainFocus(function()
				self.list:OnWidgetFocus(room_info)
				self:ShowRoomTip(room_info.room_def)
			end)
			room_info:SetOnLoseFocus(function()
				self:HideRoomTip(room_info.room_def)
			end)
			room_info:SetPosition(0, y_offset - i * SPACING)
			table.insert(widgets, room_info)
		end

		return widgets, 1, SPACING, NUM_ROWS-2, 1
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
	self.list:SetItemsData(M23M.ROOM_DEFS)
	self.list.bg:Kill()
	self.list.bg = nil
	self.list:SetPosition(self.bg_w/2 - scrollbar_xoffset - 2, -self.bg_h/2)

	self.list.up_button:SetScale(0.18)
	self.list.down_button:SetScale(0.18)

	--Tooltips
	self.tip_w = 180
	self.tip_root = self:AddChild(Widget("TipRoot"))
	self.tip_root:SetPosition(-self.tip_w - 20, 0)
	self.tip_root:Hide()

	self.tip_bg = self.tip_root:AddChild(NineSlice("images/ui/nineslice1.xml"))
	self.tip_text_root = self.tip_root:AddChild(Widget("TipTextRoot"))
	-- self.tip_text_root.type: string

	self.tip_name = self.tip_text_root:AddChild(Text(UIFONT, FONT_SIZE1, "ROOM NAME"))
	self.tip_name:SetHAlign(ANCHOR_LEFT)

	self.tip_desc = self.tip_text_root:AddChild(Text(UIFONT, FONT_SIZE2, "ROOM DESC", COLOR2))
	self.tip_desc:SetHAlign(ANCHOR_LEFT)

	self.tip_roomsize = self.tip_text_root:AddChild(Text(UIFONT, FONT_SIZE3, STRINGS.M23M_UI.SIZE_LIMITATION))
	self.tip_roomsize:SetHAlign(ANCHOR_LEFT)

	self.tip_roomsize_note_img = self.tip_text_root:AddChild(Image("images/global_redux.xml", "star_checked.tex"))
	self.tip_roomsize_note_img:SetScale(0.3, 0.3)
	self.tip_roomsize_note_img:SetTint(unpack(RGB(220, 220, 220)))
	self.tip_roomsize_note = self.tip_text_root:AddChild(Text(UIFONT, FONT_SIZE4, STRINGS.M23M_UI.SIZE_LIMITATION2, COLOR3))
	self.tip_roomsize_note:SetHAlign(ANCHOR_LEFT)

	self.tip_must_items_title = self.tip_text_root:AddChild(Text(UIFONT, FONT_SIZE3, STRINGS.M23M_UI.MUST_ITEMS_TITLE))
	self.tip_must_items_title:SetHAlign(ANCHOR_LEFT)
	self.tip_must_items_texts = {}

	self.tip_must_tiles_title = self.tip_text_root:AddChild(Text(UIFONT, FONT_SIZE3, STRINGS.M23M_UI.MUST_TILES_TITLE))
	self.tip_must_tiles_title:SetHAlign(ANCHOR_LEFT)
	self.tip_must_tiles_texts = {}

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


local function get_prefab_name(prefab)
	return type(prefab) == "string" and STRINGS.NAMES[string.upper(prefab)] or tostring(prefab)
end

--获取地皮对应的地毯的名称
local function get_tile_item_name(tile_name)
	local tile_id = WORLD_TILES[tile_name]
	if not tile_id then
		return tile_name
	end
	local turf_def = GroundTiles.turf[tile_id]
	if not turf_def or not turf_def.name then
		return tile_name
	end
	return get_prefab_name("TURF_" .. turf_def.name)
end

local function is_empty_table(tab)
	if type(tab) ~= "table" then
		return true
	end
	for k, v in pairs(tab) do
		return false
	end
	return true
end

function RoomView:ConstructTipText(room_def)
	local next_y = -TIP_MARGIN
	local pre_text_height = 0
	local function calc_next_y(segment_spacing, h)
		next_y = next_y - pre_text_height/2 - segment_spacing - h/2
		pre_text_height = h
	end
	local function set_pos(text, segment_spacing, x_offset)
		local w, h = text:GetRegionSize()
		calc_next_y(segment_spacing, h)
		x_offset = x_offset or 0
		text:SetPosition(TIP_MARGIN + x_offset + w/2, next_y)
	end

	----
	local text_max_w = self.tip_w - TIP_MARGIN * 2
	local x_offset = 8

	--tip_name
	self.tip_name:SetString(room_def.name)
	local tip_name_w, tip_name_h = self.tip_name:GetRegionSize()
	if tip_name_w > text_max_w then
		self.tip_name:SetHorizontalSqueeze(text_max_w / tip_name_w)
	end
	calc_next_y(0, tip_name_h)
	self.tip_name:SetPosition(TIP_MARGIN + math.min(text_max_w, tip_name_w)/2, next_y)

	--tip_desc
	self.tip_desc:SetMultilineTruncatedString(FunctionOrValue(room_def.desc), 10, text_max_w)
	set_pos(self.tip_desc, TIP_SEGMENT_SPACING * 1.5)

	--tip_roomsize
	self.tip_roomsize:SetMultilineTruncatedString(STRINGS.M23M_UI.SIZE_LIMITATION .. string.format("%d ~ %d", room_def.min_size or 0, room_def.max_size or 0), 2, text_max_w)
	set_pos(self.tip_roomsize, TIP_SEGMENT_SPACING)

	--tip_roomsize_note
	set_pos(self.tip_roomsize_note, TIP_SEGMENT_SPACING * 0.2, x_offset + 14)
	self.tip_roomsize_note_img:SetPosition(TIP_MARGIN + 14, next_y)

	--tip_must_items_title
	set_pos(self.tip_must_items_title, TIP_SEGMENT_SPACING)

	--tip_must_items_texts
	local need_items = false
	if type(room_def.must_items) == "table" then
		for _, items in ipairs(room_def.must_items) do
			local str
			if type(items) == "table" then
				local names = {}
				for _, item in ipairs(items) do
					table.insert(names, get_prefab_name(item))
				end
				if #names > 0 then
					str = STRINGS.M23M_UI.ANY .. table.concat(names, "/")
				end
			else
				str = get_prefab_name(items)
			end
			if str then
				need_items = true
				local text = self.tip_text_root:AddChild(Text(UIFONT, FONT_SIZE3, nil, COLOR1))
				table.insert(self.tip_must_items_texts, text)
				text:SetHAlign(ANCHOR_LEFT)
				text:SetMultilineTruncatedString(str, 2, text_max_w)
				set_pos(text, TIP_SEGMENT_SPACING, x_offset)
			end
		end
	end
	if not need_items then	--如果不需要任何物品，就显示为"无"
		local text = self.tip_text_root:AddChild(Text(UIFONT, FONT_SIZE3, nil, COLOR1))
		table.insert(self.tip_must_items_texts, text)
		text:SetHAlign(ANCHOR_LEFT)
		text:SetMultilineTruncatedString(STRINGS.M23M_UI.NONE, 2, text_max_w)
		set_pos(text, TIP_SEGMENT_SPACING, x_offset)
	end

	--tip_must_tiles_title 如果没有地皮限制，就不显示对应的标题
	if is_empty_table(room_def.available_tiles) then
		self.tip_must_tiles_title:Hide()
	else
		self.tip_must_tiles_title:Show()
		set_pos(self.tip_must_tiles_title, TIP_SEGMENT_SPACING)

		for tile_name, _ in pairs(room_def.available_tiles) do
			local str = get_tile_item_name(tile_name)
			if str then
				local text = self.tip_text_root:AddChild(Text(UIFONT, FONT_SIZE3, nil, COLOR1))
				table.insert(self.tip_must_tiles_texts, text)
				text:SetHAlign(ANCHOR_LEFT)
				text:SetMultilineTruncatedString(str, 2, text_max_w)
				set_pos(text, TIP_SEGMENT_SPACING, x_offset)
			end
		end
	end

	--BG
	local total_height = -next_y + pre_text_height/2 + TIP_MARGIN
	self.tip_bg:SetSize(self.tip_w, total_height)
	self.tip_bg:SetPosition(self.tip_w/2, total_height <= self.bg_h and -total_height/2 or (total_height/2 - self.bg_h))

	--Text Root
	self.tip_text_root:SetPosition(0, total_height <= self.bg_h and 0 or (total_height - self.bg_h))
end


function RoomView:ShowRoomTip(room_def)
	if not room_def or room_def.type == self.tip_text_root.type then
		return
	end

	self.tip_text_root.type = room_def.type
	for _, text in ipairs(self.tip_must_items_texts) do
		text:Kill()
	end
	self.tip_must_items_texts = {}
	for _, text in ipairs(self.tip_must_tiles_texts) do
		text:Kill()
	end
	self:ConstructTipText(room_def)
	self.tip_root:Show()
end


function RoomView:HideRoomTip(room_def)
	if not self.tip_root.shown or not room_def or room_def.type ~= self.tip_text_root.type then
		return
	end

	self.tip_text_root.type = nil
	for _, text in ipairs(self.tip_must_items_texts) do
		text:Kill()
	end
	self.tip_must_items_texts = {}
	for _, text in ipairs(self.tip_must_tiles_texts) do
		text:Kill()
	end
	self.tip_must_tiles_texts = {}

	self.tip_root:Hide()
end


function RoomView:SetCurrentRoomId(room_id, start_pos)
	if room_id == self.cur_room_id then
		return
	end
	self.cur_room_id = room_id
	self.cur_room_type = TheRegionMgr:GetRoomTypeById(room_id)
	self.cur_room_color = nil

	if self.cur_room_type == "NONE" and TheRegionMgr:GetRoomSize(room_id) > MAX_TILE_SHOWN then
		self:HideAllTiles()
		return
	end

	if self.cur_room_type ~= "NONE" then
		for _, room_data in ipairs(M23M.ROOM_DEFS) do
			if room_data.type == self.cur_room_type then
				self.cur_room_color = room_data.color
				break
			end
		end
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


function RoomView:ShowTile()
	if #self.temp_open_tiles == 0 or #self.rects >= MAX_TILE_SHOWN then
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
		for i = 1, MAX_TILE_NUM_SPAWN_PER_FRAME do
			self:ShowTile()
			if not self.is_showing_tile then
				break
			end
		end
	end
end


return RoomView