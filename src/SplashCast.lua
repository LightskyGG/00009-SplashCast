-- Soft-target interact is how the game's Interact key reaches the bobber; widen it only while fishing.
local SOFT = { softTargetInteract = "3", softTargetInteractRange = "45" }
local MOD = { LSHIFT = 1, RSHIFT = 1, LCTRL = 1, RCTRL = 1, LALT = 1, RALT = 1, LMETA = 1, RMETA = 1 }
local VOL = { "Sound_MasterVolume", "Sound_SFXVolume" }
local GetName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
local Instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
local Equip = C_Item and C_Item.EquipItemByName or EquipItemByName
local Count = C_Item and C_Item.GetItemCount or GetItemCount

-- Lures, cheapest first. Add any lure item ID here; the first one found in your bags is used.
local LURES = { 6529, 6530, 6811, 7307, 6532, 6533, 34861 }
local USE = {}
for i = 1, #LURES do USE[i] = "/use item:" .. LURES[i] .. "\n/use 16" end

local cfg, data, fish, active, pending, category

-- Forever (interface 16xxx) needs a pole in hand to fish; Retail (12xxxx) doesn't.
local NEED_POLE = (select(4, GetBuildInfo())) < 100000

local btn = CreateFrame("Button", "SplashCastButton", UIParent, "SecureActionButtonTemplate")
btn:RegisterForClicks("AnyDown", "AnyUp")
btn:SetAttribute("type", "spell")

local function IsPole(id)
	return id and select(7, Instant(id)) == 20 -- Weapon subclass: Fishing Poles
end

local function Say(msg)
	print("|cff33ccffSplashCast:|r " .. msg)
end

-- Runs before the secure cast. No pole in hand: equip one. No lure on it: apply one.
-- Either way this press doesn't cast; the player presses again.
btn:SetScript("PreClick", function(self, _, down)
	if InCombatLockdown() or down ~= GetCVarBool("ActionButtonUseKeyDown") then return end
	local pole = IsPole(GetInventoryItemID("player", 16))
	if pole and cfg.lure and not GetWeaponEnchantInfo() then
		for i = 1, #LURES do
			if Count(LURES[i]) > 0 then
				self:SetAttribute("type", "macro")
				self:SetAttribute("macrotext", USE[i])
				return Say("Applying a lure. Press the key again to cast.")
			end
		end
	end
	if pole or not NEED_POLE then
		self:SetAttribute("type", "spell")
		return
	end
	self:SetAttribute("type", nil)
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local id = C_Container.GetContainerItemID(bag, slot)
			if IsPole(id) then
				Equip(id)
				return Say("Fishing pole equipped. Press the key again to cast.")
			end
		end
	end
	Say("No fishing pole found in your bags.")
end)

local function FishName()
	fish = fish or GetName(131474) or GetName(7620)
	return fish
end

-- Cast key while idle, Interact while the line is out. Secure bindings can't change in combat.
local function Bind()
	if InCombatLockdown() then pending = true return end
	pending = nil
	ClearOverrideBindings(btn)
	local key = cfg.key
	if not key then return end
	if active then
		SetOverrideBinding(btn, true, key, "INTERACTTARGET")
	else
		btn:SetAttribute("spell", FishName())
		SetOverrideBindingClick(btn, true, key, "SplashCastButton", "LeftButton")
	end
end

-- Original CVar values are kept in SavedVariables so a crash/reload mid-cast can't leave them changed.
local function Restore()
	local r = data.r
	if r then
		data.r = nil
		for k, v in pairs(r) do SetCVar(k, v) end
	end
end

local function Boost()
	local r = {}
	for k, v in pairs(SOFT) do
		local cur = GetCVar(k)
		if cur and cur ~= v then r[k] = cur SetCVar(k, v) end
	end
	if cfg.volume then
		for i = 1, #VOL do
			local k = VOL[i]
			local cur = GetCVar(k)
			if cur and (tonumber(cur) or 1) < 1 then r[k] = cur SetCVar(k, "1") end
		end
	end
	data.r = next(r) and r or nil
end

---------------------------------------------------------------- settings
local function Chord(key)
	return (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
end

local function BuildPanel(panel)
	panel:SetScript("OnShow", nil)

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("SplashCast")

	local lbl = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lbl:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24)
	lbl:SetText("Cast / reel key")

	local keyBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	keyBtn:SetSize(160, 24)
	keyBtn:SetPoint("LEFT", lbl, "RIGHT", 16, 0)

	local clear = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	clear:SetSize(70, 24)
	clear:SetPoint("LEFT", keyBtn, "RIGHT", 6, 0)
	clear:SetText("Clear")

	local function Stop()
		keyBtn:EnableKeyboard(false)
		keyBtn:SetText(cfg.key or "Not bound")
	end
	local function SetKey(k)
		cfg.key = k
		Bind()
		Stop()
	end

	keyBtn:SetText(cfg.key or "Not bound")
	keyBtn:SetScript("OnClick", function(s)
		s:EnableKeyboard(true)
		s:SetText("Press a key...")
	end)
	keyBtn:SetScript("OnKeyDown", function(_, key)
		if MOD[key] then return end
		if key == "ESCAPE" then Stop() else SetKey(Chord(key)) end
	end)
	keyBtn:SetScript("OnMouseDown", function(s, b)
		if s:IsKeyboardEnabled() and b ~= "LeftButton" and b ~= "RightButton" then
			SetKey(Chord(b == "MiddleButton" and "BUTTON3" or b:upper()))
		end
	end)
	clear:SetScript("OnClick", function() SetKey(nil) end)
	panel:SetScript("OnHide", Stop)

	local function Check(anchor, y, field, text)
		local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
		cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchor == lbl and -4 or 0, y)
		cb:SetChecked(cfg[field])
		cb:SetScript("OnClick", function(s) cfg[field] = s:GetChecked() and true or false end)
		local l = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		l:SetPoint("LEFT", cb, "RIGHT", 4, 0)
		l:SetText(text)
		return cb
	end
	local vol = Check(lbl, -20, "volume", "Raise master and effects volume to 100% while the fishing cast is active")
	Check(vol, -4, "lure", "Apply a lure to the fishing pole when none is active")
end

local function Open()
	if category then Settings.OpenToCategory(category:GetID()) end
end

function SplashCast_AddonCompartmentCallback() Open() end
SLASH_SPLASHCAST1 = "/splashcast"
SlashCmdList.SPLASHCAST = Open

---------------------------------------------------------------- events
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, _, _, spellID)
	if event == "UNIT_SPELLCAST_CHANNEL_START" then
		if InCombatLockdown() or not spellID then return end
		local n = FishName()
		if n and GetName(spellID) == n then
			active = true
			Boost()
			Bind()
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if active then
			active = nil
			Restore()
			Bind()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pending then Bind() end
	else -- PLAYER_LOGIN
		self:UnregisterEvent("PLAYER_LOGIN")
		SPLASHCAST_CONFIG = SPLASHCAST_CONFIG or { volume = true }
		SPLASHCAST_DATA = SPLASHCAST_DATA or {}
		cfg, data = SPLASHCAST_CONFIG, SPLASHCAST_DATA
		if cfg.lure == nil then cfg.lure = true end
		Restore()
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		Bind()

		local panel = CreateFrame("Frame")
		panel:SetScript("OnShow", BuildPanel)
		category = Settings.RegisterCanvasLayoutCategory(panel, "SplashCast")
		Settings.RegisterAddOnCategory(category)
	end
end)