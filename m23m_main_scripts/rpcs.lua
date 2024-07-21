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
		TheWorld.net.M23M_AreaMgr:AddArea(_tiles, nil, player.userid)
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
		TheWorld.net.M23M_AreaMgr:AddArea(_tiles, nil, player.userid)
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
		TheWorld.net.M23M_AreaMgr:AddArea(_tiles, nil, player.userid)
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


AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_size_data", function(width, height, section_width, section_height)
	-- print("region_system_init_size_data", width, height, section_width, section_height)
	if TheRegionMgr and TheRegionMgr.ReceiveMapSizeData and width and height and section_width and section_height then
		TheRegionMgr:ReceiveMapSizeData(width, height, section_width, section_height)
	end
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_rooms_data", function(rooms_code)
	local rooms = json.decode(rooms_code)
	-- print("region_system_init_rooms_data", rooms)
	if TheRegionMgr and TheRegionMgr.ReceiveRoomsData and type(rooms) == "table" then
		TheRegionMgr:ReceiveRoomsData(rooms, true)
	end
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_tiles_stream", function(tiles_stream)
	local tiles = json.decode(tiles_stream)
	-- print("region_system_init_tiles_stream", tiles)
	if TheRegionMgr and TheRegionMgr.ReceiveTileStream and type(tiles) == "table" then
		TheRegionMgr:ReceiveTileStream(tiles)
	end
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_update_section_data", function(data_pack)	--{tiles = {要更新的地块数据}, rooms = {全部房间数据}}
	local data = json.decode(data_pack)
	-- print("region_system_update_section_data", data)
	if TheRegionMgr and TheRegionMgr.ReceiveSectionUpdateData and type(data) == "table" then
		TheRegionMgr:ReceiveSectionUpdateData(data)
	end
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_update_room_type", function(changes)	--{{room_id, room_type}, ...}
	local data = json.decode(changes)
	-- print("region_system_update_room_type", data)
	if TheRegionMgr and TheRegionMgr.ReceiveRoomsTypeUpdateData and type(data) == "table" then
		TheRegionMgr:ReceiveRoomsTypeUpdateData(data)
	end
end)