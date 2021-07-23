/datum/species/teshari
	name = "Teshari"
	id = "teshari"
	flavor_text = "Warning: WIP Race. May not work correctly. ::: A small feathered species, often compared to both birds, and raptors."
	default_color = "0F0"
	liked_food = GROSS | MEAT | FRIED
	say_mod = "chirps"
	species_language_holder = /datum/language_holder/teshari
	species_traits = list(MUTCOLORS,EYECOLOR,LIPS,HAS_FLESH,HAS_BONE,NO_UNDERWEAR)
	inherent_traits = list(TRAIT_RESISTCOLD, TRAIT_ADVANCEDTOOLUSER)
	attack_verb = "slash"
	attack_sound = 'sound/weapons/slash.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN | RACE_SWAP | SLIME_EXTRACT
	limbs_icon = 'icons/mob/species/teshari_parts_greyscale.dmi'
	eyes_icon = 'icons/mob/species/teshari_eyes.dmi'
	default_mutant_bodyparts = list("tail" = "Teshari Tail")
	bodytype = BODYTYPE_TESHARI

/datum/species/teshari/get_random_features()
	var/list/colormap = MANDATORY_FEATURE_LIST
	var/primary_color
	var/secondary_color
	var/tertiary_color

	var/random = rand(1, 5)

	switch(random)
		if(1)
			primary_color = "BBAA88"
			secondary_color = "AAAA99"
			tertiary_color = "EEEEDD"
		else
			primary_color = "777766"
			secondary_color = "888877"
			tertiary_color = "EEEEDD"

	colormap["mcolor"] = primary_color
	colormap["mcolor2"] = secondary_color
	colormap["mcolor3"] = tertiary_color

	return colormap

/datum/language_holder/teshari
	understood_languages = list(/datum/language/common = list(LANGUAGE_ATOM),
								/datum/language/vox = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/common = list(LANGUAGE_ATOM),
							/datum/language/vox = list(LANGUAGE_ATOM))

/mob/living/carbon/human/species/teshari
	race = /datum/species/teshari

/datum/sprite_accessory/tails/teshari
	icon = 'icons/mob/sprite_accessory/teshari_tails.dmi'
	name = "Teshari Tail"
	icon_state = "teshari"
	recommended_species = list("teshari")
