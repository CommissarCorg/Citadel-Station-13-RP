/mob
	var/vantag_hud = 0			// Do I have the HUD enabled?
	var/flying = 0				// Allows flight
	var/mob/temporary_form		// For holding onto a temporary form

	var/disconnect_time = null		//Time of client loss, set by Logout(), for timekeeping

	var/atom/movable/screen/shadekin/darkness/shadekin_dark_display = null
	var/atom/movable/screen/shadekin/energy/shadekin_energy_display = null
	var/atom/movable/screen/xenochimera/danger_level/xenochimera_danger_display = null
