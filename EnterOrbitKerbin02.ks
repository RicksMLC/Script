// EnterOrbitKerbin02.ks
// kOS Auto launch.
// Attempt auto launch and orbit.

// Objectives:
// 	Launch to a circular orbit at a given orbitAltitiude above Kerbin.

// For the Kerbal Komms Satellite Project:
//	[ ] Circularise the orbit to a greater precision (eccentricity close to 0)
//  [ ] Stage the low Kerbin orbit to KeostationaryOrbit to position the komms at the correct longitude.
//		[ ] Create the two manoeuvre nodes: 
//			[ ] Low orbit and transition to high orbit
//		[ ] 

function NodeAndBurn {
	parameter targetObtAlt.
		// Now to set up the maneuver node for orbit...
	Print "Time: " + TIME:Seconds + ". Ship AP ETA: " + round(ETA:APOAPSIS, 2).
	Print "Current velocity: " + round(SHIP:VELOCITY:ORBIT:MAG).
	Print "Velocity at AP:" + round(VELOCITYAT(SHIP, TIME:Seconds + ETA:APOAPSIS):ORBIT:MAG).
	
	LOCAL Vo is CalcOrbitalVelocity(SHIP:BODY, targetObtAlt).
	print "Calculated Vo: " + Vo.
	
	LOCAL mnDeltaV is Vo - VELOCITYAT(SHIP, TIME:Seconds + ETA:APOAPSIS):ORBIT:MAG.
	
	Print "DeltaV: " + mnDeltaV.
	local timeToApoapsis is ETA:APOAPSIS.
	LOCAL orbitNode is NODE(TimeSpan(timeToApoapsis), 0, 0, mnDeltaV).
	ADD orbitNode.

	print "Maxthrust: " + MAXTHRUST  AT(30,0).

	// OrbitLib.ks to execute the node
	if MAXTHRUST = 0 {
		print "Why, oh why, is maxthrust 0?".
	} else {
		print "Execute Manoeuvre Node".
		PSClearPrevStats().
		ExecManoeuvreNode().
	}
}

clearscreen.

lock throttle to 1.0. // 1.0 is the max, 0.0 is idle.

print "EnterOrbitKerbin02.ks".
set KeostationaryOrbit to 2863330.
set TestLowOrbit to 101000.

if not Career():CanMakeNodes {
	print "Career limited: Unable to make Maneuver Nodes.".
	print "Upgrade the Tracking Station and Mission Control to unlock.".
	print "Aborting launch.".
	SHUTDOWN.
}

//set orbitAltitiude to KeostationaryOrbit. 
set orbitAltitiude to TestLowOrbit.

set mySteer to HEADING(90, 90). // 90 degrees = East. 90 = straight up.

runoncepath("0:/OrbitLib.ks").
print "STATUS:" + STATUS.

// For safety reasons...
IF STATUS = "PRELAUNCH" {

	print "Counting down:".
	from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
		print ("..." + countdown + "  ") at (0, 2).
		wait 1.
	}

	//This is a trigger that constantly checks to see if our thrust is zero.
	//If it is, it will attempt to stage and then return to where the script
	//left off. The PRESERVE keyword keeps the trigger active even after it
	//has been triggered.
	WHEN MAXTHRUST = 0 THEN {
		if (stage:ready) {
			PRINT "Staging".
			STAGE.
		}
		if (stage:NUMBER > 0) {
			PRESERVE.
		}
	}.


	lock steering to mySteer.

	set ctrlVel to 100.
	set curAzimuth to 85.
	set maxVel to 1800.

	function SetHeading {
		parameter azimuth.
		set mySteer to HEADING(90, azimuth).
		print ("Pitching to " + azimuth + " degrees") at (0, 12).
	}

	until APOAPSIS > orbitAltitiude {
		// For the initial ascent, we want our steering to be straight
		// up and rolled due east.
		if SHIP:VELOCITY:SURFACE:MAG < 100 {
			set mySteer to HEADING(90, curAzimuth).
		} else if SHIP:VELOCITY:SURFACE:MAG >= ctrlVel and SHIP:VELOCITY:SURFACE:MAG < ctrlVel + 100 {
			SetHeading(curAzimuth).
		} else if ctrlVel < maxVel and ALT:RADAR > 7000 {
			if curAzimuth > 60 {
				set curAzimuth to curAzimuth - 10.
			}
			set ctrlVel to ctrlVel + 100.
		}
		print ("Apoapsis: " + round(SHIP:APOAPSIS, 0)) at (0,13).
	}

	PRINT "100km apoapsis reached, cutting throttle".

	//At this point, our apoapsis is above 100km and our main loop has ended. Next
	//we'll make sure our throttle is zero and that we're pointed prograde
	LOCK THROTTLE TO 0.
	LOCK STEERING to SHIP:PROGRADE.

	PRINT "Waiting until the altitude is above the atmosphere of " + SHIP:BODY:NAME + " (" + SHIP:BODY:ATM:HEIGHT + "m)".
	wait until ALT:RADAR > SHIP:BODY:ATM:HEIGHT.

	// The atmosphere may have lowered the apoapsis, so correct it.
	if APOAPSIS < orbitAltitiude {
		Print "Adjusting Ap to " + orbitAltitiude.
		set mySteer to SHIP:PROGRADE.
		wait 1.
	}
	until APOAPSIS >= orbitAltitiude {
		LOCK THROTTLE TO 0.1.
	}
	LOCK THROTTLE TO 0.

	wait 0.1. // Allow to settle so the orbitlib calculations are stable.

	NodeAndBurn(orbitAltitiude).
}

if STATUS = "ORBITING" {
	lock throttle to 0.
	print "Checking Pe: " + round(SHIP:OBT:PERIAPSIS, 2) + " target: " + round(orbitAltitiude, 2).
	if SHIP:OBT:PERIAPSIS < orbitAltitiude {
		print "Correcting orbit.  Create and Execute node? (y)".
		if terminal:input:getchar() = "y" {
			print "NodeAndBurn(" + round(orbitAltitiude) + ") executing.".
			NodeAndBurn(orbitAltitiude).
		}
	}
	// De-orbit
	print "Auto DeOrbit?(y):".
	if terminal:input:getchar() = "y" {
		Print "De-orbit commence".
		wait 4.
		lock throttle to 1.
		until SHIP:OBT:PERIAPSIS < -20 {
			LOCK STEERING to SHIP:RETROGRADE.
		}
		lock throttle to 0.
	}
	
	//This sets the user's throttle setting to zero to prevent the throttle
	//from returning to the position it was at before the script was run.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}
print "Program end.".
