pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-->8
--> MAIN
	in_game=false
    function _init()
		music(0)
		cls()
		init_camera()
		init_menu()
    end

    function _update()
		if(in_game) then update_level()
		else update_menu() end
    end

    function _draw()
		if (in_game) then draw_level()
		else draw_menu() end
    end

-->8 MENU
	menu={}
	function init_menu()
		menu = {
			id=0,
			sub=0,
			size=32,
			t=2,
		}
	end

	function update_menu()
		if (menu.sub==0) then -- main
			if (menu.id==0) then 
				if (btnp(4) or btnp(5)) then load_level_1()
				elseif (btnp(3)) then menu.id=1 end
			elseif (menu.id==1) then 
				if (btnp(4) or btnp(5)) then menu.sub=1 menu.id=0
				elseif (btnp(2)) then menu.id=0 end
			end
		elseif(menu.sub==1) then -- extras
			if (btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5)) then
				menu.sub=0
				menu.id=0
			end
		end
	end

	function draw_menu()
		cls()
		draw_menu_background()
		menu.size=sin(menu.t)*2+1
		menu.t += 1/30
		if (menu.sub==0) then
			draw_clear_box(abs_box(44-menu.size, 80-menu.size, 82+menu.size, 101+menu.size))
			printui("new game", 48, 84-menu.size*0.25, (menu.id==0 and 7 or 6))
			printui("extras", 52, 94+menu.size*0.25, (menu.id==1 and 7 or 6))
		elseif (menu.sub==1) then
			draw_clear_box(abs_box(12-menu.size, 76-menu.size, 116+menu.size, 127))
			printui("left ⬅️", 24, 80-menu.size*1, 7)
			printui("➡️ right", 72, 80-menu.size*1, 7)
			printui("jump ⬆️", 24, 90-menu.size*.8, 7)
			printui("⬇️", 72, 90-menu.size*.8, 7)
			printui("crouch", 82, 90-menu.size*.8, 7)
			printui("made for ludum dare 45 by", 14, 100-menu.size*.6, 11)
			printui("theo fafet", 44, 110-menu.size*.4, 12)
			printui("barthelemy passin-cauneau", 14, 120-menu.size*.4, 12)
		end
	end

	function draw_menu_background()
		local pos={x=rnd(128), y=rnd(128)}
		local s = sin(menu.t)


		for i=0, 4, 1 do
			for j=0, 4, 1 do
				s = sin(menu.t/10+i*0.25+j*0.25)*5+5
				rectfill(i*32, j*32, (i+1)*32, (j+1)*32, s+5)
			end
		end
		s = sin(menu.t)
		if (s>0.9) then
			explosion(pos, 10, 5, 100, false)
			blood(pos, false)
		end
		draw_particles()

		draw_clear_box(abs_box(4-menu.size, 3-menu.size, 98+menu.size,  38+menu.size))
		local thierrys = "thierry\'s"
		for i=1, #thierrys, 1 do
			local c = sub(thierrys, i, i)
			s = sin(menu.t+i*0.25)/2+0.5
			printui(c, 7*i+5, 8+s*3, flr(s*3)+11)
		end
		local adventure = "adventure"
		for i=1, #adventure, 1 do
			local c = sub(adventure, i, i)
			s = cos(menu.t+i*0.5)/2+0.5
			printui(c, 7*i+25, 24+s*3, 16-flr(3-s*3)+7)
		end
	end

-->8 PLAYER
    player={}

    function init_player()
		player={
            box=box(level.spawn.x, level.spawn.y, 8, 16),
			anim={
				idle=create_anim_w_by_h({0, 2, 4}, 2, 2, false, false, .5),
				move_right=create_anim_w_by_h({6, 8, 10}, 2, 2, false, false, .5),
				move_left=create_anim_w_by_h({6, 8, 10}, 2, 2, true, false, .5),
				wall_right=create_anim_w_by_h({34}, 2, 2, true, false, 0),
				wall_left=create_anim_w_by_h({34}, 2, 2, false, false, 0),
				jump=create_anim_w_by_h({32}, 2, 2, false, false, 0),
				crouch_right=create_anim_w_by_h({52}, 2, 1, false, false, 0),
				crouch_left=create_anim_w_by_h({52}, 2, 1, true, false, 0)
			},
			speed={x=0,y=0},
			crouch=false,
			ground=false,
			ceil=false,
			left=false,
			right=false,
			flip=false,
			acc=0.5,
			jump=5,
			walljump_x=4,
			wall_jump_y=3,
			max_run=3.5,
			max_fall=6,
			friction=0.6,
			can_jump=false, can_crouch=false, can_move=false,
			dead=false, dead_time=0
        }
	end

	function player_col_right() return col_map(player.box, "right", 1, 1) end
	function player_col_left() return col_map(player.box, "left", 1, 1) end
	function player_col_up() return col_map(player.box, "up", 1, 1) end
	function player_col_down() return col_map(player.box, "down", 1, 1) end

    function update_player()
		if (not player.dead) then
			local _crouch = player.crouch
			player.speed.y += .5
			if (player.can_crouch) then
				if (player_col_down() and btn(3) or player.can_move and (btn(0) or btn(1))) then
					player.crouch=true
				else
					player.crouch=false
				end
			end
			if (not player_col_down()) then player.crouch = false end
			if (player.crouch and not _crouch) then
				player.box = abs_box(player.box.l-4, player.box.t+6, player.box.r+4, player.box.b) 
			elseif (not player.crouch and _crouch) then
				player.box = abs_box(player.box.l+4, player.box.t-6, player.box.r-4, player.box.b) 
			end
			if (player.can_move) then
				if (btn(0) and not player_col_left()) then
					player.flip=true
					player.speed.x -= player.acc
				elseif (btn(1) and not player_col_right()) then
					player.flip=false
					player.speed.x += player.acc
				elseif (player_col_down())  then
					player.speed.x *= player.friction
				end
			end
			if (player.can_jump and btnp(2)) then
				if (player_col_down() and not player_col_up()) then
					player.speed.y = -player.jump
					air_blow(player.box.l+8, player.box.b, 10, 2, 10, false)
				elseif (player_col_right() and not player_col_up()) then
					player.speed.x = -player.walljump_x
					player.speed.y = -player.wall_jump_y
					player.flip = true
					air_blow(player.box.r, player.box.t+8, 2, 10, 10, false)
				elseif (player_col_left() and not player_col_up()) then
					player.speed.x = player.walljump_x
					player.speed.y = -player.wall_jump_y
					player.flip = false
					air_blow(player.box.l, player.box.t+8, 2, 10, 10, false)
				end
			end
			if player.speed.y > 0 then
				player.speed.y=mid(-player.max_fall, player.speed.y, player.max_fall)
				if player_col_down() then
					player.speed.y=0
					box_move(player.box, 0, -((player.box.b+1)%8)+1)
				end
			elseif( player.speed.y < 0) then
				player.speed.y=mid(-player.max_fall, player.speed.y, player.max_fall)			
				if player_col_up() then
					player.speed.y = 0
				end
			end

			if (player.speed.x < 0 or btn(0)) then
				player.speed.x = mid(-player.max_run, player.speed.x, player.max_run)
				if (player_col_left() and player.speed.x < 0) then
					player.speed.x = 0
					--box_move(player.box, -((player.box.l+1)%8), 0)
				end
			elseif (player.speed.x > 0 or btn(1)) then
				player.speed.x = mid(-player.max_run, player.speed.x, player.max_run)
				if (player_col_right()) then
					player.speed.x = 0
					--box_move(player.box, -((player.box.r+1)%8), 0)
				end				
			end

			if (col_map(player.box, "left", 0b100, 1) or
				col_map(player.box, "right", 0b100, 1) or
				col_map(player.box, "up", 0b100, 1) or
				col_map(player.box, "down", 0b100, 1))
			then player_die() return end
			box_move(player.box, player.speed.x, player.speed.y)
		else 
			if (player.dead_time >= 0.5) then
				progress.load()
			end
				player.dead_time+=1/30
		end
	end

	function draw_player()
		if (not player.dead) then
			local b = player.box
			draw_box(b)
			if (player_col_down()) then
				if (btn(1) and not player.flip) then draw_anim(b.l, b.b-16, player.anim.move_right)
				elseif (btn(0) and player.flip) then draw_anim(b.l, b.b-16, player.anim.move_left)
				elseif (player.crouch) then 
					if (player.flip) then draw_anim(b.l, b.t+2, player.anim.crouch_left)
					else draw_anim(b.l, b.t+2, player.anim.crouch_right) end
				else draw_anim(b.l-3, b.t, player.anim.idle) end
			elseif (player_col_left()) then draw_anim(b.l, b.t, player.anim.wall_left)
			elseif (player_col_right()) then draw_anim(b.l-8, b.t, player.anim.wall_right)
			else draw_anim(b.l-3, b.t, player.anim.jump) end
		end
	end

	function try_kill_player(cols)
		for _,m in pairs(cols.masks) do
			if (band(m, 0b10) != 0) then
				player_die()
			end
		end
	end

	function player_die()
		cam_shake(5, 5, .2, 10, 10)		
		blood(box_center(player.box), btn(0,2))
		player.dead = true
		player.dead_time=0
	end

	function hit_player(b)
		local h= is_in_box(b.l, b.t, player.box) or
				is_in_box(b.r, b.t, player.box) or
				is_in_box(b.l, b.b, player.box) or
				is_in_box(b.r, b.b, player.box)
		if (h) player_die()
		return h
	end

	function col_map(b,dir,m, d)
		local c = {}
		local r=false
		for i=0,d,1 do
			if dir=="left"      then c = abs_box(b.l-i, b.t+2, b.l, b.b-2)
			elseif dir=="right" then c = abs_box(b.r, b.t+2, b.r+i, b.b-2)
			elseif dir=="up"    then c = abs_box(b.l+2, b.t-i, b.r-2, b.t)
			else c = abs_box(b.l+2, b.b, b.r-2, b.b+i) end
			r = r or hit_map(c, m)
		end
		return r
	end

	function hit_map(b, m)
		return  (band(fget(map_get(b.l, b.t)), m) != 0 or
				band(fget(map_get(b.r, b.t)), m) != 0 or
				band(fget(map_get(b.l, b.b)), m) != 0 or
				band(fget(map_get(b.r, b.b)), m) != 0)
	end

-->8
-->8 CAMERA AND MAP
	cam={}
    function init_camera()
		cam={
			x=0,y=0,
			shake = {x=0, y=0, px=0, py=0, t=0, fx=0, fy=0}
		}
	end

    function update_camera()
		local x= mid(0, box_center(player.box).x-64, 1024)
		local y= player.box.b-80
		if (cam.shake.t > 0) then
			cam.shake.x += cam.shake.px * cos(0.5 * cam.shake.fx * cam.shake.t)
			cam.shake.y += cam.shake.py * sin(0.5 * cam.shake.fy * cam.shake.t)
			cam.shake.t-=1/30
		else
			cam.shake.px=0 cam.shake.fx=0
			cam.shake.py=0 cam.shake.fy=0
		end
		cam.x +=(x-cam.x)*0.75
		cam.y +=(y-cam.y)*0.75
	end

	function draw_camera()
		--camera(cam.x+cam.shake.x,cam.y+cam.shake.y)
		camera(cam.x,cam.y)
		cls()
		
	end

	function cam_shake(x, y, t, fx, fy)
		cam.shake.px=max(x, cam.shake.px)
		cam.shake.py=max(y, cam.shake.py)
		cam.shake.t=max(t, cam.shake.t)
		cam.shake.fx=max(fx, cam.shake.fx)
		cam.shake.fy=max(fy, cam.shake.fy)
	end

--> MAP
    function draw_map()
		local mx=flr(cam.x/8)
		local my=flr(cam.y/8)
		map(mx,my,mx*8,my*8,17,17)
	end

	function map_get(x, y)
		return mget(x/8, y/8)
	end

	function map_set(x, y, s)
		mset(x, y, s)
	end

--> EFFECTS
particles={}
nparts = 0

function create_raw_particles(x, y, lt, np, draw)
	local pcl={
		x=x,
		y=y,
		lifetime=lt,
		draw=draw,
		timer=0.0,
		npart=np
	}
	add(particles, pcl)
	nparts += np
	return pcl
end

function create_particles(x, y, lt, np, init, draw)
	local pcl=create_raw_particles(x, y, lt, np, draw)
	init(pcl)
end
 

function draw_particles()
	for pcl in all(particles) do
		if (pcl.timer >= pcl.lifetime and pcl.lifetime > 0) then
			nparts -= pcl.npart
			del(particles, pcl)
		else
			pcl.draw(pcl)
		end
	end
end

function explosion(pos, radius, blow, np, simulated)
	local pcl = create_raw_particles(pos.x, pos.y, 0.3, np, draw_explosion)
	pcl.radius = radius
	pcl.blow = blow
	pcl.simulated=simulated
	init_explosion(pcl)
end

function init_explosion(pcl)
	pcl.pcs = {}
	for i=1,pcl.npart,1 do
		local a=rnd(1)
		local pc = {
			x=pcl.x + rnd(pcl.radius*0.5)-pcl.radius*0.25,
			y=pcl.y + rnd(pcl.radius*0.5)-pcl.radius*0.25,
			s = {
				x=cos(a)*(pcl.blow-rnd(pcl.blow*0.5)),
				y=sin(a)*(pcl.blow-rnd(pcl.blow*0.5))
			},
			lt=pcl.lifetime*(rnd(0.4)+1)
		}
		add(pcl.pcs, pc)
	end
end

function draw_explosion(pcl)
	for pc in all(pcl.pcs) do
		local p = 1-(pc.lt / pcl.lifetime)
		if p<0.2 then
			pset(pc.x, pc.y,7)
		elseif p<0.4 then
			pset(pc.x, pc.y,10)
		elseif p<0.6 then
			pset(pc.x, pc.y,9)
		elseif p<0.8 then
			pset(pc.x, pc.y,8)
		else
			pset(pc.x, pc.y,5)
		end
		pc.s.x*=1.1-p
		pc.x+=pc.s.x
		pc.y+=pc.s.y
		pc.lt-=1/30
		if (pc.lt<=0) del(pcl.pcs, pc)
	end
	if #pcl.pcs==0 then
		pcl.timer=pcl.lifetime+1
	end
end

function blood(pos, simulated)
	local pcl=create_raw_particles(pos.x, pos.y, .5, 15, draw_blood)
	pcl.simulated=simulated
	init_blood(pcl)
end

function init_blood(pcl)
	pcl.pcs = {}
	for i=1,pcl.npart,1 do
		local a=rnd(1)
		local pc = {
			x=pcl.x, y=pcl.y,
			s={x=cos(a)*rnd(8),	y=-abs(sin(a))-2-rnd(8)},
			lt=pcl.lifetime*(rnd(0.4)+1)
		}
		add(pcl.pcs, pc)
	end
end

function draw_blood(pcl)
	for pc in all(pcl.pcs) do
		local p = (pc.lt / pcl.lifetime)
		circfill(pc.x, pc.y,2.5*p,8)
		pc.s.y += 1
		pc.x+=pc.s.x
		pc.y+=pc.s.y
		pc.lt-=1/30
		if (pc.lt<=0) del(pcl.pcs, pc)
	end
	if #pcl.pcs==0 then
		pcl.timer=pcl.lifetime+1
	end
end

function stars(pos, msg, simulated)
	local pcl=create_raw_particles(pos.x, pos.y, 2, 100, draw_stars)
	pcl.msg=msg
	pcl.simulated=simulated
	init_stars(pcl)
end

function init_stars(pcl)
	pcl.pcs = {}
	for i=1,pcl.npart,1 do
		local a=rnd(1)
		local pc = {
			x=pcl.x, y=pcl.y,
			s={x=cos(a)*2+(rnd(3)-1.5),	y=sin(a)*4-2},
			lt=pcl.lifetime*(rnd(0.4)+1)
		}
		add(pcl.pcs, pc)
	end
end

function draw_stars(pcl)
	for pc in all(pcl.pcs) do
		local p = (pc.lt / pcl.lifetime)
		circfill(pc.x, pc.y, 1-p,10)
		pc.s.x*=0.8
		pc.s.y*=0.8
		pc.x+=pc.s.x
		pc.y+=pc.s.y
		pc.lt-=1/30
		if (pc.lt<=0) del(pcl.pcs, pc)
	end
	if #pcl.pcs==0 then
		pcl.timer=pcl.lifetime+1
	end
	draw_clear_box(txt_box(pcl.msg, pcl.x-#pcl.msg*2, pcl.y-20), true)
	print(pcl.msg, pcl.x-#pcl.msg*2, pcl.y-20)
end

function air_blow(x, y, sx, sy, n, simulated)
	local pcl = create_raw_particles(x, y, .15, n, draw_air_blow)
	pcl.sx = sx
	pcl.sy = sy
	pcl.simulated=simulated
	init_air_blow(pcl)
end

function init_air_blow(pcl)
	pcl.pcs = {}
	for i=1,pcl.npart,1 do
		local pc = {
			x=pcl.x, y=pcl.y,
			s={x=pcl.sx*(rnd(2)-1), y=pcl.sy*(rnd(2)-1)},
			lt=pcl.lifetime*(rnd(.5)+.75)
		}
		add(pcl.pcs, pc)
	end
end

function draw_air_blow(pcl)
	for pc in all(pcl.pcs) do
		local p = (pc.lt / pcl.lifetime)
		if (p < 0.4) then pset(pc.x, pc.y,6)
		else pset(pc.x, pc.y,7) end
		pc.s.x*=0.5
		pc.s.y*=0.5
		pc.x+=pc.s.x
		pc.y+=pc.s.y
		pc.lt-=1/30
		if (pc.lt<=0) del(pcl.pcs, pc)
	end
	if #pcl.pcs==0 then
		pcl.timer=pcl.lifetime+1
	end
end

--> ANIMATION
	function create_anim_w_by_h(sprites, w, h, flip_x, flip_y, speed)
		return {
			sprites=sprites, w=w, h=h, flip_x=flip_x, flip_y=flip_y, speed=speed, dt=0
		}
	end

	function draw_anim(x, y, anim)
		local i = flr((anim.dt%#anim.sprites)+1)
		spr(anim.sprites[i], x, y, anim.w, anim.h, anim.flip_x, anim.flip_y)
		anim.dt+=anim.speed
	end

	function reset_anim(anim)
		anim.dt = 0
	end

--> PROPS
	props = {}

	function create_prop(update, draw)
		local prop = {update=update, draw=draw}
		add(props, prop)
		return prop
	end

	function update_props()
		for prop in all(props) do
			if (prop.update != nil) prop.update(prop)
		end
	end

	function draw_props()
		for prop in all(props) do
			if (prop.draw != nil) prop.draw(prop)
		end
	end

	function fire_ball(x, y, sx, sy)
		local fb = create_prop(update_fire_ball, draw_fire_ball)
		fb.box=box(x+1+sx, y+1+sy, 6, 6)
		fb.speed={x=sx,y=sy}
		return fb
	end

	function update_fire_ball(fb) 
		if (hit_map(fb.box, 0b1) or hit_player(fb.box)) then
			explosion(box_center(fb.box), 6, 1.5, 10, false)
			del(props, fb)
			cam_shake(1, 1, .1, 5, 5)
			return
		end
		explosion(box_center(fb.box), 12, 1, 5, false)
		box_move(fb.box, fb.speed.x, fb.speed.y)
	end

	function draw_fire_ball(fb)
		spr(54, fb.box.l, fb.box.t)
	end

	function rocket(x, y, pow, target)
		local rkt = create_prop(update_rocket, draw_rocket)
		rkt.box=box(x, y, 7, 6)
		rkt.pow = pow
		rkt.target = target
		local dx = box_center(rkt.target).x-box_center(rkt.box).x
		local dy = box_center(rkt.target).y-box_center(rkt.box).y
		rkt.a = atan2(dx, dy)
	end

	function update_rocket(rkt) 
		if (hit_map(rkt.box, 0b1) or hit_player(rkt.box)) then
			explosion(box_center(rkt.box), 6, 1.5, 10, false)
			del(props, rkt)
			cam_shake(1, 1, .1, 5, 5)
		end

		local b=box_center(rkt.target)
		local da=atan2(b.x-rkt.box.l,b.y-rkt.box.t)-rkt.a
		rkt.a += da
		
		box_move(rkt.box, rkt.pow * cos(rkt.a+0.5), rkt.pow * sin(rkt.a+0.5))
	end

	function draw_rocket(rkt)
		rspr(38, rkt.box.l, rkt.box.t, rkt.a, 3.5, 3.5)
	end

	function ball_thrower(x, y, sx, sy, timers)
		local bt = create_prop(update_ball_thrower, nil)
		map_set(x, y, 96)
		bt.x=x bt.y=y
		bt.sx=sx bt.sy=sy
		bt.timers = timers
	end

	function update_ball_thrower(bt)
		if (#bt.timers==0) return 
		if (tick_timer(bt.timers[1])) then
			fire_ball(bt.x,bt.y, bt.sx, bt.sy)
		end
		if (bt.timers[1].n<=0) del(bt.timers, bt.timers[1])
	end

	function rocket_thrower(x, y, pow, target, timers)
		local bt = create_prop(update_rocket_thrower, nil)
		map_set(x, y, 97)
		bt.x=x bt.y=y
		bt.pow = pow
		bt.target = target
		bt.timers = timers
	end

	function update_rocket_thrower(bt)
		if (#bt.timers==0) return 
		if (tick_timer(bt.timers[1])) then
			rocket(bt.x,bt.y, bt.pow,bt.target)
		end
		if (bt.timers[1].n<=0) del(bt.timers, bt.timers[1])
	end

-->8
--> BOX AND UTILS
--> BOX

	function box(x,y,w,h)
		return {l=x,t=y,r=x+w,b=y+h}
	end

	function abs_box(l,t,r,b)
		return {l=l,t=t,r=r,b=b}
	end
	
	function spr_box(x,y)
		return box(x,y,8,8)
	end
	
	function txt_box(str,x,y)
		return box(x,y,4 * #str,5)
	end
	
	function is_in_box(x,y,b)
		return x>=b.l and x<=b.r and y>=b.t and y<=b.b
	end

	function clear_box(b)
		rectfill(b.l,b.t,b.r,b.b,0)
	end

	function draw_box(b,c)
		c=c or 7
		line(b.l+1,b.t,b.r-1,b.t,c)
		line(b.l,b.t+1,b.l,b.b-1,c)
		line(b.r,b.t+1,b.r,b.b-1,c)
		line(b.l+1,b.b,b.r-1,b.b,c)
	end

	function draw_clear_box(b, world)
		if (not world) then 
			clear_box(box_s2w(add_box(abs_box(1,1,-1,-1),b)))
			draw_box(box_s2w(b))
		else 
			clear_box(add_box(abs_box(-1,-1,1,1),b))
			draw_box(add_box(abs_box(-2,-2,2,2),b))
		end
	end

	function box_w2s(b)
		return abs_box(b.l-cam.x,b.t-cam.y,b.r-cam.x,b.b-cam.y)
	end

	function box_s2w(b)
		return abs_box(b.l+cam.x,b.t+cam.y,b.r+cam.x,b.b+cam.y)
	end

	function add_box(b1,b2)
		return abs_box(b1.l+b2.l,b1.t+b2.t,b1.r+b2.r,b1.b+b2.b)
	end

	function box_center(b)
		return {x=0.5*(b.l+b.r), y=0.5*(b.t+b.b)}
	end

	function box_move(b, dx, dy)
		b.l+=dx
		b.r+=dx
		b.t+=dy
		b.b+=dy
	end

--> UTILS
	function str_num(n,d)
		local str=''..n
		for i=0,d-#str-1,1 do str='0'..str end
		return n<1 and sub(str,2) or str
	end

	function printui(t,x,y,c)
		print(t,x+cam.x,y+cam.y,c)
	end

	function sprui(s,x,y)
		spr(s,x+cam.x,y+cam.y)
	end

    function cpy(orig)
		local new={}
		for k,v in pairs(orig) do
			new[k]=v
		end
		return new
	end

	function sort(a,cmp)
		for i=1,#a do
			j = i
			while j > 1 and cmp(a[j-1],a[j]) do
				a[j],a[j-1] = a[j-1],a[j]
				j = j - 1
			end
		end
	end

	function pow(a, b)
		local r=1
		for i=1,b,1 do
			r*=a
		end
		return r
	end

	function new_timer(delay, rate, n)
		return {delay=delay, rate=rate, n=n, t=0, dt=rate}
	end

	function tick_timer(timer)
		timer.t+=1/30
		timer.dt+=1/60
		if (timer.t > timer.delay and timer.n > 0) then
			if (timer.dt >= timer.rate) then
				timer.dt=0
				timer.n -= 1
				return true
			end
		end
		return false
	end

	function rspr(n, x, y, a, px, py)
		local sx=n%16*8
		local sy=flr(n/16)*8
		local cosa = cos(a)
		local sina = sin(a)
		for dx=0,7,1 do
			for dy=0,7,1 do
				local c = sget(sx+dx, sy+dy)
				if (c!=0) then
					local cx=dx-px cy=dy-py
					pset(x + cx*cosa - cy*sina, y + cx*sina + cy*cosa, c)
				end
			end
		end
	end

-->8
--> LEVELS
	progress = {}
	level = {}
	function load_level(spawn_x, spawn_y, update, draw)
		in_game=true
		props={}
		particles={}
		level = {spawn={x=spawn_x, y=spawn_y}, update=update, draw=draw}
		
		init_player()
		init_camera()
		cam.x=player.box.l
		cam.y=player.box.t
	end

	function update_level()
        update_props()
        update_player()
		if (level.update != nil) level.update()
		update_camera()
	end

	function draw_level()
        draw_camera()
        draw_map()
		if (level.draw != nil) level.draw()
		draw_particles()
        draw_player()
        draw_props()
	end

	function load_level_1()
		progress.load=load_level_1
		load_level(60, 100, update_level_1, nil)
		level.t=0
	end

	function update_level_1()
		if (level.finished == nil) then
			if (level.t==30) then
				stars(box_center(player.box), "new skill: jump")
				player.can_jump=true
			end

			if (level.t==8*30) then
				stars(box_center(player.box), "new skill: crouch")
				player.can_crouch=true
			end

			if (level.t==17*30) then
				stars(box_center(player.box), "new skill: move")
				player.can_move=true
			end

			if (level.t >= 3*30 and level.t <= 30*30) then
				local y1 = 12.8*8
				local y2 = 11.8*8
				local y3 = 10.8*8
				local x1 = 11
				local x2 = 13.5*8
				if (level.t==2*30) then fire_ball(x1, y1, 2, 0) -- jump
				elseif (level.t==3*30) then fire_ball(x2, y1, -2, 0)
				elseif (level.t==4*30) then fire_ball(x2, y2, -2, 0)
				elseif (level.t==6*30) then fire_ball(x1, y1, 2, 0) fire_ball(x2, y2, -2, 0)
				elseif (level.t==10*30) then  fire_ball(x1, y2, 2, 0) fire_ball(x2, y3, -2, 0)-- crouch
				elseif (level.t==12*30) then  fire_ball(x2, y2, -2, 0) fire_ball(x2, y1, -2, 0)
				elseif (level.t==14*30) then  fire_ball(x1, y2, 2, 0) fire_ball(x1, y3, 2, 0) fire_ball(x2, y2, -2, 0) fire_ball(x2, y3, -2, 0)
				end
			end

			if (level.notice_wall_jump==nil and player.box.l >= 23*8) then
				stars(box_center(player.box), "new skill: wall jump")
				level.notice_wall_jump=true
			end
		end
		if (level.finished==nil and is_in_box(122*8, 11*8, player.box)) then
			stars({x=122*8, y=11*8}, "level complete!")
			level.finished=true
			level.t=0
		end

		if (level.finished==true and level.t >=3*30) load_level_2()

		level.t+=1
		printui(level.t,0,0,7)
	end

	function load_level_2()
		progress.load=load_level_2
		load_level(4*8, 30*8, nil, nil)

		player.can_jump=true
		player.can_crouch=true
		player.can_move=true
		level.t=0
	end

	function load_level_3()
		progress.load=load_level_3
		load_level(4*8, 50*8, nil, nil)

		player.can_jump=true
		player.can_crouch=true
		player.can_move=true
		level.t=0
	end


__gfx__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd0000000000000000
000660000066600000066000006660000006600000666000000000000000000000000000000000000000000000000000dddddddddddddddd0000000000000000
006e6000006e6600006e6000006e6600006e6000006e6600000000000000000000000000000000000000000000000000dddddddddddddddd0000000000000000
066e6066606ee600066e6066606ee600066e6066606ee60000dd00000000000000dd00000000000000dd00d000000000dddddddddddddddd0000000000000000
06ee6666666ee60006ee6666666ee60006ee6666666ee6000d00d0000000000000d0d000000000000d00dd0000000000ddddddddddaaaddd0000000000000000
066666c6c6666600066666c6c6666600066666c6c66666000d00d000000000000d000d00000000000d00000000000000ddddddddaaaaaadd0000000000000000
0000666666600000000066666660000000006666666000000d000000060000000d000000000000000d00000006000000dddddddaaaa0aaad0000000000000000
0000666e666000000000666e666000000000666e6660000000dd00006e60000000d000000600000000d000006e600000dddddaaaa0aaaaad0000000000000000
00000566650000d00000056665000d00000005666500d000000d00006e600000000d00006e600000000d00006e600000dddaaaaaaaaaa0ad0000000000000000
0000555155500d0000005551555000d0000055515550d0000055555566660000005555556e6600000055555566660000ddaaa0aaa0aaaa8d0000000000000000
0000555d55500d000000555d555000d00000555d5550d00005555555556c600005555555556c600005555555556c6000daaaaa0aaaaa888d0000000000000000
0000555d55500d000000555d555000d00000555d55500d000555555555666e000555555555666e000555555555666e00aaa0aaaaaa88888d0000000000000000
0000555d5550d0000000555d5550dd000000555d55500d00055555555566600005555555556660000555555555666000a0aaaaa88888888d0000000000000000
00005555555d000000005555555d000000005555555dd00005f5555f5566000005f5555f5566000005f5555f55660000aaa0a8888888888d0000000000000000
00000555550000000000055555000000000005555500000000f0000f0000000000f0000f0000000000f0000f00000000aa8888888888888d0000000000000000
000ffff5ffff0000000ffff5ffff0000000ffff5ffff000000ff000ff0000000000f000f0000000000f00000f0000000888888888888888d0000000000000000
0000000000000000666000000000000000000000000000000000000000000000cccccccccccccccc999999999999999900000000000000000000000000000000
00066000006660006ee600000000000000000000000000008800000000060000cccccccccccccccc999999999999999900000000000000000000000000000000
006e6000006e60006e6660000000000000000000000000000888668000656000cccccccccccccccc999999999999999900000000000000000000000000000000
06ee6066606ee6006666c6000000000000000000000000000666668806555600cccccccccccccccc999999999999999900000000000000000000000000000000
066666c6c6666600066666e00000000000000000000000000666668865505560ccccccccccaaaccc9999999999aaa99900000000000000000000000000000000
0000666666600000066666000000000000000000000000000888668006555600ccccccccaaaaaacc99999999aaaaaa9900000000000000000000000000000000
0000666e66600000055555000000000000000000000000008800000000656000cccccccaaaa0aaac9999999aaaa5aaa900000000000000000000000000000000
00000566650000d0f55555500000000000000000000000000000000000060000cccccaaaa0aaaaac99999aaaa5aaaaa900000000000000000000000000000000
000055515550000df55555500000000000000000000660000000000000000000cccaaaaaaaaaa0ac999aaaaaaaaaa5a900000000000000000000000000000000
0000555d5550000df55555500000000000dd0000006e60000088880000000000ccaaa0aaa0aaaa9c99aaa5aaa5aaaa0900000000000000000000000000000000
0000555d5550000d055555500d0000000d00d555506e60000889988000000000caaaaa0aaaaa999c9aaaaa5aaaaa000900000000000000000000000000000000
0000555d55500dd005555550d0000000d00555555566c600089aa98000000000aaa0aaaaaa99909caaa5aaaaaa00000900000000000000000000000000000000
00005555555dd00005555500d0000000d0555555555666e0089aa98000007000a0aaaaa99990999ca5aaaaa00000000900000000000000000000000000000000
0000055555000000f555d00d00000000d0555555555666000889988000076700aaaaa9909999999caaaaa0000000000900000000000000000000000000000000
000ffff5ffff0000f5500dd0000000000d055555555660000088880000066600aa9999999099909caa0000000000000900000000000000000000000000000000
0000000000000000f0000000000000000d0fff000fff00000000000000066600999909999999999c000000000000000900000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccaaaaaaaadddddddddd7766dd55555555555555555555555555555555555555550000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccaaaaaaaaddddddddd76dd66d65665655665556566565655656655656665565650000000000000000
3b533b333b3bb5333b3bb5335b3bb5333b533b55ccccccccaaaaaaaadddddddd77dddd6d66566665666666666666666676656657665666770000000000000000
3355333333333333333333335533333333553555ccccccccaaaaaaaadddddddd77dddddd66667676776776666557657677566667666665770000000000000000
3333333353333335533333355553333533333555ccccccccaaaaaaaadddddddd77dddddd67665666766766767656566657665665656767770000000000000000
3353335533335333333353335333533333533353ccccccccaaaaaaaadddddddd77dddd6d66666656666667766575675577566566676665750000000000000000
5333333335333533353335335533333353333355ccccccccaaaaaaaaddddddddd76dd66d65656556656567666675656577566656566567770000000000000000
3333353335533333355333335553333333333555ccccccccaaaaaaaadddddddddd7766dd66666667666666665566766677665676666766570000000000000000
3333333533335333bbbbbbbb5333533333333335ccccccccccccccccdddddddddddddddd67666567766655665555555577566575756766570000000000000000
5333333355353333bbbbbbbb5535333353333355cc7777ccccc777ccdd7777ddddd777dd67756566665665566565565677667655656556770000000000000000
3353353333333533b35bbb3b5533353333533555c777777cc777777cd777777dd777777d66666556565566666675666777566567665656770000000000000000
335533333333333333333533553333333355335577777777c777777777777777d777777765666666666566666567657576566666565665670000000000000000
33333333533333355333333555333335333333557777777777777777777777777777777765556677656656667655675677665577665567770000000000000000
3353335533335333333353335533533333533355c777777c77777777d777777d7777777766577567766667667575666677567766766656770000000000000000
5333333335333533353335335533353353333335cc7777cccc77777cdd7777dddd77777d66666556656667666556756775765666656666770000000000000000
3333353335533333355333335553333333333535ccccccccccc77cccddddddddddd77ddd66766656665566766765665676666656666566670000000000000000
5777777599999999333353339999999999944999cccccccccc4444ccddddddddd6a6a6adaaaaaaaaaaaaaaaa66566666aaaaaaaaaaaaaaaa0000000000000000
78a7777799999999553533339999999999944999cccccccccc4444ccddddddddd666666d9aaaaa9aa99aaa9a67675766aaaa99a8aa89a8aa0000000000000000
798a777799999999333335339449994499944999cccbbccccc4444ccd666666dd666666d99999999999999996656565789999999989999980000000000000000
77a9887799999999333333339944449499944999cccbbccccc4444ccd6a6a6add6a6a6ada9899aa989aa98a9766767678898a9a899a989880000000000000000
7778998799999999533333359494499999944999ccbbbbcccc4444ccd6a6a6add6a6a6ad9a9a99989998a9aa6556666689a9989989a998980000000000000000
7778998799999999353353539994494499944999ccb8bbcccc4444ccd666666dd666666d99998a8a9a99998a666565568999999999898a980000000000000000
7777887799999999555335359444444999944999cbbbb8bccc4444ccd666666dd664466d89a9a89a999aa998565555558a9a898aa89998a80000000000000000
5777777599999999555555559494499999944999cbbbbbbccc4444ccd6a6a6add664466d98999a99989a98995555555588989999899899880000000000000000
5777787599999999999999999994499999933999bbb8bbbbccccccccd6a6a6addddddddd9a99a999989999a99aa9a8a988989988999a99a80000000000000000
7777878799777799999777994994444999933999bbbbbbbbccccccccd666666dd44444dd9898998a99a9a998a989a9988a9aa9999a9a99880000000000000000
7777687897777779977777799494449493333339cc4444ccccc3ccccd666666d4444444d9a98a9a9a9999898899899998899899a988989980000000000000000
7776668777777777977777779444499993333339cc4444ccccc33cccd6a6a6ad6666666d89a999989a9a99a99a99898a88989a999a9999a80000000000000000
7766677777777777777777779994499999933999cc4444ccc3c33c3cd6a6a6ad6a666a6d98989a8a89a9899a98899a9988999a98a89a99880000000000000000
7866777797777779777777774494494493333339cc4444cc33333c33d666666d6a666a6d9a9a99999989a89aa9a9a9988989999989a989980000000000000000
7887777799777799997777799944444993333339cc4444cc33333333d666666d6664666d989989aa9a989999aa998aaa889aa8898a98a9880000000000000000
5777777599999999999779999994499999933999cc4444cc33333333d6a6a6ad6664666da9a9a989999a9989aaaaaaaa89989a9a999a99980000000000000000
d7161637161616c6d61616163716161616161616371616161616161616c6971616161616161616161616a7d616161616161616161616371616c69797a7a7a7a7
a7a7a7a7a79797a7a797a7a797a7a797a797d716161616371616161616161616c7d716161616161616161616161616371616161616161616371616a3b31616c7
d71647461647c6a7a7d6471646471616161616164616471616161647c697971616161616161616161616a7a7d61647161616161647164616c6979797a7a7a7a7
a7a797a7a79797a7a797a7a7a7a7a7a7a7a7d716471616461647161616161616c7d71616161616161616161616161646164716161616161646161616161616c7
c79696969696a7a7a7a7a6a6a6a6a616161616a69696a69696a696a6a7a7a71616161616161616161616a7a7a7a6a69696a6a6969696a6a69797979797a7a7a7
a7a7979797a797979797979797979797979797a6a696a6a6a6969696a6969696c7d716161616161616161616a69696a696a6a69696a6a69696a6a696a696a6a7
000000000000000000000000000000e4e4e4e4000000000000000000000000e4e4e4e4e4e4e4e4e4e4e400000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000e4e4e4e4e4e4e4e4e4e40000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a5b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6c5d5b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6
b6b6c595a5a495a5a5a4a4a595a4a495959595a495a4a4a4a495a5a4a4a4a595d5b6b6b6d5b6b6b6b6b6b6b6b6c5a5d5b6b6c5b6b6b6b6b6b6b6b6b6b6b6b6a5
d5747474747474747474747474747474747474747474747474c5d506747474747474747474747474747474747474747474747474747474747474747474747474
7474c59595a5a595959595a5959595a5a595a595a5a5a5a5a595a595a5a5a595d5747474d50674747474747474c595d50607c5747474747474747474747474c5
d5747484747474747485747474747474747474747474747474c5d574747474747485747474857474747474747475747474747474747474747475747474747474
7474c595a5a595a5a5a5a5a5a5a5a5a59595a5a5a5a5959595a59595959595a5d5747574d57474747474747474c595d57474c5747474747474747474747474c5
d5747474747474747474747474757474747474747474757474c5d574747474747474747474747474747474747474747474747474747474747474747474747475
7474c595959595a5a595a59595a5a5959595a595a595a5a595a5a59595a5a5a5d5957474d57474c494a4d47485c5a5d57474c5747475747474747474747474c5
d5747475740674747474077474747474747485747474747474d5d574747474747474747474747407747474747474747474747475747474748574747474747474
7474b6b6b606b6b6b607b6b6b606b6b6b607b6b6b606b6b6b607b6b6b606b6b6b6959574d57474c57474d57474c5a5d57474c5b6b6b6b6b6b6747474757474c5
d5748574747474747474747474747474747474747474747474d5d574747474747485747474747474747474747474747474747474747474747474747406747474
747474747474747474747474747474747474747474747474747474747474747474959595d57474c57474d57474c595d5747474747474747474747474747474c5
d5747474757474857474747474757474747474747474857474c5d574747474747474747474747474857474747574747485747474747474857474747474747474
747474747474747474747474747474747474747474747474747474747474747474b6b6b6d57474c57474d57574c5a5d5857474747474747474747474747574c5
d5747474747474747474747474747474740674747474747474c5d57474c4d4747474747474747474747474747474747474747474747474747474747474747474
747474747474747474747474747474747474747474747474747474747474747474747474747474c57474d57474c595d5747474747474747474747474747474c5
d5747474747474747474747474747474747474747474747474c5d57474c5d5747474747474747474747474747474747474747474747474747474747474747474
747474747474747474747474747474747474747474747474747474747474747474747474747474c57474d57474c5a5d57474c4a494a494a4d4747474747474c5
d5747474747474747474747474747474747474747474747474c5d57474c5d5747474747474747474747474747474747474747474747474747474747474747474
747474747474747474747474747474747474747474747474747474747474747474c49494947474c57474d57474c595d57474c5747474747474747474747474c5
d5747474747474747474747474747474747474747474747474c5d57474c5d5747474747474747474747474747474747474747474747474747474747474747474
7474c4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4d4959574747474c57474d57474c5a5d57474c5747474747474747474747474c5
c5747476747474747474747476747474747474747474767474b6b67474c5d574747474a474747494747474947474747474747674747474747474747474747474
7674c5959595a595959595a5a59595959595a59595959595a59595959595a595d5957476747474c57474d57474c5b6d57474c57474767474747474c0d07474c5
c574747774747474747474747774747474747474747477747474747474c5d5747474747474747474747474747474747474747774747474747474747474747474
7774c595a5a595a5a5a595a5a595a5a59595a595a595a59595a59595a5a5a595d5747477747474c574747474747474747474c57474777474747474c1d17474c5
c57487867474b494a47487748687747474747474747486748774747474c5d5747474747474747474747474747474747474878674747487747474a47474747487
8674c595959595a5a595a59595a5a5959595a595a595a5a595a5a5959595a5a5d57474868774740774747474747474747474c5748786747487747474747474c5
c5b4b4b4b4b4a595a5b5b5b5b5b5a4947474747494a494a49494a47474c5d57474747474747474747474747474747494a49494a4949494a4949495a494a4a4a4
a4a4c59595a595a59595a595a595a595a59595a595959595a5a595a59595a5a5d594a494a47474c59494a494a494a4947474c5a4a4a494a494a4a49494a49495
00000000000000000000000000000000e4e4e4e400000000000000e4e40000e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e40000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000e4e4000000000000000000e4e40000000000000000000000000000
__gff__
0001000100010001000100010000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000001010101010000000001010101010400010101010100000000010101010100000100010000000000000101010101000001000000000000000001010101010000
00000000c9ab017c88d7e9b66cec5a341df4b6a24521ec100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5162626262626262626262626262626262626262626262626251516262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626262626251
5445454545454545454545454545454545454545454545454553544545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545455345455345454545455345454545455360605345454545454545454545454545454553
5445454545454545454545454546454545454545454545454553544545454560454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545606060454545454545454545454545455360605345454545455345454545455345455345454545454545454545454545454553
5445454545454560454545454545454545454545454545454553544545564545454545455645454545454545454545454545454556454545454545454545454545564545454555454545454545554545454545454545564545454545455345455345554345455345454452525045565345454545454545454545454545454553
5445564545454545454545455645454545454556454545454553544545454545454545454545454545554545454545554545454545454545455545454545454545454545454545454545454545454545454545454545454545455545455345454545455345455345555445454545455345455545454545564545454555454553
5445454545455645454545454545455645454545455545454553544545454545454545554545454545454545454545454545456045454545454545454555454545454545454545454555454545454545454545554545454545454545455345554545455345455345455445454545455345454545454545454545454545454553
5445455545454545454555454545454545455545454545454553544545564545454545454545454545454545564545454545454555454545454556454545454545454555454545454545454545455645454545454545454545454555455345454445455356455345455445455345455345454545454545455545454545454553
5445454545454545454545454545454545454545454545454553544545454344454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545455345455445455345455345455445455345455345454545454545454545454545454553
5445454545454545454545454545454545454545454545454553544545455354454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545455345455445455345455345455445455345455345454545454545454545454545454553
5445454545454545454545454545454545454545454545454553544545455354454545454545454545454545454545454545454545454545404040454545454545454545454545454545454345454545454445454545454545454545455345455445455345455345455445455345455345454545454545454545454545454553
5445454545454545454545454545454545454545454545454553544545455354454545454545454545454545454545454545454545454545535054454545656545454545454545454545435445454545455344454545454545454545455345455445455345455345455445455345455345454545454545454545282945454553
6045654545454545454545456545456044454565454545454553544565455354454545654545454545454545654545454545454545454545535054454545757545454545454545454543505445454545455350444545454545454545456262626245455345455345655445455345456262626245454545454545383945454553
6045754545454545454545457545456054454575454545454545454575455354454545754545454545454545754545454245454545454545535054454545666645454545454545454350505445454545455350504445454545454545454545454545455345454545754545456045454545454545454545454545454545454553
6076664576454545454576456676456054457666457645454545764566765354454576664545454545457645667645425042764545457645535054457645666645764545454576435050505445454576455350505044457645454545764545457645455345457645667645455345454545457645454576454545454545454553
5040414140414140404140424041425151424242424242424242424242435150424342424342424242424342434242505050424242404042515050424042404240404040404041505050505040414040415151515151414141404140414140414041415140414040414141405141404140414140414140404041414041404151
4f4f4f4f4f242424242424242424242424242400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
797b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b797a7a7a797a7a797a7a7a7a7979797a7a797a7a797979797b7b7b7b7b7b7b7b7b7c7d7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b7b79
7d61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161797a797979797a797979797a797a797a7979797a797979796161616161616161617c7d7061616161616161616161616161616161616161616161616161616161616161617c
7d61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161617261797a7a797979797a7a7a7979797a7a7a797a7a7a797a7a796161616161616161617c7d6161616161616161616161616161616161616161616161616161616161616161617c
7d61616161617161616161616171616161616171616161616161617161616161616161616161616161617161616172616161616161616161616161797a7a7a797a7a7a7a7a7a7a7a797a7a7a7a7a7a797979796161616161617261617c7d7161616161616161616161616161616172616161616161716161616161616172617c
7d616171616161617061616161616161616161616161616161616161616161616161616172616161616161616161616161616172616161616161617a7a7a7a7a7979797a7a79797979797a79797979797a79796161616161616161617c7d6161616161616161617261616161616161616161616161616161616161616161617c
7d616161616161616161617161616161616171616161616172616161616171616161616170616161616161616161616161616161616161617161617b7b7b707b7b7b707b7b7b707b7b7b707b7b7b707b7b797b6172616161616161617c7d6161616172616161616161616161616161616161616161616161616161616161617c
7d617261616161716161616161616161616161616161616161617261616161616171616161616161616161616161617261616161616161616161617261616161616161616161616161616161616172616161616161616161616161617c7d6161616161616161616171616161616161616161616161726161616171616161617c
7d616161616161616161616161616161616161616161616170616161616161616161616161617261616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161617c7d61616c6d61616161616161616161616161616161616161616161616161616161617c
7d616161616161616161616146616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161617c7d61617c7d61616161616161616161616161616161617070616161616161616161617c
7d616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161617c7d61617c7d61616161616161616161616161616161616161616161616161616161617c
7d616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616c6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a69696969696d6161616161616161617c7d61617c7d61616161616161616161616161616161616161616161616161616161617c
7d61616361616161616161616361616161616161636161616161616161616c6161616a6161616a6161616d6161616161616161616161636161616c797a7a7a7a7a797a79797a7979797a7a79797a7979797a7d6161616163616161617c7d61617c7d616161616161616161616161616361616161616161616361612a2b61617c
__sfx__
010f00200c05300000000000c053246250c05300000000000c053000000000000000246250000000000000000c05300000000000c053246250c05300000000000c05300000000000000024625000000000000000
010f00201a0301a0001c0301a030000000000018030170301a030150001803017030150301d50010030000001a0301a0001c0301a030000000000018030170301a030150001803017030150301d5000000000000
010f0020260301a00028030260300000000000240302303026030150002403023030210301d5001000000000260301a00028030260300000000000240302303026030150002403023030210301d5002803000000
000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00010244

