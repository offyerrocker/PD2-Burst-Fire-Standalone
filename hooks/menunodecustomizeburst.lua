-- todo make ws, connect input
-- check CoreMenuNodeGui.NodeGui for inherited input stuff



local CoreMenuItemOption = core:import("CoreMenuItemOption")
Hooks:PostHook(CoreMenuItemOption.ItemOption,"trigger","fadffdsddddfdfdfsf",function(self)
	Print("Triggered",self:name())
end)
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
	
	--node.burst_count_data = {}
	
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
	burstcount_item:set_value("3")
	
	local new_item = nil
	local apply_params = {
		visible_callback = "should_show_weapon_burstfire_count_apply",
		enabled_callback = "weapon_burstfire_count_enabled",
		name = "apply",
		last_item="true",
		previous_node = "true",
		--back = true,
		callback = "apply_weapon_burstfire_count",
		text_id = "dialog_apply",
		vertical = "bottom",
		align = "right"
	}
	new_item = node:create_item({
		--type = "CoreMenuItem.Item"
	}, apply_params)
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


function MenuCustomizeBurstfireInitiator:previous_page()
	Print("Prev page")
end

function MenuCustomizeBurstfireInitiator:next_page()
	Print("Next page")
end


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

	--[[
	local burst_count = node and node:item("burstfiremod_wp_mod_set_burst_count")
	if burst_count then 
		Print("Found burst count:",burst_count:value())
	end
	--]]
	
	MenuNodeCustomizeBurstGui.super.init(self, node, layer, parameters, ...)
	
	self:setup()
	
	_G.testnode = self
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

--[[
function MenuNodeCustomizeBurstGui:input_focus()
	local current_item = managers.menu:active_menu().logic:selected_item()
	
	if self._mouse_over_row_item then
		local mouse_over_item = self._mouse_over_row_item.item

		if current_item == mouse_over_item and mouse_over_item.TYPE == "grid" then
			return 1
		end
	end

	if self._mouse_over_tab_panel or self._prev_page_highlighted or self._next_page_highlighted then
		return 1
	end
end
--]]

function MenuNodeCustomizeBurstGui:make_fine_text(text)
	local x, y, w, h = text:text_rect()

	text:set_size(w, h)
	text:set_position(math.round(x), math.round(y))

	return x, y, w, h
end


--[[
function MenuNodeCustomizeWeaponColorGui:mouse_moved(o, x, y)
	local used = false
	local icon = "arrow"

	if managers.menu_scene:input_focus() then
		self._mouse_over_row_item = nil
		self._mouse_over_tab_panel = nil

		return used, icon
	end

	local current_item = managers.menu:active_menu().logic:selected_item()
	local current_row_item = current_item and self:row_item(current_item)
	local selected_row_item = nil

	if current_row_item and current_row_item.gui_panel and current_row_item.gui_panel:inside(x, y) then
		selected_row_item = current_row_item
	else
		local inside_item_panel_parent = self:item_panel_parent():inside(x, y)
		local item, is_inside = nil

		for _, row_item in pairs(self.row_items) do
			item = row_item.item
			is_inside = false

			if item and not item.no_mouse_select then
				is_inside = item.TYPE == "grid" and item:scroll_bar_grabbed(row_item) and true or inside_item_panel_parent and row_item.gui_panel:inside(x, y)
			end

			if is_inside then
				selected_row_item = row_item

				break
			end
		end
	end

	if selected_row_item then
		local selected_name = selected_row_item.name
		used = true
		icon = "link"

		if not current_item or selected_name ~= current_item:name() then
			managers.menu:active_menu().logic:mouse_over_select_item(selected_name, false)

			current_row_item = selected_row_item
			current_item = selected_row_item.item
		end

		if current_item then
			self._mouse_over_row_item = current_row_item

			if current_item.TYPE == "grid" then
				icon = current_item:mouse_moved(x, y, current_row_item)
			elseif current_item.TYPE == "multi_choice" then
				local inside_arrow_left = current_row_item.arrow_left:visible() and current_row_item.arrow_left:inside(x, y)
				local inside_arrow_right = current_row_item.arrow_right:visible() and current_row_item.arrow_right:inside(x, y)
				local inside_gui_text = current_row_item.arrow_left:visible() and current_row_item.arrow_right:visible() and current_row_item.gui_text:inside(x, y)
				local inside_choice_panel = current_row_item.choice_panel:visible() and current_row_item.choice_panel:inside(x, y)

				if inside_arrow_left or inside_arrow_right or inside_gui_text or inside_choice_panel then
					icon = "link"
				else
					icon = "arrow"
				end
			end
		end
	else
		self._mouse_over_row_item = nil
	end

	self._mouse_over_tab_panel = self._tab_scroll_parent_panel:inside(x, y)
	local prev_page = self._tab_panel:child("prev_page")

	if alive(prev_page) then
		local is_inside = prev_page:inside(x, y) and prev_page:visible()

		if is_inside then
			used = true
			icon = "link"
		end

		if is_inside then
			if not self._prev_page_highlighted then
				self._prev_page_highlighted = true

				managers.menu_component:post_event("highlight")
				prev_page:set_color(tweak_data.screen_colors.button_stage_2)
			end

			return used, icon
		elseif self._prev_page_highlighted then
			self._prev_page_highlighted = nil

			prev_page:set_color(tweak_data.screen_colors.button_stage_3)
		end
	end

	local next_page = self._tab_panel:child("next_page")

	if alive(next_page) then
		local is_inside = next_page:inside(x, y) and next_page:visible()

		if is_inside then
			used = true
			icon = "link"
		end

		if is_inside then
			if not self._next_page_highlighted then
				self._next_page_highlighted = true

				managers.menu_component:post_event("highlight")
				next_page:set_color(tweak_data.screen_colors.button_stage_2)
			end

			return used, icon
		elseif self._next_page_highlighted then
			self._next_page_highlighted = nil

			next_page:set_color(tweak_data.screen_colors.button_stage_3)
		end
	end

	local color_group_data = self.node.color_group_data

	if color_group_data.highlighted then
		local highlighted_tab = self._tabs[color_group_data.highlighted]

		if highlighted_tab.panel:inside(x, y) then
			return true, color_group_data.highlighted == color_group_data.selected and "arrow" or "link"
		end

		local prev_highlighted = color_group_data.highlighted
		color_group_data.highlighted = nil

		self:_update_tab(prev_highlighted)
	end

	if self._mouse_over_tab_panel then
		for index, tab in ipairs(self._tabs) do
			if tab.panel:inside(x, y) then
				color_group_data.highlighted = index

				self:_update_tab(index)

				used = true
				icon = "link"

				if color_group_data.selected ~= index then
					icon = "arrow"

					managers.menu_component:post_event("highlight")
				end

				break
			end
		end
	end

	return used, icon
end

function MenuNodeCustomizeWeaponColorGui:mouse_pressed(button, x, y)
	local active_menu = managers.menu:active_menu()

	if not managers.menu:active_menu() then
		return
	end

	local logic = active_menu.logic
	local input = active_menu.input

	if self._mouse_over_row_item then
		local mouse_over_item = self._mouse_over_row_item.item

		if button == Idstring("mouse wheel down") then
			if mouse_over_item.TYPE == "grid" then
				return mouse_over_item:wheel_scroll_start(-1, self._mouse_over_row_item)
			end
		elseif button == Idstring("mouse wheel up") and mouse_over_item.TYPE == "grid" then
			return mouse_over_item:wheel_scroll_start(1, self._mouse_over_row_item)
		end

		if button == Idstring("0") then
			if mouse_over_item.TYPE == "grid" then
				mouse_over_item:mouse_pressed(button, x, y, self._mouse_over_row_item)
			elseif mouse_over_item.TYPE == "multi_choice" then
				if self._mouse_over_row_item.arrow_right:inside(x, y) then
					if mouse_over_item:next() then
						input:post_event("selection_next")
						logic:trigger_item(true, mouse_over_item)
					end
				elseif self._mouse_over_row_item.arrow_left:inside(x, y) then
					if mouse_over_item:previous() then
						input:post_event("selection_previous")
						logic:trigger_item(true, mouse_over_item)
					end
				elseif self._mouse_over_row_item.gui_text:inside(x, y) then
					if self._mouse_over_row_item.align == "left" then
						if mouse_over_item:previous() then
							input:post_event("selection_previous")
							logic:trigger_item(true, mouse_over_item)
						end
					elseif mouse_over_item:next() then
						input:post_event("selection_next")
						logic:trigger_item(true, mouse_over_item)
					end
				elseif self._mouse_over_row_item.choice_panel:inside(x, y) and mouse_over_item:enabled() then
					mouse_over_item:popup_choice(self._mouse_over_row_item)
					input:post_event("selection_next")
					logic:trigger_item(true, mouse_over_item)
				end
			elseif mouse_over_item.TYPE == "divider" then
				-- Nothing
			else
				local item = logic:selected_item()

				if item then
					input._item_input_action_map[item.TYPE](item, input._controller, true)
				end
			end

			return true
		end
	elseif self._mouse_over_tab_panel then
		if button == Idstring("mouse wheel down") then
			self:next_page()

			return true
		elseif button == Idstring("mouse wheel up") then
			self:previous_page()

			return true
		end
	elseif self._prev_page_highlighted then
		self:previous_page()

		return true
	elseif self._next_page_highlighted then
		self:next_page()

		return true
	end

	if button == Idstring("0") then
		local color_group_data = self.node.color_group_data
		local highlighted_tab = self._tabs[color_group_data.highlighted]

		if highlighted_tab and highlighted_tab.panel:inside(x, y) then
			self:_set_color_group_index(color_group_data.highlighted)

			return true
		end
	end
end

function MenuNodeCustomizeWeaponColorGui:mouse_released(button, x, y)
	local item = nil

	for _, row_item in pairs(self.row_items) do
		item = row_item.item

		if item.TYPE == "grid" then
			row_item.item:mouse_released(button, x, y, row_item)
		end
	end
end

--]]