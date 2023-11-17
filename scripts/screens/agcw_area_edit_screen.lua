local json = require "json"
local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Templates = require "widgets/redux/templates"
local PlowTileSelect = require "widgets/agcw_tile_selection"


local AreaEditScreen = Class(Screen, function(self, owner, data)
	Screen._ctor(self, "AreaEditScreen")
	self.owner = owner
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
	--ROOTS
    self.root = self:AddChild(Widget("ROOT"))
	self.top_root = self:AddChild(Widget("ROOT"))
	self.top_root:SetVAnchor(ANCHOR_TOP)
	self.top_root:SetHAnchor(ANCHOR_MIDDLE)

	self.title = self.top_root:AddChild(Text(TITLEFONT, 64, "编辑区域", RGB(255, 255, 255)))
	self.title:SetPosition(0, -50)

	self.ok_bt = self.top_root:AddChild(Templates.StandardButton(function()
		local tiles = self.selection_function and self.selection_function:GetSelectedTiles()
		if tiles then
			local _tiles = {}
			for x, zs in pairs(tiles) do
				for z, _ in pairs(zs) do
					table.insert(_tiles, {x, z})	--由于json.encode会改变表结构，因此需要重新处理表结构
				end
			end
			SendModRPCToServer(MOD_RPC[AGCW.RPC_NAMESPACE].add_area, json.encode(_tiles))
		end
        TheFrontEnd:PopScreen()
	end, "确定", {100, 50}))
	self.ok_bt:SetPosition(-80, -100)
	self.cancel_bt = self.top_root:AddChild(Templates.StandardButton(function()
        TheFrontEnd:PopScreen()
	end, "取消", {100, 50}))
	self.cancel_bt:SetPosition(80, -100)
end)


--------------------------------------------------

function AreaEditScreen:OnDestroy()
    SetAutopaused(false)
    POPUPS.AGCW_AREA_EDIT:Close(self.owner)
	AreaEditScreen._base.OnDestroy(self)
end

function AreaEditScreen:OnBecomeInactive()
    AreaEditScreen._base.OnBecomeInactive(self)
	TheAgcwInteractive:StopFunction(self.selection_function)
	if self.selection_function then
		self.selection_function:Kill()
	end
end

function AreaEditScreen:OnBecomeActive()
    AreaEditScreen._base.OnBecomeActive(self)
	if self.selection_function then
		self.selection_function:Kill()
	end
	self.selection_function = self:AddChild(PlowTileSelect())
	-- self.selection_function:SetDisableTileType({"FARMING_SOIL"})
	TheAgcwInteractive:StartFunction(self.selection_function)
end

function AreaEditScreen:OnControl(control, down)
    if AreaEditScreen._base.OnControl(self, control, down) then return true end

    if not down and (control == CONTROL_MAP or control == CONTROL_CANCEL) then
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        TheFrontEnd:PopScreen()
        return true
    end

	return false
end


-- function AreaEditScreen:OnUpdate(dt)
-- end



return AreaEditScreen
