local Widget = require "widgets/widget"
local NineSlice = require "widgets/nineslice"

local TheInput = TheInput
local ANCHOR_BOTTOM = ANCHOR_BOTTOM
local ANCHOR_LEFT = ANCHOR_LEFT
local TheSim = TheSim

local select_tile_button = AGCW.SELECT_UNIT_BUTTON    --选择地块的鼠标按键


local UnitsSelection = Class(Widget, function(self, tile_selected_fn, tile_unselected_fn, tile_preselected_fn, tile_unpreselected_fn)
    Widget._ctor(self, "UnitsSelection")

    self.tile_selected_fn = tile_selected_fn     		--function(x, z) end 当地块被选中时，对该地块执行操作
    self.tile_unselected_fn = tile_unselected_fn		--function(x, z) end 当地块被取消选中时，对该地块执行操作
    self.tile_preselected_fn = tile_preselected_fn		--function(x, z) end 当地块被预选中时，对该地块执行操作
    self.tile_unpreselected_fn = tile_unpreselected_fn	--function(x, z) end 当地块被取消选中时，对该地块执行操作

    self.selected_tiles = {}        -- 2维矩阵 {[x] = {[z] = true}}
    self.pre_selected_tiles = {}    -- 2维矩阵 {[x] = {[z] = true}}
    self.dragging = false

    self.select_quad_screen = {}    --{{x=number, y=number}, ...}
    --[[ { P_start, P1, P_end, P2 }
        P2 ---------- P_end
        |               |
        |               |
        P_start ------- P1
    ]]
end)


function UnitsSelection:OnMouseButton(button, down)
    if button == select_tile_button then
        if not TheInput:GetHUDEntityUnderMouse() and down then	--如果鼠标下没有UI并且是按下状态，进入选择状态
            self.dragging = true	--触发拖动
            TheCamera:LockHeadingTarget("agcw_plow_tile_selection")	--锁定摄像机视角
            local pos = TheInput:GetScreenPosition()
            self.select_quad_screen[1] = {x = pos.x, y = pos.y}
            self.select_quad_screen[2] = {x = pos.x, y = pos.y}
            self.select_quad_screen[3] = {x = pos.x, y = pos.y}
            self.select_quad_screen[4] = {x = pos.x, y = pos.y}
            self:CreateMultSelectRangeImage()

            if #self.selected_tiles ~= 0 then	--清除已经选择的地块
                self:ClearSelection()
            end
        elseif self.dragging and not down then	--如果正在选择,且不是按下状态
            self.dragging = false	--退出拖动
            TheCamera:UnLockHeadingTarget("agcw_plow_tile_selection")	--解锁摄像机视角
            self:RemoveMultSelectRangeImage()
			self.select_quad_screen = {}
            self:Select()	--确认选择
        end
        return true
    end
end

function UnitsSelection:OnMoveMouse(x, y)
    --更新框选范围的UI显示,并对范围内的地块进行预选择
    if self.dragging then
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
			if IsPointInsideConvexQuad({x = tile.x, y = tile.z}, quad) then
				if not tiles[tile.x] then
					tiles[tile.x] = {}
				end
				tiles[tile.x][tile.z] = true
			end
		end
		self:PreSelect(tiles)
    elseif self.fx_multselect then	--移除框选框
        self:RemoveMultSelectRangeImage()
    end
end

--------------------------------------------------

function UnitsSelection:GetSelectedTiles()
    return self.selected_tiles
end

function UnitsSelection:CreateMultSelectRangeImage()
    self.fx_multselect = self:AddChild(NineSlice("images/ui/fx_multselect.xml",
        "fx_multselect_01.tex", "fx_multselect_02.tex", "fx_multselect_03.tex",
        "fx_multselect_04.tex", "fx_multselect_05.tex", "fx_multselect_06.tex",
        "fx_multselect_07.tex", "fx_multselect_08.tex", "fx_multselect_09.tex"))
    self.fx_multselect:SetSize(0, 0)
    self.fx_multselect:SetPosition(self.select_quad_screen[1].x, self.select_quad_screen[1].y)
    self.fx_multselect:SetVAnchor(ANCHOR_BOTTOM)
    self.fx_multselect:SetHAnchor(ANCHOR_LEFT)
end

function UnitsSelection:RemoveMultSelectRangeImage()
    if self.fx_multselect then
        self.fx_multselect:Kill()
        self.fx_multselect = nil
    end
end

function UnitsSelection:Select(tiles)    --2维矩阵 {[x] = {[z] = true}}
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

function UnitsSelection:ClearSelection()
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

function UnitsSelection:PreSelect(tiles)	--2维矩阵 {[x] = {[z] = true}}
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

function UnitsSelection:ClearPreSelection()
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

--------------------------------------------------

function UnitsSelection:OnEnable()
	--Empty
end

function UnitsSelection:OnDisable()
	self.dragging = false
	TheCamera:UnLockHeadingTarget("agcw_plow_tile_selection")	--解锁摄像机视角
	self:RemoveMultSelectRangeImage()
	self.select_quad_screen = {}
	self:ClearSelection()
end

return UnitsSelection