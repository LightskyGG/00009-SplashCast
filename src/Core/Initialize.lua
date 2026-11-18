local addonName, ns = ...

local function InitializeSavedVariables()
	SPLASHCAST_CONFIG = SPLASHCAST_CONFIG or {}
	for key, value in pairs(ns.Defaults) do
		if SPLASHCAST_CONFIG[key] == nil then
			SPLASHCAST_CONFIG[key] = value
		end
	end

	SPLASHCAST_DATA = SPLASHCAST_DATA or {}
	-- Releases before 2026.11.17 stored saved CVars under "r".
	if SPLASHCAST_DATA.r then
		SPLASHCAST_DATA.savedCVars, SPLASHCAST_DATA.r = SPLASHCAST_DATA.r, nil
	end

	ns.config = SPLASHCAST_CONFIG
	ns.data = SPLASHCAST_DATA
end

function ns.Print(message)
	print("|cff33ccffSplashCast:|r " .. message)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent(event)
		ns.InitKeyBinding()
		return
	end
	if loadedAddon ~= addonName then return end
	self:UnregisterEvent(event)

	InitializeSavedVariables()
	ns.InitSettings()
	ns.InitFishing()
end)
