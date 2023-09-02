local json = require "json"
local Widget = require "widgets/widget"
local Templates = require "widgets/redux/templates"

local PlowTileSelection = require "widgets/agcw_plow_tile_selection"



local Interactive = Class(Widget, function(self, owner)
    Widget._ctor(self, "Interactive")
	self.owner = owner


    self.CheckSelect = function(button, down)
        if self.plow_tile_selection and self.plow_tile_selection:OnMouseButton(button, down) then
            return true
        end
    end

    self.OnMoveMouse = function (x, y)
		if self.plow_tile_selection then
			self.plow_tile_selection:OnMoveMouse(x, y)
		end
    end

    --初始化任务
    self.init_task = self.inst:DoPeriodicTask(0.1, function ()
        if TheInput.onmousebutton and TheInput.position then
            TheInput:AddMouseButtonHandler(self.CheckSelect)
            TheInput:AddMoveHandler(self.OnMoveMouse)
            self.init_task:Cancel()
            self.init_task = nil
        end
    end)
end)


function Interactive:GetSelectedTiles()
	return self.plow_tile_selection:GetSelectedTiles()
end

function Interactive:EnablePlowTileSelection(tile_selected_fn, tile_unselected_fn, tile_preselected_fn, tile_unpreselected_fn)
	if not self.plow_tile_selection then
		self.plow_tile_selection = self:AddChild(PlowTileSelection(tile_selected_fn, tile_unselected_fn, tile_preselected_fn, tile_unpreselected_fn))
	end
end

function Interactive:DisablePlowTileSelection()
	if self.plow_tile_selection then
		self.plow_tile_selection:OnDisable()
		self.plow_tile_selection:Kill()
		self.plow_tile_selection = nil
	end
end

return Interactive