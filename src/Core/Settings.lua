local addonName, ns = ...

local settingsCategory

local function AddCheckbox(category, key, variable, label, tooltip)
	local setting = Settings.RegisterAddOnSetting(
		category,
		variable,
		key,
		ns.config,
		Settings.VarType.Boolean,
		label,
		ns.Defaults[key]
	)
	Settings.CreateCheckbox(category, setting, tooltip)
end

function ns.InitSettings()
	local category = Settings.RegisterVerticalLayoutCategory(addonName)
	AddCheckbox(category, "volume", "SPLASHCAST_VOLUME", "Boost Volume", "Raise master and effects volume to 100% while fishing.")
	AddCheckbox(category, "lure", "SPLASHCAST_LURE", "Auto Lure", "Apply a lure when your pole has none.")
	Settings.RegisterAddOnCategory(category)
	settingsCategory = category
end

local function OpenSettings()
	if settingsCategory then
		Settings.OpenToCategory(settingsCategory:GetID())
	end
end

function SplashCast_AddonCompartmentCallback()
	OpenSettings()
end

SLASH_SPLASHCAST1 = "/splashcast"
SlashCmdList.SPLASHCAST = OpenSettings
