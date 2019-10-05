pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-->8
--> MAIN
    function _init()
        init_player()
        init_camera()
    end

    function _update()
        update_bodies()
        update_props()
        update_player()
		update_camera()
		if (btnp(5)) then
			fire_ball(16, 88, 5,-7)
		end
    end

    function _draw()
        draw_camera()
        draw_map()
		draw_particles()
        draw_player()
        draw_props()
		--print(str_num(player.body.speed.x).." "..str_num(player.body.speed.y), 0, 10, 7)

		debug()
    end

	debug_mode=false
	function debug()
		if(stat(31)=="b" or btnp(4)) debug_mode = not debug_mode
		if (debug_mode)then
			draw_clear_box(abs_box(67, 87, 127, 127))
			printui('ram: '..stat(0), 69, 89, 4)
			printui('cpu1: '..stat(1), 69, 99,4)
			printui('npar: '..nparts, 69, 109,4)
		end
	end

-->8 PLAYER
    player={}

    function init_player()
		player={
            body=new_body(64, 64, 15, 15, 0b010, 0b101),
			cols=new_check_cols(),
			anim={
				idle=create_anim_w_by_h({0, 2, 4}, 2, 2, false, false, .5),
				move_right=create_anim_w_by_h({6, 8, 10}, 2, 2, false, false, .5),
				move_left=create_anim_w_by_h({6, 8, 10}, 2, 2, true, false, .5),
				wall_right=create_anim_w_by_h({34}, 2, 2, true, false, 0),
				wall_left=create_anim_w_by_h({34}, 2, 2, false, false, 0),
				jump=create_anim_w_by_h({32}, 2, 2, false, false, 0),
				crouch_right=create_anim_w_by_h({36}, 2, 2, false, false, 0),
				crouch_left=create_anim_w_by_h({36}, 2, 2, true, false, 0)
			},
			crouch=false
        }
	end

    function update_player()
		move_player()
		old_cols = cpy(player.cols)
		check_cols(player.body.box, player.cols, player.body.col_with)
		if (not old_cols.bools.b and player.cols.bools.b) then
			b=box_center(player.body.box)
			air_blow(b.x, b.y+8, 10, 1, 5)
		end
	end

    function move_player()
        dx=(btn(0) and-1 or 0)+(btn(1) and 1 or 0)
        player.body.speed.x += dx*1.5
		player.crouch=(player.cols.bools.b and btn(3))
		if (btnp(2)) then
			if (player.cols.bools.b) then
				b=box_center(player.body.box)
				air_blow(b.x, b.y+8, 10, 1, 10)
				player.body.speed.y += -10
			elseif (not player.cols.bools.b and player.cols.bools.r and not player.cols.bools.l) then
				b=box_center(player.body.box)
				air_blow(b.x+8, b.y, 1, 10, 10)
				player.body.speed.x += -15
				player.body.speed.y += -20
			elseif (not player.cols.bools.b and not player.cols.bools.r and player.cols.bools.l) then
				b=box_center(player.body.box)
				air_blow(b.x-6, b.y, 1, 10, 10)
				player.body.speed.x += 15
				player.body.speed.y += -20
			end
		end
		if (player.cols.bools.b and dx == 0) then
			player.body.speed.x *= 0.5
		end
		if (not player.cols.bools.b and player.body.speed.y > 0 and (player.cols.bools.l or player.cols.bools.r)) then
			player.body.speed.y *= 0.5
		end
		
    end

	function draw_player()
		x = player.body.box.l y = player.body.box.t
		if (player.cols.bools.b) then
			if (player.body.speed.x >= 1) then draw_anim(x, y, player.anim.move_right)
			elseif (player.body.speed.x <= -1) then draw_anim(x, y, player.anim.move_left)
			elseif (player.crouch) then 
				if (player.body.speed.x<0) then draw_anim(x, y, player.anim.crouch_left)
				else draw_anim(x, y, player.anim.crouch_right) end
			else draw_anim(x, y, player.anim.idle) end
		elseif (player.cols.bools.l) then draw_anim(x, y, player.anim.wall_left)
		elseif (player.cols.bools.r) then draw_anim(x, y, player.anim.wall_right)
		else draw_anim(x, y, player.anim.jump) end
		
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
		blood(box_center(player.body.box))
		remove_body(player.body)
		init_player()
	end

-->8
-->8 CAMERA AND MAP
	cam={}
    function init_camera()
		cam={
			x=0,y=0,
			bounds=abs_box(60,60,68,68),
			shake = {x=0, y=0, t=0, fx=0, fy=0}
		}
	end

    function update_camera()
		cam_focus(player.body.box)
		if (cam.shake.t > 0) then
			cam.x += cam.shake.x * cos(3.1415*0.5 * cam.shake.fx * cam.shake.t)
			cam.y += cam.shake.y * sin(3.1415*0.5 * cam.shake.fy * cam.shake.t)
			cam.shake.t-=1/30
		else
			cam.shake.x=0 cam.shake.fx=0
			cam.shake.y=0 cam.shake.fy=0
		end
	end

	function draw_camera()
		camera(cam.x,cam.y)
		cls()
	end

	function cam_shake(x, y, t, fx, fy)
		cam.shake.x=max(x, cam.shake.x)
		cam.shake.y=max(y, cam.shake.y)
		cam.shake.t=max(t, cam.shake.t)
		cam.shake.fx=max(fx, cam.shake.fx)
		cam.shake.fy=max(fy, cam.shake.fy)
	end

	function cam_move_to(x,y)
		cam.x=min(896,max(0,x))
		cam.y=min(128,max(0,y))
		camera(cam.x,cam.y)
	end

	function cam_focus(b)
		cam_move_to(b.l-64,b.t-64)
	end

	function cam_follow(b)
		dx=0
		dy=0

		c=box_s2w(cam.bounds)

		if(b.l<c.l) dx+=b.l-c.l
		if(b.r>c.r) dx+=b.r-c.r
		if(b.t<c.t) dy+=b.t-c.t
		if(b.b>c.b) dy+=b.b-c.b

		cam_move_to(cam.x+dx,cam.y+dy)
	end

--> MAP
    function draw_map()
		mx=flr(cam.x/8)
		my=flr(cam.y/8)
		map(mx,my,mx*8,my*8,17,17)
	end

-->8
--> COLLISIONS AND PHYSICS
--> COLLISIONS
	col_map={}

	function col_add_box(b, m)
		for x=b.l,b.r,1 do
			col_map[flr(x).." "..b.t]=m
			col_map[flr(x).." "..b.b]=m	
			if(x==b.l or x==b.r)then
				for y=b.t+1,b.b-1,1 do
					col_map[flr(x).." "..flr(y)]=m
				end
			end
		end
	end

	function col_move_box(b, fm, m)
		if(flr(fm.x)==0 and flr(fm.y)==0) return b
		newb=cpy(b)
		newb.l+=flr(fm.x) newb.r+=flr(fm.x)
		newb.t+=flr(fm.y) newb.b+=flr(fm.y)
		col_free_box(b)
		col_add_box(newb, m)
		return newb
	end

	function col_get_mask(x, y)
		map_mask = fget(mget(flr(x/8),flr(y/8)))
		col_mask = col_map[flr(x).." "..flr(y)]
		if (col_mask==nil) col_mask=0
		return bor(col_mask, map_mask)
	end

	function col_get_point(x,y,mask)
		m = col_get_mask(x, y)
		return band(m, mask)!=0
	end

	function col_free_box(b)
		col_add_box(b, nil)
	end

	function col_free_move_point(x, y, dx, dy, cm)
		b=box(x,y,0,0)
		return col_free_move(b, dx, dy, cm)
	end

	function col_free_move(b,dx,dy,cm)
		fm={x=dx,y=dy}
		f={x=false,y=false}
		if(dx>0) x=b.r+dx
		if(dx<0) x=b.l+dx
		while true do
			if abs(fm.x)<=0 then break end
			if f.x then break end
			for y=b.t,b.b,1 do
				f.x=(not col_get_point(x,y,cm))
				if not f.x then break end
			end
			if abs(fm.x)<=0 then break end
			if f.x then break end
			x-=sgn(dx)
			fm.x-=sgn(dx)
		end
		if(dy>0) y=b.b+dy
		if(dy<0) y=b.t+dy
		while true do
			if abs(fm.y)<=0 then break end
			if f.y then break end
			for x=b.l,b.r,1 do
				f.y=(not col_get_point(x,y,cm))
				if not f.y then break end
			end
			if abs(fm.y)<=0 then break end
			if f.y then break end
			y-=sgn(dy)
			fm.y-=sgn(dy)
		end
		if abs(fm.x)>0 and abs(fm.y)>0 then
			if(fm.x>0)then x=b.r+fm.x else x=b.l+fm.x end
			if(fm.y>0)then y=b.b+fm.y else y=b.t+fm.y end
			while true do
				if(not col_get_point(x,y,cm)) return fm
				if (sgn(dx)*fm.x<=0 or sgn(dy)*fm.y<=0) return {x=0,y=0}
				x-=sgn(dx)*dx*0.1
				y-=sgn(dy)*dy*0.1
				fm.x-=sgn(dx)*dx*0.1
				fm.y-=sgn(dy)*dy*0.1
			end
		end
		return fm
	end

	function new_check_cols()
		return {bools={b=false, l=false, r=false, t=false}, masks={b=0, l=0, r=0, t=0}}
	end

	function check_cols(b, c, m)
		y=b.t-1
		for x=b.l,b.r,1 do
			c.bools.t=col_get_point(x,y,m)
			c.masks.t=col_get_mask(x,y)
			if(c.b) break
		end
		y=b.b+1
		for x=b.l,b.r,1 do
			c.bools.b=col_get_point(x,y,m)
			c.masks.b=col_get_mask(x,y)
			if(c.b) break
		end
		x=b.l-1
		for y=b.t,b.b,1 do
			c.bools.l=col_get_point(x,y,m)
			c.masks.l=col_get_mask(x,y)
			if(c.l) break
		end
		x=b.r+1
		for y=b.t,b.b,1 do
			c.bools.r=col_get_point(x,y,m)
			c.masks.r=col_get_mask(x,y)
			if(c.r) break
		end
	end

--> PHYSICS
    bodies={}
    gravity={x=0,y=1}

	function update_bodies()
		for i=1,#bodies,1 do
            bodies[i].speed.x+=gravity.x
            bodies[i].speed.y+=gravity.y
			clamp_speed(bodies[i])
            move_body(bodies[i])
		end
	end

	function new_body(x,y,sx, sy, m, cm)
		body={
			box=box(x,y,sx,sy),
			speed={x=0,y=0},
			mask=m,
			col_with=cm
		}
		col_add_box(body.box, body.mask)
        add(bodies, body)
		return body
	end

	function remove_body(body)
		col_free_box(body.box)
		del(bodies, body)
	end

	function clamp_speed(body)
		if (abs(body.speed.x)>7) body.speed.x = sgn(body.speed.x)*7
        if (abs(body.speed.y)>7) body.speed.y = sgn(body.speed.y)*7
	end

	function move_body(b)
		fm=col_free_move(b.box, b.speed.x, b.speed.y, b.col_with)
		b.speed.x = fm.x
		b.speed.y = fm.y
		b.box=col_move_box(b.box, fm, b.mask)
	end

-->8
--> EFFECTS
particles={}
nparts = 0

function create_raw_particles(x, y, lt, np, draw)
	pcl={
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
	create_raw_particles(x, y, lt, np, draw)
	init(pcl)
end
 

function draw_particles()
	printui(''..#particles, 10, 10)
	for pcl in all(particles) do
		if (pcl.timer >= pcl.lifetime and pcl.lifetime > 0) then
			nparts -= pcl.npart
			del(particles, pcl)
		else
			pcl.draw(pcl)
		end
	end
end

function explosion(pos, radius, blow, np)
	pcl = create_raw_particles(pos.x, pos.y, 0.3, np, draw_explosion)
	pcl.radius = radius
	pcl.blow = blow
	init_explosion(pcl)
end

function init_explosion(pcl)
	pcl.pcs = {}
	for i=1,pcl.npart,1 do
		a=rnd(6.28)
		pc = {
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
		p = 1-(pc.lt / pcl.lifetime)
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
		pc.s = col_free_move_point(pc.x, pc.y, pc.s.x, pc.s.y, 0b11)		
		pc.x+=pc.s.x
		pc.y+=pc.s.y
		pc.lt-=1/30
		if (pc.lt<=0) del(pcl.pcs, pc)
	end
	if #pcl.pcs==0 then
		pcl.timer=pcl.lifetime+1
	end
end

function blood(pos)
	create_particles(pos.x, pos.y, .5, 15, init_blood, draw_blood)
end

function init_blood(pcl)
	pcl.pcs = {}
	for i=1,pcl.npart,1 do
		a=rnd(6.28)
		pc = {
			x=pcl.x, y=pcl.y,
			s={x=cos(a)*rnd(8),	y=-abs(sin(a))-2-rnd(8)},
			lt=pcl.lifetime*(rnd(0.4)+1)
		}
		add(pcl.pcs, pc)
	end
end

function draw_blood(pcl)
	for pc in all(pcl.pcs) do
		p = (pc.lt / pcl.lifetime)
		circfill(pc.x, pc.y,2.5*p,8)
		pc.s.y += gravity.y
		pc.s = col_free_move_point(pc.x, pc.y, pc.s.x, pc.s.y, 0b1)
		if (abs(pc.s.y)<0.5) pc.s.x*=0.7
		pc.x+=pc.s.x
		pc.y+=pc.s.y
		pc.lt-=1/30
		if (pc.lt<=0) del(pcl.pcs, pc)
	end
	if #pcl.pcs==0 then
		pcl.timer=pcl.lifetime+1
	end
end

function air_blow(x, y, sx, sy, n)
	pcl = create_raw_particles(x, y, .15, n, draw_air_blow)
	pcl.sx = sx
	pcl.sy = sy
	init_air_blow(pcl)
end

function init_air_blow(pcl)
	pcl.pcs = {}
	for i=1,pcl.npart,1 do
		pc = {
			x=pcl.x, y=pcl.y,
			s={x=pcl.sx*(rnd(2)-1), y=pcl.sy*(rnd(2)-1)},
			lt=pcl.lifetime*(rnd(.5)+.75)
		}
		add(pcl.pcs, pc)
	end
end

function draw_air_blow(pcl)
	for pc in all(pcl.pcs) do
		p = (pc.lt / pcl.lifetime)
		if (p < 0.4) then circ(pc.x, pc.y,0,6)
		else circ(pc.x, pc.y,0,7) end
		pc.s.x*=0.5
		pc.s.y*=0.5
		pc.s = col_free_move_point(pc.x, pc.y, pc.s.x, pc.s.y, 0b1)
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
		i = flr((anim.dt%#anim.sprites)+1)
		spr(anim.sprites[i], x, y, anim.w, anim.h, anim.flip_x, anim.flip_y)
		printui(i, 10 ,10, 7)
		anim.dt+=anim.speed
	end

	function reset_anim(anim)
		anim.dt = 0
	end

--> PROPS
	props = {}

	function create_prop(update, draw)
		prop = {update=update, draw=draw}
		add(props, prop)
		return prop
	end

	function update_props()
		for prop in all(props) do
			prop.update(prop)
		end
	end

	function draw_props()
		for prop in all(props) do
			prop.draw(prop)
		end
	end

	function fire_ball(x, y, sx, sy)
		fb = create_prop(update_fire_ball, draw_fire_ball)
		fb.body=new_body(x, y, 6, 6, 0b100, 0b11)
		fb.body.speed.x = sx
		fb.body.speed.y = sy
		fb.cols = new_check_cols()
	end

	function update_fire_ball(fb) 
		check_cols(fb.body.box, fb.cols, fb.body.col_with)
		try_kill_player(fb.cols)
		for _,c in pairs(fb.cols.bools) do
			if (c) then
				explosion(box_center(fb.body.box), 6, 1.5, 10)
				remove_body(fb.body)
				del(props, fb)
				cam_shake(1, 1, .1, 5, 5)
				return
			end
		end
		explosion(box_center(fb.body.box), 12, 1, 5)
	end

	function draw_fire_ball(fb)
		spr(54, fb.body.box.l, fb.body.box.t)
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

	function draw_clear_box(b)
		clear_box(box_s2w(add_box(abs_box(1,1,-1,-1),b)))
		draw_box(box_s2w(b))
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

--> UTILS
	function str_num(n,d)
		str=''..n
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
		new={}
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
		r=1
		for i=1,b,1 do
			r*=a
		end
		return r
	end



__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000006660000006600000666000000660000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000
006e6000006e6600006e6000006e6600006e6000006e660000000000000000000000000000000000000000000000000000000000000000000000000000000000
066e6066606ee600066e6066606ee600066e6066606ee60000dd00000000000000dd00000000000000dd00d00000000000000000000000000000000000000000
06ee6666666ee60006ee6666666ee60006ee6666666ee6000d00d0000000000000d0d000000000000d00dd000000000000000000000000000000000000000000
066666c6c6666600066666c6c6666600066666c6c66666000d00d000000000000d000d00000000000d0000000000000000000000000000000000000000000000
0000666666600000000066666660000000006666666000000d000000060000000d000000000000000d0000000600000000000000000000000000000000000000
0000666e666000000000666e666000000000666e6660000000dd00006e60000000d000000600000000d000006e60000000000000000000000000000000000000
00000566650000d00000056665000d00000005666500d000000d00006e600000000d00006e600000000d00006e60000000000000000000000000000000000000
0000555155500d0000005551555000d0000055515550d0000055555566660000005555556e660000005555556666000000000000000000000000000000000000
0000555d55500d000000555d555000d00000555d5550d00005555555556c600005555555556c600005555555556c600000000000000000000000000000000000
0000555d55500d000000555d555000d00000555d55500d000555555555666e000555555555666e000555555555666e0000000000000000000000000000000000
0000555d5550d0000000555d5550dd000000555d55500d0005555555556660000555555555666000055555555566600000000000000000000000000000000000
00005555555d000000005555555d000000005555555dd00005f5555f5566000005f5555f5566000005f5555f5566000000000000000000000000000000000000
00000555550000000000055555000000000005555500000000f0000f0000000000f0000f0000000000f0000f0000000000000000000000000000000000000000
000ffff5ffff0000000ffff5ffff0000000ffff5ffff000000ff000ff0000000000f000f0000000000f00000f000000000000000000000000000000000000000
00066000006660006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006e6000006e60006ee6000000000000000000000000000000000088000600000000000000000000000000000000000000000000000000000000000000000000
06ee6000006ee6006e66600000000000000000000000000000000880006560000000000000000000000000000000000000000000000000000000000000000000
06666066606666006666c60000000000000000000000000008666660065556000000000000000000000000000000000000000000000000000000000000000000
000666c6c6660000066666e000000000000000000000000088666888655055600000000000000000000000000000000000000000000000000000000000000000
00006666666000000666660000000000000000000000000008666660065556000000000000000000000000000000000000000000000000000000000000000000
0000666e666000000555550000000000000000000000000000000880006560000000000000000000000000000000000000000000000000000000000000000000
00000566650000d0f555555000000000000000000000000000000088000600000000000000000000000000000000000000000000000000000000000000000000
000055515550000df555555000000000000000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000555d5550000df55555500000000000dd0000006e600000888800000000000000000000000000000000000000000000000000000000000000000000000000
0000555d5550000d055555500d0000000d00d555506e600008899880000000000000000000000000000000000000000000000000000000000000000000000000
0000555d55500dd005555550d0000000d00555555566c600089aa980000000000000000000000000000000000000000000000000000000000000000000000000
00005555555dd00005555500d0000000d0555555555666e0089aa980000070000000000000000000000000000000000000000000000000000000000000000000
0000055555000000f555d00d00000000d05555555556660008899880000767000000000000000000000000000000000000000000000000000000000000000000
000ffff5ffff0000f5500dd0000000000d0555555556600000888800000666000000000000000000000000000000000000000000000000000000000000000000
0000000000000000f0000000000000000d0fff000fff000000000000000666000000000000000000000000000000000000000000000000000000000000000000
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
__gff__
0001000100010001000100010000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000001010101010000000000000000000000010101010100000000000000000000000000010000000000000000000000000000000000000000000000000000000000
00000000c9ab017c88d7e9b66cec5a341df4b6a24521ec100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
51626262626262626262626262626251797b7b7b7b7b7b7b7b7b7b7b7b7b7b7a5a6b6b6b6b6b6b6b6b6b6b6b6b6b6b5a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544545454545454545454545454545537d61616161616161616161616161617c5d47474747474747474747474747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544545454545454545454545454645537d61616161616161616161616161617c5d47474847474747475847474747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544545454545456045454545454545537d61616161617161617261616171617c5d47474747474747474747474757475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544556454545454545454545564545537d61617161616161706161616161617c5d47475747604747474770474747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544545454545564545454545454545537d61616161726161616161716161617c5d47584747474747474747474747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544545554545454545455545454545537d61726161616171616161616172617c5d47474757474758474747474757475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544545454545454545454545454545537d61616161616161616161616161617c5d47474747474747474747474747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544545454545454545454545454545537d61616161616161616161614661617c5d47474747474747474747474747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544545454545454545454545454545537d61616161616161616161616161617c5d47474747474747474747474747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544545454545454545454545454545537d61616161616161616161616161617c5d47474747474747474747474747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544565454545454041454545654545537d61616361616161616161616361617c5d47476747474747474747476747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
544575454545455354454545754545537d6161736161616a6a6161617361617c5d47477747474747474747477747475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
547666457645455354457645667645537d61746461746a7a7a6a74616474617c5d47786847474b494a4778476878475c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
504041404140415050414042404142507969696969697a7a7a6a6a6a6a6a6a7a5a4b4b4b4b4b5a595a5b5b5b5b5b5b5a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
