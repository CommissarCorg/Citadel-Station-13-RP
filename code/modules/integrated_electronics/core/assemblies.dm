#define IC_COMPONENTS_BASE		20
#define IC_COMPLEXITY_BASE		60

// Here is where the base definition lives.
// Specific subtypes are in their own folder.
/obj/item/electronic_assembly
	name = "electronic assembly"
	desc = "It's a case, for building small electronics with."
	w_class = ITEMSIZE_SMALL
	icon = 'icons/obj/integrated_electronics/electronic_setups.dmi'
	icon_state = "setup_small"
	show_messages = TRUE
	var/max_components = IC_COMPONENTS_BASE
	var/max_complexity = IC_COMPLEXITY_BASE
	var/opened = FALSE
	/// If true, wrenching it will anchor it.
	var/can_anchor = FALSE
	/// Internal cell which most circuits need to work.
	var/obj/item/cell/device/battery = null
	/// Set every tick, to display how much power is being drawn in total.
	var/net_power = 0
	var/detail_color = COLOR_ASSEMBLY_BLACK


/obj/item/electronic_assembly/Initialize(mapload)
	battery = new(src)
	START_PROCESSING(SSobj, src)
	return ..()

/obj/item/electronic_assembly/Destroy()
	battery = null // It will be qdel'd by ..() if still in our contents
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/electronic_assembly/process(delta_time)
	handle_idle_power()

/obj/item/electronic_assembly/proc/handle_idle_power()
	net_power = 0 // Reset this. This gets increased/decreased with [give/draw]_power() outside of this loop.

	// First we handle passive sources. Most of these make power so they go first.
	for(var/obj/item/integrated_circuit/passive/power/P in contents)
		P.handle_passive_energy()

	// Now we handle idle power draw.
	for(var/obj/item/integrated_circuit/IC in contents)
		if(IC.power_draw_idle)
			if(!draw_power(IC.power_draw_idle))
				IC.power_fail()

/obj/item/electronic_assembly/proc/check_interactivity(mob/user)
	return ui_status(user, GLOB.physical_state) == UI_INTERACTIVE

/obj/item/electronic_assembly/get_cell()
	return battery

// TGUI
/obj/item/electronic_assembly/ui_state(mob/user)
	return GLOB.physical_state

/obj/item/electronic_assembly/ui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ICAssembly", name, parent_ui)
		ui.open()

/obj/item/electronic_assembly/ui_data(mob/user, datum/tgui/ui, datum/ui_state/state)
	var/list/data = ..()

	var/total_parts = 0
	var/total_complexity = 0
	for(var/obj/item/integrated_circuit/part in contents)
		total_parts += part.size
		total_complexity = total_complexity + part.complexity

	data["total_parts"] = total_parts
	data["max_components"] = max_components
	data["total_complexity"] = total_complexity
	data["max_complexity"] = max_complexity

	data["battery_charge"] = round(battery?.charge, 0.1)
	data["battery_max"] = round(battery?.maxcharge, 0.1)
	data["net_power"] = DYNAMIC_CELL_UNITS_TO_W(net_power, 1)

	// This works because lists are always passed by reference in BYOND, so modifying unremovable_circuits
	// after setting data["unremovable_circuits"] = unremovable_circuits also modifies data["unremovable_circuits"]
	// Same for the removable one
	var/list/unremovable_circuits = list()
	data["unremovable_circuits"] = unremovable_circuits
	var/list/removable_circuits = list()
	data["removable_circuits"] = removable_circuits
	for(var/obj/item/integrated_circuit/circuit in contents)
		var/list/target = circuit.removable ? removable_circuits : unremovable_circuits
		target.Add(list(list(
			"name" = circuit.displayed_name,
			"ref" = REF(circuit),
		)))

	return data

/obj/item/electronic_assembly/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	var/obj/held_item = usr.get_active_hand()

	switch(action)
		//Actual assembly actions
		if("rename")
			rename(usr)
			return TRUE

		if("remove_cell")
			if(!battery)
				to_chat(usr, SPAN_WARNING("There's no power cell to remove from \the [src]."))
				return FALSE
			var/turf/T = get_turf(src)
			battery.forceMove(T)
			playsound(T, 'sound/items/Crowbar.ogg', 50, TRUE)
			to_chat(usr, SPAN_NOTICE("You pull \the [battery] out of \the [src]'s power supplier."))
			battery = null
			return TRUE

		// Circuit actions
		if("open_circuit")
			var/obj/item/integrated_circuit/C = locate(params["ref"]) in contents
			if(!istype(C))
				return
			C.ui_interact(usr, null, ui)
			return TRUE

		if("rename_circuit")
			var/obj/item/integrated_circuit/C = locate(params["ref"]) in contents
			if(!istype(C))
				return
			C.rename_component(usr)
			return TRUE

		if("scan_circuit")
			var/obj/item/integrated_circuit/C = locate(params["ref"]) in contents
			if(!istype(C))
				return
			if(istype(held_item, /obj/item/integrated_electronics/debugger))
				var/obj/item/integrated_electronics/debugger/D = held_item
				if(D.accepting_refs)
					D.afterattack(C, usr, TRUE)
				else
					to_chat(usr, SPAN_WARNING("The Debugger's 'ref scanner' needs to be on."))
			else
				to_chat(usr, SPAN_WARNING("You need a multitool/debugger set to 'ref' mode to do that."))
			return TRUE

		if("remove_circuit")
			var/obj/item/integrated_circuit/C = locate(params["ref"]) in contents
			if(!istype(C))
				return
			C.remove(usr)
			return TRUE

		if("bottom_circuit")
			var/obj/item/integrated_circuit/C = locate(params["ref"]) in contents
			if(!istype(C))
				return
			// Puts it at the bottom of our contents
			// Note, this intentionally does *not* use forceMove, because forceMove will stop if it detects the same loc
			C.loc = null
			C.loc = src
	return FALSE
// End TGUI

/obj/item/electronic_assembly/verb/rename()
	set name = "Rename Circuit"
	set category = "Object"
	set desc = "Rename your circuit, useful to stay organized."

	var/mob/M = usr
	if(!check_interactivity(M))
		return

	var/input = sanitizeSafe(input(usr, "What do you want to name this?", "Rename", src.name) as null|text, MAX_NAME_LEN)
	if(src && input)
		to_chat(M, SPAN_NOTICE("The machine now has a label reading '[input]'."))
		name = input

/obj/item/electronic_assembly/proc/can_move()
	return FALSE

/obj/item/electronic_assembly/update_icon()
	if(opened)
		icon_state = initial(icon_state) + "-open"
	else
		icon_state = initial(icon_state)
	cut_overlays()
	if(detail_color == COLOR_ASSEMBLY_BLACK) //Black colored overlay looks almost but not exactly like the base sprite, so just cut the overlay and avoid it looking kinda off.
		return
	var/mutable_appearance/detail_overlay = mutable_appearance('icons/obj/integrated_electronics/electronic_setups.dmi', "[icon_state]-color")
	detail_overlay.color = detail_color
	add_overlay(detail_overlay)


/obj/item/electronic_assembly/GetAccess()
	. = list()
	for(var/obj/item/integrated_circuit/part in contents)
		. |= part.GetAccess()

/obj/item/electronic_assembly/GetIdCard()
	. = list()
	for(var/obj/item/integrated_circuit/part in contents)
		var/id_card = part.GetIdCard()
		if(id_card)
			return id_card

/obj/item/electronic_assembly/examine(mob/user)
	. = ..()
	if(Adjacent(user))
		for(var/obj/item/integrated_circuit/IC in contents)
			. += IC.external_examine(user)
		if(opened)
			ui_interact(user)

/obj/item/electronic_assembly/proc/get_part_complexity()
	. = 0
	for(var/obj/item/integrated_circuit/part in contents)
		. += part.complexity

/obj/item/electronic_assembly/proc/get_part_size()
	. = 0
	for(var/obj/item/integrated_circuit/part in contents)
		. += part.size

// Returns true if the circuit made it inside.
/obj/item/electronic_assembly/proc/add_circuit(var/obj/item/integrated_circuit/IC, var/mob/user)
	if(!opened)
		to_chat(user, SPAN_WARNING("\The [src] isn't opened, so you can't put anything inside.  Try using a crowbar."))
		return FALSE

	if(IC.w_class > src.w_class)
		to_chat(user, SPAN_WARNING("\The [IC] is way too big to fit into \the [src]."))
		return FALSE

	var/total_part_size = get_part_size()
	var/total_complexity = get_part_complexity()

	if((total_part_size + IC.size) > max_components)
		to_chat(user, SPAN_WARNING("You can't seem to add the '[IC.name]', as there's insufficient space."))
		return FALSE
	if((total_complexity + IC.complexity) > max_complexity)
		to_chat(user, SPAN_WARNING("You can't seem to add the '[IC.name]', since this setup's too complicated for the case."))
		return FALSE

	if(!IC.forceMove(src))
		return FALSE

	IC.assembly = src

	return TRUE

// Non-interactive version of above that always succeeds, intended for build-in circuits that get added on assembly initialization.
/obj/item/electronic_assembly/proc/force_add_circuit(var/obj/item/integrated_circuit/IC)
	IC.forceMove(src)
	IC.assembly = src

/obj/item/electronic_assembly/afterattack(atom/target, mob/user, proximity)
	if(proximity)
		var/scanned = FALSE
		for(var/obj/item/integrated_circuit/input/sensor/S in contents)
//			S.set_pin_data(IC_OUTPUT, 1, WEAKREF(target))
//			S.check_then_do_work()
			if(S.scan(target))
				scanned = TRUE
		if(scanned)
			visible_message(SPAN_NOTICE("\The [user] waves \the [src] around [target]."))

/obj/item/electronic_assembly/attackby(var/obj/item/I, var/mob/user)
	if(can_anchor && I.is_wrench())
		anchored = !anchored
		to_chat(user, SPAN_NOTICE("You've [anchored ? "" : "un"]secured \the [src] to \the [get_turf(src)]."))
		if(anchored)
			on_anchored()
		else
			on_unanchored()
		playsound(src, I.usesound, 50, 1)
		return TRUE

	else if(istype(I, /obj/item/integrated_circuit))
		if(!user.unEquip(I) && !istype(user, /mob/living/silicon/robot)) //Robots cannot de-equip items in grippers.
			return FALSE
		if(add_circuit(I, user))
			to_chat(user, SPAN_NOTICE("You slide \the [I] inside \the [src]."))
			playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, 1)
			ui_interact(user)
			return TRUE

	else if(I.is_crowbar())
		if(!opened)
			return FALSE
		if(!battery)
			to_chat(usr, SPAN_WARNING("There's no power cell to remove from \the [src]."))
			return FALSE
		battery.forceMove(get_turf(src))
		playsound(get_turf(src), 'sound/items/Crowbar.ogg', 50, 1)
		to_chat(user, SPAN_NOTICE("You pull \the [battery] out of \the [src]'s power supplier."))
		battery = null
		return TRUE

	else if(I.is_screwdriver())
		playsound(get_turf(src), 'sound/items/Screwdriver.ogg', 50, 1)
		opened = !opened
		to_chat(user, SPAN_NOTICE("You [opened ? "opened" : "closed"] \the [src]."))
		update_icon()
		return TRUE

	else if(istype(I, /obj/item/integrated_electronics/wirer) || istype(I, /obj/item/integrated_electronics/debugger) || I.is_screwdriver())
		if(opened)
			ui_interact(user)
		else
			to_chat(user, SPAN_WARNING("\The [src] isn't opened, so you can't fiddle with the internal components.  Try using a crowbar."))

	else if(istype(I, /obj/item/integrated_electronics/detailer))
		var/obj/item/integrated_electronics/detailer/D = I
		detail_color = D.detail_color
		update_icon()

	else if(istype(I, /obj/item/cell/device))
		if(!opened)
			to_chat(user, SPAN_WARNING("\The [src] isn't opened, so you can't put anything inside.  Try using a crowbar."))
			return FALSE
		if(battery)
			to_chat(user, SPAN_WARNING("\The [src] already has \a [battery] inside.  Remove it first if you want to replace it."))
			return FALSE
		var/obj/item/cell/device/cell = I
		user.drop_item(cell)
		cell.forceMove(src)
		battery = cell
		playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, 1)
		to_chat(user, SPAN_NOTICE("You slot \the [cell] inside \the [src]'s power supplier."))
		ui_interact(user)
		return TRUE
	else
		return ..()

/obj/item/electronic_assembly/attack_self(mob/user)
	if(!check_interactivity(user))
		return
	if(opened)
		ui_interact(user)

	var/list/input_selection = list()
	var/list/available_inputs = list()
	for(var/obj/item/integrated_circuit/input/input in contents)
		if(input.can_be_asked_input)
			available_inputs.Add(input)
			var/i = 0
			for(var/obj/item/integrated_circuit/s in available_inputs)
				if(s.name == input.name && s.displayed_name == input.displayed_name && s != input)
					i++
			var/disp_name= "[input.displayed_name] \[[input.name]\]"
			if(i)
				disp_name += " ([i+1])"
			input_selection.Add(disp_name)

	var/obj/item/integrated_circuit/input/choice
	if(available_inputs)
		var/selection = tgui_input_list(user, "What do you want to interact with?", "Interaction", input_selection)
		if(selection)
			var/index = input_selection.Find(selection)
			choice = available_inputs[index]

	if(choice)
		choice.ask_for_input(user)

/obj/item/electronic_assembly/attack_robot(mob/user as mob)
	if(Adjacent(user))
		return attack_self(user)
	else
		return ..()

/obj/item/electronic_assembly/emp_act(severity)
	..()
	for(var/atom/movable/AM in contents)
		AM.emp_act(severity)

// Returns true if power was successfully drawn.
/obj/item/electronic_assembly/proc/draw_power(amount)
	if(battery)
		var/lost = battery.use(DYNAMIC_W_TO_CELL_UNITS(amount, 1))
		net_power -= lost
		return lost > 0
	return FALSE

// Ditto for giving.
/obj/item/electronic_assembly/proc/give_power(amount)
	if(battery)
		var/gained = battery.give(DYNAMIC_W_TO_CELL_UNITS(amount, 1))
		net_power += gained
		return TRUE
	return FALSE

// Returns true if power was successfully drawn.
/obj/item/electronic_assembly/proc/draw_power_kw(amount)
	if(battery)
		var/lost = battery.use(DYNAMIC_KW_TO_CELL_UNITS(amount, 1))
		net_power -= lost
		return lost > 0
	return FALSE

// Ditto for giving.
/obj/item/electronic_assembly/proc/give_power_kw(amount)
	if(battery)
		var/gained = battery.give(DYNAMIC_KW_TO_CELL_UNITS(amount, 1))
		net_power += gained
		return TRUE
	return FALSE

/obj/item/electronic_assembly/on_loc_moved(oldloc)
	. = ..()
	for(var/obj/O in contents)
		O.on_loc_moved(oldloc)

/obj/item/electronic_assembly/Moved(var/oldloc)
	. = ..()
	for(var/obj/O in contents)
		O.on_loc_moved(oldloc)

/obj/item/electronic_assembly/proc/on_anchored()
	for(var/obj/item/integrated_circuit/IC in contents)
		IC.on_anchored()

/obj/item/electronic_assembly/proc/on_unanchored()
	for(var/obj/item/integrated_circuit/IC in contents)
		IC.on_unanchored()
