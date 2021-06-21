// EnterOrbitKerbin01.ks
// kOS Auto launch.
// Attempt auto launch and orbit.

// Objectives:
// 	[+] Fly straight up on launch.
//  [+] Set azimuth and throttle as the vessel passes each altitude in the launch profile.
// 	[+] Continue to pitch 10 degrees down for each 100m/s of velocity.
//  [+] Create orbit manoevour node
//  [+] Execute orbit manoevour node.
//
// Test and verification:
//  [ ] Craft enters orbit at required altitude.

clearscreen.
set throt to 1.0.
lock throttle to throt. // 1.0 is the max, 0.0 is idle.
set orbitAltitude to 100600.
set targetRadius to orbitAltitude + KERBIN:radius.
print "EnterOrbitKerbin01.ks: Target alt:" + round(orbitAltitude/1000, 3) + "km" at(0,0).
set col to 0.
set line to 1.

// For safety reasons...
IF STATUS = "PRELAUNCH" {

	print "Counting down:" at(col, line).
	from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
		print "..." + countdown + " " at(col + 15, line).
		wait 1.
	}
	set line to line + 1.
	set stageLine to line.
	//This is a trigger that constantly checks to see if our thrust is zero.
	//If it is, it will attempt to stage and then return to where the script
	//left off. The PRESERVE keyword keeps the trigger active even after it
	//has been triggered.
	WHEN MAXTHRUST = 0 THEN {
		if (stage:ready) {
			print "Staging " + stage:NUMBER at(col, stageLine).
			STAGE.
			print " staged." at (col + 11, stageLine).
		}
		if (stage:NUMBER > 0) {
			PRESERVE.
		}
	}.

	set mySteer to HEADING(90,90). // 90 degrees = East. 90 = straight up.
	lock steering to mySteer.

	set ctrlVel to 100.
	set curAzimuth to 90.
	set maxVel to 800.

	set line to line + 1.

	function SetHeadingAndThrottle {
		parameter azimuth.
		parameter t.
		set mySteer to HEADING(90, azimuth).
		set throt to t.
		print "Pitching to " + azimuth + " deg.  Throttle to " + round(throt, 2) at (col, line).
	}

	function PrintNextEntry {
		print "Next: " + azList[idx][1] + "deg, throttle " + round(azList[idx][2],2) + " at " + azList[idx][0] + "m" at(0,line + 1).		
	}

	// Launch azimuth profile (alt, az, throttle)
	set azList to list(
		list(  250, 85, 1.0),
		list( 1000, 80, 1.0),
		list( 6000, 75, 1.0),
		list(15000, 70, 0.75),
		list(20000, 60, 0.75),
		list(33000, 45, 0.60),
		list(45000, 10, 0.50),
		list(55000,  0, 0.50),
		list(orbitAltitude, 0, 0)
	).
	set idx to 0.
	PrintNextEntry().
	until APOAPSIS > orbitAltitude {
		// For the initial ascent, we want our steering to be straight
		// up and rolled due east.
		if (ship:altitude) > azList[idx][0] {
			SetHeadingAndThrottle(azList[idx][1], azList[idx][2]).
			set throt to azList[idx][2].
			set idx to idx + 1.
			PrintNextEntry().
		}
		print "Status: Alt: " + round(ship:altitude) + " Apoapsis: " + round(SHIP:APOAPSIS, 0) at (0,line + 2).
	}

	set col to 0.
	set line to line + 3.

	PRINT round(APOAPSIS / 1000, 2) + "km apoapsis reached, cutting throttle" at(col, line).
	set line to line + 1.

	//At this point, our apoapsis is above 100km and our main loop has ended. Next
	//we'll make sure our throttle is zero and that we're pointed prograde
	LOCK THROTTLE TO 0.

	wait until ALT:RADAR > 70000.

	// The atmosphere drag may have lowered the apoapsis, so correct it.
	if APOAPSIS < orbitAltitude {
		Print "Adjusting Ap to " + orbitAltitude at(col, line).
		set mySteer to SHIP:PROGRADE.
		wait 1.
	
		until APOAPSIS >= orbitAltitude {
			LOCK THROTTLE TO 0.1.
		}
		set line to line + 1.
	}
	LOCK THROTTLE TO 0.

	// Now to set up the maneuver node for orbit...
	Print "Time: " + round(TIME:Seconds, 2) + ". Ship AP ETA: " + round(ETA:APOAPSIS, 2) at (col, line).
	Print "Current velocity: " + round(SHIP:VELOCITY:ORBIT:MAG) at(col, line + 1).
	Print "Velocity at AP: " + round(VELOCITYAT(SHIP, TIME:Seconds + ETA:APOAPSIS):ORBIT:MAG)at(col, line + 2).
	// v = sqrt(g*m/r) => v = sqrt(mu/r) where r is the targetRadius in metres.
	SET targetV to sqrt(KERBIN:MU / targetRadius).
	SET mnDeltaV to targetV - VELOCITYAT(SHIP, TIME:Seconds + ETA:APOAPSIS):ORBIT:MAG. 
	Print "DeltaV: " + mnDeltaV at(col, line + 3).
	SET timeToApoapsis to ETA:APOAPSIS.
	SET orbitNode to NODE(TimeSpan(timeToApoapsis), 0, 0, mnDeltaV).
	ADD orbitNode.
	// How to execute?
	
	// As per the tutorial http://ksp-kos.github.io/KOS_DOC/tutorials/exenode.html
	set nd to nextnode.
	//print out node's basic parameters - ETA and deltaV
	print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag) at(col, line + 4).
	
	// Calculate the ship's max acceleration
	set max_acc to ship:maxthrust / ship:mass.
	
	// Now we just need to divide deltav:mag by our ship's max acceleration
	// to get the estimated time of the burn.
	//
	// Please note, this is not exactly correct as it does not factor fuel mass loss
	// during flight.

	set burn_duration to nd:deltav:mag/max_acc.
	print "Crude Estimated burn duration: " + round(burn_duration) + "s" at(col, line + 5).

	set line to line + 6.

	// Wait until before the eta - (1/2 the burn time + 60s to allow for slow turning.
	wait until nd:eta <= (burn_duration/2 + 60).

	// Time to line up the ship to the deltav vector.
	set np to nd:deltav. //points to node, don't care about the roll direction.
	lock steering to np.

	// now we need to wait until the burn vector and ship's facing are aligned
	wait until vang(np, ship:facing:vector) < 0.25.

	// the ship is facing the right direction, let's wait for our burn time
	wait until nd:eta <= (burn_duration/2).

	// we only need to lock throttle once to a certain variable in the beginning of the
	// loop, and adjust only the variable itself inside it.
	set tset to 0.
	lock throttle to tset.

	set done to False.
	//initial deltav
	set dv0 to nd:deltav.
	until done {

		//recalculate current max_acceleration, as it changes while we burn through fuel
		set max_acc to ship:maxthrust/ship:mass.

		// Staging during this phase may have 0 max_acc, which will cause divide by 0 error in nd:deltav:mag/max_acc
		if max_acc > 0 {

			//throttle is 100% until there is less than 1 second of time left to burn
			//when there is less than 1 second - decrease the throttle linearly
			set tset to min(nd:deltav:mag/max_acc, 1).

			// Update the node point direction as this changes over time during the burn?
			set np to nd:deltav. //points to node, don't care about the roll direction.

			// here's the tricky part, we need to cut the throttle as soon as our nd:deltav and
			// initial deltav start facing opposite directions
			// this check is done via checking the dot product of those 2 vectors
			if vdot(dv0, nd:deltav) < 0 {
				print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0,nd:deltav),1) at(col, line).
				lock throttle to 0.
				break.
			}

			//we have very little left to burn, less then 0.1m/s
			if nd:deltav:mag < 0.1 {
				//we burn slowly until our node vector starts to drift significantly from initial vector
				//this usually means we are on point
				until vdot(dv0, nd:deltav) < 0.5 {
					set np to nd:deltav.
					print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0,nd:deltav),1) at(col, line + 1).
				}

				lock throttle to 0.
				print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1) at(col, line + 2).
				set done to True.
			}
		}
	}
	print "Final orbit: AP " + round(APOAPSIS, 3) + "m, PE: " + round(PERIAPSIS, 3) at(col, line + 3).
	unlock steering.
	unlock throttle.
	wait 1.

	//we no longer need the maneuver node
	remove nd.

	//This sets the user's throttle setting to zero to prevent the throttle
	//from returning to the position it was at before the script was run.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	
	// De-orbit
	wait 20.
	Print "De-orbit commence" at(col, line + 4).
	lock steering to ship:retrograde.
	wait 4.
	lock throttle to 1.
	wait 5.
}
print "Program Terminated - you are on your own now." at(col, line + 5).