local json = require "json"


--[[On Server]]

-- AddModRPCHandler(M23M.RPC_NAMESPACE, "", function(player, tiles)
-- end)


--[[On Client]]
AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_size_data", function(width, height, section_width, section_height)
	-- print("region_system_init_size_data", width, height, section_width, section_height)
	if TheRegionMgr and TheRegionMgr.ReceiveMapSizeData and width and height and section_width and section_height then
		TheRegionMgr:ReceiveMapSizeData(width, height, section_width, section_height)
	end
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_rooms_data", function(rooms_code)
	-- print("region_system_init_rooms_data", rooms)
	if TheRegionMgr and TheRegionMgr.ReceiveRoomsData and type(rooms_code) == "string" then
		TheRegionMgr:ReceiveRoomsData(rooms_code, true)
	end
	rooms_code = nil
	collectgarbage("collect")
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_tiles_stream", function(tiles_stream)
	-- print("region_system_init_tiles_stream", tiles)
	if TheRegionMgr and TheRegionMgr.ReceiveTileStream and type(tiles_stream) == "string" then
		TheRegionMgr:ReceiveTileStream(tiles_stream)
	end
	tiles_stream = nil
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