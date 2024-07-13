local sg_wilson = require "stategraphs.SGwilson"
local sg_wilson_client = require "stategraphs.SGwilson_client"
local old_build_action_state = sg_wilson.actionhandlers[ACTIONS.BUILD].deststate
local old_build_action_state_client = sg_wilson_client.actionhandlers[ACTIONS.BUILD].deststate

AddStategraphState("wilson", State({
	name = "do_m23m_fastaction",
	onenter = function(inst)
		inst.sg:GoToState("dolongaction", 0.2)
	end,
}))
AddStategraphState("wilson_client", State({
	name = "do_m23m_fastaction",
	onenter = function(inst)
		inst.sg:GoToState("dolongaction", 0.2)
	end,
}))
--当角色位于工作间内时，减少制作时间
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BUILD, function(inst, action)
	local x, y, z = inst.Transform:GetWorldPosition()
	local cur_room_type = TheRegionMgr:GetRoomTypeAtPoint(x, z)
	if M23M.WORKSHOP_ROOMS[cur_room_type] then
		return "do_m23m_fastaction"
	end
	return old_build_action_state(inst, action)
end))
AddStategraphActionHandler("wilson_client",  ActionHandler(ACTIONS.BUILD, function(inst, action)
	local x, y, z = inst.Transform:GetWorldPosition()
	local cur_room_type = TheRegionMgr:GetRoomTypeAtPoint(x, z)
	if M23M.WORKSHOP_ROOMS[cur_room_type] then
		return "do_m23m_fastaction"
	end
	return old_build_action_state(inst, action)
end))