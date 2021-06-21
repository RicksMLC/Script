// AutoLoadTour.ks

wait until ship:unpacked.
core:DoEvent("open terminal").

print "AutoTourLoad.ks running...".

set ksList to list("psLib", "OrbitLib", "AutoTour03").

for ks in ksList {
    deletepath(ks + ".ks").
    copypath("0:/" + ks + ".ks", "").
    print "Running: " + ks.
    runoncepath(ks).
}
