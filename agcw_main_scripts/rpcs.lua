local json = require "json"


--[[On Server]]

AddModRPCHandler(AGCW.RPC_NAMESPACE, "start_next_turn", function(player)
	if TheWorld.net.components.agcw_enemy_spawner then
		TheWorld.net.components.agcw_enemy_spawner:Start()
	end
end)


--[[On Client]]
-- AddClientModRPCHandler(AGCW.RPC_NAMESPACE, "start_new_turn", function()
	
-- end)