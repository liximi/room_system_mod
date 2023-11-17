local json = require "json"
local Text = require "widgets/text"

AddClassPostConstruct("widgets/widget", function(self)
	local old_kill = self.Kill
	function self:Kill()
		if self.OnKill then
			self:OnKill()
		end
		old_kill(self)
	end
end)

local AGCW_HUD = require "widgets/agcw_hud"
AddClassPostConstruct("widgets/controls", function(self)
    --添加新UI
    self.indust_hud = self:AddChild(AGCW_HUD(self.owner))
    self.indust_hud:MoveToFront()

	self.xp = self:AddChild(Text(UIFONT, 28, "X正"))
    self.xn = self:AddChild(Text(UIFONT, 28, "X负"))
    self.zp = self:AddChild(Text(UIFONT, 28, "Z正"))
    self.zn = self:AddChild(Text(UIFONT, 28, "Z负"))

    self.inst:DoPeriodicTask(FRAMES, function ()
        local pos = ThePlayer:GetPosition()
        self.xp:SetPosition(TheSim:GetScreenPos((pos+Vector3(2,0,0)):Get()))
        self.xn:SetPosition(TheSim:GetScreenPos((pos+Vector3(-2,0,0)):Get()))
        self.zp:SetPosition(TheSim:GetScreenPos((pos+Vector3(0,0,2)):Get()))
        self.zn:SetPosition(TheSim:GetScreenPos((pos+Vector3(0,0,-2)):Get()))
    end)
end)


--<选择开垦地块Screen>
local PlowTileSelectScreen = require "screens/agcw_farm_plow_tile_select_screen"
AddClassPostConstruct("screens/playerhud", function(self)
	function self:Open_AGCW_TileSelectScreen(data)
		self:Close_AGCW_TileSelectScreen()
		self.agcw_plow_tile_select_screen = PlowTileSelectScreen(self.owner, data)
		self:OpenScreenUnderPause(self.agcw_plow_tile_select_screen)
		return true
	end

	function self:Close_AGCW_TileSelectScreen()
		if self.agcw_plow_tile_select_screen ~= nil then
			if self.agcw_plow_tile_select_screen.inst:IsValid() then
				TheFrontEnd:PopScreen(self.agcw_plow_tile_select_screen)
			end
			self.agcw_plow_tile_select_screen = nil
		end
	end
end)

local popup_plow_tile_select = AddPopup("AGCW_PLOW_TILE_SELECT")
popup_plow_tile_select.fn = function(inst, show, data)
	if type(data) == "string" then
		data = json.decode(data)
	end
    if inst.HUD then
        if not show then
            inst.HUD:Close_AGCW_TileSelectScreen()
        elseif not inst.HUD:Open_AGCW_TileSelectScreen(data) then
            POPUPS.AGCW_PLOW_TILE_SELECT:Close(inst)
        end
    end
end

--<编辑区域Screen>
local AreaEditScreen = require "screens/agcw_area_edit_screen"
AddClassPostConstruct("screens/playerhud", function(self)
	function self:Open_AGCW_AreaEditScreen(data)
		self:Close_AGCW_AreaEditScreen()
		self.agcw_area_edit_screen = AreaEditScreen(self.owner, data)
		self:OpenScreenUnderPause(self.agcw_area_edit_screen)
		return true
	end

	function self:Close_AGCW_AreaEditScreen()
		if self.agcw_area_edit_screen ~= nil then
			if self.agcw_area_edit_screen.inst:IsValid() then
				TheFrontEnd:PopScreen(self.agcw_area_edit_screen)
			end
			self.agcw_area_edit_screen = nil
		end
	end
end)

local popup_area_edit = AddPopup("AGCW_AREA_EDIT")
popup_area_edit.fn = function(inst, show, data)
	if type(data) == "string" then
		data = json.decode(data)
	end
    if inst.HUD then
        if not show then
            inst.HUD:Close_AGCW_AreaEditScreen()
        elseif not inst.HUD:Open_AGCW_AreaEditScreen(data) then
            POPUPS.AGCW_AREA_EDIT:Close(inst)
        end
    end
end