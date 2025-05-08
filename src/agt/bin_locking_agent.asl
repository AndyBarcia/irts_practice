// Agent file: bin_locking_agent.asl
// Manages locks for individual bins to prevent concurrent refilling.

// --- Beliefs ---
// bin_locked(BinNumber, LockingAgentName) : Indicates a bin is locked by an agent.

// --- Plans for Lock Management (with [atomic] annotation) ---

@tryLock1 [atomic]
+?bin_locked(BinNumber, ResultAgent)[source(RequesterAgent)]
    : not bin_locked(BinNumber, _)
    <- .print("Bin ", BinNumber, " locked for ", RequesterAgent, ".");
       +bin_locked(BinNumber, RequesterAgent);
       ResultAgent = RequesterAgent.

@tryLock2 [atomic]
+?bin_locked(BinNumber, ResultAgent)[source(RequesterAgent)]
    : bin_locked(BinNumber, LockedAgent)
    <- .print("Bin ", BinNumber, " unavailable for ", RequesterAgent, ".");
       ResultAgent = LockedAgent.

@unlockBin2 [atomic]
+!unlock_bin(BinNumber, RequesterAgent)[source(RequesterAgent)]
    <- -bin_locked(BinNumber, RequesterAgent);
       .print("Bin ", BinNumber, " unlocked by ", RequesterAgent, ".").
