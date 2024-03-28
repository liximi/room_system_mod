local json = require "json"

local PopUpScreen = Class(function(self, inst)
    self.inst = inst

	self.pop_up = nil
	self.can_show_fn = nil
	self.get_data_fn = nil
end)


function PopUpScreen:SetPopUpID(id)
	self.pop_up = id
end

function PopUpScreen:GetPopUpID()
	return type(self.pop_up) == "string" and string.upper(self.pop_up)
end

function PopUpScreen:CanShow(doer)
	if not self:GetPopUpID() then
		return false
	end
	if self.can_show_fn then
		return self.can_show_fn(self.inst, doer)
	end
	return true
end

function PopUpScreen:Show(doer)
	if doer and doer.userid and self:CanShow(doer) then
		if self.on_show_fn then
			self.on_show_fn(self.inst, doer)
		end
		doer:ShowPopUp(POPUPS[self:GetPopUpID()], true, self:GetData(doer))
		return true
	end

	return false
end

function PopUpScreen:GetData(doer)
	return self.get_data_fn and json.encode(self.get_data_fn(self.inst, doer))
end


return PopUpScreen