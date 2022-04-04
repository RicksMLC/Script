// LaunchLib.ks

function LaunchClamped {
	set throt to 1.0.
	lock throttle to throt. // 1.0 is the max, 0.0 is idle.

	// Preflight check
	PrintStatus(0, "Pre-launch checks", SHIP:STATUS, true).
	if not Career():CanMakeNodes {
		PRINT "Doomed to Fail: Career limits prevent creation of nodes".
		abort.
	}

    lock unClamped to (ship:partsnamed("launchClamp1"):empty).
	PrintStatus(0, "Counting down pre-launch", true).
    PrintStatus(2, "Clamped", not unClamped).
	from {local countdown is -10.} until countdown = 0 step {set countdown to countdown + 1.} do {
		PrintStatus(1, "Countdown", "T" + countdown).
		wait 1.
	}
	PrintStatus(1, "Countdown", "T0").

    until unClamped {
        PrintStatus(2, "Clamped", not unClamped).
		if (stage:ready) {
			print "Staging " + stage:NUMBER.
			STAGE.
			local twr is 0.
			until twr > 1.1 {
				set tSum to ThrustSum().
				set twr to tSum / mass.
				PrintPairStatus(3, "Thrust: ", round(tSum, 4) + "kN.", "TWR: ", round(twr, 2)).
				wait 0.001.
			}
            PrintStatus(4, "Staged", (choose "Still clamped" if not unClamped else "Clamps free!")).
		}
        wait 0.001.
	}.
    wait until SHIP:STATUS = "FLYING".
}