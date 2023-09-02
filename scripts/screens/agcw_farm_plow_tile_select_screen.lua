local Widget = require "widgets.widget"
local Screen = require "widgets.screen"
local Image = require "widgets.image"
local ImageButton = require "widgets.imagebutton"
local Text = require "widgets.text"


local PlowTileSelect = Class(Screen, function(self, owner, data)
	Screen._ctor(self, "PlowTileSelect")
	self.owner = owner
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self.root = self:AddChild(Widget("ROOT"))

end)


--------------------------------------------------

function PlowTileSelect:OnDestroy()
    SetAutopaused(false)
    POPUPS.AGCW_PLOW_TILE_SELECT:Close(self.owner)
	PlowTileSelect._base.OnDestroy(self)

	if type(self.tile_outlines) == "table" then
		for x, zs in pairs(self.tile_outlines) do
			for z, outline in pairs(zs) do
				outline:Remove()
			end
		end
	end
	if type(self.preselect_tile_outlines) == "table" then
		for x, zs in pairs(self.preselect_tile_outlines) do
			for z, outline in pairs(zs) do
				outline:Remove()
			end
		end
	end
end

function PlowTileSelect:OnBecomeInactive()
    PlowTileSelect._base.OnBecomeInactive(self)
	ThePlayer.HUD.controls.indust_hud.interactive_functions:DisablePlowTileSelection()
end

function PlowTileSelect:OnBecomeActive()
    PlowTileSelect._base.OnBecomeActive(self)
	self.tile_outlines = {}
	self.preselect_tile_outlines = {}
	local tile_selected_fn = function(x, z)
		if not self.tile_outlines[x] then
			self.tile_outlines[x] = {}
		end
		if self.tile_outlines[x][z] then
			return
		end
		local outline = SpawnPrefab("tile_outline")
		outline.Transform:SetPosition(x, 0, z)
		outline.AnimState:SetAddColour(0.5, 1, 0.5, 1)
		self.tile_outlines[x][z] = outline
	end
	local tile_unselected_fn = function(x, z)
		if not self.tile_outlines[x] or not self.tile_outlines[x][z] then
			return
		end
		self.tile_outlines[x][z]:Remove()
		self.tile_outlines[x][z] = nil
	end
	local tile_preselected_fn = function(x, z)
		if not self.preselect_tile_outlines[x] then
			self.preselect_tile_outlines[x] = {}
		end
		if self.preselect_tile_outlines[x][z] or (self.tile_outlines[x] and self.tile_outlines[x][z]) then
			return
		end
		local outline = SpawnPrefab("tile_outline")
		outline.Transform:SetPosition(x, 0, z)
		outline.AnimState:SetAddColour(1, 1, 1, 1)
		self.preselect_tile_outlines[x][z] = outline
	end
	local tile_unpreselected_fn = function(x, z)
		if not self.preselect_tile_outlines[x] or not self.preselect_tile_outlines[x][z] then
			return
		end
		self.preselect_tile_outlines[x][z]:Remove()
		self.preselect_tile_outlines[x][z] = nil
	end
	ThePlayer.HUD.controls.indust_hud.interactive_functions:EnablePlowTileSelection(tile_selected_fn, tile_unselected_fn, tile_preselected_fn, tile_unpreselected_fn)
end

function PlowTileSelect:OnControl(control, down)
    if PlowTileSelect._base.OnControl(self, control, down) then return true end

    if not down and (control == CONTROL_MAP or control == CONTROL_CANCEL) then
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        TheFrontEnd:PopScreen()
        return true
    end

	return false
end


-- function PlowTileSelect:OnUpdate(dt)
-- end



return PlowTileSelect
