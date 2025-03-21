local ids_single = Idstring("single")
local ids_auto = Idstring("auto")
local ids_burst = Idstring("burst")
local ids_volley = Idstring("volley")
local FIRE_MODE_IDS = {
	single = ids_single,
	auto = ids_auto,
	burst = ids_burst,
	volley = ids_volley
}

Hooks:PostHook(NewRaycastWeaponBase,"init","weaponbase_burstfiremod_init",function(self,unit)
	-- set the burst count with this helper function (doesn't actually matter much here, it'll be overwritten by future calls to _update_stats_values() )
	BurstFireMod.set_burst_count(self,BurstFireMod:get_default_burst_count())
	
	-- if the weapon has a manual list of possible firemodes,
	-- make sure burst is in them;
	if BurstFireMod:is_global_burst_enabled() then
		local td = self:weapon_tweak_data()
		
		-- allow custom weapons to opt out of allowing their weapon to use burst fire
		if not td.BURST_MOD_DISABLED then
			local fire_mode_data = td.fire_mode_data or {}
			local toggable_fire_modes = fire_mode_data.toggable
			if self._toggable_fire_modes and toggable_fire_modes then
				if not table.contains(self._toggable_fire_modes,ids_burst) then
					table.insert(self._toggable_fire_modes,ids_burst)
				end
			end
		end
	end
end)

Hooks:PostHook(NewRaycastWeaponBase,"_update_stats_values","weaponbase_burstfiremod_update_stats",function(self, disallow_replenish, ammo_data)
	-- set the burst count (again)
	BurstFireMod.set_burst_count(self,BurstFireMod:get_default_burst_count())
	
	local is_underbarrel = self.is_underbarrel and self:is_underbarrel()
	if not is_underbarrel and self._custom_burst_count then 
		-- burst firemode part setting should override other parts that incidentally change burst count
		self._burst_count = self._custom_burst_count
		return
	end
	
	local custom_stats = managers.weapon_factory:get_custom_stats_from_weapon(self._factory_id, self._blueprint)
	local part_data = nil
	local weap_factory_parts = tweak_data.weapon.factory.parts

	for part_id, stats in pairs(custom_stats) do
		part_data = weap_factory_parts[part_id]
		local can_apply = true

		if part_data.type == "underbarrel_ammo" then
			can_apply = is_underbarrel
		elseif part_data.type == "ammo" then
			can_apply = not is_underbarrel
		end

		if can_apply then
			-- if a part has the burst count stat, use that instead of the base weapon burst count
			if stats.burst_count then
				self._burst_count = stats.burst_count
			end
		end
	end
end)

local orig_toggle_firemode = Hooks:GetFunction(NewRaycastWeaponBase,"toggle_firemode")
Hooks:OverrideFunction(NewRaycastWeaponBase,"toggle_firemode",function(self, skip_post_event, ...)
	if BurstFireMod:is_global_burst_enabled() then
		local td = self:weapon_tweak_data()
		
		-- allow custom weapons to opt out of allowing their weapon to use burst fire (again)
		if not td.BURST_MOD_DISABLED then
		-- << UNCHANGED
			local can_toggle = not self._locked_fire_mode and self:can_toggle_firemode()

			if can_toggle then
				if self._toggable_fire_modes then
					local cur_fire_mode = table.index_of(self._toggable_fire_modes, self._fire_mode)

					if cur_fire_mode > 0 then
						cur_fire_mode = cur_fire_mode % #self._toggable_fire_modes + 1
						self._fire_mode = self._toggable_fire_modes[cur_fire_mode]

						if not skip_post_event then
							self._sound_fire:post_event(cur_fire_mode % 2 == 0 and "wp_auto_switch_on" or "wp_auto_switch_off")
						end

						local fire_mode_data = self._fire_mode_data[self._fire_mode:key()]
						local fire_effect = fire_mode_data and (self._silencer and fire_mode_data.muzzleflash_silenced or fire_mode_data.muzzleflash)

						self:change_fire_effect(fire_effect)

						local trail_effect = fire_mode_data and fire_mode_data.trail_effect

						self:change_trail_effect(trail_effect)
						self:call_on_digital_gui("set_firemode", self:fire_mode())
						self:update_firemode_gui_ammo()

						return true
					end

					return false
				end
		-- >>
				
		-- << DEFINTIELY CHANGED A LITTLE
				-- single --> burst --> auto ...
				if self._fire_mode == ids_single then
					self._fire_mode = ids_burst

					if not skip_post_event then
						self._sound_fire:post_event("wp_auto_switch_on")
					end
				elseif self._fire_mode == ids_burst then
					self._fire_mode = ids_auto
					if not skip_post_event then
						self._sound_fire:post_event("wp_auto_switch_on")
					end
				else
					self._fire_mode = ids_single

					if not skip_post_event then
						self._sound_fire:post_event("wp_auto_switch_off")
					end
				end
		-- >>
				
				
		-- << (mostly) UNCHANGED  (except i used a local shortcut on line 129)
				return true
			elseif self._alt_fire_data then
				self._alt_fire_active = not self._alt_fire_active

				if self._alt_fire_data.shell_ejection then
					self._shell_ejection_effect = Idstring(self._alt_fire_active and self._alt_fire_data.shell_ejection or td.shell_ejection or "effects/payday2/particles/weapons/shells/shell_556") -- slight modification on this line 
					self._shell_ejection_effect_table = {
						effect = self._shell_ejection_effect,
						parent = self._obj_shell_ejection
					}
				end

				if not skip_post_event then
					self._sound_fire:post_event(self._alt_fire_active and "wp_auto_switch_on" or "wp_auto_switch_off")
				end

				self:update_damage()

				return true
			end

			return false
		-- >> 
		end
	end
	
	return orig_toggle_firemode(self,skip_post_event,...)
end)

Hooks:PostHook(NewRaycastWeaponBase,"clbk_assembly_complete","weaponbase_burstfiremod_assembly",function(self, clbk, parts, blueprint)
	local category = tweak_data.weapon[self._name_id].use_data.selection_index == 2 and "primaries" or "secondaries"
	local slot = managers.blackmarket:equipped_weapon_slot(category)
	local crafted = managers.blackmarket:get_crafted_category_slot(category, slot)
	if crafted then 
		if crafted.part_burst_count == 1 then
			-- use custom stat count from attachment, or mod setting default
			self._custom_burst_count = nil
		else
			self._custom_burst_count = crafted.part_burst_count
		end
		-- cache burst count from part customization;
		-- no need to query blackmarketmanager every time for this
	end
end)

-- this should fix crashing from npcs or akimbo weapons using burst firemode
Hooks:PreHook(NewRaycastWeaponBase,"fire","weaponbase_burstfiremod_firepre",function(self,...)
	if self._fire_mode == ids_burst then
		self._burstfiremod_cache_bullets_fired = self._bullets_fired
		self._bullets_fired = self._bullets_fired or 0 --self._burst_count
	end
end)
Hooks:PostHook(NewRaycastWeaponBase,"fire","weaponbase_burstfiremod_firepost",function(self,...)
	if self._fire_mode == ids_burst then 
		self._bullets_fired,self._burstfiremod_cache_bullets_fired = self._burstfiremod_cache_bullets_fired,nil
	end
end)
