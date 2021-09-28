# TODO List

Here is a list of things I want to add. I will add things as I think of them and ignore the list if I feel like it. As usual I will try things fiirst and research later, or not at all.

## Graphics

### Animation
Add a system for animating sprites. It should:

* Allow a sprite to have a set of frames. These needn't be contiguous in the sprite sheet.
* Automatically advance the frame based on a global timer, and per-sprite animation speed.
* Allow a single sprite to have multiple "sets" of frames. For example, a different set of frames depending on move or damage state.
* Support palette swapping
  * We already use this for smoke effects, but should use it to easily distinguish enemy variants.

### Particles

Have a general system for handling particles. At present we have different systems for smoke and sparks, for example. We will probbaly also want debris, and particle effects for engines and weapons.

### Screen shaking

Bada Boom. Bada BIG Boom.

## Gameplay

### Score

~~We need to keep score!~~

We keep score now! Obviously it will need tuning, but for now enemies have different point values which are scored when the enemy is destroyed.

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

### Thinking out loud…

An object is either moving or not, so everything should have a boolean is_moving state.

Some movement functions we'd like to have:

* move_to(x, y, speed)
* move_straight_towards(target, speed)
* move_turn_towards(target, speed, rate_of_turn)
* move_straight_ahead(speed) # maintain course
  * This suggests that objects know their current direction and speed
* move_nowhere() # maybe hover()?
  * How is this different from is_moving = false?
  * …or move_straight_ahead with a speed of zero?
  * Really we just want this for simplification, I think; it's an implementation detail to minimise leakage about movement states into other parts of the code. Everything has a movement function, even if that function is a noop.



## Timers

We need a general solution for timers. These could be used for many things:

* spawning groups/waves of enemies
* predictable shot firing (either time between shots, or firing bursts)
* explosive timers (mines, missiles that explode after some time limit)
* limited homing (missiles/torpedos that go ballistic after a while)
* recharge timers (for special attacks, shields, etc)
* "bonus" enemies (that either flee or get stronger after some timeout)

To generalise this we should have one bit of code which is responsible for tracking timers and triggering effects. This will hopefully make it easier to compose complex actions from smaller pieces.


```
new_timer(frames, caller, callback)
  -- Register timer which calls callback(caller) after frames

check_timer(t)
  -- decrement timer and call if it's time.
```


