local addonName, ns = ...

ns.GetSpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
ns.GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
ns.GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount
ns.EquipItemByName = C_Item and C_Item.EquipItemByName or EquipItemByName

-- Forever needs a pole in hand to fish; Retail does not.
ns.requiresPole = select(4, GetBuildInfo()) < 100000
