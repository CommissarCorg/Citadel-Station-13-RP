// POWERNET SENSOR MONITORING CONSOLE
// Connects to powernet sensors and loads data from them. Shows this data to the user.
// Newly supports NanoUI.


/obj/machinery/computer/power_monitor
	name = "Power Monitoring Console"
	desc = "Computer designed to remotely monitor power levels around the station"
	icon_keyboard = "power_key"
	icon_screen = "power:0"
	light_color = "#ffcc33"

	//computer stuff
	density = 1
	anchored = 1.0
	circuit = /obj/item/circuitboard/powermonitor
	var/alerting = 0
	use_power = USE_POWER_IDLE
	idle_power_usage = 300
	active_power_usage = 300
	var/datum/nano_module/power_monitor/power_monitor

// Checks the sensors for alerts. If change (alerts cleared or detected) occurs, calls for icon update.
/obj/machinery/computer/power_monitor/process(delta_time)
	var/alert = check_warnings()
	if(alert != alerting)
		alerting = !alerting
		update_icon()

// On creation automatically connects to active sensors. This is delayed to ensure sensors already exist.
/obj/machinery/computer/power_monitor/Initialize(mapload)
	. = ..()
	power_monitor = new(src)

// On user click opens the UI of this computer.
/obj/machinery/computer/power_monitor/attack_hand(mob/user)
	add_fingerprint(user)

	if(machine_stat & (BROKEN|NOPOWER))
		return
	nano_ui_interact(user)

// Uses dark magic to operate the NanoUI of this computer.
/obj/machinery/computer/power_monitor/nano_ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	power_monitor.nano_ui_interact(user, ui_key, ui, force_open)


// Verifies if any warnings were registered by connected sensors.
/obj/machinery/computer/power_monitor/proc/check_warnings()
	for(var/obj/machinery/power/sensor/S in power_monitor.grid_sensors)
		if(S.check_grid_warning())
			return 1
	return 0
