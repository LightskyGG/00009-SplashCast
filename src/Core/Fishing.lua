local addonName, ns = ...

local GetSpellName = ns.GetSpellName

local isFishing = false
local needsBindingUpdate = false

local function OverrideCastKeys(...)
	for i = 1, select("#", ...) do
		SetOverrideBinding(ns.castButton, true, (select(i, ...)), "INTERACTTARGET")
	end
end

-- The cast key becomes Interact while the line is out. Bindings can't change in combat.
local function UpdateBindings()
	if InCombatLockdown() then
		needsBindingUpdate = true
		return
	end
	needsBindingUpdate = false
	ClearOverrideBindings(ns.castButton)
	if isFishing then
		OverrideCastKeys(GetBindingKey(ns.castBinding))
	end
end

-- Original values persist in SavedVariables so a crash or reload mid-cast can't leave them changed.
local function RestoreCVars()
	local savedCVars = ns.data.savedCVars
	if not savedCVars then return end
	ns.data.savedCVars = nil
	for name, value in pairs(savedCVars) do
		SetCVar(name, value)
	end
end

local function BoostCVars()
	local savedCVars = {}
	for name, value in pairs(ns.SoftTargetCVars) do
		local currentValue = GetCVar(name)
		if currentValue and currentValue ~= value then
			savedCVars[name] = currentValue
			SetCVar(name, value)
		end
	end
	if ns.config.volume then
		for _, name in ipairs(ns.VolumeCVars) do
			local currentValue = GetCVar(name)
			if currentValue and (tonumber(currentValue) or 1) < 1 then
				savedCVars[name] = currentValue
				SetCVar(name, "1")
			end
		end
	end
	ns.data.savedCVars = next(savedCVars) and savedCVars or nil
end

local function OnChannelStart(spellID)
	if isFishing or InCombatLockdown() or not spellID then return end
	local fishingSpellName = ns.GetFishingSpellName()
	if fishingSpellName and GetSpellName(spellID) == fishingSpellName then
		isFishing = true
		BoostCVars()
		UpdateBindings()
	end
end

local function OnChannelStop()
	if not isFishing then return end
	isFishing = false
	RestoreCVars()
	UpdateBindings()
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, _, _, spellID)
	if event == "UNIT_SPELLCAST_CHANNEL_START" then
		OnChannelStart(spellID)
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		OnChannelStop()
	elseif needsBindingUpdate then
		UpdateBindings()
	end
end)

function ns.InitFishing()
	RestoreCVars()
	eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
	eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
	eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end
