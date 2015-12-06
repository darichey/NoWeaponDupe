#No Weapon Dupe

A simple SourceMod plugin to prevent players from constantly dropping new weapons on the ground.

Cvars:

```
// The time a player must wait before they may drop another weapon. Any value below 1 will disable the cooldown.  
// Default "3"
nwd_drop_cooldown

// The number of weapons that a player can drop in <nwd_drop_limit_time> seconds before they are put on cooldown.
// Default "2"
nwd_drop_limit

// The amount of time a player can drop <nwd_drop_limit> weapons before they are put on cooldown.
// Default "2"
nwd_drop_limit_time
```
