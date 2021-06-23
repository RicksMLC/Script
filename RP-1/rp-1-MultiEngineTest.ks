
function ThrustSum {
    list engines in eList.
    local sumThrust is 0.
    for e in eList {
        set sumThrust to sumThrust + e:thrust.
    }
    return sumThrust.
}

core:DoEvent("open terminal").
print "rp-1-MultiEngineTest.ks".
print "Setting pilot throttle to max".
set ship:control:pilotmainthrottle to 1.
print "Run Test? (y): ".
set ch to terminal:input:getchar().
if ch = "y" {
    local curTwr is 0.
    stage.
    until curTwr > 1 {
        set curThrust to ThrustSum().
		set curTwr to curThrust / mass.
		print "Thrust: " + round(curThrust, 4) + "kN. TWR: " + round(curTwr, 2).
        PrintStatus(0, "TWR", curTwr).
    }
    RunMultiEngineStage(true).
}
print "Program End.".
