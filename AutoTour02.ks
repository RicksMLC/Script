// AutoTour.ks
// kOS Auto launch.
// Attempt auto launch and orbit.
// Paying tourists are on board, so land INTACT.

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
set autoDeOrbit to true.
set throt to 1.0.
lock throttle to throt. // 1.0 is the max, 0.0 is idle.
set orbitAltitude to 80000.
set lastStageNum to 2.
set targetRadius to orbitAltitude + KERBIN:radius.
print "AutoTour.ks DeOrbit("+ autoDeOrbit+") Target alt:" + round(orbitAltitude/1000, 3) + "km".
set col to 0.
set line to 1.

function SetAllAntennasOn {
	parameter activate is true.
	if not Career():CanDoActions {
		print "SetAllAntennasOn Fail: Career limit: no actions possible.".
		return.
	}
	set antennas to ship:partstagged("antenna").
	if antennas:empty {
		print "SetAntanna Fail: no tagged 'antenna' parts.".
		return.
	}
	for antenna in antennas {
		// Check for non-RemoteTech?
		set am to antenna:getmodule("ModuleRTAntenna").
		print (choose "A" if activate else "Dea") + "ctivating antenna '" + antenna:name + "'".
		am:DoAction("activate", activate).
	}
}

function StageOnFlameoutCheck {
    // Check for engine flameout:
    list ENGINES in engList.
    for eng in engList {
		if eng:flameout {
			wait until stage:ready.
			STAGE.
			print "Flameout STAGING " + stage:NUMBER.
			return.
		}
	}
}

// For safety reasons...
IF STATUS = "PRELAUNCH" {
    runoncepath("OrbitLib").
	print "Counting down:" at(col, line).
	from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
		print "..." + countdown + " " at(col + 15, line).
		wait 1.
	}
	set line to line + 1.
	set stageLine to line.
	WHEN AVAILABLETHRUST = 0 THEN {
		if (stage:ready) {
			print "Staging " + stage:NUMBER at(col, stageLine).
			STAGE.
			print " staged." at (col + 11, stageLine).
		}
		if (stage:NUMBER > lastStageNum) {
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
		list(15000, 70, 1.0),
		list(20000, 60, 1.0),
		list(28000, 45, 0.75),
		list(45000, 10, 0.75),
		list(55000,  0, 0.75),
		list(orbitAltitude, 0, 0)
	).
	set idx to 0.
	PrintNextEntry().
	until APOAPSIS > orbitAltitude {
		// For the initial ascent, we want our steering to be straight
		// up and rolled due east.
		if (ship:altitude) > azList[idx][0] {
			SetHeadingAndThrottle(azList[idx][1], azList[idx][2]).
			//set throt to azList[idx][2].
			set idx to idx + 1.
			PrintNextEntry().
		}
		StageOnFlameoutCheck().
		print "Status: Alt: " + round(ship:altitude) + " Apoapsis: " + round(SHIP:APOAPSIS, 0) at (0,line + 2).
		wait 0.001.
	}

	set col to 0.
	set line to line + 3.

	PRINT round(APOAPSIS / 1000, 2) + "km apoapsis reached, cutting throttle" at(col, line).
	set line to line + 1.

	LOCK THROTTLE TO 0.

	wait until ALT:RADAR > 70000.

	SetAllAntennasOn(true).

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

	if Career():CanMakeNodes {
    	CreateCircularOrbitNode(orbitAltitude).
    	ExecManoevourNodeSimple().
	} else {
		PRINT "Doomed to Fail: Unable to create nodes (Career:CanMakeNodes is false)".
	}

	//This sets the user's throttle setting to zero to prevent the throttle
	//from returning to the position it was at before the script was run.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

    set line to line + 4.
} // end IF STATUS = "prelaunch"

if STATUS = "ORBITING" {
    if autoDeOrbit = True {
        deletepath("OrbitLib.ks").
        if not exists("DeOrbitLib.ks") {
            copypath("0:/DeOrbitLib.ks", "").
        }
        runoncepath("DeOrbitLib").
		print "Auto De-Orbiting" at(col, line + 1).
		set line to line + 1.

        SetAllAntennasOn(false).

		DeOrbitAtm(5, -100000).
	}
}

print "Program Terminated - you are on your own now." at(col, line + 2).