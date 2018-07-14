pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- tinyshmup
-- by @johndalton

--******************************
-- initialization
--******************************

finished = false

function _init()
  gamestate=0
end

function _update()
  if gamestate == 0 then
    -- title screen
    update_title()
  elseif gamestate == 1 then
    -- game is running
    update_game()
  else
    -- game over
    update_gameover()
  end
end

function update_title()
  if btn(4) then
    play_game()
  end
end

function update_game()
  foreach(aliens, move_enemy)
  if(#aliens<3) then add(aliens, new_enemy(flr(rnd(80)),5,random_enemy())) end

  foreach(bullets,move_bullet)
  foreach(smoke, update_smoke)
  foreach(sparks, update_spark)

  move_player()
end

function update_gameover()
  if restarttimer == 0 then
    gamestate = 0
  else
    restarttimer -= 1
  end
end

function _draw()
  if gamestate == 0 then
    -- title screen
    draw_title()
  elseif gamestate == 1 then
    -- game is running
    draw_game()
  else
    -- game over
    draw_gameover()
  end
end

function draw_title()
  cls()
  print("press ➡️ to start", 32, 50)
  -- print("01234567890123456789012345678901234", 0, 60)
end

function draw_game()
  cls()
  foreach(aliens, draw_enemy)
  foreach(bullets,draw_bullet)
  foreach(sparks, draw_spark)
  -- do smoke in reverse order for best effect.
  for i = #smoke,1,-1 do
    draw_smoke(smoke[i])
  end

  draw_player()
  draw_ui()
end

function draw_gameover()
  cls()
  print("game over", 45, 50)
end

function player_death()
  -- we'll deal with lives later!
  game_over()
end

function play_game()
  gamestate = 1
  add(aliens, new_enemy(5,5,"saucer"))
  p=setup_player()
end

function game_over()
  gamestate = 2
  restarttimer = 150
  aliens    = {}
  bullets = {}
end

function draw_ui()
  -- health bar
  print("♥",0,2,8)
  rectfill(7,2,p.hp*8,6,5)  
  rectfill(7,2,(p.hp-p.dmg)*8,6,8)
end

-- ***
-- *** collision detection
-- *** from: http://www.lexaloffle.com/bbs/?tid=2179
-- *** pixel-perfect collision detection by joshmillard
-- ***
-- *** n.b. only using box collison for now, will revisit
-- *** pixel-perfect collisions if necessary.

-- return a rectangle structure
-- based on a sprite, with
-- start and end x/y screen
-- coordinates
function to_rect(sp)
  local r = {}
  r.x1 = sp.x
  r.y1 = sp.y
  r.x2 = sp.x + sp.w - 1
  r.y2 = sp.y + sp.h - 1
  return r
end

-- simple box collision:
-- takes rectangle coords for
-- two sprites.
-- return true if bounding
-- rectangles overlap, false
-- otherwise
function collide_rect(r1,r2)
  if((r1.x1 > r2.x2) or
     (r2.x1 > r1.x2) or
     (r1.y1 > r2.y2) or
     (r2.y1 > r1.y2)) then
    return false
  end
  return true
end

-- ***
-- *** end collision detection
-- ***

function out_of_bounds(o)
  -- return (o.x>127 or o.x<0 or o.y>127 or o.y<0)
  if (o.x>127 or o.x<0 or o.y>127 or o.y<0)
  then
    return true
  else
    return false
  end
end

-->8
-- the player
p={}

function setup_player()
  local p = {}
  -- player ship
  p.x  = 63
  p.y  = 120
  p.dx = 0
  p.d  = 0
  p.a  = 2
  p.sp = 1
  p.w  = 8
  p.h  = 7
  p.dmg= 0
  p.hp = 5

  -- player cannons
  p.bullets  = 0
  p.maxshots = 8
  p.cannon   = 0  -- left or right
  p.cooldown = 5  -- between shots
  p.shottmr  = 0  -- cooldown tmr
  p.bdy      = -4 -- bullet speed

  return p
end

function move_player()
  p.dx=0
  p.dy=0
  if p.shottmr > 0 then p.shottmr-=1 end

  if btn(0) then p.dx = p.a*-1 end
  if btn(1) then p.dx = p.a end
  if btn(2) then p.dy = p.a*-1 end
  if btn(3) then p.dy = p.a end
 
  if btn(4) and p.shottmr == 0
  then
    fire_player_bullet()
    sfx(2)
    p.shottmr = p.cooldown
  end
 
  p.x += p.dx
  p.y += p.dy

  if p.x<0   then p.x=0 end
  if p.x>120 then p.x=120 end
  if p.y<0   then p.y=0 end
  if p.y>120 then p.y=120 end

  -- did we hit an enemy? ouch!
  for a in all(aliens) do
    if check_hit(a,p)
    then
      sfx(0)
      p.dmg += a.hp
      a.dmg += p.hp
    end
  end

  -- Are we on fire?
  if rnd(p.hp*2) < p.dmg then
    add(smoke, make_smoke({x=p.x+rnd(7), y=p.y+6}))
  end
  
  -- are we still flying?
  if p.dmg >= p.hp then
    player_death()
  end
end

function ship_sprite()
  local s=1
 
  if (p.dx==0 and p.dy!=0) then
    s=2
  elseif (p.dx>0) then
    s=3
  elseif (p.dx<0) then
    s=4
  end
 
  return s
end 

function draw_player()
  spr(ship_sprite(),p.x,p.y)
  --print("hp: "..p.hp.." dmg: "..p.dmg, 3, 8)
  --print("bullets: "..p.bullets, 3, 16)
 
  --sspr(8,8,16,16,p.x,p.y)
 
  -- draw half, then again flipped!
  --sspr(8,8,8,16,p.x,p.y)
  --sspr(8,8,8,16,p.x+8,p.y,8,16,1)
end

function fire_player_bullet()
  if (p.bullets<p.maxshots)
  then
    -- bullets fire from alternate cannons:
    -- here we set the appropriate x offset.
    local boffset=2
    if (p.cannon==1)
    then
      boffset+=3
      p.cannon=0
    else
      p.cannon=1
    end
    local bullet={
      x=p.x+boffset,y=p.y-1,
      dx=0,dy=p.bdy,w=1,h=2,
      sp=0,player=true}
    add(bullets,bullet)
    p.bullets+=1
  end
end

-->8
-- aliens
aliens={}
enemy_types={}
enemy_types["saucer"]={
  name="saucer",
  dx=0, dy=0, a=1, w=8, h=4,
  hp=2, dmg=0, timer=1, ticks=0,
  xmove=0, ymove=0, sprite=8,
  timers={4,20,2},
  dxtarget={3,0,-3,0},
  dytarget={0,1,-1,0,1},
  move=move_with_timers
}
enemy_types["diamond"]={
  name="diamond",
  dx=0, dy=0, a=1, w=7, h=6,
  hp=2, dmg=0, timer=1, ticks=0,
  xmove=0, ymove=0, sprite=9,
  timers={4,15,2},
  dxtarget={3,-1,0},
  dytarget={0,1},
  move=move_with_timers
}

function random_enemy()
  choice=rnd(2)
  print(choice,0,8,1)
  if choice > 1
  then
    return "saucer"
  else
    return "diamond"
  end
end

function new_enemy(x,y,n)
  -- spawn enemy type n at x,y
  local s={}
  for k,v in pairs(enemy_types[n]) do
    s[k]=v
  end
  s.x=x
  s.y=y

  s.move=move_with_timers

  return s
end

function move_with_timers(s)
  if (s.ticks==0) then
    s.ticks=s.timers[s.timer]
    s.timer+=1
    if(s.timer > #s.timers) then s.timer=1 end
    s.xmove+=1
    if(s.xmove > #s.dxtarget) then s.xmove=1 end
    s.ymove+=1
    if(s.ymove > #s.dytarget) then s.ymove=1 end
  end
  
  if(s.dx<s.dxtarget[s.xmove]) then
    s.dx+=s.a
  elseif(s.dx>s.dxtarget[s.xmove]) then
    s.dx-=s.a
  end
  
  if(s.dy<s.dytarget[s.ymove]) then
    s.dy+=s.a
  elseif(s.dy>s.dytarget[s.ymove]) then
    s.dy-=s.a
  end

  s.x+=s.dx  
  s.y+=s.dy
  s.ticks-=1
end

function move_enemy(s)
  if (s.dmg >= s.hp) then
    sfx(0)
    del(aliens,s)
    return -1
  end

  if rnd(s.hp*2) < s.dmg then
    add(smoke, make_smoke(s))
  end
  
  s.move(s)

  if out_of_bounds(s)
  then
    del(aliens,s)
  end

  fire_chance=rnd(100)
  if fire_chance > 96
  then
    if s.name == "diamond"
    then
      fire_enemy_bullet(s,2)
    else
      fire_enemy_bullet(s,3,p)
    end
  end
end

function draw_enemy(s)
  --print("ticks:"..s.ticks,2,2)
  --print("dx:"..s.dx,s.x-10,s.y-4)
  --print("dy:"..s.dy,s.x+10,s.y-4)
  spr(s.sprite, s.x, s.y)
end

-->8
-- bullets
bullets={}
smoke={}
smoke_colour={8,10,6,6,5,12}
sparks={}

function fire_enemy_bullet(e, s, t)
  -- By default a bullet travels straight down.
  local bullet={
    x=e.x+e.w/2,y=e.y+e.h,
    dx=0,dy=s,w=3,h=3,
    sp=48,player=false}
  -- If there's a target, aim at it.
  if t
  then
    local angle=atan2(t.x - e.x, t.y - e.y)
    bullet.dx=s*cos(angle)
    bullet.dy=s*sin(angle)
  end
  add(bullets,bullet)
end

function remove_bullet(b)
  del(bullets,b)
  if b.player == true
  then
    p.bullets-=1
  end
end 

function move_bullet(b)
  b.x += b.dx
  b.y += b.dy
  if out_of_bounds(b)
  then
    remove_bullet(b)
  else
    if b.player
    then
      for a in all(aliens) do
        if check_hit(a,b)
        then
          sfx(1)
          a.dmg += 1
          remove_bullet(b)
          for i=1,3 do
            add(sparks, make_spark(a))
          end
        end
      end
    else
      if check_hit(p,b)
      then
        sfx(1)
        p.dmg += 1
        remove_bullet(b)
        for i=1,3 do
          add(sparks, make_spark(p))
        end
      end
    end
  end
end

function draw_bullet(b)
  spr(b.sp,b.x,b.y)
end

function check_hit(a, b)
  return collide_rect(to_rect(a), to_rect(b)) 
end

function make_spark(p)
  s={}
  -- sparks start at p.x,p.y
  -- then move randomly
  s.x=p.x
  s.dx=rnd(4)-2

  s.y=p.y
  s.dy=rnd(4)-2

  s.age=1
  s.change=2
  s.colour=1

  return s
end

function update_spark(s)
  s.age+=1

  if s.age > 8
  then
    del(sparks, s)
  else
    if s.age>s.change
    then
      s.colour+=1
      s.change+=3
    end
  end

  s.x+=s.dx
  s.y+=s.dy
end

function make_smoke(p)
  s={}
  -- x pos might be offset
  s.x=p.x
  offset=rnd(9)
  if offset < 4 then s.x-=offset end
  if offset > 6 then s.x+=offset-6 end

  -- smoke goes up  
  s.y=p.y
  s.dy=rnd(2)/2*-1

  s.age=1
  s.change=2
  s.sprite=16
  s.colour=1

  return s
end

function update_smoke(s)
  s.age+=1
  
  if s.age > 32
  then
    del(smoke, s)
  else
    if s.age>s.change
    then
      s.sprite+=1
      s.colour+=1
      s.change*=2
    end
  end
  
  s.y+=s.dy
end

function draw_smoke(s)
  pal(15,smoke_colour[s.colour])
  -- random sprite by age
  ss=s.sprite+flr(rnd(1))*16
  spr(ss,s.x,s.y)
end

function draw_spark(s)
  pset(s.x,s.y,smoke_colour[s.colour])
end

__gfx__
a00000000000000000000000000000000000000000000000000000000000000000067000000a0000000000000000000000000000000000000000000000000000
70000000007006000070060000706000000707000000000000000bb3b3b00000056666700099a000007006000070600000070700000000000000000000000000
000000000060050000600500006050000006060000700700000bb3bb3b3b30005dd6666704999a00006005000060500000060600000000000000000000000000
00000000006cc500006cc500006c50000007c6000007700000bbbbb3bbbbbb0005588d604933b9a0006cc500006c50000007c600000000000000000000000000
00000000076cd650076cd650076c65000076c560000770000b3bb22bb22b3bb00000000004449900076cd650076c65000076c560000000000000000000000000
00000000765dd555765dd5557d5d55000076d5d6007007000bb3b203b203bb300000000000409000765dd5557d5d55000076d5d6000000000000000000000000
000000006506506565965965659596000069595600000000b3bbb00b300bb3bb0000000000000000659659656595960000695956000000000000000000000000
000000000000000000a00a0000a0a000000a0a0000000000bbb3bb3bbb3bbb3b000000000000000000a00a0000a0a000000a0a00000000000000000000000000
f0f0000000f00000000000000f0000000000000000000000bb3bb3bbbb3bb3bb0000000000000000000000000000000000000000000000000000000000000000
0f0000000f0f00000fff0000fff000000f00000000000000b3b3bbb88bbb3b3b0000000000000700007000000000000000000000000000000000000000000000
f0f00000f0f0f0000fff00000f00000000000000000000000bbbbb8ee8bbbbb00000000000000705507000000000000000000000000000000000000000000000
000000000f0f00000fff00000000000000000000000000000b0bb355553bb0b00000000000000655556000000000000000000000000000000000000000000000
0000000000f0000000000000000000000000000000000000b000b000000b000b000000000000065cc56000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000b00b000000b00b000000000000076cccc6700000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000b000b0000b000b000000000000076cddc6700000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000766cddc6670000000000000000000000000000000000000000000
0f000000f0f0000000f000000f0000000f00000000000000000000000000000000000000000667cccc7660000000000000000000000000000000000000000000
fff000000f0f00000fff0000000f000000000000000000000000000000000000000000000076766cc66567000000000000000000000000000000000000000000
0f000000f0f00000fffff0000f00000000f000000000000000000000000000000000000070767656676567060000000000000000000000000000000000000000
000000000f0f00000fff000000000000000000000000000000000000000000000000000077667656676566760000000000000000000000000000000000000000
000000000ff0000000f0000000000000000000000000000000000000000000000000000078667656676566860000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000078675556665566860000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000068659916659956860000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000aa0660aa00000000000000000000000000000000000000000000
3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200002f650226501d650186501c6501f65024650276502a6502c6502d6502b6502965026650216501e650196501665013650106500b6500965005650036500165006650016500365001650066500165002650
00020000251501d650151500e6500b1500a6500315003650021000460001100371003710034100371003710036100341003710034100341003510013100011000110000000000000000000000000000000000000
0002000038650161502d6500160008600016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
