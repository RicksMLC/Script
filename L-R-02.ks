//L-R-02.ks : Launch And Recover booster test

wait until ship:unpacked.

InitPrintStatus().

lock throttle to 1.0.
lock steering to heading(90, 80).
print "L-R-02.ks Launch and Recover Test 02".

if SHIP:STATUS = "PRELAUNCH" {

    print "PreLaunch phase of testing.".
    PrintStatus(0, "PreLaunch", SHIP:STATUS, true).
    from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
        PrintStatus(1, "Launch", "T-" + countdown).
        wait 1.
    }

    set lastLaunchStage to 2.
    // While we still have launch clamps, we are pinned to the ground.
    lock clamps to ship:partsnamed("launchClamp1").
    lock unClamped to (ship:partsnamed("launchClamp1"):empty).
    print "Got clamps? " + not unClamped.
    until unClamped {
        PrintStatus(1, "Clamped", not unClamped).
		if (stage:ready) {
			print "Staging " + stage:NUMBER.
			STAGE.
            PrintStatus(2, "Staged", (choose "Still clamped" if not unClamped else "Clamps free!")).
		}
        wait 0.001.
	}.
    print "Ship unclamped.  Moving on...".
  
    ControlFlight().
    lock throttle to 0.
    print "End of launch test.".
}
function ControlFlight {
	// Check for engine flameout:
	PrintStatus(0, "Launch Flight Control", SHIP:STATUS, true).
	list engines in engList.
	print engList.
	set n to 0.
	set lastStageNum to 1.
	set isFlamedOut to false.
	until stage:NUMBER <= lastStageNum
		or engList:empty
		or (engList:Length = 1 and engList[0]:flameout) 
	{
		PrintStatus(0, "Launch Flight Control", SHIP:STATUS).
		PrintStatus(1, "Stage", STAGE:NUMBER + " flameout check (" + n + ")").
		set i to 0.
		for eng in engList {
			PrintStatus(2 + i, "Engine", eng:name + " flameout: " + eng:flameout).
			set i to i + 1.
			if eng:flameout {
				set isFlamedOut to true.
			}
		}
		if isFlamedOut {
			wait until stage:ready.
			STAGE.
			set n to n + 1.
			print "STAGING " + stage:NUMBER.
			list engines in engList.
			wait 2. // pause for effect
			PrintStatus(0, "Launch Flight Control", SHIP:STATUS, true).
			set isFlamedOut to false.
		}
		wait 0.001.
	}
	print "Engine status check finished.".
	PrintStatus(0, "Coasting to Parachute Deploy", SHIP:STATUS, true).
	print "Waiting until Ap > 50000".
	until APOAPSIS > 50000 {
		PrintStatus(0, "Coasting to Parachute Deploy", SHIP:STATUS).
		PrintStatus(1, "Ap", APOAPSIS).
		PrintStatus(2, "Alt",Round(SHIP:ALTITUDE,1)).
		PrintStatus(3, "Chutessafe", CHUTESSAFE).
		PrintStatus(4, "Chutes deployed", CHUTES).
		wait 0.001.
	}
	PrintStatus(1, "Ap", "> 50000").
	lock throttle to 0.
	print "Waiting until Altitude > 70000".
	until SHIP:ALTITUDE > 70000 {
		PrintStatus(0, "Coasting to Parachute Deploy", SHIP:STATUS).
		PrintStatus(2, "Alt",Round(SHIP:ALTITUDE,1)).
		PrintStatus(3, "Chutessafe", CHUTESSAFE).
		PrintStatus(4, "Chutes deployed", CHUTES).
		wait 0.001.
	}
	PrintStatus(2, "Alt", "> 70000").
	print "Staging fairings.".
	stage.
	print "Chutessafe trigger active...".
	WHEN (not CHUTESSAFE) THEN {
		CHUTESSAFE ON.
		RETURN (NOT CHUTES).
	}
	print "Waiting until all chutes are safe.".
	until CHUTES {
		PrintStatus(0, "Coasting to Parachute Deploy", SHIP:STATUS).
		PrintStatus(3, "Chutessafe", CHUTESSAFE).
		PrintStatus(4, "Chutes deployed", CHUTES).
		wait 0.001.
	}
	PrintStatus(4, "Chutes deployed", CHUTES).
	print SHIP:STATUS.
	PrintStatus(0, "Final Phase", SHIP:STATUS, true).
	until SHIP:VERTICALSPEED = 0 and ALTITUDE < 1000 {
		PrintStatus(0, "Final Phase", SHIP:STATUS).
		PrintStatus(1, "Vert Speed", round(SHIP:VERTICALSPEED, 2)).
		wait 0.001.
	}
	print SHIP:STATUS.
	wait 10.
	PrintStatus(0, "Final Phase", SHIP:STATUS).
	print SHIP:STATUS.
}
