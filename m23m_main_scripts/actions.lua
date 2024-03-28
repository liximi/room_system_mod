--<打开Screen动作>
AddAction("M23M_POPUP_SCREEN", STRINGS.ACTIONS.M23M_POPUP_SCREEN, function(act)
    if act.target and act.target:IsValid() then
		local popupscreen = act.target.components.m23m_popupscreen
		if popupscreen then
			return popupscreen:Show(act.doer)
		end
    end
	return false
end)
STRINGS.ACTIONS.M23M_POPUP_SCREEN = STRINGS.ACTIONS.M23M_SHOW_UI_OVERRIDE
--为 M23M_POPUP_SCREEN 行为的目标配置 m23m_popupscreen_action_strid 属性，可以改变行为的显示文本
ACTIONS.M23M_POPUP_SCREEN.strfn = function(act)
    return act.target ~= nil and act.target.m23m_popupscreen_action_strid or nil
end
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.M23M_POPUP_SCREEN, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.M23M_POPUP_SCREEN, "doshortaction"))

AddComponentAction("SCENE", "m23m_popupscreen", function(inst, doer, actions, right)
	if right then
		table.insert(actions, ACTIONS.M23M_POPUP_SCREEN)
	end
end)