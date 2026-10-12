-- Spell lists are account-wide per class; macros are per-character.

local PREFIX = "MO "
local COND = {
	help = "[@mouseover,help,nodead][]",
	harm = "[@mouseover,harm,nodead][]",
}
local KIND = { add = "help", harm = "harm" }

local db, class
local pending = false

local function say(msg)
	print("|cff33ccffMM|r " .. msg)
end

local function macroName(spell)
	return (PREFIX .. spell):sub(1, 16)
end

local function macroBody(spell, kind)
	return ("#showtooltip %s\n/cast %s %s"):format(spell, COND[kind], spell)
end

local function find(spell)
	local lower = spell:lower()
	for i, e in ipairs(db.spells[class]) do
		if e.name:lower() == lower then
			return i, e
		end
	end
end

-- Truncated macro names can collide; returns the listed spell already using spell's name.
local function nameClash(spell)
	local name = macroName(spell)
	for _, e in ipairs(db.spells[class]) do
		if macroName(e.name) == name then
			return e.name
		end
	end
end

-- Character macro index for name, 0 if none, nil if an account macro holds the name.
local function macroIndex(name)
	local idx = GetMacroIndexByName(name)
	if idx > 0 and idx <= (MAX_ACCOUNT_MACROS or 120) then
		return nil
	end
	return idx
end

local function sync()
	if InCombatLockdown() then
		pending = true
		return false
	end
	pending = false

	local made, updated = 0, 0
	local _, numChar = GetNumMacros()
	local maxChar = MAX_CHARACTER_MACROS or 18
	for _, e in ipairs(db.spells[class]) do
		local name, body = macroName(e.name), macroBody(e.name, e.kind)
		local idx = macroIndex(name)
		if not idx then
			say("account macro already named " .. name .. ", skipped: " .. e.name)
		elseif idx == 0 then
			if numChar >= maxChar then
				say("character macro slots full, skipped: " .. e.name)
			else
				CreateMacro(name, "INV_Misc_QuestionMark", body, true)
				numChar = numChar + 1
				made = made + 1
			end
		elseif GetMacroBody(idx) ~= body then
			EditMacro(idx, name, nil, body)
			updated = updated + 1
		end
	end

	if made + updated > 0 then
		say(("macros synced: %d created, %d updated"):format(made, updated))
	end
	return true
end

local function parseSpell(arg)
	local id = arg:match("|Hspell:(%d+)")
	if id then
		return C_Spell.GetSpellName(tonumber(id))
	end
	arg = strtrim(arg)
	return arg ~= "" and arg or nil
end

local function add(cmd, list)
	local kind = KIND[cmd]
	local parsed, added = false, 0
	for piece in list:gmatch("[^,]+") do
		local spell = parseSpell(piece)
		if spell then
			parsed = true
			local _, existing = find(spell)
			local clash = not existing and nameClash(spell)
			if clash then
				say(spell .. ": macro name same as " .. clash .. " after truncation, skipped")
			else
				if existing then
					existing.kind = kind
				else
					table.insert(db.spells[class], { name = spell, kind = kind })
				end
				if not C_Spell.GetSpellInfo(spell) then
					say(spell .. ": not in your spellbook (other spec?), added anyway")
				end
				added = added + 1
			end
		end
	end
	if not parsed then
		say("usage: /mm " .. cmd .. " Spell One, Spell Two")
		return
	end
	if added == 0 then
		return
	end
	if not sync() then
		say("in combat, macros sync when it ends")
	end
end

local function remove(list)
	if InCombatLockdown() then
		say("can't delete macros in combat")
		return
	end
	for piece in list:gmatch("[^,]+") do
		local spell = parseSpell(piece)
		local i = spell and find(spell)
		if i then
			local e = table.remove(db.spells[class], i)
			local idx = macroIndex(macroName(e.name))
			if idx and idx > 0 then
				DeleteMacro(idx)
			end
			say("removed " .. e.name)
		else
			say("not in list: " .. (spell or piece))
		end
	end
end

local function list()
	local spells = db.spells[class]
	if #spells == 0 then
		say("empty. /mm add Spell One, Spell Two")
		return
	end
	for _, e in ipairs(spells) do
		say(("%s (%s)"):format(e.name, e.kind))
	end
end

local function help()
	say("/mm add Spell, Spell   friendly mouseover, falls back to target")
	say("/mm harm Spell, Spell  hostile mouseover, falls back to target")
	say("/mm del Spell, Spell   remove from list and delete macro")
	say("/mm list               show this class's list")
	say("/mm sync               force a sync")
	say("Shift-click spells from the spellbook to insert them.")
end

SLASH_MOUSEOVERMACROS1 = "/mm"
SLASH_MOUSEOVERMACROS2 = "/momacro"
SlashCmdList.MOUSEOVERMACROS = function(msg)
	if not db then
		return
	end
	local cmd, rest = msg:match("^(%S*)%s*(.-)%s*$")
	cmd = cmd:lower()
	if KIND[cmd] then
		add(cmd, rest)
	elseif cmd == "del" or cmd == "remove" then
		remove(rest)
	elseif cmd == "list" then
		list()
	elseif cmd == "sync" then
		if not sync() then
			say("in combat, macros sync when it ends")
		end
	else
		help()
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		MouseoverMacrosDB = MouseoverMacrosDB or {}
		db = MouseoverMacrosDB
		db.spells = db.spells or {}
		class = UnitClassBase("player")
		db.spells[class] = db.spells[class] or {}
		sync()
	elseif pending then
		sync()
	end
end)
