//Geiger counter
//Rewritten version of TG's geiger counter
//I opted to show exact radiation levels

/obj/item/geiger
	name = "geiger counter"
	desc = "A handheld device used for detecting and measuring radiation in an area."
	icon = 'icons/obj/device.dmi'
	icon_state = "geiger_off"
	item_state = "multitool"
	w_class = ITEMSIZE_SMALL
	var/scanning = 0
	var/radiation_count = 0
	var/datum/looping_sound/geiger/soundloop

	matter = list(MAT_STEEL = 200, MAT_GLASS = 100)

/obj/item/geiger/Initialize(mapload)
	soundloop = new(list(src), FALSE)
	return ..()

/obj/item/geiger/Destroy()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(soundloop)
	return ..()

/obj/item/geiger/process(delta_time)
	get_radiation()

/obj/item/geiger/proc/get_radiation()
	if(!scanning)
		return
	radiation_count = SSradiation.get_rads_at_turf(get_turf(src))
	update_icon()
	update_sound()

/obj/item/geiger/examine(mob/user)
	. = ..()
	get_radiation()
	. += "<span class='warning'>[scanning ? "Ambient" : "Stored"] radiation level: [radiation_count ? radiation_count : "0"]Bq.</span>"

/obj/item/geiger/rad_act(amount)
	if(!amount || !scanning)
		return FALSE

	if(amount > radiation_count)
		radiation_count = amount

	update_icon()
	update_sound()

/obj/item/geiger/proc/update_sound()
	var/datum/looping_sound/geiger/loop = soundloop
	if(!scanning)
		loop.stop()
		return
	if(!radiation_count)
		loop.stop()
		return
	loop.last_radiation = radiation_count
	loop.start()

/obj/item/geiger/AltClick(var/mob/user)
	attack_self(user)

/obj/item/geiger/attack_self(var/mob/user)
	scanning = !scanning
	if(scanning)
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj, src)
	update_icon()
	update_sound()
	to_chat(user, "<span class='notice'>[icon2html(thing = src, target = user)] You switch [scanning ? "on" : "off"] \the [src].</span>")

/obj/item/geiger/update_icon()
	if(!scanning)
		icon_state = "geiger_off"
		return 1

	switch(radiation_count)
		if(null)
			icon_state = "geiger_on_1"
		if(-INFINITY to RAD_LEVEL_LOW)
			icon_state = "geiger_on_1"
		if(RAD_LEVEL_LOW to RAD_LEVEL_MODERATE)
			icon_state = "geiger_on_2"
		if(RAD_LEVEL_MODERATE to RAD_LEVEL_HIGH)
			icon_state = "geiger_on_3"
		if(RAD_LEVEL_HIGH to RAD_LEVEL_VERY_HIGH)
			icon_state = "geiger_on_4"
		if(RAD_LEVEL_VERY_HIGH to INFINITY)
			icon_state = "geiger_on_5"
