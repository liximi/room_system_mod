local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Templates = require "widgets/redux/templates"

local HUD = Class(Widget, function(self, owner)
    Widget._ctor(self, "IndustHUD")
	self.owner = owner
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)

	--ROOTS
	self.top_root = self:AddChild(Widget("ROOT"))
	self.top_root:SetVAnchor(ANCHOR_TOP)
	self.top_root:SetHAnchor(ANCHOR_MIDDLE)

	--敌人刷新按钮
	-- self.current_turn_text = self.top_root:AddChild(Text(UIFONT, 28, tostring(TheWorld.net.replica.agcw_enemy_spawner:GetCurrentTurn())))
	-- self.current_turn_text:SetPosition(0, -50)
	-- self.start_next_turn_bt = self.top_root:AddChild(Templates.StandardButton(function () self:StartNextTurn() end,
	-- 	STRINGS.UI.SC_NEXT_TURN, {200, 50}))
	-- self.start_next_turn_bt:SetPosition(0, -90)

	-- self.inst:ListenForEvent("agcw_enemy_spawner.current_turn", function()
	-- 	local current_turn = TheWorld.net.replica.agcw_enemy_spawner:GetCurrentTurn()
	-- 	self.current_turn_text:SetString(tostring(current_turn))
	-- end, TheWorld.net)

	-- self.inst:ListenForEvent("agcw_enemy_spawner.is_started", function()
	-- 	if TheWorld.net.replica.agcw_enemy_spawner:IsStarted() then
	-- 		self.start_next_turn_bt:Disable()
	-- 	else
	-- 		self.start_next_turn_bt:Enable()
	-- 	end
	-- end, TheWorld.net)
end)


function HUD:StartNextTurn()
	SendModRPCToServer(MOD_RPC[AGCW.RPC_NAMESPACE].start_next_turn)
end

return HUD