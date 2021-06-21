//LobShotCheapSounder.ks

function NullDelegate {

}

function ControlFlight {
	parameter targetAp.
	parameter targetAlt.
	parameter lastStageNum is 0.
	parameter execDelegate is NullDelegate@. // This delegate must not block: no waiting.

	// Check for engine flameout:
	PrintStatus(0, "Launch Flight Control", SHIP:STATUS, true).
	list engines in engList.
	print engList.
	local isFlamedOut to false.
	local n to 2.
	when SHIP:ALTITUDE > 250 then {
		lock steering to heading(90, 85).
	}
	until apoapsis >= targetAp 
		or ship:ALTITUDE >= targetAlt
		or engList:empty
		or (engList:Length = 1 and engList[0]:flameout) 
	{
		PrintStatus(0, "Launch Flight Control", SHIP:STATUS).
		PrintPairStatus(1, "Ap", round(apoapsis), "Alt", round(ship:altitude)).
		PrintPairStatus(n, "Engines:", engList:Length, "Eng0:", engList[0]:flameout).
		
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
sciQueue:PUSH(17000).
sciQueue:PUSH(70100).

function CollectSciOnAlt {
	set go to sciQueue:PEEK.
	if SHIP:ALTITUDE >= go {
		CollectSci(sciStage, sciStageLine).
		set sciStage to sciStage + 1.
		sciQueue:POP.
	}
}

function CollectSci {
	parameter sciStage.
	parameter n.
	for sciModule in sciModules {
		if sciStage < sciModule:Length {
			DeployAndRetainSci(sciModule[sciStage], n).
			set n to n + 1.
			print "PreLaunch: Sci["+sciStage+ "] " + sciModule[sciStage]:part:name + " Done.".
		}
	}
}

wait until ship:unpacked.

lock throttle to 1.0.
lock steering to heading(90, 90).
print "LobShotCheapSounder.ks".

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
//	CollectSci(sciStage, n).
	set sciStage to sciStage + 1.

	PrintStatus(0, "PreLaunch", SHIP:STATUS, true).
	from {local countdown is 10.} until countdown = 0 step {set countdown to countdown -1.} do {
		PrintStatus(1, "Launch", "T-" + countdown).
		wait 1.
	}

	stage.
	wait until stage:ready.
}

if SHIP:STATUS = "FLYING" {
	PrintStatus(0, "Flying", SHIP:STATUS, true).
	print "Sci at Ap".

	lock steering to ship:facing. // heading(90, 90).
	ControlFlight(72000, 72000, 1, CollectSciOnAlt@). // Last engine light stage is #1. Stage 0 is the parachute.
}

if apoapsis > 70000 {
	wait until SHIP:STATUS = "SUB_ORBITAL".
	CollectSci(sciStage, n).	
}

print "Chutessafe trigger active...".
WHEN (not CHUTESSAFE) THEN {
	CHUTESSAFE ON.
	RETURN (NOT CHUTES).
}
lock throttle to 0.
wait until alt:radar < 100.
print "End of launch test.".
