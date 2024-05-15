local Widget = require "widgets/widget"
local Text = require "widgets/text"
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

	--ROOTS
	self.top_root = self:AddChild(Widget("ROOT"))
	self.top_root:SetVAnchor(ANCHOR_TOP)
	self.top_root:SetHAnchor(ANCHOR_MIDDLE)

	self.room_name_text = self.top_root:AddChild(Text(UIFONT, 28, STRINGS.M23M_ROOMS.NONE.NAME))
	self.room_name_text:SetPosition(0, -150)

	self.room_desc_text = self.top_root:AddChild(Text(UIFONT, 24, STRINGS.M23M_ROOMS.NONE.DESC))
	self.room_desc_text:SetPosition(0, -180)

	self:StartUpdating()
end)


function RoomView:OnKill()
	self:HideAllTiles()
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