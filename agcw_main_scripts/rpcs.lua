local json = require "json"


--[[On Server]]

AddModRPCHandler(AGCW.RPC_NAMESPACE, "start_next_turn", function(player)
	if TheWorld.net.components.agcw_enemy_spawner then
		TheWorld.net.components.agcw_enemy_spawner:Start()
	end
end)

AddModRPCHandler(AGCW.RPC_NAMESPACE, "spawn_plowsolid", function(player, tiles)
	tiles = json.decode(tiles)
	if player._current_operate_plow_tile_machine and player._current_operate_plow_tile_machine.doer == player then
		player._current_operate_plow_tile_machine:StartUp(tiles)
	end
end)


--[[On Client]]
-- AddClientModRPCHandler(AGCW.RPC_NAMESPACE, "start_new_turn", function()
	
-- end)