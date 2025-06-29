local json = require "json"
local function IsRegionMgrExist()
    if TheRegionMgr ~= nil then
        return true
    else
        M23MLogUtils.PrintErrorLog("TheRegionMgr is not exist.")
        return false
    end
end

--[[On Server]]

AddModRPCHandler(M23M.RPC_NAMESPACE, "region_system_require_rooms_data", function(player)
    if IsRegionMgrExist() then
        M23MLogUtils.PrintRPCLog(string.format("Player %s (%s) requires rooms data.", player.name, player.userid))
        TheRegionMgr:CheckData()
        TheRegionMgr:RefreashRooms()
        TheRegionMgr:SendAllDatasToPlayer(player)
    end
end)

AddModRPCHandler(M23M.RPC_NAMESPACE, "region_system_not_find_room", function(player, room_id)
    if IsRegionMgrExist() then
        M23MLogUtils.PrintRPCLog(string.format("Player %s (%s) was not find room: %s.", player.name, player.userid,
            tostring(room_id)))
        -- TheRegionMgr:SendAllDatasToPlayer(player)
    end
end)

--[[On Client]]

--Init Datas
AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_size_data",
    function(width, height, section_width, section_height)
        if IsRegionMgrExist() and TheRegionMgr.ReceiveMapSizeData and width and height and section_width and section_height then
            TheRegionMgr:ReceiveMapSizeData(width, height, section_width, section_height)
            M23MLogUtils.PrintRPCLog(string.format(
                "Start receiving region datas from server.\n\twidth: %d\n\theight: %d\n\tsection_width: %d\n\tsection_height: %d",
                width, height, section_width, section_height))
        end
    end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_rooms_data", function(rooms_code)
    if IsRegionMgrExist() and TheRegionMgr.ReceiveRoomsData and type(rooms_code) == "string" then
        local start_clock = os.clock()
        local start_mem = collectgarbage("count")
        TheRegionMgr:ReceiveRoomsData(rooms_code, true)
        M23MLogUtils.PrintRPCLog(string.format("Received init rooms data, cost time: ~%.4fs, cost memory: ~%.4fMb",
            os.clock() - start_clock, (collectgarbage("count") - start_mem) / 1024))
    end
    rooms_code = nil
    collectgarbage("collect")
end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_init_data", function(sections_cache)
    if IsRegionMgrExist() and TheRegionMgr.ReceiveInitSectionCache and type(sections_cache) == "string" then
        TheRegionMgr:ReceiveInitSectionCache(sections_cache)
    end
    sections_cache = nil
end)


--Update Datas

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_update_section_data",
    function(data_pack) -- {tiles = {要更新的地块数据}, rooms = {全部房间数据}}
        local data = json.decode(data_pack)
        if IsRegionMgrExist() and TheRegionMgr.ReceiveSectionUpdateData and type(data) == "table" then
            TheRegionMgr:ReceiveSectionUpdateData(data)
        end
    end)

AddClientModRPCHandler(M23M.RPC_NAMESPACE, "region_system_update_room_type",
    function(changes) -- {{room_id, room_type}, ...}
        local data = json.decode(changes)
        if IsRegionMgrExist() and TheRegionMgr.ReceiveRoomsTypeUpdateData and type(data) == "table" then
            TheRegionMgr:ReceiveRoomsTypeUpdateData(data)
        end
    end)
