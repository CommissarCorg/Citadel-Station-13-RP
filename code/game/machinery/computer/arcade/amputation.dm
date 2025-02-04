// ** AMPUTATION ** //

/obj/machinery/computer/arcade/amputation
	name = "Mediborg's Amputation Adventure"
	desc = "A picture of a blood-soaked medical cyborg flashes on the screen. The mediborg has a speech bubble that says, \"Put your hand in the machine if you aren't a <b>coward!</b>\""
	icon_state = "arcade1"
	icon_screen = null
	circuit = /obj/item/circuitboard/arcade/amputation

/obj/machinery/computer/arcade/amputation/attack_hand(mob/user, list/modifiers)
	if(!iscarbon(user))
		return
	var/mob/living/carbon/c_user = user
	if(!c_user.get_organ(BP_L_ARM) && !c_user.get_organ(BP_R_ARM))
		return
	to_chat(c_user, SPAN_WARNING("You move your hand towards the machine, and begin to hesitate as a bloodied guillotine emerges from inside of it..."))
	if(do_after(c_user, 50, target = src))
		to_chat(c_user, SPAN_USERDANGER("The guillotine drops on your arm, and the machine sucks it in!"))
		playsound(loc, 'sound/weapons/slice.ogg', 25, TRUE, -1)
		var/which_hand = BP_L_ARM
		if(!(c_user.get_active_hand() % 2))
			which_hand = BP_R_ARM
		var/obj/item/organ/external/chopchop = c_user.get_organ(which_hand)
		chopchop.droplimb()
		qdel(chopchop)
		//user.mind?.adjust_experience(/datum/skill/gaming, 100)
		playsound(loc, 'sound/arcade/win.ogg', 50, TRUE)
		prizevend(user, rand(3,5))
	else
		to_chat(c_user, SPAN_NOTICE("You (wisely) decide against putting your hand in the machine."))

/obj/machinery/computer/arcade/amputation/festive //dispenses wrapped gifts instead of arcade prizes, also known as the ancap christmas tree
	name = "Mediborg's Festive Amputation Adventure"
	desc = "A picture of a blood-soaked medical cyborg wearing a Santa hat flashes on the screen. The mediborg has a speech bubble that says, \"Put your hand in the machine if you aren't a <b>coward!</b>\""
	prize_override = list(/obj/item/a_gift/anything = 1)
