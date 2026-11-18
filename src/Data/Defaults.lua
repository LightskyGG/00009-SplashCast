local addonName, ns = ...

ns.Defaults = {
	volume = true,
	lure = true,
}

-- Soft-target interact is how the Interact key reaches the bobber; it is widened only while fishing.
ns.SoftTargetCVars = {
	softTargetInteract = "3",
	softTargetInteractRange = "45",
}

ns.VolumeCVars = { "Sound_MasterVolume", "Sound_SFXVolume" }

-- Cheapest first. The first one found in your bags is used.
ns.Lures = { 6529, 6530, 6811, 7307, 6532, 6533, 34861 }

ns.FishingSpellIDs = { 131474, 7620 }

ns.FishingPole = {
	classID = 2,
	subclassID = 20,
}
