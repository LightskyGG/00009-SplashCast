local addonName, ns = ...

local CAST_BINDING = "CLICK SplashCastButton:LeftButton"
BINDING_HEADER_SPLASHCAST = "SplashCast"
_G["BINDING_NAME_" .. CAST_BINDING] = "Cast / Reel"

local GetSpellName = ns.GetSpellName
local GetItemInfoInstant = ns.GetItemInfoInstant
local GetItemCount = ns.GetItemCount
local EquipItemByName = ns.EquipItemByName

local fishingSpellName
local lureMacros = {}
for i, lureID in ipairs(ns.Lures) do
	lureMacros[i] = "/use item:" .. lureID .. "\n/use " .. INVSLOT_MAINHAND
end

local castButton = CreateFrame("Button", "SplashCastButton", UIParent, "SecureActionButtonTemplate")
castButton:RegisterForClicks("AnyDown", "AnyUp")
castButton:SetAttribute("type", "spell")
ns.castButton = castButton
ns.castBinding = CAST_BINDING

function ns.GetFishingSpellName()
	if fishingSpellName then return fishingSpellName end
	for _, spellID in ipairs(ns.FishingSpellIDs) do
		fishingSpellName = GetSpellName(spellID)
		if fishingSpellName then break end
	end
	return fishingSpellName
end

local function IsFishingPole(itemID)
	if not itemID then return false end
	local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemID)
	return classID == ns.FishingPole.classID and subclassID == ns.FishingPole.subclassID
end

local function TryApplyLure(button)
	for i, lureID in ipairs(ns.Lures) do
		if GetItemCount(lureID) > 0 then
			button:SetAttribute("type", "macro")
			button:SetAttribute("macrotext", lureMacros[i])
			ns.Print("Applying a lure. Press again to cast.")
			return true
		end
	end
	return false
end

local function EquipFishingPole()
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemID = C_Container.GetContainerItemID(bag, slot)
			if IsFishingPole(itemID) then
				EquipItemByName(itemID)
				ns.Print("Fishing pole equipped. Press again to cast.")
				return true
			end
		end
	end
	return false
end

-- Runs before the secure action. Equipping a pole or applying a lure replaces this press's cast.
castButton:SetScript("PreClick", function(self, _, isDown)
	if InCombatLockdown() or isDown ~= GetCVarBool("ActionButtonUseKeyDown") then return end

	local hasPole = IsFishingPole(GetInventoryItemID("player", INVSLOT_MAINHAND))
	if hasPole and ns.config.lure and not GetWeaponEnchantInfo() and TryApplyLure(self) then return end

	if hasPole or not ns.requiresPole then
		self:SetAttribute("type", "spell")
		self:SetAttribute("spell", ns.GetFishingSpellName())
		return
	end

	self:SetAttribute("type", nil)
	if not EquipFishingPole() then
		ns.Print("No fishing pole found in your bags.")
	end
end)

-- Moves a key saved by the old settings panel into the game's Key Bindings.
function ns.InitKeyBinding()
	local legacyKey = ns.config.key
	if GetBindingKey(CAST_BINDING) then
		ns.config.key = nil
		return
	end
	if not legacyKey then
		ns.Print("Bind a cast key in Key Bindings > AddOns > SplashCast.")
		return
	end
	if InCombatLockdown() then return end
	if SetBinding(legacyKey, CAST_BINDING) then
		SaveBindings(GetCurrentBindingSet())
		ns.config.key = nil
	end
end
