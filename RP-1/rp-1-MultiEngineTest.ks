
core:DoEvent("open terminal").
print "rp-1-MultiEngineTest.ks".
print "Setting pilot throttle to max".
set ship:control:pilotmainthrottle to 1.
print "Run Test? (y): ".
set ch to terminal:input:getchar().
if ch = "y" {
    stage.
    local engineSpoolUpTime is 1.
    RunMultiEngineStage(engineSpoolUpTime, true).
}
print "Program End.".
