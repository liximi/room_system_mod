local AGCW_HUD = require "widgets.agcw_hud"
AddClassPostConstruct("widgets/controls", function (self)
    --添加新UI
    self.indust_hud = self:AddChild(AGCW_HUD(self.owner))
    self.indust_hud:MoveToFront()
end)