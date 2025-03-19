-- todo fix customize burst menu navigation (make it less janky)
-- todo make mod options menu generate multiplechoice from _LOOKUP_BURST_COUNT so it's easier to change in the future

BurstFireMod = BurstFireMod or {
	save_path = SavePath .. "burstfiremod_settings.json",
	options_path = ModPath .. "menu/options.json",
	default_settings = {
		use_global_burst = true,
		default_burst_count = 3 -- default number of rounds in a burst, if the weapon does not have either BURST_COUNT already set in its tweakdata in weapontweakdata, or burst_count in its custom_stats for any of its attachments
	},
	settings = nil,
	_needs_upd_burst_count = nil -- flag that's set when the default_burst_count setting is changed and needs to be updated to the player's weapons
}
BurstFireMod.settings = table.deep_map_copy(BurstFireMod.default_settings)

BurstFireMod._LOOKUP_BURST_COUNT = { -- possible burstfire counts
	2,
	3,
	4
}

function BurstFireMod:get_default_burst_count()
	return self.settings.default_burst_count
end

function BurstFireMod:is_global_burst_enabled()
	return self.settings.use_global_burst
end

function BurstFireMod.set_burst_count(wpn_base,amount)
	wpn_base._burst_count = wpn_base:weapon_tweak_data().BURST_COUNT or BurstFireMod:get_default_burst_count()
end

function BurstFireMod:load_settings()
	local file = io.open(self.save_path, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
		end
	end
end

function BurstFireMod:save_settings()
	local file = io.open(self.save_path,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

Hooks:Add("MenuManagerSetupCustomMenus", "burstfiremod_MenuManagerSetupCustomMenus", function(menu_manager, nodes)
	local new_node = {
		_meta = "node",
		align_line_proportions = 0.7,
		gui_class = "MenuNodeCustomizeBurstGui",
--		menu_components = "blackmarket inventory_chats", -- attaching this makes the menu default to opening the steam inventory every time. undesirable
		modifier = "MenuCustomizeBurstfireInitiator",
		name = "blackmarket_customize_burstfire",
		refresh = "MenuCustomizeBurstfireInitiator",
--		back_callback = "callback_burstfiremod_wp_mod_back",
		scene_state = "blackmarket_crafting",
		topic_id = "menu_burstfiremod_customize_burstfire",
		[1] = {
			["_meta"] = "default_item",
			["name"] = "back"
		}
	}
	local noed = core:import("CoreMenuNode").MenuNode:new(new_node)
	local main_menu = menu_manager:get_menu("menu_main")
	if main_menu then 
		noed:set_callback_handler(main_menu.callback_handler)
	end
	nodes["blackmarket_customize_burstfire"] = noed
end)

Hooks:Add("MenuManagerInitialize", "burstfiremod_MenuManagerInitialize", function(menu_manager)
	MenuCallbackHandler.weapon_burstfire_count_enabled = function(self)
		return true
	end
	MenuCallbackHandler.should_show_weapon_burstfire_count_apply = function(self)
		return true
	end
	MenuCallbackHandler.apply_weapon_burstfire_count = function(self,item)
		local active_menu = managers.menu:active_menu()
		if not active_menu then
			return false
		end
		local logic = active_menu.logic
		if not logic then
			return false
		end
		local node = logic:selected_node()
		if not node then
			return false
		end
		local data = node:parameters().menu_component_data
		if data then
			local slot = data.slot
			local category = data.category
			local crafted_weapon = category and slot and managers.blackmarket:get_crafted_category_slot(category,slot)
			if crafted_weapon then
				local burstcount_item = node:item("burst_count")
				if burstcount_item then
					crafted_weapon.part_burst_count = burstcount_item:value()
				end
			end
		else
			--Print("Apply (no data)")
		end
	end
	MenuCallbackHandler.callback_burstfiremod_wp_mod_set_burst_count = function(self,item)
		--Print("Set burst count:",item:value())
	end
	
	MenuCallbackHandler.callback_burstfiremod_menu_back = function(self)
		if BurstFireMod._needs_upd_burst_count then
			-- on exiting the menu, if setting was changed, change the burst count on any and all applicable guns
			-- (instead of updating every weapon every time the user changes the setting immediately)
			BurstFireMod._needs_upd_burst_count = nil
			local player = managers.player and managers.player:local_player()
			if alive(player) then
				local inv_ext = player:inventory()
				if inv_ext then
					for selection_id,selection_data in pairs(inv_ext._available_selections) do 
						local unit = selection_data.unit
						if alive(unit) then 
							local wpn_base = unit:base()
							if wpn_base then 
								wpn_base:_update_stats_values(true,wpn_base:ammo_data())
							end
						end
					end
				end
			end
		end
	end
	MenuCallbackHandler.callback_burstfiremod_use_global_burst = function(self,item)
		BurstFireMod.settings.use_global_burst = item:value() == "on"
		BurstFireMod:save_settings()
	end
	MenuCallbackHandler.callback_burstfiremod_default_burst_count = function(self,item)
		BurstFireMod.settings.default_burst_count = math.round(item:value())
		BurstFireMod:save_settings()
		BurstFireMod._needs_upd_burst_count = true
	end
	BurstFireMod:load_settings()
	MenuHelper:LoadFromJsonFile(BurstFireMod.options_path, BurstFireMod, BurstFireMod.settings)
end)