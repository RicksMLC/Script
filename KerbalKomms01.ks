// KerbalKomms01.ks
// RicksMLC
// kOS Auto launch.
//
// Objectives:
// 	Establish the Kerbal Komms Keostationary Network.
//
// For the Kerbal Komms Satellite Project:
//	[ ] Circularise the orbit to a greater precision (eccentricity close to 0)
//		[ ] Read up on "Tsiolkovsky rocket equation"
//		[ ] Update OrbitLib.ks to have this precision.
//	[-] Ship Design and construction
//		[+] Add fairing
//		[+] Include logic for staging of the fairings before break atmosphere.
//		[ ] Check if fairing is there.
//  [-] Stage the low Kerbin orbit to KeostationaryOrbit to position the komms at the correct longitude.
//		[+] Make a function CreateCircularOrbit() in OrbitLib.ks.
//		[+] Create a transition manoeuvre node. CreateHohmannTransferNode()
//		[ ] Calculate where to place the transition for a given target keostationary satellite longitude.
//			[ ] Set the periapsis of the current orbit to the correct longitude before Hohmann transfer setup.
//		[+] Create the three manoeuvre nodes: 
//			[+] Low orbit 
//			[+] Transition to komms orbit
//			[+] Circularise komms orbit
//		[-] Inefficient launch needs fixing...?
//		[+] Set the manoeuvre nodes after breaking atmosphere.
//		[+] Code transition between nodes.
//	[+] kOS and RemoteTech
//		[+] Activate comms equipment
//		[+] Handle CPU Reboot/Power Reboot.

wait until ship:unpacked.
clearscreen.
print "KerbalKomms01.ks".

set KeostationaryOrbit to 2863330.
set TestLowOrbit to 100000.

set targetAltitude to KeostationaryOrbit.
set DeOrbit to false.
print "DeOrbit is " + DeOrbit.

set orbitAltitiude to KeostationaryOrbit. 
//set orbitAltitiude to TestLowOrbit.

set prevStatus to STATUS.

runoncepath("OrbitLib.ks").

// For safety reasons...
IF STATUS = "PRELAUNCH" {
	if not exists("OrbitLib.ks") {
		copypath("0:/OrbitLib.ks", "").
	}

	print "Counting down:".
	from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
		print ("..." + countdown + "  ") at (0, 3).
		wait 1.
	}
	
	set mySteer to HEADING(90, 90). // 90 degrees = East. 90 = straight up.
	lock throttle to 1.0. // 1.0 is the max, 0.0 is idle.
	lock steering to mySteer.

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


	function SetHeading {
		parameter azimuth.
		set mySteer to HEADING(90, azimuth).
		print ("Pitching to " + azimuth + " degrees") at (0, 12).
	}

	set ctrlAltitude to 15000.
	set curAzimuth to 80.
	set throt to 1.
	LOCK throttle to throt.
	
	until APOAPSIS > orbitAltitiude {
		// For the initial ascent, we want our steering to be straight
		// up and rolled due east.
		if ALT:RADAR < 300 {
			PRINT "Clearing tower" at(0,12).
			// Do nothing yet
		} else if ALT:RADAR < ctrlAltitude {
			set mySteer to HEADING(90, curAzimuth).
		} else {
			if curAzimuth > 20 {
				set throt to 0.7.
			} else {
				set throt to 1.
			}
		}
		if ALT:RADAR >= ctrlAltitude {
			if ALT:RADAR < ctrlAltitude + 5000 {
				SetHeading(curAzimuth).
			} else if curAzimuth > 10 {
				set curAzimuth to curAzimuth - 15.
				set ctrlAltitude to ctrlAltitude + 5000.
				SetHeading(curAzimuth).
			}
		}
		print "Ap: " + round(SHIP:APOAPSIS, 0) at (0,13).
		print "Q:  " + round(SHIP:Q, 3) at (0,14).
	}

	PRINT round(TestLowOrbit / 1000, 2) + "km apoapsis reached, cutting throttle".

	//At this point, our apoapsis is above the target altitude and our main loop has ended. Next
	//we'll make sure our throttle is zero and that we're pointed prograde
	LOCK THROTTLE TO 0.
	LOCK STEERING to SHIP:PROGRADE.

	// Deploy Fairing
	SET fairingDeployHeight to SHIP:BODY:ATM:HEIGHT - 15000.
	PRINT "Deploy fairing at high atmosphere " + SHIP:BODY:NAME + " (" + fairingDeployHeight + "m)".
	wait until ALT:RADAR > fairingDeployHeight.
	SET partList to SHIP:PARTSTAGGED("fairing").
	// FIXME: Assume only one fairing for now.
	set fairingPart to partList[0]:GetModule("ModuleProceduralFairing").
	fairingPart:DOEVENT("deploy").

	/// Break Atmosphere events:
	PRINT "Waiting until the altitude is above the atmosphere of " + SHIP:BODY:NAME + " (" + SHIP:BODY:ATM:HEIGHT + "m)".
	wait until ALT:RADAR > SHIP:BODY:ATM:HEIGHT.

	// The atmosphere drag may have lowered the apoapsis, so correct it.
	if APOAPSIS < orbitAltitiude {
		Print "Adjusting Ap to " + orbitAltitiude.
		set mySteer to SHIP:PROGRADE.
		wait 1.
	
		until APOAPSIS >= orbitAltitiude {
			LOCK THROTTLE TO 0.1.
		}
	}
	LOCK THROTTLE TO 0.

	CreateCircularOrbitNode(orbitAltitiude, SHIP:BODY, true).
	
	// OrbitLib.ks to execute the node
	if MAXTHRUST = 0 {
		print "Why, oh why, is maxthrust 0?".
		print "Terminating program in error state.".
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
		print 1/0. // Terminate program.
	} 	
	print "ExecManoevourNodeSimple execute".
	ExecManoevourNodeSimple().
	
	wait 2.
	Print "Deploying Antennas.".
	// Deploy Antennas. From http://ksp-kos.github.io/KOS_DOC/addons/RemoteTech.html#antennas
	SET P TO SHIP:PARTSTAGGED("Komms-0")[0].
	SET M to p:GETMODULE("ModuleRTAntenna").
	M:DOEVENT("activate").
	M:SETFIELD("target", "Kerbin Komms Mk 1 - 0").
	SET P TO SHIP:PARTSTAGGED("Komms-1")[0].
	SET M to p:GETMODULE("ModuleRTAntenna").
	M:DOEVENT("activate").
	M:SETFIELD("target", "Kerbin Polar Komms Mk 1").
}
	
IF STATUS = "ORBITING" {
	// The ship is now assumed to be in a circular orbit.
	print "Status: Orbiting".
	//list.
	if prevStatus <> "PRELAUNCH" {
		runoncepath("OrbitLib.ks").
	}

	// TODO: adjust periapsis to correct longitude.
	if not HASNODE {
		LOCAL startAltitude is SHIP:OBT:PERIAPSIS.
		if targetAltitude < startAltitude {
			SET startAltitude TO SHIP:OBT:APOAPSIS.
		}
		if (CreateHohmannTransferNodes(targetAltitude, startAltitude, SHIP:BODY, true)) {
			PRINT "Hohmann transfer nodes prepared.".
		} else {
			PRINT "Failed to create Hohmann transfer nodes :(".
		}
	}
	if HASNODE {
		ExecManoevourNodeSimple().
		PRINT "Transfer complete.".
	}
	if HASNODE {
		ExecManoevourNodeSimple().
		PRINT "Final burn complete.".
	}

	if DeOrbit {
		// De-orbit
		wait 20.
		Print "De-orbit commence".
		LOCK STEERING to SHIP:RETROGRADE.
		wait 4.
		lock throttle to 1.
		until SHIP:OBT:PERIAPSIS < -20000 {
			
		}
		lock throttle to 0.
	}
}

//This sets the user's throttle setting to zero to prevent the throttle
//from returning to the position it was at before the script was run.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

