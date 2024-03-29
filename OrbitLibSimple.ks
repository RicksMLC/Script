// OrbitLibSimple.ksp
// Rick's Mid-Life Crisis.
// Some functions to help with orbits - Early Version.

function StageOnFlameoutCheck {
	// Returns True if no flameout yet or successfully staged to a new engine
	// Returns False if all stages deployed and still no thrust.
    // Check for engine flameout:
    list ENGINES in engList.
    for eng in engList {
		if eng:flameout {
			wait until stage:ready.
			print "StageOnFlameoutCheck() " + eng:name + " Flameout STAGING " + stage:NUMBER.
			STAGE.
			wait until stage:ready.
			wait 0.001.
			until maxthrust > 0 {
				print "StageOnFlameoutCheck() maxthrust = 0 STAGING " + stage:NUMBER.
				stage.
				wait until stage:ready.
				wait 0.001.
				if stage:number < 1 {
					print "StageOnFlameoutCheck() maxthrust = 0 NO MORE STAGES - return false." + stage:NUMBER.
					return false.
				}
			}
			return true.
		}
	}
	return true. // No flameouts
}


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
	// 
	
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

function ExecManoevourNodeSimple {
	// As per the tutorial http://ksp-kos.github.io/KOS_DOC/tutorials/exenode.html
	local nd is nextnode.
	// print out node's basic parameters - ETA and deltaV
	print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).
	
	// Calculate the ship's max acceleration
	LOCAL max_acc IS ship:maxthrust / ship:mass.
	
	// Now we just need to divide deltav:mag by our ship's max acceleration
	// to get the estimated time of the burn.
	//
	// Please note, this is not exactly correct.  The real calculation
	// needs to take into account the fact that the mass will decrease
	// as you lose fuel during the burn.  In fact throwing the fuel out
	// the back of the engine very fast is the entire reason you're able
	// to thrust at all in space.  The proper calculation for this
	// can be found easily enough online by searching for the phrase
	//   "Tsiolkovsky rocket equation".
	// This example here will keep it simple for demonstration purposes,
	// but if you're going to build a serious node execution script, you
	// need to look into the Tsiolkovsky rocket equation to account for
	// the change in mass over time as you burn.
	//
	set burn_duration to nd:deltav:mag/max_acc.
	print "Crude Estimated burn duration: " + round(burn_duration) + "s".
	PrintStatus(0, "Node ETA", nd:eta).
	// Wait until before the eta - (1/2 the burn time + 60s to allow for slow turning.
	until nd:eta <= (burn_duration/2 + 60) {
		PrintStatus(1, "Start turn at eta -" + round((burn_duration/2 + 60), 1) + "s", round(nd:eta - (burn_duration/2 + 60), 1)).
		wait 0.001.
	}
	PrintStatus(1, "Lining up for node", nd:eta).

	// Time to line up the ship to the deltav vector.
	local np is nd:deltav. //points to node, don't care about the roll direction.
	lock steering to np.

	// now we need to wait until the burn vector and ship's facing are aligned
	local targetVang is round(vang(np, ship:facing:vector) - 0.25, 2).
	until vang(np, ship:facing:vector) < 0.25 {
		PrintPairStatus(2, "Turn to ", targetVang, " cur", vang(np, ship:facing:vector)).
		wait 0.001.
	}

	// the ship is facing the right direction, let's wait for our burn time
	until nd:eta <= (burn_duration/2) {
		PrintPairStatus(3, "Wait for burn. ETA", round(nd:eta, 1) + "s", "Start burn", round(nd:eta - (burn_duration/2), 1) + "s", 30).
		wait 0.001.
	}

	// we only need to lock throttle once to a certain variable in the beginning of the
	// loop, and adjust only the variable itself inside it.
	local tset is 0.
	lock throttle to tset.

	local done is False.
	//initial deltav
	local dv0 is nd:deltav.
	until done {

		//recalculate current max_acceleration, as it changes while we burn through fuel
		set max_acc to ship:maxthrust/ship:mass.
		
		// Staging during this phase may have 0 max_acc, which will cause divide by 0 error in nd:deltav:mag/max_acc
		if max_acc > 0 {

			//throttle is 100% until there is less than 1 second of time left to burn
			//when there is less than 1 second - decrease the throttle linearly
			set tset to min(nd:deltav:mag/max_acc, 1).

			// here's the tricky part, we need to cut the throttle as soon as our nd:deltav and
			// initial deltav start facing opposite directions
			// this check is done via checking the dot product of those 2 vectors
			if vdot(dv0, nd:deltav) < 0
			{
				print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0,nd:deltav),1).
				lock throttle to 0.
				break.
			}

			//we have very little left to burn, less then 0.1m/s
			if nd:deltav:mag < 0.1
			{
				print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0,nd:deltav),1).
				
				//we burn slowly until our node vector starts to drift significantly from initial vector
				//this usually means we are on point
				wait until vdot(dv0, nd:deltav) < 0.5.

				lock throttle to 0.
				print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
				set done to True.
			}
		}
	}
	unlock steering.
	unlock throttle.
	wait 1.

	//we no longer need the maneuver node
	remove nd.
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
	local nd is nextnode.
	print "ExecManoeuvreNode in: " + round(nd:eta) + "s, DeltaV: " + round(nd:deltav:mag, 2) + "m".
	
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
	PrintStatus(0, "Node ETA", nd:eta).
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
	PrintStatus(1, "Lining up for node", nd:eta).

	// Time to line up the ship to the deltav vector.
	local np is nd:deltav. //points to node, don't care about the roll direction.
	//FIXME: What if we lock to nd:deltav instead?
	//lock steering to np.
	lock steering to nd:deltav.

	// now we need to wait until the burn vector and ship's facing are aligned
	local targetVang is round(vang(np, ship:facing:vector) - 0.25, 2).
	until vang(np, ship:facing:vector) < 0.25 {
		PrintPairStatus(2, "Turn to ", targetVang, " cur", vang(np, ship:facing:vector)).
		wait 0.001.
	}

	// the ship is facing the right direction, let's wait for our burn time
	until nd:eta <= (startBurnT) {
		PrintPairStatus(3, "Wait for burn. ETA", round(nd:eta, 1) + "s", "Start burn", round(nd:eta - (startBurnT), 1) + "s", 30).
		wait 0.001.
	}

	local tset is 0.
	lock throttle to tset.

	local done is False.
	//initial deltav
	local dv0 is nd:deltav.
	local nodeAP is round(nd:orbit:apoapsis, 2).
	local nodePE is round(nd:orbit:periapsis, 2).
	local targetIsAP is round(ship:obt:apoapsis,2) < nodeAP. 

	local stagesOk is true.
	until done {

		//recalculate current maxAcceleration, as it changes while we burn through fuel
		set maxAcc to ship:maxthrust/ship:mass.
		
		set stagesOk to StageOnFlameoutCheck().

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
			if vdot(dv0, nd:deltav) < 0
			{
				print "End burn, remain dv " + round(nd:deltav:mag,2) + "m/s, vdot: " + round(vdot(dv0,nd:deltav),1).
				lock throttle to 0.
				break.
			}

			//we have very little left to burn, less then 0.1m/s
			// Try for 15m first... but should really be 0.1m/s :)
			set finalBurnTheshold to 15.
			if nd:deltav:mag < finalBurnTheshold
			{
				print "Finalizing burn, remain dv " + round(nd:deltav:mag,2) + "m/s, vdot: " + round(vdot(dv0,nd:deltav),2).
				set tset to min( (nd:deltav:mag)/(maxAcc * 10), 1).
				local epsilonApsis is 0.01. // m/s
				//we burn slowly until our node vector starts to drift significantly from initial vector
				//this usually means we are on point
				until (vdot(dv0, nd:deltav) < 0.01) 
					or (targetIsAP and abs((ship:obt:apoapsis - nodeAP)) < epsilonApsis) 
					or (not targetIsAP and abs(ship:obt:periapsis - nodePE) < epsilonApsis) {

					set stagesOk to StageOnFlameoutCheck().
					wait 0.001.
				}
				lock throttle to 0.
				print "End burn, remain dv " + round(nd:deltav:mag,2) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
				set done to True.
			}
		}
		if not stagesOK {
			set done to True.
		}
	}
	unlock steering.
	unlock throttle.
	wait 1.

	// We no longer need the maneuver node
	remove nd.
}