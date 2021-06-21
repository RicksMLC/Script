// autoload.ks
// Rick's Mid-Life Crisis
// Script for loading other scripts.

wait until ship:unpacked.
core:DoEvent("open terminal").
print "autoload.ks running...".
set ksList to list("psLib", "LobShotCheapSounder").
set runList to "".
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


