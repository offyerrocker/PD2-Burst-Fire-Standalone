Hooks:PostHook(BlackMarketGui,"populate_mods","burstfiremod_addmenunode",function(self,data)
	local crafted = managers.blackmarket:get_crafted_category(data.prev_node_data.category)[data.prev_node_data.slot]
	local global_values = crafted.global_values or {}

	local weapon_blueprint = managers.blackmarket:get_weapon_blueprint(data.prev_node_data.category, data.prev_node_data.slot) or {}
	
	local equipped
	for i, mod in ipairs(data) do
		for _, weapon_mod in ipairs(weapon_blueprint) do
			if mod.name == weapon_mod and (not global_values[weapon_mod] or global_values[weapon_mod] == data[i].global_value) then
				equipped = i
				
				break
			end
		end
	end
	
	if equipped then 
		local data_equipped = data[equipped]
		if data_equipped.name == "wpn_fps_upg_i_burstfire" then
			-- prrrrobably not the best way to do that.
			-- ...anyway!
			table.insert(data_equipped,"wcs_customize_burstfire")
		end
	end
end)

Hooks:PostHook(BlackMarketGui,"_setup","burstfiremod_initbuttons",function(self,is_start_page,component_data)
	if self._tabs[self._selected] then
		local btn_x = 10
		local btn_data = {
			btn = "BTN_A",
			prio = 1,
			name = "bm_menu_btn_customize_burstfire",
			callback = callback(self,self,"open_customize_burstfire_menu")
		}
		btn_data.callback = callback(self,self,"overridable_callback",{
			button = "wcs_customize_burstfire",
			callback = btn_data.callback
		})
		self._btns.wcs_customize_burstfire = BlackMarketGuiButtonItem:new(self._buttons, btn_data, btn_x)
	end
	if self._selected_slot then 
		--self:show_btns(self._selected_slot)
		self:on_slot_selected(self._selected_slot)
	end
end)

function BlackMarketGui:open_customize_burstfire_menu(data)
	local current_value = BurstFireMod:get_default_burst_count()
	local crafted = managers.blackmarket:get_crafted_category_slot(data.category, data.slot)
	if crafted then
		current_value = crafted.part_burst_count
	end
	
	managers.menu:open_node("blackmarket_customize_burstfire", {
		{
			name = data.name,
			topic_id = "bm_menu_blackmarket_title",
			topic_params = {
				item = self._data.prev_node_data.name_localized
			},
			category = data.category,
			slot = data.slot,
			burst_count_options = BurstFireMod._LOOKUP_BURST_COUNT,
			default_value = BurstFireMod.default_settings.default_burst_count,
			current_value = current_value
		}
	})
end