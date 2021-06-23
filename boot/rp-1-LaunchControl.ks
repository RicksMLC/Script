// RP-1 Launch Controller
function PitchAtAltitude{
	parameter alt.
	parameter pitch.
	print "waiting for alt > " + round(alt) + " to set pitch to " + round(pitch).
	wait until altitude > alt.
	lock steering to heading(90, pitch, 0).
	print "Set steering to (90, " + round(pitch) + ", 0)".
}

wait until ship:unpacked.
core:DoEvent("open terminal").
print "Launch Controller ver 0.1".
list engines in eList.
print eList.
print "Enter main engine number:".
set n to terminal:input:getchar().
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
	stage.
	until e:thrust >= e:possiblethrust {
		print "Thrust: " + round(e:thrust, 4) + "kN possible: " + round(e:possiblethrust, 4) + "kN" at(0, 15).
		wait 0.001.
	}
	wait until stage:ready. stage.
	print "Liftoff".

	PitchAtAltitude(1000, 80).
	PitchAtAltitude(5000, 70).
	PitchAtAltitude(10000, 65).
	PitchAtAltitude(20000, 60).
	PitchAtAltitude(25000, 55).
	PitchAtAltitude(30000, 50).
	PitchAtAltitude(35000, 45).

	wait until apoapsis > 100000.

	wait until e:flameout.
	set steer to prograde.
	lock steering to steer.
	until altitude > 100000 {
		set steer to prograde.
		wait 0.001.
	}

	// Stage the fairings and base, then adjust direction for next stage
	// acceleration.
	stage.
	wait until stage:ready.
	stage.
	rcs on.
	lock steering to heading(90,45,0).
	wait 20. // give it time to point in the right direction.

	// Second stage: Stage the solids for ullage and then stage the Aerobees
	stage. wait until stage:ready. stage.

	// Second stage running - watch for flameouts.
	set eAs to ship:partstagged("S2-Ea").
	set eBs to ship:partstagged("S2-Eb").
	set isFlameout to false.
	while not isFlameout {
		for engine in eAs {
			if engine:flameout {
				for e in eAs {
					e:shutdown.
				}
				set isFlameout to true.
			}
		}
		for engine in eBs {
			if engine:flameout {
				for e in eBs {
					e:shutdown.
				}
				set isFlameout to true.
			}
		}
		wait 0.001.
	}
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
