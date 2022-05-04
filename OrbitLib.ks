// OrbitLib.ksp
// Rick's Mid-Life Crisis.
// Some functions to help with orbits.
// Note: Depends on FlightLib.ks.

function VisVivaDeltaV1 {
	// VisViva is:
	// v^2 = mu(2/r - 1/a)
	// 		v = speed of orbiting body.
	// 		mu = body Gm.
	// 		r = the distance of the orbiting body from the primary focus. altitude + body:radius
	// 		a = semi-major axis of the body's orbit.
	// Convert to deltaV calcultion:
	// dV1 is the transfer from r1 altitude to r2 altitude.
	// dV1 = sqrt(mu / r1)(sqrt(2r2 / (r1 + r2)) - 1)
	
	parameter bodyMu.
	parameter r1.
	parameter r2.
	
	RETURN sqrt(bodyMu / r1) * (sqrt(2 * r2 / (r1 + r2)) - 1).
}

function VisVivaDeltaV2 {
	// VisViva for the final second burn to circularise.
	// dV2 = sqrt(mu / r2)(1 - sqrt(2r1 / (r1 + r2))
	
	parameter bodyMu.
	parameter r1.
	parameter r2.
	
	RETURN sqrt(bodyMu / r2) * (1 - sqrt(2 * r1 / (r1 + r2))).
}

function CreateHohmannTransferNodes {
	// A Hohmann transfer is typically a prograde acceleration
	// to raise the apoapsis or lower the periapsis to the target altitude.
	// https://en.wikipedia.org/wiki/Hohmann_transfer_orbit
	// https://en.wikipedia.org/wiki/Vis-viva_equation
	// The base Hohmann transfer assumes transitioning from one circular orbit to another.
	// In the real world of Kerbin, a perfectly circlular orbit is difficult to do, so the real
	// starting orbit will probably be elliptic ie (the PE and AP will be different).
	// To adjust for this the current difference in velocity between the ideal circular orbit
	// and current orbit at the xferNodePoint is calculated and subtracted to the transfer orbit dV.
	
	// Assume the current periapsis is at the correct longitude for the resulting apoapsis.
	parameter targetAlt.
	parameter startAltitude is SHIP:OBT:PERIAPSIS.
	parameter targetBody is SHIP:BODY.
	parameter etaToNode is -1.
	parameter verbose is false.

	LOCAL timeToXferNodePoint IS etaToNode.
	LOCAl xferPt IS "pe".
	if etaToNode = -1 {
		// Default to transition to a higher orbit.
		set timeToXferNodePoint to ETA:PERIAPSIS.
		if targetAlt < startAltitude {
			// We are transitioning to a lower orbit.
			SET timeToXferNodePoint TO ETA:APOAPSIS.
			set xferPt to "ap".
		}
	}
	
	// Correct for eccentricity of the current orbit
	LOCAL Vo IS CalcOrbitalVelocity(targetBody, startAltitude).
	LOCAL Vnd is VELOCITYAT(SHIP, TIME:Seconds + timeToXferNodePoint):ORBIT:MAG.
	LOCAL vDelta IS Vo - Vnd.

	LOCAL mnDeltaV1 IS VisVivaDeltaV1(targetBody:MU, startAltitude + targetBody:RADIUS, targetAlt + targetBody:RADIUS).
	LOCAL mnDeltaV2 IS VisVivaDeltaV2(targetBody:MU, startAltitude + targetBody:RADIUS, targetAlt + targetBody:RADIUS).
	LOCAL adjmnDeltaV1 is mnDeltaV1 + vDelta. // The difference in dV is the amount already built into the current orbit.
	
	if verbose {
		print "Hohmann Transfer:".
		print "  Current V" + xferPt + ": " + round(Vnd, 2) +"m Vo: " + round(Vo, 2) +"m vDelta: " + round(vDelta, 2) + "m".
		print "  Hohmann transfer: dV1:" + round(mnDeltaV1, 2) + "m, dV2: " + round(mnDeltaV2, 2) +"m".
		print "  Adjusted mvDeltaV1: " + round(adjmnDeltaV1, 2).
	}
	
	LOCAL transferNode IS NODE(TimeSpan(timeToXferNodePoint), 0, 0, adjmnDeltaV1).
	ADD transferNode.

	LOCAL timeToFinalNodePoint is transferNode:ORBIT:ETA:APOAPSIS.
	if targetAlt < startAltitude {
		// We are circularising from a higher orbit.
		SET timeToFinalNodePoint TO transferNode:ORBIT:ETA:PERIAPSIS.
	}

	// Default to circularise from a lower orbit.
	LOCAL orbitNode IS NODE(TimeSpan(timeToFinalNodePoint), 0, 0, mnDeltaV2).
	ADD orbitNode.
	
	return true.
}

function CreateCircularOrbitNode {
	parameter orbitAltitude.
	parameter targetBody is SHIP:BODY.
	parameter verbose is False.
	
	LOCAL Vo IS CalcOrbitalVelocity(targetBody, orbitAltitude, verbose).
	LOCAL mnDeltaV IS Vo - VELOCITYAT(SHIP, TIME:Seconds + ETA:APOAPSIS):ORBIT:MAG.
	
	if verbose {
		Print "  Time: " + TIME:Seconds + ". Ship AP ETA: " + ETA:APOAPSIS.
		Print "  Current velocity: " + round(SHIP:VELOCITY:ORBIT:MAG).
		Print "  Velocity at AP:" + round(VELOCITYAT(SHIP, TIME:Seconds + ETA:APOAPSIS):ORBIT:MAG).
		print "  Calculated Vo: " + Vo.
		Print "  DeltaV: " + mnDeltaV.
	}
	LOCAL tToApoapsis IS ETA:APOAPSIS.
	LOCAL orbitNode IS NODE(TimeSpan(tToApoapsis), 0, 0, mnDeltaV).
	ADD orbitNode.
}

function CalcOrbitalVelocity {
	// Calculate the orbital velocity required for a circular orbit.
	// Vo = Sqrt(Gm / r)
	// 		G = gravitational constant
	//		m = mass of the body
	//		r = distance to the centre of the body.
	// The G constant for the body can be looked up, but as the m is also a constant for
	// that body, Gm is already pre-defined as Body:MU
	
	parameter bodyObj.
	parameter requiredAltitude.
	parameter isVerbose is false.
	if not bodyexists(bodyObj:name) {
		PRINT "CalcOrbitalVelocity(): Error: Body '" + bodyObj:Name + "' does not exist.".
		RETURN 0.
	}
	if (isVerbose) {
		print "CalcOrbitalVelocity(): mu: " + bodyObj:MU + " r " + bodyObj:RADIUS + " alt " + requiredAltitude.
	}
	LOCAL Vo IS sqrt(bodyObj:MU / (bodyObj:RADIUS + requiredAltitude)).
	RETURN Vo.
}

function GetStageMass {
	parameter parentPart.
	if parentPart = "None" {
		return 0.
	}
	local parameter lvl is 0.
	local mSum is parentPart:mass.
	for p in parentPart:children {
		set mSum to mSum + GetStageMass(p, lvl + 1).
	}
	return mSum.
}

function ExecManoeuvreNode {
	// Based on and adapted from tutorial http://ksp-kos.github.io/KOS_DOC/tutorials/exenode.html
	local nd is nextnode.
	print "ExecManoeuvreNode in: " + round(nd:eta) + "s, DeltaV: " + round(nd:deltav:mag, 2) + "m".

	local tset is 0.
	lock throttle to tset.

	// Calculate burn time
	print "stage dv: " + stage:deltav:current + "m/s " + stage:deltav:duration + "s".
	local sDv is stage:deltaV. // ship:stagenum
	local burnT is 0.
	local maxAcc IS ship:MAXTHRUST / ship:mass.

	if sDv:current > nd:deltav:mag {
		print "current stage enough".
		set burnT to nd:deltav:mag / maxAcc.
	} else {
		print "multi-stage needed".
		local decoupler is stage:nextdecoupler.
		local sMass is GetStageMass(decoupler).
		local nextStageMass is ship:mass - sMass.
		print "ship:mass: " + round(ship:mass, 3) + "t sMass: " + round(sMass, 3) + "t nextStageMass: " + round(nextStageMass, 3) + "t".

		set burnT to sDv:duration.
		print "Stage: " + stage:number + " " + round(burnT, 4) + "s" + " dvC: " + round(sDv:current, 3).
		local remainDvMag is nd:deltav:mag - sDv:current.
		// Another stage better be available.
		if stage:nextdecoupler = "None" {
			print "No more stages. Insufficient delta-V. Aborting ExecManoeuvreNode()".
			return.
		}
		local nextEngine is stage:nextdecoupler:parent.
		print "Remaining dV: " + round(remainDvMag, 3).
		// Tsiolkovsky rocket equation:
		// 		dV = Ve * ln(m0 / mf) = ISPg0 * ln(m0/mf)
		// Therefore to find the mass of fuel used to get dV
		//		dV/ISPg0 = ln(m0 / mf)
		//		e^(dV/ISPg0) = m0 / mf
		//		mf * e^(dV/ISPg0) = m0
		// 		mf = m0 / e^(dV/ISPg0).
		local dVonISPg0 is remainDvMag / (nextEngine:VACUUMISP * CONSTANT:g0).
		local m0 is ship:mass - sMass.
		local mf is m0 / (CONSTANT:E ^ dVonISPg0).
		local fuelMass is m0 - mf.
		print "m0: " + round(m0, 4) + " mf: " + round(mf, 4) + " fuel: " + round(fuelMass, 4) + "t".
		print "dVonISPg0: " + round(dVonISPg0, 3).
		local mfBurnT is fuelMass / nextEngine:MaxMassFlow.
		print "Engine MaxMassFlow(MMF): " + round(nextEngine:MaxMassFlow, 4) + " fuel / MMF => mfBurnT: " + round(mfBurnT, 3) + "s".
		
		print "Stage: " + nextEngine:stage + " " + mfBurnT + "s".
		set burnT to burnT + mfBurnT. // add 0.25 stage time?
	}
	print "Calculated Burn Time " + burnT.

	// Now we just need to divide deltav:mag by our ship's max acceleration
	// to get the estimated time of the burn.
	set burn_duration to burnT.
	set startBurnT to (burnT / 2).

	print "Crude Estimated burn duration: " + round(burn_duration) + "s".
	PrintStatus(0, "Node ETA", nd:eta, true).
	// Wait until before the eta - (1/2 the burn time + 60s to allow for slow turning.
	//until nd:eta <= (burn_duration + 60) {
	//	PrintStatus(1, "Start turn at eta -" + round((burn_duration + 60), 1) + "s", round(nd:eta - (burn_duration + 60), 1)).
	//	wait 0.001.
	//}
	//PrintStatus(1, "Lining up for node", nd:eta).

	until nd:eta <= (startBurnT + 60) {
		PrintStatus(1, "Start turn at eta T-" + round((startBurnT + 60), 1) + "s", round(nd:eta - (startBurnT + 60), 1)).
		wait 0.001.
	}
	kuniverse:timewarp:CancelWarp().
	PrintStatus(1, "Lining up for node", nd:eta).

	// Time to line up the ship to the deltav vector.
	local np is nd:deltav. // points to node, don't care about the roll direction.
	//FIXME: What if we lock to nd:deltav instead?
	//lock steering to np.
	lock steering to nd:deltav.
	rcs on.
	WaitToFaceVector(nd:deltav, true).
	rcs off.
	// the ship is facing the right direction, let's wait for our burn time
	until nd:eta <= (startBurnT) {
		PrintPairStatus(3, "Wait for burn. ETA", round(nd:eta, 1) + "s", "Start burn", round(nd:eta - (startBurnT), 1) + "s", 30).
		wait 0.001.
	}

	kuniverse:timewarp:CancelWarp().

	local done is False.
	//initial deltav
	local dv0 is nd:deltav.
	local nodeAP is round(nd:orbit:apoapsis, 2).
	local nodePE is round(nd:orbit:periapsis, 2).
	local targetIsAP is abs(round(ship:obt:apoapsis,2) - nodeAP) > abs(round(ship:obt:periapsis, 2) - nodePE). 
	local epsilonApsis is 1.

	print "targetIs: " + (choose "AP" if targetIsAP else "PE") + " Ship AP:" + round(ship:obt:apoapsis,2) + " nodeAP: " + nodeAP + " Ship PE: " + ship:obt:periapsis + " nodePE: " + nodePE.

	local stagesOk is true.
	until done {

		//recalculate current maxAcceleration, as it changes while we burn through fuel
		set maxAcc to ship:maxthrust/ship:mass.
		
		set stagesOk to StageOnFlameoutCheck(true, 1).

		PrintStatus(4, "Remain dV " + round(nd:deltav:mag,2) + "m/s, vdot: " + round(vdot(dv0,nd:deltav), 1)).
		if targetIsAP {
			PrintPairStatus(5, "Target AP", round(nodeAP, 2), "Curr AP", round(ship:obt:apoapsis, 2)).
		} else {
			PrintPairStatus(5, "Target PE", round(nodePE, 2), "Curr PE", round(ship:obt:periapsis, 2)).
		}

		// TODO: Adjust the pitch of the ship to correct the orbit AP/PE to match the target AP/PE during the burn.
		// Eg: During launch to orbit the first node burn increases the AP while the PE is being brought up to the target PE.
		// The script needs to detect the drift for AP when the target is PE and vice versa.
		// Adjust the pitch proportional to the +/- AP/TargetAP?

		// Staging during this phase may have 0 maxAcc, which will cause divide by 0 error in nd:deltav:mag/maxAcc
		if maxAcc > 0 {

			//throttle is 100% until there is less than 1 second of time left to burn
			//when there is less than 1 second - decrease the throttle linearly
			set tset to min(nd:deltav:mag/maxAcc, 1).

			// here's the tricky part, we need to cut the throttle as soon as our nd:deltav and
			// initial deltav start facing opposite directions
			// this check is done via checking the dot product of those 2 vectors
			if vdot(dv0, nd:deltav) < 0	{
				print "End burn, remain dv " + round(nd:deltav:mag,2) + "m/s, vdot: " + round(vdot(dv0,nd:deltav),1).
				break.
			}

			//we have very little left to burn, less then 0.1m/s
			// Try for 5m first... but should really be 0.1m/s :)
			set finalBurnTheshold to 5.
			if nd:deltav:mag < finalBurnTheshold {
				print "Finalizing burn, remain dv " + round(nd:deltav:mag,2) + "m/s, vdot: " + round(vdot(dv0,nd:deltav),2).
				set tset to min( (nd:deltav:mag)/(maxAcc * 20), 1).
				//we burn slowly until our node vector starts to drift significantly from initial vector
				//this usually means we are on point
				until (targetIsAP and abs((ship:obt:apoapsis - nodeAP)) < epsilonApsis) 
					or (not targetIsAP and abs(ship:obt:periapsis - nodePE) < epsilonApsis)
					or (vdot(dv0, nd:deltav) < 0.01) {
					
					PrintStatus(4, "Remain dV " + round(nd:deltav:mag,2) + "m/s, vdot: " + round(vdot(dv0,nd:deltav), 1)).
					set stagesOk to StageOnFlameoutCheck().
					wait 0.001.
				}
				print "End burn, remain dv " + round(nd:deltav:mag,2) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
				set done to True.
			}
		}
		if not stagesOK {
			set done to True.
		}
	}
	print "Node execution done. Set tset to 0 and unlock throttle.".
	set tset to 0.
	unlock steering.
	unlock throttle.
	wait 1.

	// We no longer need the maneuver node
	remove nd.
}

function ExecHohmannTransfer {
	parameter targetAltitude.
	parameter startAltitude is -1.
	parameter etaToNode is -1.
	parameter verbose is false.

	print "ExecHohmannTransfer:".
	if not HASNODE {
		if startAltitude = -1 {
			set startAltitude to SHIP:OBT:PERIAPSIS.
			if targetAltitude < startAltitude {
				SET startAltitude TO SHIP:OBT:APOAPSIS.
			}
		}

		print "  Hohmann Node target alt: " + targetAltitude + " Start alt: " + startAltitude.
		if (CreateHohmannTransferNodes(targetAltitude, startAltitude, SHIP:BODY, etaToNode, verbose)) {
			PRINT "  Hohmann transfer nodes prepared.".
		} else {
			PRINT " Failed to create Hohmann transfer nodes :(".
		}
	}
	if HASNODE {
		ExecManoeuvreNode().
		PRINT " Transfer complete.".
	}
	if HASNODE {
		ExecManoeuvreNode().
		PRINT "  Final burn complete.".
	}
}