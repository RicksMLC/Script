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
	until PERIAPSIS < targetPE {
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

	WHEN (not CHUTESSAFE) THEN {
		CHUTESSAFE ON.
		RETURN (NOT CHUTES).
	}
	wait until CHUTES.
}
