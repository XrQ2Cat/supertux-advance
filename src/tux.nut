/*=========*\
| TUX ACTOR |
\*=========*/

::Tux <- class extends PhysAct {
	canJump = 16
	didJump = false //Checks if up speed can be slowed by letting go of jump
	friction = 0.05
	gravity = 0.0
	frame = 0.0
	flip = 0
	canMove = true //If player has control
	mspeed = 4 //Maximum running speed
	climbf = 0
	blinking = 0 //Invincibility frames
	startx = 0.0
	starty = 0.0
	firetime = 0
	hurt = false

	//Animations
	anim = [] //Animation frame delimiters: [start, end, speed]
	anStand = [0.0, 0.0]
	anWalk = [8.0, 15.0]
	anRun = [16.0, 23.0]
	anDive = [24.0, 25.0]
	anSlide = [26.0, 29.0]
	anHurt = [30.0, 31.0]
	anJumpU = [32.0, 33.0]
	anJumpT = [34.0, 35.0]
	anFall = [36.0, 37.0]
	anClimb = [44.0, 47.0]
	anWall = [48.0, 49.0]
	anSwim = [52.0, 55.0]

	constructor(_x, _y) {
		base.constructor(_x, _y)
		anim = anStand
		shape = Rec(x, y + 2, 5, 12, 0)
		if(gvPlayer == 0) gvPlayer = this
		startx = _x.tofloat()
		starty = _y.tofloat()
	}

	function run() {
		//Side checks
		local freeDown = placeFree(x, y + 1)
		local freeLeft = placeFree(x - 1, y)
		local freeRight = placeFree(x + 1, y)
		local freeUp = placeFree(x, y - 1)
		//Checks are done at the beginning and stored here so that they can be
		//quickly reused. Location checks will likely need to be done multiple
		//times per frame.

		//Animation states
		switch(anim) {
			case anStand:
				frame = 0.0

				if(hspeed != 0) {
					anim = anWalk
					frame = anim[0]
				}

				if(placeFree(x, y + 2)) {
					if(vspeed >= 0) anim = anFall
					else anim = anJumpU
					frame = anim[0]
				}
				break
			case anWalk:
				frame += abs(hspeed) / 8
				if(hspeed == 0) anim = anStand
				if(abs(hspeed) > 1.8) anim = anRun

				if(placeFree(x, y + 2)) {
					if(vspeed >= 0) anim = anFall
					else anim = anJumpU
					frame = anim[0]
				}
				break
			case anRun:
				frame += abs(hspeed) / 8
				if(abs(hspeed) < 1.2) anim = anWalk

				if(placeFree(x, y + 2)) {
					if(vspeed >= 0) anim = anFall
					else anim = anJumpU
					frame = anim[0]
				}
				break
			case anJumpU:
				if(frame < anim[0] + 1) frame += 0.1

				if(!freeDown) {
					anim = anStand
					frame = 0.0
				}

				if(vspeed > 0) {
					anim = anJumpT
					frame = anim[0]
				}
				break
			case anJumpT:
				frame += 0.2
				if(!freeDown) {
					anim = anStand
					frame = 0.0
				}

				if(frame > anim[1]) {
					anim = anFall
					frame = anim[0]
				}
				break
			case anFall:
				frame += 0.15
				if(!freeDown) {
					anim = anStand
					frame = 0.0
				}
				break
			case anClimb:
				if(frame < anim[0]) {
					frame = anim[0]
					climbf = 1
				}

				if(frame > anim[1]) {
					frame = anim[1]
					climbf = -1
				}

				frame += (vspeed / 4) * climbf
				break
			case anWall:
				frame += 0.2
				vspeed = 0

				if(floor(frame) > anim[1]) {
					vspeed = -3.2
					if(flip == 0) hspeed = 2
					else hspeed = -2
					anim = anJumpU
					frame = anim[0]
				}
				break
			case anDive:
				frame += 0.25

				if(floor(frame) >= anim[1]) {
					anim = anSlide
					frame = anim[0]
				}
				break
			case anSlide:
				frame = getFrames() / 8
				break
			case anHurt:
				frame += 0.1
				if(floor(frame) > anim[1]) {
					anim = anStand
					frame = anim[0]
				}
		}

		frame = wrap(frame, anim[0], anim[1])

		if(!inWater(x, y)) {
			//Sliding acceleration
			if(anim == anDive || anim == anSlide) {
				if(!freeDown && abs(hspeed) < 6) {
					if(placeFree(x + 4, y + 2)) hspeed += 0.1
					if(placeFree(x - 4, y + 2)) hspeed -= 0.1

					if(placeFree(x + 4, y + 4)) {
						hspeed += 0.1
						vspeed += 0.5
					}

					if(placeFree(x - 4, y + 4)) {
						hspeed -= 0.1
						vspeed += 0.5
					}
				}

				if(!keyDown(config.key.down) || hspeed == 0) anim = anWalk
			}

			if(anim != anClimb && anim != anWall) {
				if(hspeed > 0.1) flip = 0
				if(hspeed < -0.1) flip = 1
			}

			//Controls
			if(!placeFree(x, y + 2)) canJump = 15
			else if(canJump > 0) canJump--
			if(canMove) {
				if(keyDown(config.key.run)) mspeed = 2
				else if(keyDown(config.key.sneak)) mspeed = 0.5
				else mspeed = 1

				if(keyDown(config.key.right) && hspeed < mspeed && anim != anWall && anim != anSlide && anim != anHurt) hspeed += 0.1
				if(keyDown(config.key.left) && hspeed > -mspeed && anim != anWall && anim != anSlide && anim != anHurt) hspeed -= 0.1

				//Jumping
				if(keyPress(config.key.jump) && canJump > 0) {
					vspeed = -3.8
					didJump = true
					canJump = 0
					if(anim == anDive || anim == anSlide) {
						anim = anJumpU
						frame = anim[0]
					}
					playSound(sndJump, 0)
				}

				if(keyRelease(config.key.jump) && vspeed < 0 && didJump)
				{
					didJump = false
					vspeed /= 2
				}

				//Wall jumping
				if(freeDown && keyDown(config.key.jump))
				{
					if(!placeFree(x - 2, y) && keyPress(config.key.right)) {
						flip = 0
						anim = anWall
						frame = anim[0]

					}

					if(!placeFree(x + 2, y) && keyPress(config.key.left)) {
						flip = 1
						anim = anWall
						frame = anim[0]
					}
				}

				//Going into slide
				if(!freeDown && keyDown(config.key.down) && anim != anDive && anim != anSlide && anim != anJumpU && anim != anJumpT && anim != anFall && anim != anHurt) {
					if((freeRight && freeDown) || hspeed >= 2) {
						anim = anDive
						frame = anim[0]
						flip = 0
						playSound(sndSlide, 0)
					}

					if((freeLeft && freeDown) || hspeed <= -2) {
						anim = anDive
						frame = anim[0]
						flip = 1
						playSound(sndSlide, 0)
					}
				}
			}

			//Movement
			if(!freeDown) {
				if(anim == anSlide) {
					if(hspeed > 0) hspeed -= friction / 3
					if(hspeed < 0) hspeed += friction / 3
					if(abs(hspeed) < 1) anim = anStand
				} else {
					if(hspeed > 0) hspeed -= friction
					if(hspeed < 0) hspeed += friction
				}
			}

			if(abs(hspeed) < friction) hspeed = 0.0
			if(freeDown && vspeed < 3) vspeed += gravity
			if(!freeUp && vspeed < 0) vspeed = 0.0 //If Tux bumped his head
			if(!freeDown && vspeed >= 0) {
				//If Tux hits the ground while sliding
				if(anim == anSlide) {
					if(flip) hspeed -= vspeed / 5
					else hspeed += vspeed / 5
				} else vspeed = 0.0
			}

			//Gravity cases
			gravity = 0.11
			if(anim == anClimb || anim == anWall) gravity = 0

			if(placeFree(x, y + vspeed)) y += vspeed
			else {
				vspeed /= 2
				if(abs(vspeed) > 1) vspeed -= vspeed / abs(vspeed)
				if(placeFree(x, y + vspeed)) y += vspeed
			}

			if(hspeed != 0) {
				if(placeFree(x + hspeed, y)) { //Try to move straight
					for(local i = 0; i < 2; i++) if(!freeDown && placeFree(x + hspeed, y + 1)) {
						y += 1
					}
					x += hspeed
				} else {
					local didstep = false
					for(local i = 1; i <= 4; i++){ //Try to move up hill
						if(placeFree(x + hspeed, y - i)) {
							x += hspeed
							y -= i
							didstep = true
							break
						}
					}

					//If no step was taken, slow down
					if(didstep == false && abs(hspeed) >= 1) hspeed -= (hspeed / abs(hspeed))
					else if(didstep == false && abs(hspeed) < 1) hspeed = 0
				}
			}

			if(gvMap.w > 320) {
				if(x < 4) x = 4

				if(x > gvMap.w - 4) x = gvMap.w - 4
			} else x = wrap(x, 0, gvMap.w)

			shape.setPos(x, y + 2)
			if(y > gvMap.h + 16) {
				deleteActor(id)
				gvPlayer = 0
				newActor(TuxDie, x, gvMap.h)
				game.health = 0
			}

			//Attacks
			if(firetime > 0) firetime--
			if(keyPress(config.key.shoot) && anim != anSlide && anim != anHurt && firetime == 0) {
				switch(game.tuxwep) {
					case 0: //Noot
						break
					case 1: //Fireball
						local c = actor[newActor(Fireball, x, y - 4)]
						if(!flip) c.hspeed = 3
						else c.hspeed = -3
						firetime = 60
						playSound(sndFireball, 0)
				}
			}
		}
		else { //While swimming

		}

		//Hurt
		if(hurt) {
			hurt = false
			if(blinking == 0) {
				blinking = 120
				anim = anHurt
				frame = anim[0]
				if(game.health > 0) game.health--
				if(game.health == 0) {
					deleteActor(id)
					gvPlayer = 0
					newActor(TuxDie, x, y)
				}
				playSound(sndHurt, 0)
			}
		}
		if(blinking > 0) blinking--

		//Draw
		if((blinking / 2) % 2 == 0 || anim == anHurt) drawSpriteEx(sprTux, floor(frame), floor(x - camx), floor(y - camy), 0, flip, 1, 1, 1)
	}

	function _typeof(){ return "Tux" }
}

::Fireball <- class extends PhysAct {
	constructor(_x, _y) {
		base.constructor(_x, _y)

		shape = Rec(x, y, 3, 3, 0)
	}

	function run() {
		if(!placeFree(x, y + 1)) vspeed = -1.2
		if(!placeFree(x, y - 1)) vspeed = 1
		if(!placeFree(x + 1, y) || !placeFree(x - 1, y)) {
			if(placeFree(x + 1, y) || placeFree(x - 1, y)) vspeed = -1
			else deleteActor(id)
		}
		vspeed += 0.1

		if(placeFree(x + hspeed, y)) x += hspeed
		else if(placeFree(x + hspeed, y - 2)) {
			x += hspeed
			y += -2
			vspeed = -1
		} else deleteActor(id)

		if(placeFree(x, y + vspeed)) y += vspeed
		else vspeed /= 2

		if(y > gvMap.h) deleteActor(id)

		if(hspeed > 0) drawSpriteEx(sprFireball, getFrames() / 2, floor(x - camx), floor(y - camy), 0, 0, 1, 1, 1)
		else drawSpriteEx(sprFireball, getFrames() / 2, floor(x - camx), floor(y - camy), 0, 1, 1, 1, 1)

		shape.setPos(x, y)
	}

	function _typeof () {return "Fireball"}
}

::TuxDie <- class extends Actor {
	vspeed = -3.0

	function run() {
		vspeed += 0.05
		y += vspeed
		if(y > camy + 320) {
			startPlay(gvMap.name)
			deleteActor(id)
		}
		drawSprite(sprTux, wrap(getFrames() / 15, 50, 51), floor(x - camx), floor(y - camy))
	}
}