// CX-4181-4-OVT.ks
// kOS Auto launch.
// Attempt auto launch and orbit.

// Objectives:
// 	Launch to a circular orbit at a given orbitAltitude above Kerbin.

function NodeAndBurnPrototype {
	parameter targetObtAlt.
		// Now to set up the maneuver node for orbit...
	Print "Time: " + TIME:Seconds + ". Ship AP ETA: " + round(ETA:APOAPSIS, 2).
	Print "Current velocity: " + round(SHIP:VELOCITY:ORBIT:MAG).
	Print "Velocity at AP:" + round(VELOCITYAT(SHIP, TIME:Seconds + ETA:APOAPSIS):ORBIT:MAG).
	
	LOCAL Vo is CalcOrbitalVelocity(SHIP:BODY, targetObtAlt, true).
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

function NodeAndBurn {
    parameter targetObtAlt.
    parameter verbose is false.

    CreateCircularOrbitNode(targetObtAlt, SHIP:BODY, verbose).
	if MAXTHRUST = 0 {
		print "Why, oh why, is maxthrust 0?".
	} else {
		print "Execute Manoeuvre Node".
		PSClearPrevStats().
        //ExecManoevourNodeSimple().
		ExecManoeuvreNode().
	}
}

function ThrustSum {
    list engines in eList.
    local sumThrust is 0.
    for e in eList {
        set sumThrust to sumThrust + e:thrust.
    }
    return sumThrust.
}

lock throttle to 1.0. // 1.0 is the max, 0.0 is idle.

print "CX-4181-4-OVT.ks".
set KeostationaryOrbit to 2863330.
set TestLowOrbit to 101000.

if not Career():CanMakeNodes {
	print "Career limited: Unable to make Maneuver Nodes.".
	print "Upgrade the Tracking Station and Mission Control to unlock.".
	print "Aborting launch.".
	SHUTDOWN.
}

set orbitAltitude to TestLowOrbit.

set mySteer to HEADING(90, 90). // 90 degrees = East. 90 = straight up.

runoncepath("0:/FlightLib.ks").
runoncepath("0:/OrbitLib.ks").
print "STATUS:" + STATUS.

// For safety reasons...
IF STATUS = "PRELAUNCH" {

	lock unClamped to (ship:partsnamed("launchClamp1"):empty).
	PrintStatus(0, "Counting down pre-launch", true).
    PrintStatus(2, "Clamped", not unClamped).
	from {local countdown is -10.} until countdown = 0 step {set countdown to countdown + 1.} do {
		PrintStatus(1, "Countdown", "T" + countdown).
		wait 1.
	}
	PrintStatus(1, "Countdown", "T0").

	local twr is 0.
	stage.
	until twr > 1.1 {
		set tSum to ThrustSum().
		set twr to tSum / mass.
		PrintPairStatus(3, "Thrust: ", round(tSum, 4) + "kN.", "TWR: ", round(twr, 2)).
		wait 0.001.
	}
	print "".
	wait until stage:ready. stage.
	print "Liftoff".
    PrintStatus(2, "Clamped", not unClamped).

	lock steering to mySteer.

	set ctrlVel to 100.
	set curAzimuth to 85.
	set maxVel to 1800.

	function SetHeadingAndThrottle {
		parameter azimuth.
		parameter t.
		set mySteer to HEADING(90, azimuth).
		set throt to t.
		PrintPairStatus(4, "Heading", "Pitching to " + azimuth + " deg.", "Throttle", round(throt, 2)).
	}

	function PrintNextEntry {
		PrintStatus(5, "Next", azList[idx][1] + " deg, throttle " + round(azList[idx][2],2) + " at " + azList[idx][0] + "m").
	}

	// Launch azimuth profile (alt, az, throttle)
	set azList to list(
		list(  250, 85, 1.0),
		list( 1000, 80, 1.0),
		list( 6000, 75, 1.0),
		list(15000, 70, 1.0),
		list(20000, 60, 1.0),
		list(25000, 45, 1.0),
		list(30000,  0, 1.0),
		list(40000,  0, 1.0),
		list(orbitAltitude, 0, 0)
	).
	set idx to 0.
	PrintNextEntry().
	until APOAPSIS >= orbitAltitude {
		// For the initial ascent, we want our steering to be straight
		// up and rolled due east.
		if (ship:altitude) > azList[idx][0] {
			SetHeadingAndThrottle(azList[idx][1], azList[idx][2]).
			set idx to idx + 1.
			PrintNextEntry().
		}
		StageOnFlameoutCheck().
		PrintStatus(7, "Altitude", round(ship:altitude) + "m").
        PrintPairStatus(8, "Ap", round(SHIP:APOAPSIS, 0) + "m", "ETA", round(SHIP:OBT:ETA:APOAPSIS, 2) + "s").
		wait 0.001.
	}

	PRINT "100km apoapsis reached, cutting throttle".

	//At this point, our apoapsis is above 100km and our main loop has ended. Next
	//we'll make sure our throttle is zero and that we're pointed prograde
	LOCK THROTTLE TO 0.
	LOCK STEERING to SHIP:PROGRADE.

	PRINT "Waiting until the altitude is above the atmosphere of " + SHIP:BODY:NAME + " (" + SHIP:BODY:ATM:HEIGHT + "m)".
	wait until ALT:RADAR > SHIP:BODY:ATM:HEIGHT.

	// The atmosphere may have lowered the apoapsis, so correct it.
	if APOAPSIS < orbitAltitude {
		Print "Adjusting Ap to " + orbitAltitude.
		LOCK STEERING TO heading(90, 0, 0).// SHIP:PROGRADE.
		wait 1.
	}
	until APOAPSIS >= orbitAltitude {
		LOCK THROTTLE TO 0.2.
        StageOnFlameoutCheck().
        wait 0.001.
	}
	LOCK THROTTLE TO 0.

	wait 1. // Allow to settle so the orbitlib calculations are stable.

	NodeAndBurn(orbitAltitude, true).
}

if STATUS = "ORBITING" {
	lock throttle to 0.
	print "Checking Pe: " + round(SHIP:OBT:PERIAPSIS, 2) + " target: " + round(orbitAltitude, 2).
	if SHIP:OBT:PERIAPSIS < orbitAltitude {
		print "PE < target altitude. Create and Execute node to correct orbit? (y)".
		if terminal:input:getchar() = "y" {
			print "NodeAndBurn(" + round(orbitAltitude) + ") executing.".
			NodeAndBurn(SHIP:OBT:APOAPSIS, true).
		}
	}
	print "Target orbit achieved. AP: " + round(ship:obt:apoapsis, 2) + " PE: " + round(ship:obt:periapsis, 2) + " ecc: " + round(ship:obt:eccentricity, 6).
	// De-orbit
	terminal:input:clear().
	print "Auto DeOrbit?(y):".
	if terminal:input:getchar() = "y" {
		Print "De-orbit commence".
		LOCK STEERING to SHIP:RETROGRADE.
		wait 4.
		lock throttle to 1.
		wait 0.01.
		wait until (SHIP:OBT:PERIAPSIS < -50000 or ThrustSum() = 0).
		lock throttle to 0.
		print "Auto De-orbit complete.".
	}
	
	//This sets the user's throttle setting to zero to prevent the throttle
	//from returning to the position it was at before the script was run.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}
print "Program end.".
