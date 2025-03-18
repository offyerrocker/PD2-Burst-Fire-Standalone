Hooks:PostHook(WeaponFactoryTweakData,"init","burstfireattachmentmod_addtoweapons",function(self)
	-- ALLOW burstfire attachment on all weapons that can accept the autofire or singlefire attachments
	for id,wpn in pairs(self) do 
		if type(wpn) == "table" and type(wpn.uses_parts) == "table" then 
			if (table.contains(wpn.uses_parts,"wpn_fps_upg_i_autofire") or table.contains(wpn.uses_parts,"wpn_fps_upg_i_singlefire")) and not table.contains(wpn.uses_parts,"wpn_fps_upg_i_burstfire") then
				table.insert(wpn.uses_parts,"wpn_fps_upg_i_burstfire")
			end	
		end
	end
end)

Hooks:PostHook(WeaponFactoryTweakData,"_init_content_dlc2","burstfireattachmentmod_addpart",function(self)
	-- BLOCK burstfire attachment on all parts that are also incompatible with autofire or singlefire attachments
	for id,part in pairs(self.parts) do 
		if part.forbids and type(part.forbids) == "table" then -- if someone screwed up the formatting for their part data they're sure as hell not gonna blame it on me
			if (table.contains(part.forbids,"wpn_fps_upg_i_autofire") or table.contains(part.forbids,"wpn_fps_upg_i_singlefire")) and not table.contains(part.forbids,"wpn_fps_upg_i_burstfire") then 
				table.insert(part.forbids,"wpn_fps_upg_i_burstfire")
			end
		end
	end
end)