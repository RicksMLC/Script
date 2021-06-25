// autoload.ks
// Rick's Mid-Life Crisis
// Script for loading other scripts.

wait until ship:unpacked.
core:DoEvent("open terminal").
print "rp-1-auto.ks running...".
set ksList to list("psLib", "RP-1/rp-1-EngineFailures", "RP-1/rp-1-MultiEngineTest").
set runList to "".
for ks in ksList {
    deletepath(ks + ".ks").
    deletepath(ks + ".ksm").
    if exists("0:/" + ks + ".ksm") {
        copypath("0:/" + ks + ".ksm", ks + ".ksm").
    } else {
        copypath("0:/" + ks + ".ks", ks + ".ks").
    }
    print "Running: " + ks.
    runoncepath(ks).
}


