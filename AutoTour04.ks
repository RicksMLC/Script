// AutoTour04.ks
// kOS Auto launch.
// Attempt auto launch and orbit.
// Paying tourists are on board, so land INTACT.
// Use the FlightLib to perform the common flight functions.

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
//  [+] Craft enters orbit at required altitude.
//	[+] Deorbit executed
//  [+] Chutes deployed

set autoDeOrbit to true.
set orbitAltitude to 80000.
set fairingDeployAltitude to 55000.
set lastStageNum to 2.
set targetRadius to orbitAltitude + KERBIN:radius.
print "AutoTour03.ks DeOrbit("+ autoDeOrbit+") Target alt:" + round(orbitAltitude/1000, 3) + "km".

set autoAntenna to not Career():CanDoActions.
if not autoAntenna {
	print "Warning: No kOS Antenna activations. Career limit (actions not available).".
	print "         Remember to set antennas manually.".
}

// For safety reasons...
IF SHIP:STATUS = "PRELAUNCH" {
    LaunchClamped().
} // End STATUS = "PRELAUNCH"

print "Ship Status: " + SHIP:STATUS.
if SHIP:STATUS = "FLYING" {
    print "Liftoff!".
    PrintStatus(0, "Liftoff", SHIP:STATUS).
	wait 3.
	PrintStatus(0, "Liftoff", SHIP:STATUS, true).

	print "Wait until " + round(fairingDeployAltitude) + " to deploy fairing and set antennas on".
	when ship:altitude > fairingDeployAltitude then {
        DeployFairing("fairing"). 
        wait 1.
    	if autoAntenna {
	    	SetAllAntennasOn(true, "antenna").
	    } else {
    		print "NOTE: No auto antennas. Recommend manually activate the antennas.".
    	}
     }
    set launchDirection to 80.
   	set flightProfile to Queue(
		List(  250, launchDirection, 85, 1.0),
		List( 1000, launchDirection, 80, 1.0),
		List( 4000, launchDirection, 70, 1.0),
		List( 6000, launchDirection, 60, 1.0),
		List(21000, launchDirection, 45, 1.0),
		List(30000, launchDirection, "p", 1.0),
		List(orbitAltitude, 90, 0, 0)
	).
    ControlFlight(orbitAltitude, orbitAltitude, flightProfile, 1).

	PRINT round(APOAPSIS / 1000, 2) + "km apoapsis reached, cutting throttle".

	LOCK THROTTLE TO 0.

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
	PrintStatus(0, "Status", STATUS, true).
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
        	SetAllAntennasOn(false, "antenna").
		} else {
			print "NOTE: No auto antenna.  This would be a good time to retract antennas.".
		}

		DeOrbitAtm(5, -100000).
	}
}

print "AutoTour04 Program Complete - you are on your own now.".