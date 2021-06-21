// ScienceSounder.ks
// Script for loading other scripts.

wait until ship:unpacked.
core:DoEvent("open terminal").
print "ScienceSounder.ks running...".
set ksList to list("psLib", "SciToolsLib", "LobShotSounder").
for ks in ksList {
    deletepath(ks + ".ks").
    deletepath(ks + ".ksm").
    if exists("0:/" + ks + ".ksm") {
        copypath("0:/" + ks + ".ksm", "").
    } else {
        copypath("0:/" + ks + ".ks", "").
    }
    print "Running: " + ks.
    runoncepath(ks).
}


