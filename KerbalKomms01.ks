// KerbalKomms01.ks
// RicksMLC
// kOS Auto launch.
//
// Objectives:
// 	Establish the Kerbal Komms Keostationary Network.
//
// For the Kerbal Komms Satellite Project:
//	[?] Circularise the orbit to a greater precision (eccentricity close to 0)
//		[+] Read up on "Tsiolkovsky rocket equation"
//		[-] Update OrbitLib.ks to have this precision.
//	[-] Ship Design and construction
//		[+] Add fairing
//		[+] Include logic for staging of the fairings before break atmosphere.
//		[?] Check if fairing is there.
//  [-] Stage the low Kerbin orbit to KeostationaryOrbit to position the komms at the correct longitude.
//		[+] Make a function CreateCircularOrbit() in OrbitLib.ks.
//		[+] Create a transition manoeuvre node. CreateHohmannTransferNode()
//		[-] Calculate where to place the transition for a given target keostationary satellite longitude.
//			[-] Set the periapsis of the current orbit to the correct longitude before Hohmann transfer setup.
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

function TweakOrbitPeriod {
	parameter newPeriod.
	parameter verbose is false.

	if (not ship:hasbody) {
		print "  What are we doing here? No BODY to orbit!".
		return.
	}
	set kDay to ship:body:rotationperiod.
	set epsilonPeriod to 0.5.
	if abs(ship:obt:period - kDay) > epsilonPeriod {
		PrintPairStatus(0, "Adjusting period to ", round(kDay, 4), "Epslion", round(epsilonPeriod, 4)).
		if ship:obt:period < kDay {
			lock steering to PROGRADE.
			//WaitToFacePrograde(verbose).
		} else {
			lock steering to RETROGRADE.
			//WaitToFaceRetrograde(verbose).
		}
		wait 3.
		until abs(ship:obt:period - kDay) < epsilonPeriod {
			PrintStatus(1, "obt:period", round(ship:obt:period, 4)).
			lock throttle to 0.002.
			wait 0.001.
		}
		unlock throttle.
		print "Period adjusted to " + ship:obt:period.
	}
}

function SetKomms {
	parameter antennaTag.
	parameter tgt.
	// Deploy Antennas. From http://ksp-kos.github.io/KOS_DOC/addons/RemoteTech.html#antennas
	SET P TO SHIP:PARTSTAGGED(antennaTag)[0].
	SET M to p:GETMODULE("ModuleRTAntenna").
	M:DOEVENT("activate").
	M:SETFIELD("target", tgt).
}


wait until ship:unpacked.

print "KerbalKomms01.ks".

set KeostationaryOrbit to 2863330.
set InitLowOrbit to 130000.
set lastStageNum to 0.
set targetAltitude to KeostationaryOrbit.
set DeOrbit to false.
print "DeOrbit is " + DeOrbit.

set orbitAltitude to InitLowOrbit.

set prevStatus to STATUS.
set throt to 1.

set kscLng to -74.55.
set targetLngE to kscLng + 90.
set targetLngW to kscLng - 90.
set targetLngOpp to kscLng + 180.

// Kerbal Komms Mk 1 - 0	= KSC long
//   Komms-0 => Kerbin
//	 Komms-1 => Kerbal Komms Mk 1 - E
//	 Komms-2 => Kerbal Komms Mk 1 - W
set ship:shipname to "Kerbal Komms Mk 1 - 0".
set komms0Target to "Kerbin".
set komms1Target to "no-target".
set komms2Target to "no-target".
set targetLng to kscLng.

set kommsId to "1".

if kommsId = "E" {
	// Kerbal Komms Mk 1 - E	= east
	//   Komms-0 => Kerbin
	//   Komms-1 => Kerbal Komms Mk 1 - 0
	//	 Komms-2 => Kerbal Komms Mk 1 - 1
	set ship:shipname to "Kerbal Komms Mk 1 - E".
	set komms0Target to "Kerbin".
	set komms1Target to "Kerbal Komms Mk 1 - 0".
	set komms2Target to "no-target".
	set targetLng to targetLngE.
} else if kommsId = "W" {
	// Kerbal Komms Mk 1 - W	= west
	//   Komms-0 => Kerbin
	//   Komms-1 => Kerbal Komms Mk 1 - 0
	//	 Komms-2 => Kerbal Komms Mk 1 - 1
	set ship:shipname to "Kerbal Komms Mk 1 - W".
	set komms0Target to "Kerbin".
	set komms1Target to "Kerbal Komms Mk 1 - 0".
	set komms2Target to "no-target".
	set targetLng to targetLngW.
} else if kommsId = "1" {
	// Kerbal Komms Mk 1 - 1	= opposite
	//   Komms-0 => Kerbin
	//   Komms-1 => Kerbal Komms Mk 1 - E
	//	 Komms-2 => Kerbal Komms Mk 1 - W
	set ship:shipname to "Kerbal Komms Mk 1 - 1".
	set komms0Target to "Kerbin".
	set komms1Target to "Kerbal Komms Mk 1 - E".
	set komms2Target to "Kerbal Komms Mk 1 - W".
	set targetLng to targetLngOpp.
}

// For safety reasons...
IF SHIP:STATUS = "PRELAUNCH" {
    LaunchClamped().
}

if status = "FLYING" {
    print "Liftoff!".
    PrintStatus(0, "Liftoff", SHIP:STATUS).
	wait 3.
	PrintStatus(0, "Liftoff", SHIP:STATUS, true).

	WHEN AVAILABLETHRUST = 0 THEN {
		if (stage:ready) {
			PrintStatus(4, "Staging", stage:NUMBER).
			STAGE.
		}
		return stage:NUMBER > lastStageNum.
	}.

	set mySteer to HEADING(90,90). // 90 degrees = East. 90 = straight up.
	lock steering to mySteer.

	set ctrlVel to 100.
	set curAzimuth to 90.
	set maxVel to 800.

	function SetHeadingAndThrottle {
		parameter azimuth.
		parameter t.
		if azimuth = "SP" {
			lock mySteer to SRFPROGRADE.
		} else if azimuth = "P" {
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
		list(15000, 45, 1.0),
		list(25000, "SP", 1.0),
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

	PRINT round(APOAPSIS / 1000, 2) + "km apoapsis reached, cutting throttle".

	LOCK THROTTLE TO 0.

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
	if APOAPSIS < orbitAltitude {
		Print "Adjusting Ap to " + orbitAltitude.
		set mySteer to SHIP:PROGRADE.
		wait 1.
	
		until APOAPSIS >= orbitAltitude {
			LOCK THROTTLE TO 0.1.
			wait 0.001.
		}
	}
	LOCK THROTTLE TO 0.

	CreateCircularOrbitNode(APOAPSIS, SHIP:BODY, true).
	
	// OrbitLib.ks to execute the node
	if MAXTHRUST = 0 {
		print "Why, oh why, is maxthrust 0?".
		print "Terminating program in error state.".
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
		print 1/0. // Terminate program.
	} 	
	ExecManoeuvreNode().
	wait 1.

	if ship:obt:eccentricity > 0.001 {
		print "Orbit ecc: " + round(ship:obt:eccentricity, 4) + " Correcting...".
		CreateCircularOrbitNode(APOAPSIS, SHIP:BODY, true).
		ExecManoeuvreNode().
		wait 1.
	}
}

IF STATUS = "ORBITING" {
	// The ship is now assumed to be in a circular orbit.
	print "Status: Orbiting".

	if prevStatus <> "PRELAUNCH" {
		runoncepath("OrbitLib.ks").
	}

	// Try to set the PE to the desired Lng so the transfers will happen at the correct time.
	// Note 1h24m from PE to AP transfer node.
	PSClearPrevStats().
	PrintStatus(0, "Adjusting PE to Lng", targetLng).
	// Calc the burn longitude of the burn for setting the PE for the Hohmann transfer.
	// timeHohmannTransfer = 1h 24m = (1 * 60 + 24) * 60 // seconds
	// shipDegPerSec = 360 / SHIP:OBT:PERIOD
	// long for the burn = [opposite side to the target long] => + 180 deg
	//					 - [body rotation during the Hohmann transfer] => - (HTT * KRR) deg
	//					 - [body rotation during ship PE point to HohmannNode] =>  deg
	//					 - [body rotation during ship current long  to PE setpoint]
	// burnLongitudeApprox = targetLongiude + 180 + (timeHohmannTransfer * kerbinRotationRate)
	// degreesToBurnLongApprox = burnLongitudeApprox - shipLong
	// secondsTilBurn = degreesToBurnLongApprox * shipDegPerSec
	// burnLongitudeApprox = (burnLongitudeApprox + (secondsTilBurn / kerbinRotationRate)
	//
	// secondsTilBurn2 = (burnLongitudeApprox  - shipLong) * shipDegPerSec
	// dT = secondsTilBurn2 - secondsTilBurn
	// if dT > epsilon
	//		factor in time to burn again.
	//
	//
	// Normalise the longitude from -180 -> 180 to 0->360
	// bLngApprox = targetLong + 180
	// timeToPE = (bLngApprox - mod(SHIP:GEOPOSITION:LNG + 180, 360)) * (SHIP:OBT:PERIOD / 360)
	// bLng = tLng - degToBurn
	// if bLng < 0 { bLng = 360 - bLng. }
	//
	
	print "Calculating PE adjust burn to set up Hohmann Transfer.".
	// Normalise the longitude from -180 -> 180 to 0->360
	set tgtLngN to targetLng + 180.
	
	set tHohmannTransferSec to (1 * 60 + 24) * 60. // timeHohmannTransfer duration from PE in seconds (1h 24m).
	set shipDegPerSec to 360 / SHIP:OBT:PERIOD.
	set kerbinRR to 360 / ship:body:rotationperiod. 

	set burnLongApprox to (tgtLngN + 180) - (tHohmannTransferSec * kerbinRR).
	set degShipToBurn to burnLongApprox - (SHIP:GEOPOSITION:LNG + 180).
	set secondsTilBurn to degShipToBurn * shipDegPerSec.
	set burnLongApprox to burnLongApprox - (secondsTilBurn * kerbinRR).
	set secondsTilBurn2 to (burnLongApprox - (SHIP:GEOPOSITION:LNG + 180)) * shipDegPerSec.
	print "TimeToBurn: " + round(secondsTilBurn, 2) + " TimeToBurn2: " + round(secondsTilBurn2, 2).
	if secondsTilBurn2 - secondsTilBurn > 10 {
		// Apply one more time?
		print "TimeToBurn diff > 10. Do something?".
	}
	// Denormalise to -180 to 180.
	print "burnLongApprox:" + burnLongApprox.
	set burnLongApprox to mod(burnLongApprox, 360).
	set burnLng to burnLongApprox - 180.

	lock steering to ship:RETROGRADE.
	set burnTime to 2.
	set epsilonDeg to 0.5.
	PrintStatus(1, "Adjust PE to prepare for Hohmann Transfer nodes.").
	when abs(SHIP:GEOPOSITION:LNG - burnLng) < epsilonDeg * 10 then {
		kuniverse:timewarp:CancelWarp().
		print "Cancelling warp.".
	}
	until abs(SHIP:GEOPOSITION:LNG - burnLng) < epsilonDeg {
		PrintPairStatus(2, "BurnLng", round(burnLng, 2), "ShipLng", round(SHIP:GEOPOSITION:LNG, 2)).
		wait 0.001.
	}
	set throt to 1.
	lock throttle to throt.
	wait burnTime.
	set throt to 0.
	unlock steering.
	wait 1.
	ExecHohmannTransfer(targetAltitude, -1, -1, true).

	print "Target Long:" + round(targetLng, 2) + "Ship Orbit Long: " + round(ship:GEOPOSITION:LNG) + " diff: " + (round(targetLng, 2) - round(ship:GEOPOSITION:LNG)) + "deg.".

	wait 2.
	Print "Deploying Antennas.".
	SetKomms("Komms-0", komms0Target).
	SetKomms("Komms-1", komms1Target).
	SetKomms("Komms-2", komms2Target).

	// Tweak the orbit to have a period of body day (eg Kerbin Day = 6 * 60 * 60).
	print "Tweaking orbit to body period".
	TweakOrbitPeriod(ship:body:rotationperiod, true).

	lock steering to north.
	wait 6.

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

