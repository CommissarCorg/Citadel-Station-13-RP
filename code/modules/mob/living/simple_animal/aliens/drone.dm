/datum/category_item/catalogue/fauna/malf_drone
	name = "Malfunctioning Combat Drone"
	desc = "Many drones like this are fielded by Corporate naval fleets. \
	Armed with heavy lasers, powerful combat shielding, armored frames, and \
	self destruct cores, stumbling across one of these in the field is an almost \
	guaranteed death sentence. When a combat drone malfunctions, it becomes twice \
	as deadly, as it will attack anything it sees - even former allies."
	value = CATALOGUER_REWARD_MEDIUM

//malfunctioning combat drones
/mob/living/simple_mob/hostile/malf_drone
	name = "combat drone"
	desc = "An automated combat drone armed with state of the art weaponry and shielding."
	icon_state = "drone3"
	icon_living = "drone3"
	icon_dead = "drone_dead"

	faction = "malf_drone"
	intelligence_level = SA_ROBOTIC
	maxHealth = 300
	health = 300
	speed = 8
	stop_when_pulled = 0

	turns_per_move = 3
	response_help = "pokes"
	response_disarm = "gently pushes aside"
	response_harm = "hits"

	a_intent = INTENT_HARM
	ranged = 1
	rapid = 1
	projectiletype = /obj/item/projectile/beam/drone
	projectilesound = 'sound/weapons/laser3.ogg'
	destroy_surroundings = 0
	hovering = TRUE

	armor = list(melee = 25, bullet = 25, laser = 25, energy = 10, bomb = 25, bio = 100, rad = 100)	// Some level of armor plating makes sense
	//Drones aren't affected by atmos.
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0

	speak_chance = 5
	speak = list("ALERT.","Hostile-ile-ile entities dee-twhoooo-wected.","Threat parameterszzzz- szzet.","Bring sub-sub-sub-systems uuuup to combat alert alpha-a-a.")
	emote_see = list("beeps menacingly","whirrs threateningly","scans its immediate vicinity")


	var/datum/effect_system/ion_trail_follow/ion_trail
	var/turf/patrol_target
	var/explode_chance = 1
	var/disabled = 0
	var/exploding = 0
	var/has_loot = 1

/mob/living/simple_mob/hostile/malf_drone/Initialize(mapload)
	. = ..()
	if(prob(5))
		projectiletype = /obj/item/projectile/beam/pulse/drone
		projectilesound = 'sound/weapons/pulse2.ogg'
	ion_trail = new
	ion_trail.set_up(src)
	ion_trail.start()

/mob/living/simple_mob/hostile/malf_drone/Process_Spacemove(var/check_drift = 0)
	return 1

/mob/living/simple_mob/hostile/malf_drone/isSynthetic()
	return TRUE

//self repair systems have a chance to bring the drone back to life
/mob/living/simple_mob/hostile/malf_drone/Life()

	//emps and lots of damage can temporarily shut us down
	if(disabled > 0)
		set_stat(UNCONSCIOUS)
		icon_state = "drone_dead"
		disabled--
		wander = 0
		speak_chance = 0
		if(disabled <= 0)
			set_stat(CONSCIOUS)
			icon_state = "drone0"
			wander = 1
			speak_chance = 5

	//repair a bit of damage
	if(prob(1))
		src.visible_message("<font color='red'>[icon2html(thing = src, target = world)] [src] shudders and shakes as some of it's damaged systems come back online.</font>")
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, src)
		s.start()
		health += rand(25,100)

	//spark for no reason
	if(prob(5))
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, src)
		s.start()

	//sometimes our targetting sensors malfunction, and we attack anyone nearby
	if(prob(disabled ? 0 : 1))
		if(hostile)
			src.visible_message("<font color=#4F49AF>[icon2html(thing = src, target = world)] [src] retracts several targetting vanes, and dulls it's running lights.</font>")
			hostile = 0
		else
			src.visible_message("<font color='red'>[icon2html(thing = src, target = world)] [src] suddenly lights up, and additional targetting vanes slide into place.</font>")
			hostile = 1

	if(health / getMaxHealth() > 0.9)
		icon_state = "drone3"
		explode_chance = 0
	else if(health / getMaxHealth() > 0.7)
		icon_state = "drone2"
		explode_chance = 0
	else if(health / getMaxHealth() > 0.5)
		icon_state = "drone1"
		explode_chance = 0.5
	else if(health / getMaxHealth() > 0.3)
		icon_state = "drone0"
		explode_chance = 5
	else if(health > 0)
		//if health gets too low, shut down
		icon_state = "drone_dead"
		exploding = 0
		if(!disabled)
			if(prob(50))
				src.visible_message("<font color=#4F49AF>[icon2html(thing = src, target = world)] [src] suddenly shuts down!</font>")
			else
				src.visible_message("<font color=#4F49AF>[icon2html(thing = src, target = world)] [src] suddenly lies still and quiet.</font>")
			disabled = rand(150, 600)
			walk(src,0)

	if(exploding && prob(20))
		if(prob(50))
			src.visible_message("<font color='red'>[icon2html(thing = src, target = world)] [src] begins to spark and shake violenty!</font>")
		else
			src.visible_message("<font color='red'>[icon2html(thing = src, target = world)] [src] sparks and shakes like it's about to explode!</font>")
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, src)
		s.start()

	if(!exploding && !disabled && prob(explode_chance))
		exploding = 1
		set_stat(UNCONSCIOUS)
		wander = 1
		walk(src,0)
		spawn(rand(50,150))
			if(!disabled && exploding)
				explosion(get_turf(src), 0, 1, 4, 7)
				//proc/explosion(turf/epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, adminlog = 1)
	..()

//ion rifle!
/mob/living/simple_mob/hostile/malf_drone/emp_act(severity)
	health -= rand(3,15) * (severity + 1)
	disabled = rand(150, 600)
	hostile = 0
	walk(src,0)
	..()

/mob/living/simple_mob/hostile/malf_drone/death()
	..(null,"suddenly breaks apart.")
	qdel(src)

/mob/living/simple_mob/hostile/malf_drone/Destroy()
	//More advanced than the default S_A loot system, for visual effect and random tech levels.
	if(has_loot)
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, src)
		s.start()
		var/obj/O

		//shards
		O = new /obj/item/material/shard(src.loc)
		step_to(O, get_turf(pick(view(7, src))))
		if(prob(75))
			O = new /obj/item/material/shard(src.loc)
			step_to(O, get_turf(pick(view(7, src))))
		if(prob(50))
			O = new /obj/item/material/shard(src.loc)
			step_to(O, get_turf(pick(view(7, src))))
		if(prob(25))
			O = new /obj/item/material/shard(src.loc)
			step_to(O, get_turf(pick(view(7, src))))

		//rods
		O = new /obj/item/stack/rods(src.loc)
		step_to(O, get_turf(pick(view(7, src))))
		if(prob(75))
			O = new /obj/item/stack/rods(src.loc)
			step_to(O, get_turf(pick(view(7, src))))
		if(prob(50))
			O = new /obj/item/stack/rods(src.loc)
			step_to(O, get_turf(pick(view(7, src))))
		if(prob(25))
			O = new /obj/item/stack/rods(src.loc)
			step_to(O, get_turf(pick(view(7, src))))

		//plasteel
		O = new /obj/item/stack/material/plasteel(src.loc)
		step_to(O, get_turf(pick(view(7, src))))
		if(prob(75))
			O = new /obj/item/stack/material/plasteel(src.loc)
			step_to(O, get_turf(pick(view(7, src))))
		if(prob(50))
			O = new /obj/item/stack/material/plasteel(src.loc)
			step_to(O, get_turf(pick(view(7, src))))
		if(prob(25))
			O = new /obj/item/stack/material/plasteel(src.loc)
			step_to(O, get_turf(pick(view(7, src))))

		//also drop dummy circuit boards deconstructable for research (loot)
		var/obj/item/circuitboard/C

		//spawn 1-4 boards of a random type
		var/spawnees = 0
		var/num_boards = rand(1,4)
		var/list/options = list(1,2,4,8,16,32,64,128,256,512)
		for(var/i=0, i<num_boards, i++)
			var/chosen = pick(options)
			options.Remove(options.Find(chosen))
			spawnees |= chosen

		if(spawnees & 1)
			C = new(src.loc)
			C.name = "Drone CPU motherboard"
			C.origin_tech = list(TECH_DATA = rand(3, 6))

		if(spawnees & 2)
			C = new(src.loc)
			C.name = "Drone neural interface"
			C.origin_tech = list(TECH_BIO = rand(3,6))

		if(spawnees & 4)
			C = new(src.loc)
			C.name = "Drone suspension processor"
			C.origin_tech = list(TECH_MAGNET = rand(3,6))

		if(spawnees & 8)
			C = new(src.loc)
			C.name = "Drone shielding controller"
			C.origin_tech = list(TECH_BLUESPACE = rand(3,6))

		if(spawnees & 16)
			C = new(src.loc)
			C.name = "Drone power capacitor"
			C.origin_tech = list(TECH_POWER = rand(3,6))

		if(spawnees & 32)
			C = new(src.loc)
			C.name = "Drone hull reinforcer"
			C.origin_tech = list(TECH_MATERIAL = rand(3,6))

		if(spawnees & 64)
			C = new(src.loc)
			C.name = "Drone auto-repair system"
			C.origin_tech = list(TECH_ENGINEERING = rand(3,6))

		if(spawnees & 128)
			C = new(src.loc)
			C.name = "Drone phoron overcharge counter"
			C.origin_tech = list(TECH_PHORON = rand(3,6))

		if(spawnees & 256)
			C = new(src.loc)
			C.name = "Drone targetting circuitboard"
			C.origin_tech = list(TECH_COMBAT = rand(3,6))

		if(spawnees & 512)
			C = new(src.loc)
			C.name = "Corrupted drone morality core"
			C.origin_tech = list(TECH_ILLEGAL = rand(3,6))

	..()

/obj/item/projectile/beam/drone
	damage = 15

/obj/item/projectile/beam/pulse/drone
	damage = 10

// A slightly easier drone, for POIs.
// Difference is that it should not be faster than you.
/mob/living/simple_mob/hostile/malf_drone/lesser
	desc = "An automated combat drone with an aged apperance."
	returns_home = TRUE
	move_to_delay = 6
