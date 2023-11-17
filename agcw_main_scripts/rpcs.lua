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

AddModRPCHandler(AGCW.RPC_NAMESPACE, "add_area", function(player, tiles)
	tiles = json.decode(tiles)
	if TheWorld and type(tiles) == "table" then
		local _tiles = {}
		for _, pt in ipairs(tiles) do
			if not _tiles[pt[1]] then
				_tiles[pt[1]] = {}
			end
			_tiles[pt[1]][pt[2]] = true
		end
		TheWorld.net.AgcwAreaMgr:AddArea(_tiles, nil, player.user_id)
	end
end)

AddModRPCHandler(AGCW.RPC_NAMESPACE, "area_might_type", function(player, tiles)
	tiles = json.decode(tiles)
	if TheWorld and type(tiles) == "table" then
		local _tiles = {}
		for _, pt in ipairs(tiles) do
			if not _tiles[pt[1]] then
				_tiles[pt[1]] = {}
			end
			_tiles[pt[1]][pt[2]] = true
		end
		TheWorld.net.AgcwAreaMgr:AddArea(_tiles, nil, player.user_id)
	end
end)

AddModRPCHandler(AGCW.RPC_NAMESPACE, "change_area_type", function(player, tiles)
	tiles = json.decode(tiles)
	if TheWorld and type(tiles) == "table" then
		local _tiles = {}
		for _, pt in ipairs(tiles) do
			if not _tiles[pt[1]] then
				_tiles[pt[1]] = {}
			end
			_tiles[pt[1]][pt[2]] = true
		end
		TheWorld.net.AgcwAreaMgr:AddArea(_tiles, nil, player.user_id)
	end
end)


--[[On Client]]
AddClientModRPCHandler(AGCW.RPC_NAMESPACE, "refresh_area_data", function(id, tiles, area_type)
	if TheWorld and id then
		tiles = json.decode(tiles)
		local _tiles = {}
		for _, tile in ipairs(tiles) do
			if not _tiles[tile[1]] then
				_tiles[tile[1]] = {}
			end
			_tiles[tile[1]][tile[2]] = true
		end
		if TheWorld.net.AgcwAreaMgr_client then
			TheWorld.net.AgcwAreaMgr_client:RefreshClientData(tostring(id), _tiles, area_type)
		end
	end
end)

AddClientModRPCHandler(AGCW.RPC_NAMESPACE, "remove_area", function(id)
	if TheWorld and id then
		if TheWorld.net.AgcwAreaMgr_client then
			TheWorld.net.AgcwAreaMgr_client:RefreshClientData(tostring(id), nil, nil, true)
		end
	end
end)