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
	set retroDirection to ship:retrograde.
	lock steering to retroDirection.
	wait 8.
	// FIXME: handle out of fuel before targetPE reached.
	until PERIAPSIS < targetPE or altitude < 70000 {
		set retroDirection to ship:retrograde.
		lock throttle to 1.
		wait 0.001.
	}
	
	Print "De-orbit burn complete".
	lock throttle to 0.
	lock steering to ship:retrograde.
	unlock throttle.
	wait 10.
	wait until (stage:ready).
	stage.

	// Wait until altitude is safe for drogue chute?
	print "Waiting until altitude is below atm height " + (ship:body:atm:height-100).
	wait until ALT:RADAR < (ship:body:atm:height-100).

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
