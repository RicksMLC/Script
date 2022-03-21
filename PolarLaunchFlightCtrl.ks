// PolarLaunchFlightCtrl.ks
// Rick's Mid Life Crisis

set autoAntenna to true.
set orbitAltitude to 80000.
set lastStageNum to 2.
set targetRadius to orbitAltitude + KERBIN:radius.
print "PolarLaunchFlightCtrl.ks Target alt:" + round(orbitAltitude/1000, 3) + "km".

IF SHIP:STATUS = "PRELAUNCH" {
    LaunchClamped().
}

if SHIP:STATUS = "FLYING" {
    print "Liftoff!".
    PrintStatus(0, "Liftoff", SHIP:STATUS).
	wait 3.
	PrintStatus(0, "Liftoff", SHIP:STATUS, true).

   	set flightProfile to Queue(
        List(0,     -10, 80, 1.0),
		List(300,   -10, 80, 1.0),
		List(5000,  -10, 70, 1.0),
		List(15000, -10, 60, 1.0),
        List(25000, -10, 45, 1.0),
        List(30000, -10, 10, 1.0),
        List(40000, -10,  0, 1.0)
	).

	lock steering to ship:facing. // heading(90, 90).
	ControlFlight(orbitAltitude, orbitAltitude, flightProfile, 1). // Last engine light stage is #1.

	LOCK THROTTLE TO 0.

	wait until ship:altitude > 55000.
	DeployFairing("fairing").

	wait until ship:altitude > 70000.
	kuniverse:timewarp:CancelWarp().

    // The atmosphere drag may have lowered the apoapsis, so correct it.
	if APOAPSIS < orbitAltitude {
		Print "Adjusting Ap to " + orbitAltitude.
		set mySteer to SHIP:PROGRADE.
		wait 1.
	
		until APOAPSIS >= orbitAltitude {
			LOCK THROTTLE TO 0.1.
		}
	}
	LOCK THROTTLE TO 0.
	wait 1. // wait to settle down for deltav duration calc.

   	CreateCircularOrbitNode(orbitAltitude, SHIP:BODY, true).

	ExecManoeuvreNode().

	//This sets the user's throttle setting to zero to prevent the throttle
	//from returning to the position it was at before the script was run.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

}
