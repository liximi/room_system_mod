global("TheRegionMgr")
AddPrefabPostInit("forest_network", function(inst)
	if TheWorld.ismastersim then
        inst.M23M_AreaMgr = inst:AddComponent("m23m_area_manager")
        inst.M23M_PowerMgr = inst:AddComponent("m23m_power_manager")

        local start_clock = os:clock()

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

        print(string.format("[M23M] Init Region Manager Cost: %.2f sec", (os:clock() - start_clock)/1000))

        _G.TheRegionMgr = inst.M23M_RegionMgr
    else
        inst.M23M_AreaMgr_client = inst:AddComponent("m23m_area_manager_client")
	end
end)