#define MAX_DENT_DECALS 15

/turf/closed/wall
	name = "wall"
	desc = "A huge chunk of iron used to separate rooms."
	icon = 'icons/turf/walls/solid_wall.dmi'
	icon_state = "wall-0"
	base_icon_state = "wall"
	explosion_block = 1

	thermal_conductivity = WALL_HEAT_TRANSFER_COEFFICIENT
	heat_capacity = 62500 //a little over 5 cm thick , 62500 for 1 m by 2.5 m by 0.25 m iron wall. also indicates the temperature at wich the wall will melt (currently only able to melt with H/E pipes)

	baseturfs = /turf/open/floor/plating

	flags_ricochet = RICOCHET_HARD

	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_SHUTTERS_BLASTDOORS, SMOOTH_GROUP_WALLS, SMOOTH_GROUP_AIRLOCK, SMOOTH_GROUP_WINDOW_FULLTILE)

	rcd_memory = RCD_MEMORY_WALL

	color = "#57575c" //To display in mapping softwares

	///lower numbers are harder. Used to determine the probability of a hulk smashing through.
	var/hardness = 40
	var/slicing_duration = 100  //default time taken to slice the wall
	/// Material type of the plating
	var/plating_material = /datum/material/iron
	/// Material type of the reinforcement
	var/reinf_material
	/// Paint color of which the wall has been painted with.
	var/wall_paint
	/// Paint color of which the stripe has been painted with. Will not overlay a stripe if no paint is applied
	var/stripe_paint
	/// Whether this wall is hard to deconstruct, like a reinforced plasteel wall. Dictated by material
	var/hard_decon
	/// Deconstruction state, matters if the wall is hard to deconstruct (hard_decon)
	var/d_state = INTACT
	/// Whether this wall is rusted or not, to apply the rusted overlay
	var/rusted

	var/list/dent_decals

	/// Typecache of all objects that we seek out to apply a neighbor stripe overlay
	var/static/list/neighbor_typecache

/turf/closed/wall/update_name()
	. = ..()
	name = ""
	if(rusted)
		name = "rusted "
	if(reinf_material)
		name += "reinforced wall"
	else
		name += "wall"

/turf/closed/wall/Initialize(mapload)
	. = ..()
	paint_wall(wall_paint) //To ensure varedit wall paint works properly
	if(mapload)
		set_materials(plating_material, reinf_material)
	if(is_station_level(z))
		GLOB.station_turfs += src

/turf/closed/wall/Destroy()
	if(is_station_level(z))
		GLOB.station_turfs -= src
	return ..()

/turf/closed/wall/copyTurf(turf/T)
	. = ..()
	if(istype(., /turf/closed/wall))
		var/turf/closed/wall/pasted_turf = .
		pasted_turf.d_state = d_state
		pasted_turf.set_wall_information(plating_material, reinf_material, wall_paint, stripe_paint)

/// Most of this code is pasted within /obj/structure/falsewall. Be mindful of this
/turf/closed/wall/update_overlays()
	//Updating the unmanaged wall overlays (unmanaged for optimisations)
	overlays.Cut()
	if(stripe_paint)
		var/datum/material/plating_mat_ref = GET_MATERIAL_REF(plating_material)
		var/mutable_appearance/smoothed_stripe = mutable_appearance(plating_mat_ref.wall_stripe_icon, icon_state, appearance_flags = RESET_COLOR)
		smoothed_stripe.color = stripe_paint
		overlays += smoothed_stripe
	var/neighbor_stripe = NONE
	if(!neighbor_typecache)
		neighbor_typecache = typecacheof(list(/obj/machinery/door/airlock, /obj/structure/window/reinforced/fulltile, /obj/structure/window/fulltile, /obj/structure/window/shuttle, /obj/machinery/door/poddoor))
	for(var/cardinal in GLOB.cardinals)
		var/turf/step_turf = get_step(src, cardinal)
		for(var/atom/movable/movable_thing as anything in step_turf)
			if(neighbor_typecache[movable_thing.type])
				neighbor_stripe ^= cardinal
				break
	if(neighbor_stripe)
		var/mutable_appearance/neighb_stripe_appearace = mutable_appearance('icons/turf/walls/neighbor_stripe.dmi', "[neighbor_stripe]", appearance_flags = RESET_COLOR)
		if(stripe_paint)
			neighb_stripe_appearace.color = stripe_paint
		else
			neighb_stripe_appearace.color = color
		overlays += neighb_stripe_appearace

	if(rusted)
		var/mutable_appearance/rust_overlay = mutable_appearance('icons/turf/rust_overlay.dmi', "blobby_rust", appearance_flags = RESET_COLOR)
		overlays += rust_overlay

	if(hard_decon && d_state)
		var/mutable_appearance/decon_overlay = mutable_appearance('icons/turf/walls/decon_states.dmi', "[d_state]", appearance_flags = RESET_COLOR)
		overlays += decon_overlay

	if(dent_decals)
		add_overlay(dent_decals)
	//And letting anything else that may want to render on the wall to work (ie components)
	return ..()

/turf/closed/wall/examine(mob/user)
	. += ..()
	if(wall_paint)
		. += SPAN_NOTICE("It's coated with a <font color=[wall_paint]>layer of paint</font>.")
	if(stripe_paint)
		. += SPAN_NOTICE("It has a <font color=[stripe_paint]>painted stripe</font> around its base.")
	. += deconstruction_hints(user)

/turf/closed/wall/proc/deconstruction_hints(mob/user)
	if(hard_decon)
		switch(d_state)
			if(INTACT)
				return SPAN_NOTICE("The outer <b>grille</b> is fully intact.")
			if(SUPPORT_LINES)
				return SPAN_NOTICE("The outer <i>grille</i> has been cut, and the support lines are <b>screwed</b> securely to the outer cover.")
			if(COVER)
				return SPAN_NOTICE("The support lines have been <i>unscrewed</i>, and the metal cover is <b>welded</b> firmly in place.")
			if(CUT_COVER)
				return SPAN_NOTICE("The metal cover has been <i>sliced through</i>, and is <b>connected loosely</b> to the girder.")
			if(ANCHOR_BOLTS)
				return SPAN_NOTICE("The outer cover has been <i>pried away</i>, and the bolts anchoring the support rods are <b>wrenched</b> in place.")
			if(SUPPORT_RODS)
				return SPAN_NOTICE("The bolts anchoring the support rods have been <i>loosened</i>, but are still <b>welded</b> firmly to the girder.")
			if(SHEATH)
				return SPAN_NOTICE("The support rods have been <i>sliced through</i>, and the outer sheath is <b>connected loosely</b> to the girder.")
	else
		return SPAN_NOTICE("The outer plating is <b>welded</b> firmly in place.")

/turf/closed/wall/attack_tk()
	return

/// Most of this code is pasted within /obj/structure/falsewall. Be mindful of this
/turf/closed/wall/proc/paint_wall(new_paint)
	wall_paint = new_paint
	if(wall_paint)
		color = wall_paint
	else
		/// Reset color to material color
		var/datum/material/plating_mat_ref = GET_MATERIAL_REF(plating_material)
		color = plating_mat_ref.wall_color
	update_appearance()

/// Most of this code is pasted within /obj/structure/falsewall. Be mindful of this
/turf/closed/wall/proc/paint_stripe(new_paint)
	stripe_paint = new_paint
	update_appearance()

/// Most of this code is pasted within /obj/structure/falsewall. Be mindful of this
/turf/closed/wall/proc/set_wall_information(plating_mat, reinf_mat, new_paint, new_stripe_paint)
	wall_paint = new_paint
	if(wall_paint)
		color = wall_paint
	stripe_paint = new_stripe_paint
	set_materials(plating_mat, reinf_mat)

/// Most of this code is pasted within /obj/structure/falsewall. Be mindful of this
/turf/closed/wall/proc/set_materials(plating_mat, reinf_mat)
	var/datum/material/plating_mat_ref
	if(plating_mat)
		plating_mat_ref = GET_MATERIAL_REF(plating_mat)
	var/datum/material/reinf_mat_ref
	if(reinf_mat)
		reinf_mat_ref = GET_MATERIAL_REF(reinf_mat)

	if(reinf_mat_ref && plating_mat_ref.hard_wall_decon)
		hard_decon = TRUE
	else
		hard_decon = null

	if(reinf_mat_ref)
		icon = plating_mat_ref.reinforced_wall_icon
	else
		icon = plating_mat_ref.wall_icon

	if(!wall_paint)
		color = plating_mat_ref.wall_color

	plating_material = plating_mat
	reinf_material = reinf_mat

	update_appearance()

/turf/closed/wall/proc/dismantle_wall(devastated = FALSE, explode = FALSE)
	if(devastated)
		devastate_wall()
	else
		playsound(src, 'sound/items/welder.ogg', 100, TRUE)
		var/newgirder = break_wall()
		if(newgirder) //maybe we don't /want/ a girder!
			transfer_fingerprints_to(newgirder)

	for(var/obj/O in src.contents) //Eject contents!
		if(istype(O, /obj/structure/sign/poster))
			var/obj/structure/sign/poster/P = O
			P.roll_and_drop(src)

	ScrapeAway()

/turf/closed/wall/proc/break_wall(drop_mats = TRUE)
	if(drop_mats)
		drop_materials_used()
	return new /obj/structure/girder(src, reinf_material, wall_paint, stripe_paint)

/turf/closed/wall/proc/devastate_wall()
	drop_materials_used(TRUE)
	new /obj/item/stack/sheet/iron(src)

/turf/closed/wall/proc/drop_materials_used(drop_reinf = FALSE)
	var/datum/material/plating_mat_ref = GET_MATERIAL_REF(plating_material)
	new plating_mat_ref.sheet_type(src, 2)
	if(drop_reinf && reinf_material)
		var/datum/material/reinf_mat_ref = GET_MATERIAL_REF(reinf_material)
		new reinf_mat_ref.sheet_type(src, 2)

/turf/proc/create_rubble(adjacent = FALSE)
	var/rubble_type = prob(50) ? /obj/structure/rubble/medium : /obj/structure/rubble/large
	var/turf/destination = src
	if(adjacent)
		ImmediateCalculateAdjacentTurfs()
		var/list/adjacent_turfs = GetAtmosAdjacentTurfs()
		var/list/free_turfs = list()
		for(var/i in adjacent_turfs)
			var/turf/Turf = i
			if(!Turf.is_blocked_turf(TRUE))
				free_turfs += Turf
		if(length(free_turfs))
			destination = pick(free_turfs)
		else if(length(adjacent_turfs))
			destination = pick(adjacent_turfs)
	new rubble_type(destination)

/turf/closed/wall/ex_act(severity, target)
	if(target == src)
		dismantle_wall(1,1)
		return

	var/make_rubble = prob(50) ? TRUE : FALSE
	switch(severity)
		if(EXPLODE_DEVASTATE)
			//SN src = null
			var/turf/NT = ScrapeAway()
			NT.contents_explosion(severity, target)
			return
		if(EXPLODE_HEAVY)
			if(prob(50))
				dismantle_wall(TRUE, TRUE)
				if(make_rubble)
					create_rubble()
			else
				dismantle_wall(FALSE, TRUE)
				if(make_rubble)
					create_rubble(TRUE)
		if(EXPLODE_LIGHT)
			if (prob(hardness))
				dismantle_wall(0,1)
				if(make_rubble)
					create_rubble(TRUE)
	if(!density)
		..()


/turf/closed/wall/blob_act(obj/structure/blob/B)
	if(prob(50))
		dismantle_wall()
	else
		add_dent(WALL_DENT_HIT)

/turf/closed/wall/attack_paw(mob/living/user, list/modifiers)
	user.changeNext_move(CLICK_CD_MELEE)
	return attack_hand(user, modifiers)


/turf/closed/wall/attack_animal(mob/living/simple_animal/user, list/modifiers)
	if(hard_decon)
		user.changeNext_move(CLICK_CD_MELEE)
		user.do_attack_animation(src)
		if(!user.environment_smash)
			return
		if(user.environment_smash & ENVIRONMENT_SMASH_RWALLS)
			dismantle_wall(1)
			playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
		else
			playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
			to_chat(user, SPAN_WARNING("This wall is far too strong for you to destroy."))
	else
		user.changeNext_move(CLICK_CD_MELEE)
		user.do_attack_animation(src)
		if((user.environment_smash & ENVIRONMENT_SMASH_WALLS) || (user.environment_smash & ENVIRONMENT_SMASH_RWALLS))
			playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
			dismantle_wall(1)
			return

/turf/closed/wall/attack_hulk(mob/living/carbon/user)
	..()
	var/obj/item/bodypart/arm = user.hand_bodyparts[user.active_hand_index]
	if(!arm)
		return
	if(arm.bodypart_disabled)
		return
	if(prob(hardness))
		playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
		user.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ), forced = "hulk")
		hulk_recoil(arm, user)
		dismantle_wall(1)

	else
		playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		add_dent(WALL_DENT_HIT)
		user.visible_message(SPAN_DANGER("[user] smashes \the [src]!"), \
					SPAN_DANGER("You smash \the [src]!"), \
					SPAN_HEAR("You hear a booming smash!"))
	return TRUE

/**
 *Deals damage back to the hulk's arm.
 *
 *When a hulk manages to break a wall using their hulk smash, this deals back damage to the arm used.
 *This is in its own proc just to be easily overridden by other wall types. Default allows for three
 *smashed walls per arm. Also, we use CANT_WOUND here because wounds are random. Wounds are applied
 *by hulk code based on arm damage and checked when we call break_an_arm().
 *Arguments:
 **arg1 is the arm to deal damage to.
 **arg2 is the hulk
 */
/turf/closed/wall/proc/hulk_recoil(obj/item/bodypart/arm, mob/living/carbon/human/hulkman, damage = 20)
	arm.receive_damage(brute = damage, blocked = 0, wound_bonus = CANT_WOUND)
	var/datum/mutation/human/hulk/smasher = locate(/datum/mutation/human/hulk) in hulkman.dna.mutations
	if(!smasher || !damage) //sanity check but also snow and wood walls deal no recoil damage, so no arm breaky
		return
	smasher.break_an_arm(arm)

/turf/closed/wall/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	user.changeNext_move(CLICK_CD_MELEE)
	to_chat(user, SPAN_NOTICE("You push the wall but nothing happens!"))
	playsound(src, 'sound/weapons/genhit.ogg', 25, TRUE)
	add_fingerprint(user)

/turf/closed/wall/attackby(obj/item/W, mob/user, params)
	user.changeNext_move(CLICK_CD_MELEE)
	if (!ISADVANCEDTOOLUSER(user))
		to_chat(user, SPAN_WARNING("You don't have the dexterity to do this!"))
		return

	//get the user's location
	if(!isturf(user.loc))
		return //can't do this stuff whilst inside objects and such

	add_fingerprint(user)

	var/turf/T = user.loc //get user's location for delay checks

	//the istype cascade has been spread among various procs for easy overriding
	if(try_clean(W, user, T) || try_wallmount(W, user, T) || try_decon(W, user, T))
		return

	return ..()

/turf/closed/wall/proc/try_clean(obj/item/W, mob/living/user, turf/T)
	if((user.combat_mode) || !LAZYLEN(dent_decals))
		return FALSE

	if(W.tool_behaviour == TOOL_WELDER)
		if(!W.tool_start_check(user, amount=0))
			return FALSE

		to_chat(user, SPAN_NOTICE("You begin fixing dents on the wall..."))
		if(W.use_tool(src, user, 0, volume=100))
			if(iswallturf(src) && LAZYLEN(dent_decals))
				to_chat(user, SPAN_NOTICE("You fix some dents on the wall."))
				cut_overlay(dent_decals)
				dent_decals.Cut()
			return TRUE

	return FALSE

/turf/closed/wall/proc/try_wallmount(obj/item/W, mob/user, turf/T)
	//check for wall mounted frames
	if(istype(W, /obj/item/wallframe))
		var/obj/item/wallframe/F = W
		if(F.try_build(src, user))
			F.attach(src, user)
		return TRUE
	//Poster stuff
	else if(istype(W, /obj/item/poster))
		place_poster(W,user)
		return TRUE

	return FALSE

/turf/closed/wall/proc/try_decon(obj/item/I, mob/user, turf/T)
	if(hard_decon)
		switch(d_state)
			if(INTACT)
				if(I.tool_behaviour == TOOL_WIRECUTTER)
					I.play_tool_sound(src, 100)
					d_state = SUPPORT_LINES
					update_appearance()
					to_chat(user, SPAN_NOTICE("You cut the outer grille."))
					return TRUE
	
			if(SUPPORT_LINES)
				if(I.tool_behaviour == TOOL_SCREWDRIVER)
					to_chat(user, SPAN_NOTICE("You begin unsecuring the support lines..."))
					if(I.use_tool(src, user, 40, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != SUPPORT_LINES)
							return TRUE
						d_state = COVER
						update_appearance()
						to_chat(user, SPAN_NOTICE("You unsecure the support lines."))
					return TRUE
	
				else if(I.tool_behaviour == TOOL_WIRECUTTER)
					I.play_tool_sound(src, 100)
					d_state = INTACT
					update_appearance()
					to_chat(user, SPAN_NOTICE("You repair the outer grille."))
					return TRUE
	
			if(COVER)
				if(I.tool_behaviour == TOOL_WELDER)
					if(!I.tool_start_check(user, amount=0))
						return
					to_chat(user, SPAN_NOTICE("You begin slicing through the metal cover..."))
					if(I.use_tool(src, user, 60, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != COVER)
							return TRUE
						d_state = CUT_COVER
						update_appearance()
						to_chat(user, SPAN_NOTICE("You press firmly on the cover, dislodging it."))
					return TRUE
	
				if(I.tool_behaviour == TOOL_SCREWDRIVER)
					to_chat(user, SPAN_NOTICE("You begin securing the support lines..."))
					if(I.use_tool(src, user, 40, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != COVER)
							return TRUE
						d_state = SUPPORT_LINES
						update_appearance()
						to_chat(user, SPAN_NOTICE("The support lines have been secured."))
					return TRUE
	
			if(CUT_COVER)
				if(I.tool_behaviour == TOOL_CROWBAR)
					to_chat(user, SPAN_NOTICE("You struggle to pry off the cover..."))
					if(I.use_tool(src, user, 100, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != CUT_COVER)
							return TRUE
						d_state = ANCHOR_BOLTS
						update_appearance()
						to_chat(user, SPAN_NOTICE("You pry off the cover."))
					return TRUE
	
				if(I.tool_behaviour == TOOL_WELDER)
					if(!I.tool_start_check(user, amount=0))
						return
					to_chat(user, SPAN_NOTICE("You begin welding the metal cover back to the frame..."))
					if(I.use_tool(src, user, 60, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != CUT_COVER)
							return TRUE
						d_state = COVER
						update_appearance()
						to_chat(user, SPAN_NOTICE("The metal cover has been welded securely to the frame."))
					return TRUE
	
			if(ANCHOR_BOLTS)
				if(I.tool_behaviour == TOOL_WRENCH)
					to_chat(user, SPAN_NOTICE("You start loosening the anchoring bolts which secure the support rods to their frame..."))
					if(I.use_tool(src, user, 40, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != ANCHOR_BOLTS)
							return TRUE
						d_state = SUPPORT_RODS
						update_appearance()
						to_chat(user, SPAN_NOTICE("You remove the bolts anchoring the support rods."))
					return TRUE
	
				if(I.tool_behaviour == TOOL_CROWBAR)
					to_chat(user, SPAN_NOTICE("You start to pry the cover back into place..."))
					if(I.use_tool(src, user, 20, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != ANCHOR_BOLTS)
							return TRUE
						d_state = CUT_COVER
						update_appearance()
						to_chat(user, SPAN_NOTICE("The metal cover has been pried back into place."))
					return TRUE
	
			if(SUPPORT_RODS)
				if(I.tool_behaviour == TOOL_WELDER)
					if(!I.tool_start_check(user, amount=0))
						return
					to_chat(user, SPAN_NOTICE("You begin slicing through the support rods..."))
					if(I.use_tool(src, user, 100, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != SUPPORT_RODS)
							return TRUE
						d_state = SHEATH
						update_appearance()
						to_chat(user, SPAN_NOTICE("You slice through the support rods."))
					return TRUE
	
				if(I.tool_behaviour == TOOL_WRENCH)
					to_chat(user, SPAN_NOTICE("You start tightening the bolts which secure the support rods to their frame..."))
					I.play_tool_sound(src, 100)
					if(I.use_tool(src, user, 40))
						if(!istype(src, /turf/closed/wall) || d_state != SUPPORT_RODS)
							return TRUE
						d_state = ANCHOR_BOLTS
						update_appearance()
						to_chat(user, SPAN_NOTICE("You tighten the bolts anchoring the support rods."))
					return TRUE

			if(SHEATH)
				if(I.tool_behaviour == TOOL_CROWBAR)
					to_chat(user, SPAN_NOTICE("You struggle to pry off the outer sheath..."))
					if(I.use_tool(src, user, 100, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != SHEATH)
							return TRUE
						to_chat(user, SPAN_NOTICE("You pry off the outer sheath."))
						dismantle_wall()
					return TRUE
	
				if(I.tool_behaviour == TOOL_WELDER)
					if(!I.tool_start_check(user, amount=0))
						return
					to_chat(user, SPAN_NOTICE("You begin welding the support rods back together..."))
					if(I.use_tool(src, user, 100, volume=100))
						if(!istype(src, /turf/closed/wall) || d_state != SHEATH)
							return TRUE
						d_state = SUPPORT_RODS
						update_appearance()
						to_chat(user, SPAN_NOTICE("You weld the support rods back together."))
					return TRUE
	else
		if(I.tool_behaviour == TOOL_WELDER)
			if(!I.tool_start_check(user, amount=0))
				return FALSE
	
			to_chat(user, SPAN_NOTICE("You begin slicing through the outer plating..."))
			if(I.use_tool(src, user, slicing_duration, volume=100))
				if(iswallturf(src))
					to_chat(user, SPAN_NOTICE("You remove the outer plating."))
					dismantle_wall()
				return TRUE

	return FALSE

/turf/closed/wall/singularity_pull(S, current_size)
	..()
	wall_singularity_pull(current_size)

/turf/closed/wall/proc/wall_singularity_pull(current_size)
	if(hard_decon)
		if(current_size >= STAGE_FIVE)
			if(prob(30))
				dismantle_wall()
	else
		if(current_size >= STAGE_FIVE)
			if(prob(50))
				dismantle_wall()
			return
		if(current_size == STAGE_FOUR)
			if(prob(30))
				dismantle_wall()

/turf/closed/wall/narsie_act(force, ignore_mobs, probability = 20)
	. = ..()
	if(.)
		ChangeTurf(/turf/closed/wall/mineral/cult)

/turf/closed/wall/get_dumping_location(obj/item/storage/source, mob/user)
	return null

/turf/closed/wall/acid_act(acidpwr, acid_volume)
	if(explosion_block >= 2)
		acidpwr = min(acidpwr, 50) //we reduce the power so strong walls never get melted.
	return ..()

/turf/closed/wall/acid_melt()
	dismantle_wall(1)

/turf/closed/wall/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(hard_decon && !the_rcd.canRturf)
		return
	switch(the_rcd.mode)
		if(RCD_DECONSTRUCT)
			return list("mode" = RCD_DECONSTRUCT, "delay" = 40, "cost" = 26)
	return FALSE

/turf/closed/wall/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	if(hard_decon && !the_rcd.canRturf)
		return
	switch(passed_mode)
		if(RCD_DECONSTRUCT)
			to_chat(user, SPAN_NOTICE("You deconstruct the wall."))
			ScrapeAway()
			return TRUE
	return FALSE

/turf/closed/wall/proc/add_dent(denttype, x=rand(-8, 8), y=rand(-8, 8))
	if(LAZYLEN(dent_decals) >= MAX_DENT_DECALS)
		return

	var/mutable_appearance/decal = mutable_appearance('icons/effects/effects.dmi', "", BULLET_HOLE_LAYER)
	switch(denttype)
		if(WALL_DENT_SHOT)
			decal.icon_state = "bullet_hole"
		if(WALL_DENT_HIT)
			decal.icon_state = "impact[rand(1, 3)]"

	decal.pixel_x = x
	decal.pixel_y = y

	if(LAZYLEN(dent_decals))
		cut_overlay(dent_decals)
		dent_decals += decal
	else
		dent_decals = list(decal)

	add_overlay(dent_decals)

/turf/closed/wall/rust_heretic_act()
	if(rusted)
		return
	if(hard_decon && prob(50))
		return
	if(prob(70))
		new /obj/effect/temp_visual/glowing_rune(src)
	rusted = TRUE
	update_appearance()

#undef MAX_DENT_DECALS
