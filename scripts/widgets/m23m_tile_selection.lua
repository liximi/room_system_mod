local Widget = require "widgets/widget"
local NineSlice = require "widgets/nineslice"
local Text = require "widgets/text"

local TheInput = TheInput
local ANCHOR_BOTTOM = ANCHOR_BOTTOM
local ANCHOR_LEFT = ANCHOR_LEFT
local TheSim = TheSim

local select_tile_button = M23M.SELECT_UNIT_BUTTON    	--选择地块的鼠标按键
local diselect_tile_button = M23M.DISELECT_TILE_BUTTON	--取消选择地块的鼠标按键
local selected_color = RGB(50, 220, 50)
local diselect_color = RGB(255, 50, 50)
local hover_color = RGB(255, 255, 255)

local function SpawnOutline(x, y, z, colour)
	local outline = SpawnPrefab("tile_outline")
	outline.Transform:SetPosition(x, y, z)
	colour = colour or hover_color
	outline.AnimState:SetScale(0.95, 0.95)
	outline.AnimState:SetAddColour(unpack(colour))
	return outline
end

--------------------------------------------------
-- 地块选择交互功能
--------------------------------------------------

local TileSelection = Class(Widget, function(self)
    Widget._ctor(self, "TileSelection")

	self.tile_outlines = {}
	local _tile_selected_fn = function(x, z)
		if not self.tile_outlines[x] then
			self.tile_outlines[x] = {}
		end
		if self.tile_outlines[x][z] then
			self.tile_outlines[x][z].AnimState:SetAddColour(unpack(selected_color))
		else
			self.tile_outlines[x][z] = SpawnOutline(x, 0, z, selected_color)
		end
	end
	local _tile_preselected_fn = _tile_selected_fn
	local _tile_preunselected_fn = function(x, z)
		if not self.tile_outlines[x] then
			self.tile_outlines[x] = {}
		end
		if self.tile_outlines[x][z] then
			self.tile_outlines[x][z].AnimState:SetAddColour(unpack(diselect_color))
		else
			self.tile_outlines[x][z] = SpawnOutline(x, 0, z, diselect_color)
		end
	end
	local _tile_hovered_fn = function(x, z)
		if not self.tile_outlines[x] then
			self.tile_outlines[x] = {}
		end
		if self.tile_outlines[x][z] then
			self.tile_outlines[x][z].AnimState:SetAddColour(unpack(hover_color))
		else
			self.tile_outlines[x][z] = SpawnOutline(x, 0, z)
		end
	end

	local _tile_unselected_fn = function(x, z)
		if not self.tile_outlines[x] or not self.tile_outlines[x][z] then
			return
		end
		self.tile_outlines[x][z]:Remove()
		self.tile_outlines[x][z] = nil
	end
	local _tile_unpreselected_fn = function(x, z)
		if not self.tile_outlines[x] or not self.tile_outlines[x][z] then
			return
		end
		if self:IsTileSelected(x, z) then
			self.tile_outlines[x][z].AnimState:SetAddColour(unpack(selected_color))
		else
			self.tile_outlines[x][z]:Remove()
			self.tile_outlines[x][z] = nil
		end
	end
	local _tile_unpreunselected_fn = _tile_unpreselected_fn
	local _tile_unhovered_fn = _tile_unpreselected_fn

    self.tile_selected_fn = _tile_selected_fn			--function(x, z) end 当地块被选中时，对该地块执行操作
    self.tile_unselected_fn = _tile_unselected_fn		--function(x, z) end 当地块被取消选中时，对该地块执行操作
    self.tile_preselected_fn = _tile_preselected_fn	--function(x, z) end 当地块被预选中时，对该地块执行操作
    self.tile_unpreselected_fn = _tile_unpreselected_fn	--function(x, z) end 当地块被取消预选中时，对该地块执行操作
	self.tile_preunselect_fn = _tile_preunselected_fn		--function(x, z) end 当地块被预取消选中时，对该地块执行操作
	self.tile_unpreunselect_fn = _tile_unpreunselected_fn	--function(x, z) end 当地块被取消预取消选中时，对该地块执行操作
	self.tile_hovered_fn = _tile_hovered_fn			--function(x, z) end 当鼠标悬浮在地块上时，对该地块执行操作
	self.tile_unhovered_fn = _tile_unhovered_fn		--function(x, z) end 当悬浮中的鼠标离开地块时，对该地块执行操作

	self.enable_ocean = false
	self.disable_tile_types = {}

    self.selected_tiles = {}        -- 2维矩阵 {[x] = {[z] = true}}
    self.pre_selected_tiles = {}    -- 2维矩阵 {[x] = {[z] = true}}
	self.pre_diselected_tiles = {}	-- 2维矩阵 {[x] = {[z] = true}}
	self.current_hover_tile = {}	-- {x, z}
    self.mouse_isdown = nil

	local hover_str = TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PRIMARY)..": "..STRINGS.TILE_SELECTION_HOVERER_TEXT_SELECT
		.."\n"..TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_SECONDARY)..": "..STRINGS.TILE_SELECTION_HOVERER_TEXT_DISELECT
	self.hover_text = self:AddChild(Text(UIFONT, 18, hover_str, hover_color))
	self.hover_text_w, self.hover_text_h = self.hover_text:GetRegionSize()
	self:RefreshHoverPos()

    self.select_quad_screen = {}    --{{x=number, y=number}, ...}
    --[[ { P_start, P1, P_end, P2 }
        P2 ---------- P_end
        |               |
        |               |
        P_start ------- P1
    ]]
end)


function TileSelection:OnMouseButton(button, down)
    if button == select_tile_button or button == diselect_tile_button then
        if not TheInput:GetHUDEntityUnderMouse() and down and not self.mouse_isdown then	--如果按下鼠标时，鼠标下没有UI并且之前不处于按下状态中，则进入选择状态
            self.mouse_isdown = button
            TheCamera:LockHeadingTarget("m23m_plow_tile_selection")	--锁定摄像机视角
            local pos = TheInput:GetScreenPosition()
            self.select_quad_screen[1] = {x = pos.x, y = pos.y}
            self.select_quad_screen[2] = {x = pos.x, y = pos.y}
            self.select_quad_screen[3] = {x = pos.x, y = pos.y}
            self.select_quad_screen[4] = {x = pos.x, y = pos.y}
            self:CreateMultSelectRangeImage()

            if #self.selected_tiles ~= 0 then	--清除已经选择的地块
                self:ClearSelection()
            end
        elseif self.mouse_isdown and not down then	--如果正在选择,且不是按下状态
            TheCamera:UnLockHeadingTarget("m23m_plow_tile_selection")	--解锁摄像机视角
            self:RemoveMultSelectRangeImage()
			if #self.select_quad_screen == 4 then
                local distance = Vector3(self.select_quad_screen[1].x , self.select_quad_screen[1].y):Dist(Vector3(self.select_quad_screen[3].x , self.select_quad_screen[3].y))
                if distance > 10 then	--框选
					if self.mouse_isdown == select_tile_button then
						self:Select()
					else
						self:Diselect()
					end
                else					--单选
					local pt_world = TheInput:GetWorldPosition()
					if self:IsEnableTile(pt_world.x, pt_world.z) then
						local tile_center_x, tile_center_y, tile_center_z = TheWorld.Map:GetTileCenterPoint(pt_world.x, 0, pt_world.z)
						if self.mouse_isdown == select_tile_button then
							self:Select({[tile_center_x] = {[tile_center_z] = true}})
						else
							self:Diselect({[tile_center_x] = {[tile_center_z] = true}})
						end
					end
                end
            end
			self.select_quad_screen = {}
			self.mouse_isdown = nil
        end
        return true
    end
end

function TileSelection:OnMoveMouse(x, y)
	--移动 hoverer 文本
	self:RefreshHoverPos(x, y)
    --更新框选范围的UI显示,并对范围内的地块进行预选择
    if self.mouse_isdown then
		--移除悬浮状态
		if self.current_hover_tile[1] and self.current_hover_tile[2] then
			self:ClearHover()
		end
		--提取P_start和P_end的数据, 用于接下来的计算
		local x1, y1 = self.select_quad_screen[1].x,  self.select_quad_screen[1].y
		local x2, y2 = x, y
		local drag_vec = Vector3(x, y, 0) - Vector3(x1, y1, 0)
		local center_x, center_y = x1 + drag_vec.x/2, y1 + drag_vec.y/2
		--更新框选框的位置和缩放
        if self.fx_multselect then
            self.fx_multselect:SetPosition(center_x, center_y, 0)
            self.fx_multselect:SetSize(math.abs(drag_vec.x), math.abs(drag_vec.y))
		end
		--更新四边形顶点坐标
		self.select_quad_screen[2] = {x = x2, y = y1}
		self.select_quad_screen[3] = {x = x2, y = y2}
		self.select_quad_screen[4] = {x = x1, y = y2}
		--获取框选范围(圆形)内的所有地块(坐标)
		local start_pt_world = Vector3(TheSim:ProjectScreenPos(x1, y1))
		local p1_pt_world = Vector3(TheSim:ProjectScreenPos(x2, y1))
		local end_pt_world = Vector3(TheSim:ProjectScreenPos(x2, y2))
		local p2_pt_world = Vector3(TheSim:ProjectScreenPos(x1, y2))
		local center_pt_world = Vector3(TheSim:ProjectScreenPos(center_x, center_y))

		local radius = math.sqrt(math.max(start_pt_world:DistSq(center_pt_world), p1_pt_world:DistSq(center_pt_world),
			end_pt_world:DistSq(center_pt_world), p2_pt_world:DistSq(center_pt_world)))
		local _tiles = GetTiles(center_pt_world.x, center_pt_world.z, radius)
		--筛选出真正在框选范围(四边形)内的所有地块(坐标)
		local tiles = {}
		local quad = {start_pt_world, p1_pt_world, end_pt_world, p2_pt_world}
		for k, v in ipairs(quad) do
			v.y = v.z
			v.z= 0
		end

		for i, tile in ipairs(_tiles) do
			if IsPointInsideConvexQuad({x = tile.x, y = tile.z}, quad) and self:IsEnableTile(tile.x, tile.z) then
				if not tiles[tile.x] then
					tiles[tile.x] = {}
				end
				tiles[tile.x][tile.z] = true
			end
		end
		if self.mouse_isdown == select_tile_button then
			self:PreSelect(tiles)
		else
			self:PreDiselect(tiles)
		end
    else
		--移除框选框
		if self.fx_multselect then
			self:RemoveMultSelectRangeImage()
		end
		--鼠标悬浮效果
		local pt_world_x, pt_world_y, pt_world_z = TheSim:ProjectScreenPos(x , y)
		local tile_center_x, tile_center_y, tile_center_z = TheWorld.Map:GetTileCenterPoint(pt_world_x, 0, pt_world_z)
		self:Hover({tile_center_x, tile_center_z})
    end
end

--------------------------------------------------

function TileSelection:GetSelectedTiles()
    return self.selected_tiles
end

function TileSelection:CreateMultSelectRangeImage()
    self.fx_multselect = self:AddChild(NineSlice("images/ui/fx_multselect.xml",
        "fx_multselect_01.tex", "fx_multselect_02.tex", "fx_multselect_03.tex",
        "fx_multselect_04.tex", "fx_multselect_05.tex", "fx_multselect_06.tex",
        "fx_multselect_07.tex", "fx_multselect_08.tex", "fx_multselect_09.tex"))
    self.fx_multselect:SetSize(0, 0)
    self.fx_multselect:SetPosition(self.select_quad_screen[1].x, self.select_quad_screen[1].y)
    self.fx_multselect:SetVAnchor(ANCHOR_BOTTOM)
    self.fx_multselect:SetHAnchor(ANCHOR_LEFT)
end

function TileSelection:RemoveMultSelectRangeImage()
    if self.fx_multselect then
        self.fx_multselect:Kill()
        self.fx_multselect = nil
    end
end


function TileSelection:RefreshHoverPos(mouse_x, mouse_y)
	local scale = self:GetScale()
	local pt = (mouse_x and mouse_y) and Vector3(mouse_x, mouse_y) or TheInput:GetScreenPosition()
	pt.x = pt.x / scale.x
	pt.y = pt.y / scale.y
	pt = pt + Vector3(self.hover_text_w/2 + 8, -self.hover_text_h/2 + 4, 0)
	self.hover_text:SetPosition(pt:Get())
end

function TileSelection:Select(tiles)    --2维矩阵 {[x] = {[z] = true}}
    if not tiles then
        tiles = self.pre_selected_tiles
    end
    self:ClearPreSelection()

    local count = 0
    for x, zs in pairs(tiles) do
        count = count + 1
		break
    end
    if count == 0 then return end

    for x, zs in pairs(self.selected_tiles) do
		for z, _ in pairs(zs) do
			if tiles[x] and tiles[x][z] then	--筛选重复的
				tiles[x][z] = nil
			end
		end
    end
    for x, zs in pairs(tiles) do
		for z, _ in pairs(zs) do
			if not self.selected_tiles[x] then
				self.selected_tiles[x] = {}
			end
			self.selected_tiles[x][z] = true
			if self.tile_selected_fn then
				self.tile_selected_fn(x, z)
			end
		end
    end
end

function TileSelection:ClearSelection()
    local tiles = self.selected_tiles
    self.selected_tiles = {}
	for x, zs in pairs(tiles) do
		for z, _ in pairs(zs) do
			if self.tile_unselected_fn then
				self.tile_unselected_fn(x, z)
			end
		end
    end
end

function TileSelection:Diselect(tiles)	--2维矩阵 {[x] = {[z] = true}}
	if not tiles then
        tiles = self.pre_diselected_tiles
    end
    self:ClearPreDiselection()
    for x, zs in pairs(tiles) do
		for z, _ in pairs(zs) do
			if self.selected_tiles[x] and self.selected_tiles[x][z] then
				self.selected_tiles[x][z] = nil
			end
			if self.tile_unselected_fn then
				self.tile_unselected_fn(x, z)
			end
		end
    end
end

function TileSelection:PreSelect(tiles)	--2维矩阵 {[x] = {[z] = true}}
	self:ClearPreDiselection()
	for x, zs in pairs(self.pre_selected_tiles) do
		for z, _ in pairs(zs) do
			if tiles[x] and tiles[x][z] then	--筛选重复的
				tiles[x][z] = nil
			else
				self.pre_selected_tiles[x][z] = nil	--减去没有包括的地块
				if self.tile_unpreselected_fn then
					self.tile_unpreselected_fn(x, z)
				end
			end
		end
    end
	for x, zs in pairs(tiles) do	--增加之前没有的地块
		for z, _ in pairs(zs) do
			if not self:IsTileSelected(x, z) then	--如果该地块已经被选择，则不需要标记为将会被选择
				if not self.pre_selected_tiles[x] then
					self.pre_selected_tiles[x] = {}
				end
				self.pre_selected_tiles[x][z] = true
				if self.tile_preselected_fn then
					self.tile_preselected_fn(x, z)
				end
			end
		end
    end
end

function TileSelection:ClearPreSelection()
    local tiles = self.pre_selected_tiles
    self.pre_selected_tiles = {}
	for x, zs in pairs(tiles) do
		for z, _ in pairs(zs) do
			if self.tile_unpreselected_fn then
				self.tile_unpreselected_fn(x, z)
			end
		end
    end
end

function TileSelection:PreDiselect(tiles)	--2维矩阵 {[x] = {[z] = true}}
	self:ClearPreSelection()
	for x, zs in pairs(self.pre_diselected_tiles) do
		for z, _ in pairs(zs) do
			if tiles[x] and tiles[x][z] then	--筛选重复的
				tiles[x][z] = nil
			else
				self.pre_diselected_tiles[x][z] = nil	--减去没有包括的地块
				if self.tile_unpreunselect_fn then
					self.tile_unpreunselect_fn(x, z)
				end
			end
		end
    end
	for x, zs in pairs(tiles) do	--增加之前没有的地块
		for z, _ in pairs(zs) do
			if self:IsTileSelected(x, z) then	--如果该地块未被已经选择，则不需要标记为会被取消选择
				if not self.pre_diselected_tiles[x] then
					self.pre_diselected_tiles[x] = {}
				end
				self.pre_diselected_tiles[x][z] = true
				if self.tile_preunselect_fn then
					self.tile_preunselect_fn(x, z)
				end
			end
		end
    end
end

function TileSelection:ClearPreDiselection()
	local tiles = self.pre_diselected_tiles
    self.pre_diselected_tiles = {}
	for x, zs in pairs(tiles) do
		for z, _ in pairs(zs) do
			if self.tile_unpreunselect_fn then
				self.tile_unpreunselect_fn(x, z)
			end
		end
    end
end

function TileSelection:Hover(tile)		--{x, z}
	if self.current_hover_tile[1] ~= tile[1] or self.current_hover_tile[2] ~= tile[2] then
		self:ClearHover()
		self.current_hover_tile = tile
		self.tile_hovered_fn(tile[1], tile[2])
	end
end

function TileSelection:ClearHover()
	self.tile_unhovered_fn(self.current_hover_tile[1], self.current_hover_tile[2])
	self.current_hover_tile = {}
end

--------------------------------------------------

function TileSelection:IsTileSelected(x, z)
	return type(x) == "number" and type(z) == "number" and self.selected_tiles[x] and self.selected_tiles[x][z]
end

--------------------------------------------------

function TileSelection:SetDisableTileType(tile_types)	--{填WORLD_TILES的Key, ...}
	for i, tile in ipairs(tile_types) do
		if WORLD_TILES[tile] then
			table.insert(self.disable_tile_types, WORLD_TILES[tile])
		end
	end
end

function TileSelection:IsEnableTile(x, z)
	if not self.enable_ocean and TheWorld.Map:IsOceanTileAtPoint(x, 0, z) then
		return false
	end
	local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
	for i, tile_id in ipairs(self.disable_tile_types) do
		if tile == tile_id then
			return false
		end
	end
	return true
end

--------------------------------------------------

function TileSelection:OnEnable()
	--Empty
end

function TileSelection:OnDisable()
	self.mouse_isdown = false
	TheCamera:UnLockHeadingTarget("m23m_plow_tile_selection")	--解锁摄像机视角
	self:RemoveMultSelectRangeImage()
	self.select_quad_screen = {}
	self:ClearPreDiselection()
	self:ClearPreSelection()
	self:ClearHover()
	self:ClearSelection()
end

function TileSelection:OnKill()	--Mod Function
	self:OnDisable()
end


return TileSelection