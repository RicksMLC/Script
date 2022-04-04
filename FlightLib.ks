// FlightLib.ks
// Rick's Mid Life Crisis
// Some handy functions for flight.

function StageOnFlameoutCheck {
	// Returns True if no flameout yet or successfully staged to a new engine
	// Returns False if all stages deployed and still no thrust.
    parameter verbose is false.
    parameter lastStageNum is 1.

    // Check for engine flameout:
    list ENGINES in engList.
    for eng in engList {
		if eng:flameout {
            if verbose {
			    print "StageOnFlameoutCheck() " + eng:name + " Flameout STAGING " + stage:NUMBER.
            }
			STAGE.
			wait until stage:ready.
			wait 0.001.
			until maxthrust > 0 {
                if stage:number < lastStageNum {
                    if verbose {
					    print "StageOnFlameoutCheck() maxthrust = 0 NO MORE STAGES - return false." + stage:NUMBER.
                    }
					return false.
				}
                if verbose {
				    print "StageOnFlameoutCheck() maxthrust = 0 STAGING " + stage:NUMBER.
                }
				stage.
				wait until stage:ready.
				wait 0.001.
			}
			return true.
		}
	}
	return true. // No flameouts
}

function NullDelegate {}

function SetAllAntennasOn {
	parameter activate is true.
	set antennas to ship:partstagged("antenna").
	if antennas:empty {
		print "SetAntanna Fail: no tagged 'antenna' parts.".
		return.
	}
	for antenna in antennas {
		// Check for non-RemoteTech?
		set am to antenna:getmodule("ModuleRTAntenna").
		set eventName to (choose "A" if activate else "Dea") +"ctivate".
		print eventName + "ing antenna '" + antenna:name + "'".
		am:DoEvent(eventName).
	}
}

function ControlFlight {
	parameter targetAp.
	parameter targetAlt.
	parameter flightProfile. // Queue of List(alt, heading, pitch, throttle)
	parameter lastStageNum is 0.
	parameter execDelegate is NullDelegate@. // This delegate must not block: no waiting.

	PrintStatus(0, "Launch Flight Control", SHIP:STATUS, true).
	list engines in engList.
	local isFlamedOut to false.
	local n to 2.
	local curProfile is flightProfile:POP.
    local hdg is heading(90, 90).
    lock steering to hdg.
    local throt is 1.
    lock throttle to throt.
    set planComplete to false.
    set horiz to heading(90, 0).
	until apoapsis >= targetAp 
		or ship:ALTITUDE >= targetAlt
        or isFlamedOut
	{
		if not planComplete and ship:ALTITUDE > curProfile[0] {
            print "flightProfile: " + flightProfile:Length.
            if curProfile[2] = "p" {
                print "Lock steering to prograde".
                lock steering to prograde.
            } else {
                print "At " + round(curProfile[0]) + " Lock steering to heading(" + round(curProfile[1]) + ", " + round(curProfile[2]) + ")".
			    set hdg to heading(curProfile[1], curProfile[2]).
            }
			set throt to curProfile[3].
            if flightProfile:Length > 0 {
			    set curProfile to flightProfile:POP.
            } else {
                set planComplete to true.
            }
		}

		PrintStatus(0, "Launch Flight Control", SHIP:STATUS).
		PrintMultiStatus(1, "Ap", round(apoapsis), "Alt", round(ship:altitude), "Hdg", round(ship:bearing)).
		PrintPairStatus(2,  "Pitch", round(vang(horiz:FOREVECTOR, SHIP:FACING:FOREVECTOR), 2), "Throttle", round(THROTTLE, 2)).
        PrintMultiStatus(3, "Next alt", round(curProfile[0]), "Pitch", choose "Prograde" if curProfile[2] = "p" else round(curProfile[2]), "Throttle", round(curProfile[3], 2)).

		execDelegate:Call().

        set isFlamedOut to not StageOnFlameoutCheck(true, lastStageNum).

		wait 0.01.
	}
}

function DeployFairing {
	parameter tag.
	set fairings to ship:partstagged(tag).
	if fairings:empty {
		print "DeployFairing fail: No tagged '" + tag + "' parts.".
		return.
	}
	for fairing in fairings {
		set fm to fairing:getmodule("ModuleProceduralFairing").
		print "Deploying fairing".
		fm:DoEvent("deploy").
	}
}


function WaitToFacePrograde {
    parameter verbose is false.
    WaitToFaceShipDirection(true, verbose).
}

function WaitToFaceRetrograde {
    parameter verbose is false.
    WaitToFaceShipDirection(false, verbose).
}

function ThrustSum {
    list engines in eList.
    local sumThrust is 0.
    for e in eList {
        set sumThrust to sumThrust + e:thrust.
    }
    return sumThrust.
}


local epsilonDegAngle is 0.5.
function WaitToFaceShipDirection {
    parameter isPrograde is true.
    parameter verbose is false.

    lock targetDir to choose SHIP:PROGRADE if isPrograde else SHIP:RETROGRADE.
    local targetVang is round(vang(targetDir:FOREVECTOR, ship:facing:vector) - epsilonDegAngle, 2).
	until vang(targetDir:FOREVECTOR, ship:facing:vector) < epsilonDegAngle {
        if verbose {
		    PrintPairStatus(2, "Turn ", targetVang, " d", vang(targetDir:FOREVECTOR, ship:facing:vector)).
        }
		wait 0.001.
	}
}


function WaitToFaceDirection {
    parameter dir.
    parameter verbose is false.

    WaitToFaceVector(dir:FOREVECTOR, verbose).
}

function WaitToFaceVector {
    parameter vect.
    parameter verbose is false.

    local targetVang is round(vang(vect, ship:facing:vector) - epsilonDegAngle, 2).
	until vang(vect, ship:facing:vector) < epsilonDegAngle {
        if verbose {
		    PrintPairStatus(2, "Turn ", targetVang, " d", vang(vect, ship:facing:vector)).
        }
		wait 0.001.
	}
}