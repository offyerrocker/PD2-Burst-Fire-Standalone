-- issue: divider can be selected
	-- fix: figure out how menu input is normally handled 
	-- instead of reverse engineering and macgyvering it all myself (impractical)

local CoreMenuItemOption = core:import("CoreMenuItemOption")

require("lib/managers/menu/MenuInitiatorBase")
require("lib/managers/menu/renderers/MenuNodeBaseGui")

MenuCustomizeBurstfireInitiator = MenuCustomizeBurstfireInitiator or class(MenuInitiatorBase)
function MenuCustomizeBurstfireInitiator:modify_node(original_node,node_data)
	local node = original_node
	return self:setup_node(node, node_data)
end

function MenuCustomizeBurstfireInitiator:setup_node(node, node_data)
	node:clean_items()

	node.topic_id = node_data.topic_id
	node.topic_params = node_data.topic_params
	
	-- i'm 80% certain this is not how you are supposed to do this either
	local parameters = node:parameters()
	parameters.menu_component_data = node_data

	--local crafted = managers.blackmarket:get_crafted_category_slot(node_data.category, node_data.slot)
	--if not crafted then
	--	return node
	--end
	
	self:create_divider(node, "padding", nil, 4)
	
	if node_data.burst_count_options then 
		
		local burstcount_options = {
			{
				_meta = "option",
				localize = true,
				text_id = "menu_burstfiremod_burst_count_use_default",
				value = 1,
				index = 1
			}
		}
		local default_value = node_data.default_value
		local current_value = node_data.current_value
		for i,v in ipairs(node_data.burst_count_options) do
			table.insert(burstcount_options,{
				_meta = "option",
				localize = false,
				text_id = tostring(v),
				value = v,
				index = i + 1
			})
			table.sort(burstcount_options,function(a,b) return a.index < b.index end)
		end
		for _,b_opt in pairs(burstcount_options) do 
			-- verify current burst value
			if b_opt.value == current_value then
				default_value = b_opt.value
				break
			elseif not default_value then
				default_value = b_opt.value
				break
			end
		end
		
		local burstcount_item = self:create_multichoice(node, burstcount_options, {
			callback = "callback_burstfiremod_wp_mod_set_burst_count",
			visible_callback = "should_show_weapon_burstfire_count_apply",
			enabled_callback = "weapon_burstfire_count_enabled",
			name = "burst_count",
			text_id = "menu_burstfiremod_wp_mod_set_burst_count_title"
		})
		burstcount_item:set_value(default_value)
	end
	
	self:create_divider(node, "padding", nil, 25)
	
	do
		local new_item = nil
		local apply_params = {
			visible_callback = "should_show_weapon_burstfire_count_apply",
			enabled_callback = "weapon_burstfire_count_enabled",
			name = "apply",
			previous_node = "true",
			callback = "apply_weapon_burstfire_count",
			text_id = "dialog_apply",
			vertical = "bottom",
			align = "right"
		}
		new_item = node:create_item({}, apply_params)
		node:add_item(new_item)
	end
	
	do 
		local new_item = nil
		local apply_params = {
--			visible_callback = "should_show_weapon_burstfire_count_apply",
--			enabled_callback = "weapon_burstfire_count_enabled",
			name = "back",
			last_item = "true",
			previous_node = "true",
			callback = nil,
			text_id = "dialog_cancel",
			vertical = "bottom",
			align = "right"
		}
		new_item = node:create_item({}, apply_params)
		node:add_item(new_item)
	end

	node.randomseed = os.time()

	math.randomseed(node.randomseed)

	return node
end

function MenuCustomizeBurstfireInitiator:refresh_node(node)
	-- todo move the burst count multichoice verification stuff here
	return node
end

MenuNodeCustomizeBurstGui = MenuNodeCustomizeBurstGui or class(MenuNodeBaseGui)
function MenuNodeCustomizeBurstGui:init(node,layer,parameters, ...)
	if parameters then
		parameters.font = tweak_data.menu.pd2_small_font
		parameters.font_size = tweak_data.menu.pd2_small_font_size
		parameters.align = "left"
		parameters.row_item_blend_mode = "add"
		parameters.row_item_color = tweak_data.screen_colors.button_stage_3
		parameters.row_item_hightlight_color = tweak_data.screen_colors.button_stage_2
		parameters.marker_alpha = 1
		parameters.to_upper = true
	end
	
	self._row_selection_index = 0
	
	MenuNodeCustomizeBurstGui.super.init(self, node, layer, parameters, ...)
	
	self:setup()
end

function MenuNodeCustomizeBurstGui:setup(...)
	MenuNodeCustomizeBurstGui.super.setup(self, ...)
end



function MenuNodeCustomizeBurstGui:_setup_item_panel(safe_rect, res, ...)
	MenuNodeCustomizeBurstGui.super._setup_item_panel(self, safe_rect, res, ...)
	
	
	self.item_panel:set_w(safe_rect.width * (1 - self._align_line_proportions))
	self.item_panel:set_h(safe_rect.height * (0.15))
	self.item_panel:set_center(self.item_panel:parent():w() / 2, self.item_panel:parent():h() / 2)
	
	local static_y = self.static_y and safe_rect.height * self.static_y

	if static_y and static_y < self.item_panel:y() then
		self.item_panel:set_y(static_y)
	end
	
	self.item_panel:set_position(math.round(self.item_panel:x()), math.round(self.item_panel:y()))
	self:_rec_round_object(self.item_panel)


	if alive(self.box_panel) then
		self.item_panel:parent():remove(self.box_panel)

		self.box_panel = nil
	end

	self.box_panel = self.item_panel:parent():panel()

	self.box_panel:set_x(self.item_panel:x())
	self.box_panel:set_w(self.item_panel:w())

	if self._align_data.panel:h() < self.item_panel:h() then
		self.box_panel:set_y(0)
		self.box_panel:set_h(self.item_panel:parent():h())
	else
		self.box_panel:set_y(self.item_panel:top())
		self.box_panel:set_h(self.item_panel:h())
	end

	self.box_panel:grow(20, 20)
	self.box_panel:move(-10, -10)
	self.box_panel:set_layer(151)

	self._texture_panel = self.box_panel:panel({
		w = 128,
		h = 128,
		layer = 10
	})

	self._texture_panel:set_center(self.box_panel:w() / 2, self.box_panel:h() / 2)
	--self:_set_reticle_texture(self._texture)

	self.boxgui = BoxGuiObject:new(self.box_panel, {
		sides = {
			1,
			1,
			1,
			1
		}
	})

	self.boxgui:set_clipping(false)
	self.boxgui:set_layer(1000)
	self.box_panel:rect({
		rotation = 360,
		color = tweak_data.screen_colors.dark_bg
	})
	self._align_data.panel:set_left(self.box_panel:left())
	self._list_arrows.up:set_world_left(self._align_data.panel:world_left())
	self._list_arrows.up:set_world_top(self._align_data.panel:world_top() - 10)
	self._list_arrows.up:set_width(self.box_panel:width())
	self._list_arrows.up:set_rotation(360)
	self._list_arrows.up:set_layer(1050)
	self._list_arrows.down:set_world_left(self._align_data.panel:world_left())
	self._list_arrows.down:set_world_bottom(self._align_data.panel:world_bottom() + 10)
	self._list_arrows.down:set_width(self.box_panel:width())
	self._list_arrows.down:set_rotation(360)
	self._list_arrows.down:set_layer(1050)
	self:_set_topic_position()




--[[


	self._TEST_OBJECT = self.item_panel:rect({
		name = "TEST_OBJECT",
		alpha = 0.5,
		color = Color.red
	})
	--]]
	--[[
	self._text_panel = self._item_panel_parent:panel({
		name = "title_panel",
		layer = self.layers.background
	})
	
--]]


end

function MenuNodeCustomizeBurstGui:_setup_item_panel_parent(safe_rect, shape, ...)
	shape = shape or {}
	shape.x = shape.x or safe_rect.x
	shape.y = shape.y or safe_rect.y + 0
	shape.w = shape.w or safe_rect.width
	shape.h = shape.h or safe_rect.height - 0

	MenuNodeCustomizeBurstGui.super._setup_item_panel_parent(self, safe_rect, shape, ...)
end


function MenuNodeCustomizeBurstGui:_setup_item_rows(node, ...)
	MenuNodeCustomizeBurstGui.super._setup_item_rows(self, node, ...)
end

function MenuNodeCustomizeBurstGui:reload_item(item, ...)
	MenuNodeCustomizeBurstGui.super.reload_item(self, item, ...)

	local row_item = self:row_item(item)

	if row_item and alive(row_item.gui_panel) then
		row_item.gui_panel:set_halign("right")
		row_item.gui_panel:set_right(self.item_panel:w())
	end
end

function MenuNodeCustomizeBurstGui:close(...)
	MenuNodeCustomizeBurstGui.super.close(self,...)
end

function MenuNodeCustomizeBurstGui:_align_marker(row_item)
	MenuNodeCustomizeBurstGui.super._align_marker(self, row_item)

	if row_item.item:parameters().pd2_corner then
		self._marker_data.marker:set_world_right(row_item.gui_panel:world_right())

		return
	end

	self._marker_data.marker:set_world_right(self.item_panel:world_right())
end

function MenuNodeCustomizeBurstGui:_rec_round_object(object)
	if object.children then
		for i, d in ipairs(object:children()) do
			self:_rec_round_object(d)
		end
	end

	local x, y = object:position()

	object:set_position(math.round(x), math.round(y))
end

function MenuNodeCustomizeBurstGui:make_fine_text(text)
	local x, y, w, h = text:text_rect()

	text:set_size(w, h)
	text:set_position(math.round(x), math.round(y))

	return x, y, w, h
end

function MenuNodeCustomizeBurstGui:confirm_pressed()
	
	local active_menu = managers.menu:active_menu()
	if not active_menu then 
		return
	end
	
	local row_item = self.row_items[self._row_selection_index+1]
	if row_item then 
		local item = row_item.item
		active_menu.logic:trigger_item(true, item)

		-- close menu
		active_menu.logic:navigate_back(true)
	end
	return true
end

function MenuNodeCustomizeBurstGui:_highlight_row_item(row_item,mouse_over,...)
	MenuNodeCustomizeBurstGui.super._highlight_row_item(self,row_item,mouse_over,...)
	local row_index = table.index_of(self.row_items,row_item)
	if row_index then 
		self._row_selection_index = row_index - 1
	end
end

function MenuNodeCustomizeBurstGui:move_up()
	local active_menu = managers.menu:active_menu()
	if not active_menu then
		return
	end
	local selection_index = self._row_selection_index
	local index_start = selection_index
	local num_items = #self.row_items
	while true do 
		selection_index = (selection_index - 1) % num_items
		if selection_index == index_start then
			selection_index = nil
			break
			-- full loop, no other valid selections; abort selection
		else
			local row_item = self.row_items[selection_index + 1]
			local item = row_item and row_item.item
			if item and item._type ~= "divider" then -- todo chk can_select() or whatever
				-- found next valid object; break and select
				break
			end
		end
	end
	
	if selection_index then
		--self._row_selection_index = selection_index -- let set highlight manage this (for mouse compat)
		local row_item = self.row_items[selection_index+1]
		self:_fade_row_item(self.row_items[index_start+1])
		self:_highlight_row_item(row_item,false)
		active_menu.logic:select_item(row_item.item)
		active_menu.input:post_event("selection_previous")
	end
	
	return true
end

function MenuNodeCustomizeBurstGui:move_down()
	local active_menu = managers.menu:active_menu()
	if not active_menu then
		return
	end
	local selection_index = self._row_selection_index
	local index_start = selection_index
	local num_items = #self.row_items
	while true do 
		selection_index = (selection_index + 1) % num_items
		if selection_index == index_start then
			selection_index = nil
			break
			-- full loop, no other valid selections; abort selection
		else
			local row_item = self.row_items[selection_index + 1]
			local item = row_item and row_item.item
			if item and item._type ~= "divider" then -- todo chk can_select() or whatever
				-- found next valid object; break and select
				break
			end
		end
	end
	
	if selection_index then
		--self._row_selection_index = selection_index -- let set highlight manage this (for mouse compat)
		local row_item = self.row_items[selection_index+1]
		self:_fade_row_item(self.row_items[index_start+1])
		self:_highlight_row_item(row_item,false)
		active_menu.logic:select_item(row_item.item)
		active_menu.input:post_event("selection_previous")
	end
	return true
end

function MenuNodeCustomizeBurstGui:move_left()
	local active_menu = managers.menu:active_menu()
	if not active_menu then
		return
	end
	
	local row_item = self.row_items[self._row_selection_index + 1]
	local item = row_item and row_item.item
	if item then 
		if item._type == "multi_choice" then 
			if item:previous() then
				item:reload(row_item,self)
				active_menu.input:post_event("selection_previous")
				active_menu.logic:trigger_item(true, item)
			end
		elseif item._type == "slider" then 
			-- etc
		end
	end
	
	
	return true
end

function MenuNodeCustomizeBurstGui:move_right()
	local active_menu = managers.menu:active_menu()
	if not active_menu then
		return
	end
	
	local row_item = self.row_items[self._row_selection_index + 1]
	local item = row_item and row_item.item
	if item then 
		if item._type == "multi_choice" then 
			if item:next() then
				item:reload(row_item,self)
				active_menu.input:post_event("selection_next")
				active_menu.logic:trigger_item(true, item)
			end
		elseif item._type == "slider" then 
			-- etc
		end
	end
	return true
end
