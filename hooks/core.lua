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

Hooks:Add("MenuManagerInitialize", "burstfiremod_MenuManagerInitialize", function(menu_manager)
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
