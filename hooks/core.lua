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
	--MenuHelper:NewMenu("blackmarket_customize_burstfire")

	local menu_component_data = {
		topic_id = "menu_burstfiremod_customize_burstfire",
		init_callback_name = "nothing"
	}
	menu_component_data.init_callback_params = menu_component_data
	
	local new_node = {
		_meta = "node",
		align_line_proportions=0.7,
		gui_class = "MenuNodeCustomizeBurstGui",
--		menu_components = "blackmarket inventory_chats", -- attaching this makes the menu default to opening the steam inventory every time. undesirable
--		menu_component_data = menu_component_data,
		modifier = "MenuCustomizeBurstfireInitiator",
		name = "blackmarket_customize_burstfire",
		refresh = "MenuCustomizeBurstfireInitiator",
--		back_callback = "callback_burstfiremod_wp_mod_back",
		scene_state = "blackmarket_crafting",
		topic_id="menu_burstfiremod_customize_burstfire",
		[1] = {
			["_meta"] = "default_item",
			["name"] = "back"
		}
	}
	local noed = core:import("CoreMenuNode").MenuNode:new(new_node)
	nodes["blackmarket_customize_burstfire"] = noed
end)

Hooks:Add("MenuManagerPopulateCustomMenus", "burstfiremod_MenuManagerPopulateCustomMenus", function(menu_manager, nodes)
--[[
	MenuHelper:AddMultipleChoice({
		id = "burstfiremod_wp_mod_set_burst_count",
		title = "menu_burstfiremod_wp_mod_set_burst_count_title",
		desc = "menu_burstfiremod_wp_mod_set_burst_count_desc",
		callback = "callback_burstfiremod_wp_mod_set_burst_count",
		items = {
			"menu_burstfiremod_wp_mod_burst_count_2",
			"menu_burstfiremod_wp_mod_burst_count_3",
			"menu_burstfiremod_wp_mod_burst_count_4"
		},
		value = 1,
		menu_id = "blackmarket_customize_burstfire",
		priority = 1
	})
--]]
end)

Hooks:Add("MenuManagerBuildCustomMenus", "burstfiremod_MenuManagerBuildCustomMenus", function(menu_manager, nodes)
--[[
	local burstfiremod_customize_menu = MenuHelper:BuildMenu(
		"blackmarket_customize_burstfire",{
			--area_bg = "none",
			--back_callback = "callback_burstfiremod_back",
			--focus_changed_callback = "callback_burstfiremod_focus"
		}
	)
	nodes["blackmarket_customize_burstfire"] = burstfiremod_customize_menu
	--]]
	
	--MenuHelper:AddMenuItem(nodes.blt_options,"blackmarket_customize_burstfire","bm_menu_btn_customize_burstfire","bm_menu_btn_customize_burstfire_desc")
end)

Hooks:Add("MenuManagerInitialize", "burstfiremod_MenuManagerInitialize", function(menu_manager)
	MenuCallbackHandler.should_show_weapon_burstfire_count_apply = function(self)
		return true
	end
	MenuCallbackHandler.apply_weapon_burstfire_count = function(self,data)
		Print("Apply weapon burstfire count",data)
		_G.asdfddfd = data
	end
	MenuCallbackHandler.callback_burstfiremod_wp_mod_set_burst_count = function(self,item)
		Print("Set burst count:",item:value())
	end
	
	MenuCallbackHandler.callback_burstfiremod_menu_back = function(self)
		if BurstFireMod._needs_upd_burst_count then -- if setting was changed, change the burst count on any and all applicable guns
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
		-- apply to all weapons
		BurstFireMod:save_settings()
		BurstFireMod._needs_upd_burst_count = true
	end
	BurstFireMod:load_settings()
	MenuHelper:LoadFromJsonFile(BurstFireMod.options_path, BurstFireMod, BurstFireMod.settings)
end)