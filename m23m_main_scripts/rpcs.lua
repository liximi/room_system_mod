local json = require "json"


--[[On Server]]

-- AddModRPCHandler(M23M.RPC_NAMESPACE, "", function(player, tiles)
-- end)


--[[On Client]]
AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_size_data", function(width, height, section_width, section_height)
	if TheRegionMgr and TheRegionMgr.ReceiveMapSizeData and width and height and section_width and section_height then
		TheRegionMgr:ReceiveMapSizeData(width, height, section_width, section_height)
		print(string.format("Start receiving region datas from server.\n\twidth: %d\n\theight: %d\n\tsection_width: %d\n\tsection_height: %d", width, height, section_width, section_height))
	end
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_rooms_data", function(rooms_code)
	if TheRegionMgr and TheRegionMgr.ReceiveRoomsData and type(rooms_code) == "string" then
		local start_clock = os.clock()
		local start_mem = collectgarbage("count")
		TheRegionMgr:ReceiveRoomsData(rooms_code, true)
		print(string.format("Received init rooms data, cost time: ~%.4fs, cost memory: ~%.4fMb", os.clock() - start_clock, (collectgarbage("count") - start_mem)/1024))
	end
	rooms_code = nil
	collectgarbage("collect")
end)

local start_receiving_init_tiles_data_clock, start_receiving_init_tiles_data_mem
AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_tiles_stream", function(tiles_stream)
	if TheRegionMgr and TheRegionMgr.ReceiveTileStream and type(tiles_stream) == "string" then
		if not start_receiving_init_tiles_data_clock then
			start_receiving_init_tiles_data_clock = os.clock()
			start_receiving_init_tiles_data_mem = collectgarbage("count")
		end
		local finished = TheRegionMgr:ReceiveTileStream(tiles_stream)
		if finished then
			print(string.format("Received init tiles data, cost time: ~%.4fs, cost memory: ~%.4fMb", os.clock() - start_receiving_init_tiles_data_clock, (collectgarbage("count") - start_receiving_init_tiles_data_mem)/1024))
			print("Finished receiving datas from server.")
		end
	end
	tiles_stream = nil
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_update_section_data", function(data_pack)	--{tiles = {要更新的地块数据}, rooms = {全部房间数据}}
	local data = json.decode(data_pack)
	if TheRegionMgr and TheRegionMgr.ReceiveSectionUpdateData and type(data) == "table" then
		TheRegionMgr:ReceiveSectionUpdateData(data)
	end
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_update_room_type", function(changes)	--{{room_id, room_type}, ...}
	local data = json.decode(changes)
	if TheRegionMgr and TheRegionMgr.ReceiveRoomsTypeUpdateData and type(data) == "table" then
		TheRegionMgr:ReceiveRoomsTypeUpdateData(data)
	end
end)