local PowerSource = Class(function(self, inst)
    self.inst = inst

	self.standard_output_power = 0
	self.current_output_power = self.standard_output_power

	self.inst:AddTag("agcw_power_source")
end)


function PowerSource:OnRemoveFromEntity()
	self.inst:RemoveTag("agcw_power_source")
end

function PowerSource:OnRemoveEntity()
	self:Unregister()
end


function PowerSource:Register()
	local pos = self.inst:GetPosition()
	local tile_x, y, tile_z = TheWorld.Map:GetTileCenterPoint(pos.x, 0, pos.z)
	return TheWorld.net.AgcwPowerMgr:AddPowerSource(self.inst, tile_x, tile_z)
end

function PowerSource:Unregister()
	return TheWorld.net.AgcwPowerMgr:RemovePowerSource(self.inst)
end


function PowerSource:SetStandardOuput(val)
	self.standard_output_power = val
end

function PowerSource:GetStandardOutput()
	return self.standard_output_power
end


function PowerSource:SetOuput(val)
	self.current_output_power = math.clamp(val, 0, self.standard_output_power)
end

function PowerSource:GetCurrentOuput()
	return self.current_output_power
end


return PowerSource