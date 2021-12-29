// function GetStageDryMass {
// 	parameter parentPart.
//     //print parentPart:name + " drymass: " + parentPart:drymass.
// 	local mSum is parentPart:drymass.
// 	for p in parentPart:children {
// 		set mSum to mSum + GetStageDryMass(p).
// 	}
// 	return mSum.
// }

function GetStageDryMass {
	parameter parentPart.
	local parameter lvl is 0.
	if lvl = 0 print "GetStageDryMass:".
    print round(lvl) + "":padleft(lvl) + "part: " + parentPart:name + " " + parentPart:CID + " drymass: " + parentPart:drymass.
	local mSum is parentPart:drymass.
	for p in parentPart:children {
		set mSum to mSum + GetStageDryMass(p, lvl + 1).
	}
	return mSum.
}

parameter nd_deltaV_mag.
print "GetStageDryMass".
print GetStageDryMass(stage:nextdecoupler).

if false {
    local sDv is stage:deltaV. // ship:stagenum
    local burnT is 0.
    local maxAcc IS ship:MAXTHRUST / ship:mass.
    local decoupler is stage:nextdecoupler.
    set sMass to GetStageDryMass(decoupler).

    if sDv:current > nd_deltav_mag {
        print "curr stage enough".
        set burnT to nd_deltav_mag / max_acc.
    } else {
        print "multi-stage needed".
        set burnT to sDv:duration.
        print "stage " + stage:number + " " + burnT + "s".
        local remainDvMag is nd_deltav_mag - sDv:current.
        // Another stage better be available.
        local nextEngine is stage:nextdecoupler:parent.
        //local nDv is ship:stagedeltav(nextEngine:stage).
        local stageAcc is nextEngine:maxpossiblethrust / (ship:mass - sMass).
        print "stage: " + nextEngine:stage + " " + (remainDvMag / stageAcc) + "s".
        set burnT to burnT + (remainDvMag / stageAcc).
    }
    print "Burn Time " + burnT.
}
