local TILE_SIZE = 4
local POWERSOURCE_COMPONENT = "agcw_power_source"
local POWERAPPLIANCE_COMPONENT = "agcw_power_appliance"
local VAILD_TILE = GROUND.ARCHIVE

local function debug_print(...)
	-- return print(...)
end

local PowerManager = Class(function(self, inst)
    self.inst = inst

	self.nets = {}				--{net_id = {"tile_x-tile_z" = {[1] = x, [2] = z}, ...}, ...}

	self.efficiencies = {}		--{net_id = efficieny number, ...}
	self.power_outputs = {}		--{net_id = power output, ...}
	self.power_demands = {}		--{net_id = power demand, ...}

	self.power_sources = {}		--{tile_id = {"power source" = true, ...}, ...}
	self.power_appliances = {}	--{tile_id = {"power appliance" = true, ...}, ...}

	self.waitting_for_update_efficiency_nets = {}	--{net_id = {"output_delta"= number, "demand_delta" = number}}

	self.onterraform = function(world, data)
		if data.tile == VAILD_TILE then
			local pt = self:GetTilePosByTileCoord(data.x, data.y)
			self:AddTile(pt.x, pt.z, true)
		end
		if data.original_tile == VAILD_TILE then
			local pt = self:GetTilePosByTileCoord(data.x, data.y)
			self:RemoveTile(pt.x, pt.z, true)
		end
	end
	self.inst:ListenForEvent("onterraform", self.onterraform, TheWorld)
	self:Init_Private()
	self:StartUpdate()
end)


------------------------------
-- About Tile
------------------------------

function PowerManager:GetTileId(pos_x, pos_z, is_center_pos)
	if not is_center_pos then
		local y
		pos_x, y, pos_z = TheWorld.Map:GetTileCenterPoint(pos_x, 0, pos_z)
	end
	return tostring(pos_x).."-"..tostring(pos_z), pos_x, pos_z
end

function PowerManager:GetTilePos(tile_id)
	local x, z = string.match(tile_id, "(-?%d+)-(-?%d+)")
	return tonumber(x), tonumber(z)
end

function PowerManager:GetTilePosByTileCoord(x, y)	--return Vector3
	local zero_coord_x, zero_coord_y = TheWorld.Map:GetTileCoordsAtPoint(0, 0, 0)
	local zero_tile_pt = Vector3(TheWorld.Map:GetTileCenterPoint(0, 0, 0))
	return zero_tile_pt + Vector3((x - zero_coord_x) * TILE_SIZE, 0, (y - zero_coord_y) * TILE_SIZE)
end

function PowerManager:Init_Private()
	local world_w, world_h = TheWorld.Map:GetSize()
	local zero_coord_x, zero_coord_y = TheWorld.Map:GetTileCoordsAtPoint(0, 0, 0)
	local zero_tile_pt = Vector3(TheWorld.Map:GetTileCenterPoint(0, 0, 0))
	print("PowerManager:Init_Private()")
	for i = 0, world_w do
		for j = 0, world_h do
			local tile = TheWorld.Map:GetTile(i, j)
			if tile == VAILD_TILE then
				local pt = zero_tile_pt + Vector3((i - zero_coord_x) * TILE_SIZE, 0, (j - zero_coord_y) * TILE_SIZE)
				self:AddTile(pt.x, pt.z, true)
			end
		end
	end
end

function PowerManager:GetNetIdByTile(pos_x, pos_z, is_center_pos)
	local tile_id = type(pos_x) == "string" and pos_x or self:GetTileId(pos_x, pos_z, is_center_pos)
	for net_id, tiles in pairs(self.nets) do
		if tiles[tile_id] then
			return net_id
		end
	end
end

function PowerManager:AddTile(pos_x, pos_z, is_center_pos)
	debug_print("---------------")
	debug_print("PowerManager:AddTile()", pos_x, pos_z, is_center_pos)
	local tile_id = type(pos_x) == "string" and pos_x or self:GetTileId(pos_x, pos_z, is_center_pos)
	--如果该地块已经在网络中，则直接返回当前的net id
	local net_id = self:GetNetIdByTile(tile_id, nil, is_center_pos)
	if net_id then
		debug_print("PowerManager:AddTile() Aleady In The Net", net_id)
		return tile_id, net_id
	end
	--如果该地块旁边的地块已经在网络中，则将其加入其中，并判断是否要连接两个原本分开的网络
	local connected_nets = {}
	for i, tile_pos in ipairs(self:GetNeighborTiles(pos_x, pos_z, is_center_pos)) do
		local _net_id = self:GetNetIdByTile(tile_pos[1], tile_pos[2], true)
		if _net_id then
			local aleady_in = false
			for j, id in ipairs(connected_nets) do
				if _net_id == id then
					aleady_in = true
					break
				end
			end
			if not aleady_in then
				table.insert(connected_nets, _net_id)
			end
		end
	end
	if #connected_nets > 0 then
		local _net_id = connected_nets[1]
		debug_print("PowerManager:AddTile() Join The Net", _net_id)
		self.nets[_net_id][tile_id] = {self:GetTilePos(tile_id)}
		if #connected_nets > 1 then
			for i = 2, #connected_nets do
				local _id = connected_nets[i]
				for _tile_id, _tile_pos in pairs(self.nets[_id]) do
					self.nets[_net_id][_tile_id] = _tile_pos
					debug_print("PowerManager:AddTile() Merge The Net", _id, "->", _net_id, "tile:", _tile_id)
				end
				self.nets[_id] = {}
				self:DeleteNet_Private(_id)
			end
		end
		self:OnTileChanged_Private(_net_id)
		return tile_id, _net_id
	end
	--创建新网络，将地块加入其中
	local net
	net_id, net = self:CreateNet_Private()
	net[tile_id] = {self:GetTilePos(tile_id)}
	self:OnTileChanged_Private(net_id)
	debug_print("PowerManager:AddTile() Create The Net", net_id)
	return tile_id, net_id
end

function PowerManager:RemoveTile(pos_x, pos_z, is_center_pos)
	local tile_id = type(pos_x) == "string" and pos_x or self:GetTileId(pos_x, pos_z, is_center_pos)
	local net_id = self:GetNetIdByTile(tile_id, nil, is_center_pos)
	--如果该地块不在网络中，则直接返回
	if not net_id then
		return
	end
	--从网络中移除当前地块
	self.nets[net_id][tile_id] = nil

	local empty = true
	local only_one_connect = true
	local neighbor_tiles = self:GetNeighborTiles(pos_x, pos_z, is_center_pos)
	local count = 0
	for i, tile in ipairs(neighbor_tiles) do
		local id = self:GetTileId(tile[1], tile[2], true)
		if self.nets[net_id][id] then
			empty = false
			count = count + 1
			if count > 1 then
				only_one_connect = false
				break
			end
		end
	end
	--如果该网络中没有其他地块了，则移除该网络
	if empty then
		self:DeleteNet_Private(net_id)
		return
	end
	--如果该地块原先值连接着一个地块，则不用继续进行其他判断
	if only_one_connect then
		self:OnTileChanged_Private(net_id)
		return
	end
	--否则，判断移除该地块是否导致原先的网络被拆分成了多个网络
	--[[从当前网络中的任一地块出发，遍历与其相连的所有其他地块，并将其计入一个新网络中
		如果遍历完成后仍然有地块没有被遍历到，则从没有被遍历到的地块出发，重复上一步
		直到遍历完所有地块，就能得出，哪些地块被分成了几个网络
	]]
	local vaild_tiles = {}		--所有需要遍历的地块 {"tile id" = "tile pos"}
	local new_nets = {}			--要计算的网络结果  Array[ "a net table", ... ]
	local vaild_tiles_is_empty = false
	for id, pos in pairs(self.nets[net_id]) do
		vaild_tiles[id] = pos
	end

	while not vaild_tiles_is_empty do
		local net = {}
		local open_list = {}
		local closed_list = {}
		local cur_tile_id, cur_tile_pos
		for id, pos in pairs(vaild_tiles) do
			cur_tile_id = id
			cur_tile_pos = pos
			vaild_tiles[id] = nil
			closed_list[id] = pos
			break
		end

		while cur_tile_id ~= nil do
			net[cur_tile_id] = cur_tile_pos
			local tiles = self:GetNeighborTiles(cur_tile_pos[1], cur_tile_pos[2], true)
			for i, tile in ipairs(tiles) do
				local id = self:GetTileId(tile[1], tile[2], true)
				if self.nets[net_id][id] and not closed_list[id] and not open_list[id] then
					open_list[id] = tile
				end
			end
			cur_tile_id = nil
			for id, pos in pairs(open_list) do
				cur_tile_id = id
				cur_tile_pos = pos
				vaild_tiles[id] = nil
				open_list[id] = nil
				closed_list[id] = pos
				break
			end
		end
		table.insert(new_nets, net)
		vaild_tiles_is_empty = true
		for id, _ in pairs(vaild_tiles) do
			vaild_tiles_is_empty = false
			break
		end
	end

	if #new_nets > 1 then
		self.nets[net_id] = table.remove(new_nets)
		self:OnTileChanged_Private(net_id)
		for i, net in ipairs(new_nets) do
			local new_net_id = self:CreateNet_Private()
			self.nets[new_net_id] = net
			self:OnTileChanged_Private(new_net_id)
		end
	end
end

function PowerManager:GetNeighborTiles(pos_x, pos_z, is_center_pos)		--return Array[ {[1]=x, [2]=z} ]
	if type(pos_x) == "string" then
		pos_x, pos_z = self:GetTilePos(pos_x)
	elseif not is_center_pos then
		local y
		pos_x, y, pos_z = TheWorld.Map:GetTileCenterPoint(pos_x, 0, pos_z)
	end
	return {
		{pos_x - TILE_SIZE, pos_z}, {pos_x + TILE_SIZE, pos_z},
		{pos_x, pos_z - TILE_SIZE}, {pos_x, pos_z + TILE_SIZE},
		{pos_x - TILE_SIZE, pos_z - TILE_SIZE}, {pos_x + TILE_SIZE, pos_z + TILE_SIZE},
		{pos_x - TILE_SIZE, pos_z + TILE_SIZE}, {pos_x + TILE_SIZE, pos_z - TILE_SIZE},
	}
end


------------------------------
-- About Power Source & Power Applicance
------------------------------

function PowerManager:AddPowerSource(power_source, tile_x, tile_z)	--return success or faild, net id
	if not power_source:IsValid() or not power_source.components[POWERSOURCE_COMPONENT] then
		return false
	end

	for tile_id, power_sources in pairs(self.power_sources) do
		if power_sources[power_source] then
			return false, self:GetNetIdByTile(tile_id)
		end
	end

	local tile_id = self:GetTileId(tile_x, tile_z)
	if not self.power_sources[tile_id] then
		self.power_sources[tile_id] = {}
	end
	self.power_sources[tile_id][power_source] = true

	local net_id = self:GetNetIdByTile(tile_id)
	if net_id then
		local output = power_source.components[POWERSOURCE_COMPONENT]:GetCurrentOuput()
		self:AddEfficiencyDeltaBuffer_Private(net_id, output)
		return true, net_id
	else
		return false
	end
end

function PowerManager:RemovePowerSource(power_source)
	for tile_id, power_sources in pairs(self.power_sources) do
		if power_sources[power_source] then
			power_sources[power_source] = nil
			local net_id = self:GetNetIdByTile(tile_id)
			if net_id then
				local output = power_source.components[POWERSOURCE_COMPONENT]:GetCurrentOuput()
				self:AddEfficiencyDeltaBuffer_Private(net_id, -output)
			end
		end
	end
	return true
end

function PowerManager:AddPowerAppliance(power_app, tile_x, tile_z)	--return success or faild, net id
	if not power_app:IsValid() or not power_app.components[POWERAPPLIANCE_COMPONENT] then
		return false
	end

	for tile_id, power_appliance in pairs(self.power_appliances) do
		if power_appliance[power_app] then
			return false, self.GetNetIdByTile(tile_id)
		end
	end

	local tile_id = self:GetTileId(tile_x, tile_z)
	if not self.power_appliances[tile_id] then
		self.power_appliances[tile_id] = {}
	end
	self.power_appliances[tile_id][power_app] = true

	local net_id = self:GetNetIdByTile(tile_x, tile_z)
	if net_id then
		local demand = power_app.components[POWERAPPLIANCE_COMPONENT]:GetCurrentDemand()
		self:AddEfficiencyDeltaBuffer_Private(net_id, nil, demand)
		return true, net_id
	else
		return false
	end
end

function PowerManager:RemovePowerAppliance(power_app)
	for tile_id, power_appliance in pairs(self.power_appliances) do
		if power_appliance[power_app] then
			power_appliance[power_app] = nil
			local net_id = self:GetNetIdByTile(tile_id)
			if net_id then
				local demand = power_app.components[POWERAPPLIANCE_COMPONENT]:GetCurrentDemand()
				self:AddEfficiencyDeltaBuffer_Private(net_id, nil, -demand)
			end
		end
	end
	return true
end

function PowerManager:OnPowerSourceOutputChanged(power_source, output_delta)
	for tile_id, power_sources in pairs(self.power_sources) do
		if power_sources[power_source] then
			local net_id = self:GetNetIdByTile(tile_id)
			if net_id then
				self:AddEfficiencyDeltaBuffer_Private(net_id, output_delta)
			end
			return
		end
	end
end

function PowerManager:OnPowerApplianceDemandChanged(power_app, demand_delta)
	for tile_id, power_appliance in pairs(self.power_appliances) do
		if power_appliance[power_app] then
			local net_id = self:GetNetIdByTile(tile_id)
			if net_id then
				self:AddEfficiencyDeltaBuffer_Private(net_id, demand_delta)
			end
			return
		end
	end
end

------------------------------
-- About Power Net
------------------------------

function PowerManager:AddEfficiencyDeltaBuffer_Private(net_id, output_delta, demand_delta)
	local buffer = self.waitting_for_update_efficiency_nets[net_id]
	if not buffer then
		self.waitting_for_update_efficiency_nets[net_id] = {output_delta = 0, demand_delta = 0}
		buffer = self.waitting_for_update_efficiency_nets[net_id]
	end
	if output_delta and output_delta ~= 0 then
		buffer.output_delta = buffer.output_delta + output_delta
	end
	if demand_delta and demand_delta ~= 0 then
		buffer.demand_delta = buffer.demand_delta + demand_delta
	end
end

function PowerManager:RefreshEfficiency_Private(net_id, buffer)
	local output = self.power_outputs[net_id]
	if output then
		output = math.max(0, output + buffer.output_delta)
		self.power_outputs[net_id] = output
	end
	local demand = self.power_demands[net_id]
	if demand then
		demand = math.max(0, demand + buffer.demand_delta)
		self.power_demands[net_id] = demand
	end
	local old_efficiency = self.efficiencies[net_id]
	if output and demand and old_efficiency then
		local new_efficiency = output == 0 and 0 or (demand == 0 and 1 or math.clamp(output/demand, 0, 1))
		if old_efficiency == new_efficiency then
			return
		end
		self.efficiencies[net_id] = new_efficiency
		for i, power_app in ipairs(self:GetNetPowerAppliances(net_id)) do
			power_app:PushEvent("agcw_power_manager.efficiencies", {old = old_efficiency, new = self.efficiencies[net_id]})
		end
	end
end

function PowerManager:GetEfficiencyByNet(net_id)
	if not net_id then
		return 0
	end
	return self.efficiencies[net_id] or 0
end

function PowerManager:GetEfficiencyByTile(pos_x, pos_z, is_center_pos)
	local net_id = self:GetNetIdByTile(pos_x, pos_z, is_center_pos)
	return self:GetEfficiencyByNet(net_id)
end

function PowerManager:CreateNet_Private()
	local net_id = UUID()
	while self.nets[net_id] do
		net_id = UUID()
	end
	self.nets[net_id] = {}
	self.efficiencies[net_id] = 0
	self.power_outputs[net_id] = 0
	self.power_demands[net_id] = 0
	return net_id, self.nets[net_id]
end

function PowerManager:DeleteNet_Private(net_id)	--return success or faild
	if not self.nets[net_id] then
		return true
	end
	local empty = true
	for tile_id, tile_pos in pairs(self.nets[net_id]) do
		empty = false
		break
	end
	if not empty then
		return false
	end
	self.nets[net_id] = nil
	self.efficiencies[net_id] = nil
	self.power_outputs[net_id] = nil
	self.power_demands[net_id] = nil
	Delete_UUID(net_id)
end

function PowerManager:OnTileChanged_Private(net_id)
	if not self.nets[net_id] then
		return
	end

	local output = 0
	local demand = 0
	for tile_id, tile_pos in pairs(self.nets[net_id]) do
		for i, ent in ipairs(TheWorld.Map:GetEntitiesOnTileAtPoint(tile_pos[1], 0, tile_pos[2])) do
			if ent.components[POWERSOURCE_COMPONENT] then
				output = output + ent.components[POWERSOURCE_COMPONENT]:GetCurrentOuput()
			end
			if ent.components[POWERAPPLIANCE_COMPONENT] then
				demand = demand + ent.components[POWERAPPLIANCE_COMPONENT]:GetCurrentDemand()
			end
		end
	end

	self.power_outputs[net_id] = output
	self.power_demands[net_id] = demand
	local old_efficiency = self.efficiencies[net_id]
	local new_efficiency = output == 0 and 0 or (demand == 0 and 1 or math.clamp(output/demand, 0, 1))
	if old_efficiency == new_efficiency then
		return
	end
	self.efficiencies[net_id] = new_efficiency
	for i, power_app in ipairs(self:GetNetPowerAppliances(net_id)) do
		power_app:PushEvent("agcw_power_manager.efficiencies", {old = old_efficiency, new = new_efficiency})
	end
end

function PowerManager:GetNetTiles(net_id)	--return {[1]={x=x, z=z}, [2]=...}
	if not self.nets[net_id] then
		return {}
	end
	local tiles = {}
	for tile_id, tile_pos in pairs(self.nets[net_id]) do
		table.insert(tiles, {x=tile_pos[1], z=tile_pos[2]})
	end
	return tiles
end

function PowerManager:GetNetPowerSources(net_id)
	if not net_id or not self.nets[net_id] then
		return {}
	end
	local result = {}
	for tile_id, tile_pos in pairs(self.nets[net_id]) do
		local power_sources = self.power_sources[tile_id]
		if power_sources then
			for power_source, _ in pairs(power_sources) do
				table.insert(result, power_source)
			end
		end
	end
	return result
end

function PowerManager:GetNetPowerAppliances(net_id)
	if not net_id or not self.nets[net_id] then
		return {}
	end
	local result = {}
	for tile_id, tile_pos in pairs(self.nets[net_id]) do
		local power_apps = self.power_appliances[tile_id]
		if power_apps then
			for power_app, _ in pairs(power_apps) do
				table.insert(result, power_app)
			end
		end
	end
	return result
end

function PowerManager:GetNetPowerOutput(net_id)
	return net_id and self.power_outputs[net_id]
end

function PowerManager:GetNetPowerDemand(net_id)
	return net_id and self.power_demands[net_id]
end


------------------------------
-- Update
------------------------------

function PowerManager:StartUpdate()
	self.inst:StartUpdatingComponent(self)
end

function PowerManager:StopUpdate()
	self.inst:StopUpdatingComponent(self)
end

function PowerManager:OnUpdate(dt)
	for net_id, buffer in pairs(self.waitting_for_update_efficiency_nets) do
		self:RefreshEfficiency_Private(net_id, buffer)
		self.waitting_for_update_efficiency_nets[net_id] = nil
	end
end


return PowerManager