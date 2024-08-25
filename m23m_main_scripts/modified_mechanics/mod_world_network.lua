global("TheRegionMgr")

local world_networks = {
    "forest_network",
    "cave_network",
}

local function PostInit(inst)
    if TheWorld.ismastersim then
        -- inst.M23M_PowerMgr = inst:AddComponent("m23m_power_manager")

        local start_clock = os:clock()
        local memory_before = collectgarbage("count")

        inst.M23M_RegionMgr = inst:AddComponent("m23m_region_manager")
        local map_w, map_h = TheWorld.Map:GetSize()
        inst.M23M_RegionMgr:Generation(map_w * 4, map_h * 4, 34, 34)    --因为墙体每个只占1格，所以整个地图的尺寸必须是这么多，section尺寸过小会导致性能问题
        local waters = {}
        local min_x, min_z = inst.M23M_RegionMgr:GetPointAtTileCoords(0, 0)
        local max_x, max_z = inst.M23M_RegionMgr:GetPointAtTileCoords(map_w * 4, map_h * 4)
        for  i = min_x, max_x do
            for j = min_z, max_z do
                local is_water = TheWorld.Map:IsOceanTileAtPoint(i, 0, j)
                if is_water then
                    table.insert(waters, {inst.M23M_RegionMgr:GetTileCoordsAtPoint(i, j)})
                end
            end
        end
        inst.M23M_RegionMgr:AddWaters(waters)
        waters = nil
        collectgarbage("collect")
        local end_clock = os:clock()
        local memory_after = collectgarbage("count")
        print(string.format("[M23M] Init Region Manager | Cost Time: %.2f secs | RAM Usage: %.2f Mb", (end_clock - start_clock)/1000, (memory_after - memory_before)/1024))
    else
        inst.M23M_RegionMgr = inst:AddComponent("m23m_region_manager_client")
    end
end


for _, network in ipairs(world_networks) do
    AddPrefabPostInit(network, PostInit)
end
