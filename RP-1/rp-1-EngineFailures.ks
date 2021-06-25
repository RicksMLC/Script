// rp-1-EngineFailures.ks library.
// Usage: RunMultiEngineStage([isVerbose])
// Pre: Engines are already running eg:
//          stage.
//          RunMultiEngineStage(false)
// Engines are kOS tagged as "S2-Ea-n" and S2-Eb-n" where n is the engine number in the group.
// Currently only handles a pair of engine groups.

function CheckForEngineFailures {
    parameter engines.
    local isShutdown is false.
    for e in engines {
        // Detect if engine loses performance or shuts down.
        if e:thrust < e:maxthrust * 0.9 or e:thrust = 0 or e:maxthrust = 0 {
            local reason is 
                choose "shutdown detected." 
                    if e:thrust = 0 
                    else choose "lost engine." if e:maxthrust = 0 else " performance loss.".
            print "Engine " + e:name + " '" + e:tag + "'"
                + reason
                + " thrust:" + round(e:thrust, 4) + " maxthrust:" + round(e:maxthrust, 4).
            for e in engines {
                print "   Shutting down "+ e:name + " '" + e:tag + "'".
                e:shutdown.
            }
            set isShutdown to true.
            break.
        }
    }
    return isShutdown.
}

function RunMultiEngineStage {
    parameter stagePrefix.
    parameter verbose is false.

    local expr is "^" + stagePrefix + "-Ea".

    // TODO: parameterise to allow more than two groups.
    declare eAs to ship:partstaggedpattern(expr).
    if verbose {
        print eAs.
    }
    set expr to "^" + stagePrefix + "-Eb".
    declare eBs to ship:partstaggedpattern(expr).
    if verbose {
        print eBs.
    }

    local isShutdownA is false.
    local isShutdownB is false.
    until isShutdownA and isShutdownB {
        local n is 1.
        for e in eAs {
            if verbose {
                PrintPairStatus(n, 
                    "Engine", e:tag, 
                    "Thrust", round(e:thrust, 4):tostring :padright(6) + " m: " + round(e:maxthrust, 4):tostring:padright(6)).
                set n to n + 1.                    
            }

        }
        set n to 3.
        for e in eBs {
            if verbose {
                PrintPairStatus(n, 
                    "Engine", e:tag, 
                    "Thrust", round(e:thrust, 4):tostring:padright(6) + " m: " + round(e:maxthrust, 4):tostring:padright(6)).
                set n to n + 1.
            }
        }
        if not isShutdownA {
            set isShutdownA to CheckForEngineFailures(eAs).
            if isShutdownA {
                print "Engine Group A is shut down.".
                eAs:Clear().
            }
        }
        if not isShutdownB {
            set isShutdownB to CheckForEngineFailures(eBs).
            if isShutdownB {
                print "Engine Group B is shut down.".
                eBs:Clear().
            }
        }
        wait 0.001.
    }
    print "All Engines are Shutdown.".
}
