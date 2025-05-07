// Agent file: bin_locking_agent.asl
// Manages locks for individual bins to prevent concurrent refilling.

// --- Beliefs ---
// bin_locked(BinNumber, LockingAgentName) : Indicates a bin is locked by an agent.

// --- Plans for Lock Management (with [atomic] annotation) ---

// Try to lock a bin
// Case 1: Bin is NOT locked by anyone. Grant lock.
@tryLock1 [atomic]
+!try_lock_bin(BinNumber, RequesterAgent)
    : not bin_locked(BinNumber, _)
    <- +bin_locked(BinNumber, RequesterAgent);
       .print("BinLockingAgent: Bin ", BinNumber, " locked for ", RequesterAgent, ".");
       .send(RequesterAgent, tell, got_bin_lock(BinNumber)).

// Case 2: Bin IS already locked by someone else. Deny lock.
@tryLock2 [atomic]
+!try_lock_bin(BinNumber, RequesterAgent)
    : bin_locked(BinNumber, CurrentHolder) & CurrentHolder \== RequesterAgent
    <- .print("BinLockingAgent: Bin ", BinNumber, " is already locked by ", CurrentHolder, ". Lock denied for ", RequesterAgent, ".");
       .send(RequesterAgent, tell, bin_lock_unavailable(BinNumber, CurrentHolder)).

// Case 3: Requester already holds the lock (e.g., redundant request). Confirm they still have it.
@tryLock3 [atomic]
+!try_lock_bin(BinNumber, RequesterAgent)
    : bin_locked(BinNumber, RequesterAgent)
    <- .print("BinLockingAgent: ", RequesterAgent, " already holds lock for bin ", BinNumber, ".");
       .send(RequesterAgent, tell, got_bin_lock(BinNumber)). // Re-confirm they have it


// Unlock a bin
// Case 1: Requester holds the lock. Release it.
@unlock1 [atomic]
+!unlock_bin(BinNumber, RequesterAgent)
    : bin_locked(BinNumber, RequesterAgent)
    <- -bin_locked(BinNumber, RequesterAgent);
       .print("BinLockingAgent: Bin ", BinNumber, " unlocked by ", RequesterAgent, ".");
       .send(RequesterAgent, tell, unlocked_bin(BinNumber)).

// Case 2: Requester does not hold the lock (or bin is free). Log warning, do nothing to locks.
@unlock2 [atomic]
+!unlock_bin(BinNumber, RequesterAgent)
    : not bin_locked(BinNumber, RequesterAgent)
    <- .print("BinLockingAgent: WARNING - ", RequesterAgent, " tried to unlock bin ", BinNumber, ", but does not hold the lock (or bin is free).").
