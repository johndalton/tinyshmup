# TODO List

Here is a list of things I want to add. I will add things as I think of them and ignore the list if I feel like it. As usual I will try things fiirst and research later, or not at all.

## Graphics

### Animation
Add a system for animating sprites. It should:

* Allow a sprite to have a set of frames. These needn't be contiguous in the sprite sheet.
* Automatically advance the frame based on a global timer, and per-sprite animation speed.
* Allow a single sprite to have multiple "sets" of frames. For example, a different set of frames depending on move or damage state.
* Support palette swapping

### Particles

Have a general system for handling particles. At present we have different systems for smoke and sparks, for example. We will probbaly also want debris, and particle effects for engines and weapons.

### Screen shaking

Bada Boom. Bada BIG Boom.

## Gameplay

### Score

We need to keep score!

### Pickups

We need powerups, bonus drops, etc.

### Bosses

We absolutely need boss battles. Later.

## Weapons

### Ballistic

* ~~Enemies need to be able to aim weapons at you, not just shoot straight down.~~
	* Revised some basic trig using http://www.helixsoft.nl/articles/circle/sincos.htm as a reference!   
* Player powerups should include things like spread shots.

### Guided

* Missiles for both player and enemies. These need to change course toward a target. They also need a time limit or some other way of ensuring they don't stay on screen for ever.
* Mines could be another example; stray within range and you activate them, they start a countdown timer and begin moving toward you.

### AoE

* Explosions that damage everything within their blast radius. Probably the result of a missile or similar.
* EMP charges? These could prevent enemies from firing, and maybe even cause them to move ballistically.

### Beam

* Beam weapons are cool.

## AI

The enemy movement system needs a complete overhaul. I wanted simple defined behaviours for different types of enemies, and this is still how I imagine the majority of enemies will work. However enemies also need to be able to change state, as they move from hold into attack patterns, etc. Think Galaga as a starting point; an enemy might have a "hold formation" state, a "swoop attack" state, an "attempt capture" state, and maybe even an "escape" state.

* Enemies need state management
* Changing state will change the move behaviour for an enemy.
* Changing state may require some logic (trigger based on health, time, proximity, target selection, etc)



