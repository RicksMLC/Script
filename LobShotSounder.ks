//LobShotSounder.ks

function NullDelegate {
}

function ControlFlight {
	parameter targetAp.
	parameter targetAlt.
	parameter flightProfile.
	parameter lastStageNum is 0.
	parameter execDelegate is NullDelegate@. // This delegate must not block: no waiting.

	// Check for engine flameout:
	PrintStatus(0, "Launch Flight Control", SHIP:STATUS, true).
	list engines in engList.
	local isFlamedOut to false.
	local n to 2.
	local planAttitude is flightProfile:POP.
	until apoapsis >= targetAp 
		or ship:ALTITUDE >= targetAlt
		or engList:empty
		or (engList:Length = 1 and engList[0]:flameout) 
	{
		if ship:ALTITUDE > planAttitude[0] {
			lock steering to heading(90, planAttitude[1]).
			lock throttle to planAttitude[2].
			set planAttitude to flightProfile:POP.
		}

		PrintStatus(0, "Launch Flight Control", SHIP:STATUS).
		PrintPairStatus(1, "Ap", round(apoapsis), "Alt", round(ship:altitude)).
		PrintPairStatus(2, "Pitch", round(SHIP:FACING:PITCH, 2), "Throttle", round(THROTTLE, 2)).
		PrintPairStatus(3, "Next", round(planAttitude[1]), "Throttle", round(planAttitude[2], 2)).

		execDelegate:Call().

		for eng in engList {
			if eng:flameout {
				set isFlamedOut to true.
			}
		}
		if isFlamedOut {
			if stage:NUMBER > lastStageNum {
				print "STAGING " + stage:NUMBER.
				wait until stage:ready.
				STAGE.
			}
			set n to n + 1.
			list engines in engList.
			PrintStatus(0, "Launch Flight Control", SHIP:STATUS).
			set isFlamedOut to false.
		}
		wait 0.001.
	}
}

global sciQueue is Queue().
sciQueue:PUSH(0.86).
sciQueue:PUSH(17000).
sciQueue:PUSH(70100).

function CollectSciOnAlt {
	set go to sciQueue:PEEK.
	if SHIP:ALTITUDE >= go {
		print "Science alt " + round(go, 2) + "m.  Collecting science.".
		CollectSci(sciStage, sciStageLine).
		set sciStage to sciStage + 1.
		sciQueue:POP.
	} else {
		PrintStatus(4, "Next Sci Alt", go).
	}
}

function CollectSci {
	parameter sciStage.
	parameter n.
	for sciModule in sciModules {
		if sciStage < sciModule:Length {
			DeployAndRetainSci(sciModule[sciStage], n).
			set n to n + 1.
			print ship:status + ": Sci["+sciStage+ "] " + sciModule[sciStage]:part:name + " Done.".
		}
	}
}

wait until ship:unpacked.

lock throttle to 1.0.
lock steering to heading(90, 90).
print "LobShotSounder.ks".

set sciList to List(
	"sensorThermometer",
	"sensorBarometer",
	"GooExperiment",
	"restock-goocanister-625-1").

set sciModules to List().
for sciName in sciList {
	set sciModule to GetSciModules(sciName).
	if sciModule[0] {
		sciModules:Add(sciModule[1]).
	}	
}

global sciStage to 0.
global sciStageLine to 5.

if sciModules:Length > 0 {
	print "... for SCIENCE!".
} else {
	print "... for glory only.".
}

if SHIP:STATUS = "PRELAUNCH" {
	print "PreLaunch phase.".
	PrintStatus(0, "PreLaunch", SHIP:STATUS, true).

	local n is 5.
	//set sciStage to sciStage + 1.

	PrintStatus(0, "PreLaunch", SHIP:STATUS, true).
	from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
		PrintStatus(1, "Launch", "T-" + countdown).
		wait 1.
	}

	stage.
	wait until stage:ready.
}

print "Debugging science:".
CollectSciOnAlt().
print "Debugging science done.".

if SHIP:STATUS = "FLYING" {
	PrintStatus(0, "Flying", SHIP:STATUS, true).

	set flightProfile to Queue(
		List(200, 90, 1.0),
		List(30000, 85, 1.0),
		List(45000, 60, 1.0)
	).

	lock steering to ship:facing. // heading(90, 90).
	ControlFlight(72000, 72000, flightProfile, 1, CollectSciOnAlt@). // Last engine light stage is #1. Stage 0 is the parachute.
}

if apoapsis > 70000 {
	wait until SHIP:STATUS = "SUB_ORBITAL".
	CollectSci(sciStage, 5).	
}

print "Chutessafe trigger active...".
WHEN (not CHUTESSAFE) THEN {
	CHUTESSAFE ON.
	RETURN (NOT CHUTES).
}
lock throttle to 0.
wait until alt:radar < 100.
print "End of launch test.".
