// RP-1 Launch Controller
function PitchAtAltitude{
	parameter alt.
	parameter pitch.
	print "waiting for alt > " + round(alt) + " to set pitch to " + round(pitch).
	wait until altitude > alt.
	lock steering to heading(90, pitch, 0).
	print "Set steering to (90, " + round(pitch) + ", 0)".
}

function ThrustSum {
    list engines in eList.
    local sumThrust is 0.
    for e in eList {
        set sumThrust to sumThrust + e:thrust.
    }
    return sumThrust.
}

//wait until ship:unpacked.
//core:DoEvent("open terminal").
print "Launch Controller ver 1.1".
list engines in eList.
print eList.
print "Enter main engine number:".
local c is " ".
local n is "".
until c = terminal:input:return {
	set c to terminal:input:getchar().
	if c <> terminal:input:return. {
		set n to n + c.
	}
}
set e to eList[n:TOSCALAR(-1)].
print "Engine:" + e.

print "Setting pilot throttle to max".
set ship:control:pilotmainthrottle to 1.

print "Set steering to up (90, 90, 0)".
lock steering to heading(90, 90, 0).
print "Launch? (y): ".
set ch to terminal:input:getchar().
if ch = "y" {
	print "Proceeding with launch. Engine start". print "". print "".
	local twr is 0.
	stage.
	until twr > 1.1 {
		set tSum to ThrustSum().
		set twr to tSum / mass.
		print "Thrust: " + round(tSum, 4) + "kN. TWR: " + round(twr, 2) at(0,14).
	}
	print "".
	// FIXME: Remove
	//until e:thrust >= e:possiblethrust {
	//	print "Thrust: " + round(e:thrust, 4) + "kN possible: " + round(e:possiblethrust, 4) + "kN" at(0, 15).
	//	wait 0.001.
	//}
	wait until stage:ready. stage.
	print "Liftoff".

	PitchAtAltitude(1000, 80).
	PitchAtAltitude(5000, 70).
	PitchAtAltitude(15000, 65).
	PitchAtAltitude(25000, 60).
	PitchAtAltitude(30000, 55).
	PitchAtAltitude(40000, 45).

	print "wait until flameout.".
	wait until e:flameout.

	lock steering to heading(90,45,0).

	wait until altitude > 70000.

	// Aerobee Quad Midstage
	// wait until altitude > 50000.
	// print "S2: Quad Aerobee stage.".
	// stage. wait until stage:ready.
	// stage. wait until stage:ready.
	// stage. wait 0.7. stage.
	// rcs on.
	// wait 1. // Engine spool up time
	// RunMultiEngineStage("S2", true).

	print "Lock on to Stage 3 trajectory > 100km".
	set steer to prograde.
	lock steering to steer.
	until altitude > 100000 {
		set steer to prograde.
		wait 0.001.
	}

	// Stage the fairings and base, then adjust direction for next stage
	// acceleration.
	rcs on.
	stage.
	wait until stage:ready.
	stage.
	lock steering to heading(90,20,0).
	print "  wait 10... ".
	wait 10. // give it time to point in the right direction.

	print "S3. Payload Stage".
	// Stage the solids for ullage and then stage the Aerobees
	stage.
	wait 0.6.
	stage.
	wait until stage:ready.

	wait 1. // Engine spool up time

    RunMultiEngineStage("S3", true).

	// FIXME: Wait until after apoapsis reached?

	lock steering to heading(90,20,0).

	wait until altitude < 140000.
	lock steering to heading(90, -30, 0).
	wait until altitude < 110000.
	set steer to prograde.
	lock steering to steer.
	until altitude > 100000 {
		set steer to prograde.
		wait 0.001.
	}


} else {
    print "Launch aborted.".
}
print "Program end.".
