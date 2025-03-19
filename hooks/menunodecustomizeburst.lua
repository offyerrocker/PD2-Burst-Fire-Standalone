-- todo make ws, connect input
-- check CoreMenuNodeGui.NodeGui for inherited input stuff



local CoreMenuItemOption = core:import("CoreMenuItemOption")

require("lib/managers/menu/MenuInitiatorBase")
require("lib/managers/menu/renderers/MenuNodeBaseGui")

MenuCustomizeBurstfireInitiator = MenuCustomizeBurstfireInitiator or class(MenuInitiatorBase)
function MenuCustomizeBurstfireInitiator:modify_node(original_node,node_data)
	
	Print("Customize Modify node")
	local node = original_node

	return self:setup_node(node, node_data)
end

function MenuCustomizeBurstfireInitiator:setup_node(node, node_data)
	Print("Customize setup node",self)
	
	node:clean_items()

	node.topic_id = node_data.topic_id
	node.topic_params = node_data.topic_params
	
	local crafted = managers.blackmarket:get_crafted_category_slot(node_data.category, node_data.slot)
	Print("MenuCustomizeBurstfireInitiator:setup_node()",node_data.category,node_data.slot)
	if not crafted then
		--return node
	end
	
	local burstcount_options = {
		{
			localize = true,
			_meta = "option",
			value = "2",
			text_id = "menu_burstfiremod_wp_mod_burst_count_2",
			index = 1
		},
		{
			localize = true,
			_meta = "option",
			value = "3",
			text_id = "menu_burstfiremod_wp_mod_burst_count_3",
			index = 2
		},
		{
			localize = true,
			_meta = "option",
			value = "4",
			text_id = "menu_burstfiremod_wp_mod_burst_count_4",
			index = 3
		}
	}
	
	local burstcount_item = self:create_multichoice(node, burstcount_options, {
		callback = "callback_burstfiremod_wp_mod_set_burst_count",
		visible_callback = "should_show_weapon_burstfire_count_apply",
		enabled_callback = "weapon_burstfire_count_enabled",
		name = "burst_count",
		text_id = "menu_burstfiremod_wp_mod_set_burst_count_title"
	})
	_G.asdfd1 = burstcount_item
	burstcount_item:set_value("3")
	
	local new_item = nil
	local apply_params = {
		visible_callback = "should_show_weapon_burstfire_count_apply",
		enabled_callback = "weapon_burstfire_count_enabled",
		name = "apply",
		last_item = "true",
		previous_node = "true",
		callback = "apply_weapon_burstfire_count",
		text_id = "menu_back",
		vertical = "bottom",
		align = "right"
	}
	new_item = node:create_item({}, apply_params)
	_G.asdfd2 = new_item
	node:add_item(new_item)

--[[
	local colors_data = {}

	table.insert(colors_data, {
		visible_callback = "is_weapon_color_option_visible",
		_meta = "option",
		disabled_icon_callback = "get_weapon_color_disabled_icon",
		enabled_callback = "is_weapon_color_option_unlocked",
		value = id,
		--color = color_tweak.color,
		--text_id = "bm_wskn_" .. id,
		unlocked = true,
		texture = guis_catalog .. "textures/pd2/blackmarket/icons/weapon_color/" .. id
	})

	local color_item = self:create_grid(node, colors_data, {
		callback = "refresh_node",
		name = "cosmetic_color",
		height_aspect = 0.85,
		text_id = "menu_weapon_color_title",
		align_line_proportions = 0,
		rows = 2.5,
		sort_callback = "sort_weapon_colors",
		columns = 20
	})

	color_item:set_value(weapon_color_id)
	self:create_divider(node, "padding", nil, 10)
	
--]]
	node.randomseed = os.time()

	math.randomseed(node.randomseed)

	return node
end


--function MenuCustomizeBurstfireInitiator:previous_page()
--end

--function MenuCustomizeBurstfireInitiator:next_page()
--end


function MenuCustomizeBurstfireInitiator:refresh_node(node)
	-- ???
	Print("Refresh customize node")
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
	
	--[[
	local burst_count = node and node:item("burstfiremod_wp_mod_set_burst_count")
	if burst_count then 
		Print("Found burst count:",burst_count:value())
	end
	--]]
	
	MenuNodeCustomizeBurstGui.super.init(self, node, layer, parameters, ...)
	
	self:setup()
	
	_G.testnode = self
	_G.testnode2 = node
end

function MenuNodeCustomizeBurstGui:setup(...)
	MenuNodeCustomizeBurstGui.super.setup(self, ...)
end



function MenuNodeCustomizeBurstGui:_setup_item_panel(safe_rect, res, ...)
	MenuNodeCustomizeBurstGui.super._setup_item_panel(self, safe_rect, res, ...)
	
	
	self.item_panel:set_w(safe_rect.width * (1 - self._align_line_proportions))
	self.item_panel:set_h(safe_rect.height * (1 - self._align_line_proportions))
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
	
--	self:_insert_row_item(node:item("apply"),node,1)
--	self:_insert_row_item(node:item("burst_count"),node,2)
	
	
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
	--self:_end_customize_controller()
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

function MenuNodeCustomizeBurstGui:input_focus()
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
	local logic = active_menu.logic
	
	Print("PRESSED",self._row_selection_index)
	local row_item = self.row_items[self._row_selection_index+1]
	if row_item then 
		local item = row_item.item
		logic:trigger_item(true, item)
		--item:trigger()
	end
	return true
end

function MenuNodeCustomizeBurstGui:move_up()
	local active_menu = managers.menu:active_menu()
	if not active_menu then
		return
	end
	self._row_selection_index = (self._row_selection_index + 1) % #self.row_items
	Print("MOVE UP",self._row_selection_index)
	self:_highlight_row_item(self.row_items[self._row_selection_index+1],false)
	
	active_menu.input:post_event("selection_previous")
	return true
end

function MenuNodeCustomizeBurstGui:move_down()
	local active_menu = managers.menu:active_menu()
	if not active_menu then
		return
	end
	
	self._row_selection_index = (self._row_selection_index - 1) % #self.row_items
	Print("MOVE DOWN",self._row_selection_index)
	self:_highlight_row_item(self.row_items[self._row_selection_index+1],false)
	
	active_menu.input:post_event("selection_next")
	return true
end

function MenuNodeCustomizeBurstGui:move_left()
	
	Print("MOVE LEFT")
	return true
end

function MenuNodeCustomizeBurstGui:move_right()
	Print("MOVE RIGHT")
	return true
end
