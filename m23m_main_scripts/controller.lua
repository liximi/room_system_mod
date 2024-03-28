global("M23M_Interactive")

--------------------------------------------------
-- 用于驱动与鼠标交互
--------------------------------------------------

local Interactive = Class(function(self)
	self.functions = {}

    self.CheckSelect = function(button, down)
		local invaild_widget_idxs = {}
		for i, widget in ipairs(self.functions) do
			if not widget.inst:IsValid() then
				table.insert(invaild_widget_idxs, i)
			else
				if widget.OnMouseButton and widget:OnMouseButton(button, down) then
					return true
				end
			end
		end
		for i, idx in ipairs(invaild_widget_idxs) do
			table.remove(self.functions, idx)
		end
    end

    self.OnMoveMouse = function (x, y)
		local invaild_widget_idxs = {}
		for i, widget in ipairs(self.functions) do
			if not widget.inst:IsValid() then
				table.insert(invaild_widget_idxs, i)
			else
				if widget.inst:IsValid() and widget.OnMoveMouse then
					widget:OnMoveMouse(x, y)
				end
			end
		end
		for i, idx in ipairs(invaild_widget_idxs) do
			table.remove(self.functions, idx)
		end
    end

    --初始化任务
    self.init_task = scheduler:ExecutePeriodic(FRAMES, function ()
        if TheInput.onmousebutton and TheInput.position then
            TheInput:AddMouseButtonHandler(self.CheckSelect)
            TheInput:AddMoveHandler(self.OnMoveMouse)
            self.init_task:Cancel()
            self.init_task = nil
        end
    end, nil, nil, "M23M_Interactive")
end)


function Interactive:StartFunction(function_widget)
	table.insert(self.functions, function_widget)
end

function Interactive:StopFunction(function_widget)
	for i, widget in ipairs(self.functions) do
		if widget == function_widget then
			table.remove(self.functions, i)
		end
	end
end

_G.M23M_Interactive = Interactive()