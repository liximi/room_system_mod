local json = require "json"


--[[On Server]]

AddModRPCHandler(M23M.RPC_NAMESPACE, "add_area", function(player, tiles)
	tiles = json.decode(tiles)
	if TheWorld and type(tiles) == "table" then
		local _tiles = {}
		for _, pt in ipairs(tiles) do
			if not _tiles[pt[1]] then
				_tiles[pt[1]] = {}
			end
			_tiles[pt[1]][pt[2]] = true
		end
		TheWorld.net.M23M_AreaMgr:AddArea(_tiles, nil, player.user_id)
	end
end)

AddModRPCHandler(M23M.RPC_NAMESPACE, "area_might_type", function(player, tiles)
	tiles = json.decode(tiles)
	if TheWorld and type(tiles) == "table" then
		local _tiles = {}
		for _, pt in ipairs(tiles) do
			if not _tiles[pt[1]] then
				_tiles[pt[1]] = {}
			end
			_tiles[pt[1]][pt[2]] = true
		end
		TheWorld.net.M23M_AreaMgr:AddArea(_tiles, nil, player.user_id)
	end
end)

AddModRPCHandler(M23M.RPC_NAMESPACE, "change_area_type", function(player, tiles)
	tiles = json.decode(tiles)
	if TheWorld and type(tiles) == "table" then
		local _tiles = {}
		for _, pt in ipairs(tiles) do
			if not _tiles[pt[1]] then
				_tiles[pt[1]] = {}
			end
			_tiles[pt[1]][pt[2]] = true
		end
		TheWorld.net.M23M_AreaMgr:AddArea(_tiles, nil, player.user_id)
	end
end)


--[[On Client]]
AddClientModRPCHandler(M23M.RPC_NAMESPACE, "refresh_area_data", function(id, tiles, area_type)
	if TheWorld and id then
		tiles = json.decode(tiles)
		local _tiles = {}
		for _, tile in ipairs(tiles) do
			if not _tiles[tile[1]] then
				_tiles[tile[1]] = {}
			end
			_tiles[tile[1]][tile[2]] = true
		end
		if TheWorld.net.M23M_AreaMgr_client then
			TheWorld.net.M23M_AreaMgr_client:RefreshClientData(tostring(id), _tiles, area_type)
		end
	end
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "remove_area", function(id)
	if TheWorld and id then
		if TheWorld.net.M23M_AreaMgr_client then
			TheWorld.net.M23M_AreaMgr_client:RefreshClientData(tostring(id), nil, nil, true)
		end
	end
end)