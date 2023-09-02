--<打开Screen动作>
AddAction("AGCW_POPUP_SCREEN", STRINGS.ACTIONS.AGCW_POPUP_SCREEN, function(act)
    if act.target and act.target:IsValid() then
		local agcw_popupscreen = act.target.components.agcw_popupscreen
		if agcw_popupscreen then
			return agcw_popupscreen:Show(act.doer)
		end
    end
	return false
end)
STRINGS.ACTIONS.AGCW_POPUP_SCREEN = STRINGS.ACTIONS.GENESIS_SHOW_UI_OVERRIDE
--为AGCW_POPUP_SCREEN行为的目标配置agcw_popupscreen_action_strid属性，可以改变行为的显示文本
ACTIONS.AGCW_POPUP_SCREEN.strfn = function(act)
    return act.target ~= nil and act.target.agcw_popupscreen_action_strid or nil
end
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.AGCW_POPUP_SCREEN, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.AGCW_POPUP_SCREEN, "doshortaction"))

AddComponentAction("SCENE", "agcw_popupscreen", function(inst, doer, actions, right)
	if right then
		table.insert(actions, ACTIONS.AGCW_POPUP_SCREEN)
	end
end)