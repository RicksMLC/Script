// DeOrit functions
// TODO:
//  [?] Deorbit over water (hmm? simple timer?)
//  [+] Stage retro engine
//  [+] Stage chutes
//  [-] Deploy Drogue chute
//  [-] Deploy Main chute

function DeOrbitAtm {
	parameter timeToDeOrbit is 1.
	parameter targetPE is -50000.
	// De-orbit
	wait timeToDeOrbit.
	Print "De-orbit burn commence".
	lock steering to ship:retrograde.
	WaitToFaceRetrograde(true).

	until PERIAPSIS < targetPE or altitude < SHIP:BODY:ATM:HEIGHT or AVAILABLETHRUST = 0 {
		lock throttle to 1.
		wait 0.001.
	}
	
	Print "De-orbit burn complete".
	lock throttle to 0.
	// Stage off the last engine
	Print "Staging engine away from flight path".
	local popEngineDir is R(-20, 10, 0).
	lock steering to popEngineDir.
	WaitToFaceDirection(popEngineDir, true).
	wait 3.
	stage.
	unlock throttle.
	print "Locking steering to Retrograde".
	lock steering to ship:retrograde.
	WaitToFaceRetrograde(true).
	wait until (stage:ready).

	// Wait until altitude is safe for drogue chute?
	print "Waiting until altitude is below atm height " + (ship:body:atm:height - 100).
	wait until ALT:RADAR < (ship:body:atm:height - 100).

	kuniverse:timewarp:CancelWarp().
	
	// This is a WHEN trigger... return is the return out of the WHEN, not the enclosing function.
	WHEN (not CHUTESSAFE) THEN {
		CHUTESSAFE ON.
		RETURN (NOT CHUTES).
	}
	print "ChutesSafe On.".
	wait until CHUTES.
	print "Chutes deployed.".
}
