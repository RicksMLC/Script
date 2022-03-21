// AutoTour03.ks
// kOS Auto launch.
// Attempt auto launch and orbit.
// Paying tourists are on board, so land INTACT.

// Objectives:
// 	[+] Fly straight up on launch.
//  [+] Set azimuth and throttle as the vessel passes each altitude in the launch profile.
//  [+] Create orbit manoevour node
//  [+] Execute orbit manoevour node.
//	[+] Deorbit manoevour.
//  [+] Deploy chutes
//  [+] Survive
//
// Test and verification:
//  [ ] Craft enters orbit at required altitude.
//	[ ] Deorbit executed
//  [ ] Chutes deployed

set autoDeOrbit to true.
set orbitAltitude to 80000.
set lastStageNum to 2.
set targetRadius to orbitAltitude + KERBIN:radius.
print "AutoTour03.ks DeOrbit("+ autoDeOrbit+") Target alt:" + round(orbitAltitude/1000, 3) + "km".

function SetAllAntennasOn {
	parameter activate is true.
	set antennas to ship:partstagged("antenna").
	if antennas:empty {
		print "SetAntanna Fail: no tagged 'antenna' parts.".
		return.
	}
	for antenna in antennas {
		// Check for non-RemoteTech?
		set am to antenna:getmodule("ModuleRTAntenna").
		set eventName to (choose "A" if activate else "Dea") +"ctivate".
		print eventName + "ing antenna '" + antenna:name + "'".
		am:DoEvent(eventName).
	}
}

function DeployFairing {
	parameter tag.
	set fairings to ship:partstagged(tag).
	if fairings:empty {
		print "DeployFairing fail: No tagged '" + tag + "' parts.".
		return.
	}
	for fairing in fairings {
		set fm to fairing:getmodule("ModuleProceduralFairing").
		print "Deploying fairing".
		fm:DoEvent("deploy").
	}
}

set autoAntenna to not Career():CanDoActions.
if not autoAntenna {
	print "Warning: No kOS Antenna activations. Career limit (actions not available).".
	print "         Remember to set antennas manually.".
}

// For safety reasons...
IF SHIP:STATUS = "PRELAUNCH" {
	set throt to 1.0.
	lock throttle to throt. // 1.0 is the max, 0.0 is idle.

	// Preflight check
	PrintStatus(0, "Pre-launch checks", SHIP:STATUS, true).
	if not Career():CanMakeNodes {
		PRINT "Doomed to Fail: Career limits prevent creation of nodes".
		abort.
	}

    lock unClamped to (ship:partsnamed("launchClamp1"):empty).
	PrintStatus(0, "Counting down pre-launch", true).
    PrintStatus(2, "Clamped", not unClamped).
	from {local countdown is -10.} until countdown = 0 step {set countdown to countdown + 1.} do {
		PrintStatus(1, "Countdown", "T" + countdown).
		wait 1.
	}
	PrintStatus(1, "Countdown", "T0").

    until unClamped {
        PrintStatus(2, "Clamped", not unClamped).
		if (stage:ready) {
			print "Staging " + stage:NUMBER.
			STAGE.
            PrintStatus(3, "Staged", (choose "Still clamped" if not unClamped else "Clamps free!")).
		}
        wait 0.001.
	}.

} // End STATUS = "PRELAUNCH"
print "Ship Status: " + SHIP:STATUS.
if SHIP:STATUS = "FLYING" {
    print "Liftoff!".
    PrintStatus(0, "Liftoff", SHIP:STATUS).
	wait 3.
	PrintStatus(0, "Liftoff", SHIP:STATUS, true).

	// FIXME: Remove this trigger?
	//WHEN AVAILABLETHRUST = 0 THEN {
	//	if (stage:ready) {
	//		PrintStatus(4, "Staging", stage:NUMBER).
	//		STAGE.
	//	}
	//	return stage:NUMBER > lastStageNum.
	//}.

	set mySteer to HEADING(90,90). // 90 degrees = East. 90 = straight up.
	lock steering to mySteer.

	set ctrlVel to 100.
	set curAzimuth to 90.
	set maxVel to 800.

	function SetHeadingAndThrottle {
		parameter azimuth.
		parameter t.
		if azimuth = "P" {
			lock mySteer to PROGRADE.
		} else {
			set mySteer to HEADING(90, azimuth).
		}
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
		list( 4000, 70, 1.0),
		list( 6000, 60, 1.0),
		list(10000, 45, 1.0),
		list(15000, "P", 1.0),
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
		PrintStatus(6, "Altitude", round(ship:altitude) + "m").
        PrintPairStatus(7, "Ap", round(SHIP:APOAPSIS, 0) + "m", "ETA", round(SHIP:OBT:ETA:APOAPSIS, 2) + "s").
		wait 0.001.
	}

	PRINT round(APOAPSIS / 1000, 2) + "km apoapsis reached, cutting throttle".

	LOCK THROTTLE TO 0.

	wait until ship:altitude > 65000.
	DeployFairing("fairing").

	wait until ship:altitude > 70000.
	kuniverse:timewarp:CancelWarp().

	if autoAntenna {
		SetAllAntennasOn(true).
	} else {
		print "NOTE: No auto antennas. Recommend manually activate the antennas.".
	}

    // The atmosphere drag may have lowered the apoapsis, so correct it.
	if APOAPSIS < orbitAltitude {
		Print "Adjusting Ap to " + orbitAltitude.
		set mySteer to SHIP:PROGRADE.
		wait 1.
		LOCK THROTTLE TO 0.1.
		
		until APOAPSIS >= orbitAltitude {
			StageOnFlameoutCheck().
		}
	}
	LOCK THROTTLE TO 0.
	wait 1. // wait to settle down for deltav duration calc.

   	CreateCircularOrbitNode(orbitAltitude).
	ExecManoeuvreNode().

	//This sets the user's throttle setting to zero to prevent the throttle
	//from returning to the position it was at before the script was run.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

} // end IF STATUS = "flying"


if STATUS = "ORBITING" {
	PSClearPrevStats().
	PrintStatus(0, "Status", STATUS).
    if autoDeOrbit = True {
		print "Auto De-Orbiting".
		if not HOMECONNECTION:ISCONNECTED {
			print "LOS.".
			LOCK THROTTLE TO 0.
			print "Throttle locked to 0 for safety.".
			print "... waiting for comms.".
		}
		wait until HOMECONNECTION:ISCONNECTED.
		kuniverse:timewarp:CancelWarp().
		print "Comms OK.".
        deletepath("OrbitLib.ks").
        if not exists("DeOrbitLib.ks") {
            copypath("0:/DeOrbitLib.ks", "").
        }
		print "Running: DeOrbitLib.ks".
        runoncepath("DeOrbitLib").

		if autoAntenna {
        	SetAllAntennasOn(false).
		} else {
			print "NOTE: No auto antenna.  This would be a good time to retract antennas.".
		}

		DeOrbitAtm(5, -100000).
	}
}

print "AutoTour03 Program Complete - you are on your own now.".