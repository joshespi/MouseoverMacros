# MouseoverMacros

WoW addon that keeps mouseover cast macros in sync with a spell list per class.

Each spell gets a character macro named `MO <spell>`:

```
#showtooltip Flash Heal
/cast [@mouseover,help,nodead][] Flash Heal
```

## Commands

| Command | Does |
| --- | --- |
| `/mm add Spell, Spell` | Cast on a friendly mouseover target, otherwise your current target |
| `/mm harm Spell, Spell` | Cast on a hostile mouseover target, otherwise your current target |
| `/mm del Spell, Spell` | Remove spells from the list and delete their macros |
| `/mm list` | Show this class's list |
| `/mm sync` | Force a sync |

Shift-click a spell in the spellbook to insert it.

## Notes

- Spell lists are shared by all characters of the same class on the account. Macros are per character.
- Macros sync at login and after each change. Changes made in combat are applied when combat ends.
- Macro names are cut to 16 characters, so two spells that end up with the same name can't both be added.
