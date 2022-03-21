// LaunchFlightCtrl.ks
// Rick's Mid Life Crisis
// Short script for launching to orbit using:
//    LaunchLib.ks, FlightLib.ks, OrbitLib.ks and psLib.ks. 

set autoAntenna to true.
set orbitAltitude to 80000.
set lastStageNum to 2.
set targetRadius to orbitAltitude + KERBIN:radius.
print "LaunchFlightCtrl.ks Target alt:" + round(orbitAltitude/1000, 3) + "km".

IF SHIP:STATUS = "PRELAUNCH" {
    LaunchClamped().
}

if SHIP:STATUS = "FLYING" {
    print "Liftoff!".
    PrintStatus(0, "Liftoff", SHIP:STATUS).
	wait 3.
	PrintStatus(0, "Liftoff", SHIP:STATUS, true).

   	set flightProfile to Queue(
		List(300,   90, 80, 1.0),
		List(5000,  90, 70, 1.0),
		List(15000, 90, 60, 1.0),
        List(25000, 90, 45, 1.0),
        List(30000, 90, "p", 1.0)
	).

	lock steering to ship:facing. // heading(90, 90).
	ControlFlight(orbitAltitude, orbitAltitude, flightProfile, 1). // Last engine light stage is #1. Stage 0 is the parachute.

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
