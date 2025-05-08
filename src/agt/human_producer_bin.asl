// Agent file: human_producer.asl
// Produces parts for an assigned bin, determined by its instance name and by listening to public broadcasts.

// --- Static Configuration Beliefs ---
production_time(15000).     // Simulate 15 seconds to produce parts for the bin
check_interval(3000).       // Interval to check bin status if not actively working
retry_lock_interval(5000).  // Interval to wait before retrying a failed lock

// --- Mapping from agent instance name to the bin number it services ---
human_bin(human_producer_bin1, 1).
human_bin(human_producer_bin2, 2).
human_bin(human_producer_bin3, 3).
human_bin(human_producer_bin4, 4).

// --- Beliefs for State Management ---
// +my_bin_number(N) : The bin this instance is responsible for.

// --- Initial Goal ---
!start.

// --- Startup Plan (Simplified, direct initialization) ---
+!start : true
    <- .my_name(MySelf);
       ?human_bin(MySelf, MyBinNumber);
       +my_bin_number(MyBinNumber);
       .print(MySelf, " started. Assigned to bin: ", MyBinNumber, ". Listening for broadcasts.").

// --- Plans to React to Broadcasts from Bin Agents ---

// If a bin needs parts, we attempt to lock it.
+needs_parts_public(N)
    : my_bin_number(N)
    <- .print("Learned my bin ", N, " needs parts via broadcast.");
       !attempt_to_lock_bin.
       
// If a bin is now full, we stop attempting to lock it.
-needs_parts_public(N)
    : my_bin_number(N)
    <- .print("Learned my bin ", N, " is now full via broadcast.");
       .drop_desire(attempt_to_lock_bin).

// --- Plans for Monitoring and Production ---

// Try to lock our bin by asking the bin_locking_agent.
+!attempt_to_lock_bin
    : my_bin_number(MyBin)
    <- .my_name(MyHumanName);

       // Try to ask for our bin to be locked, waiting up to 2 seconds for a reply.
       .send(bin_locking_agent, askOne, bin_locked(MyBin, _), bin_locked(_, LockedAgent), 2000);
       
       // If we were indeed the ones that got the lock, we can start production.
       if (LockedAgent == MyHumanName) {
           +got_bin_lock;
       } else {
           .print("Bin ", MyBin, " was already locked by ", LockedAgent, ". Retrying...");
           ?retry_lock_interval(RetryInterval);
           .wait(RetryInterval);
           !attempt_to_lock_bin;
       }.

// --- Plans for Handling Lock Agent Responses ---

// If we get the lock, we start production.
+got_bin_lock
    : my_bin_number(MyBin) & production_time(ProdTime)
    <- .print("Lock acquired for bin ", MyBin, ". Starting production.");
       .wait(ProdTime);
       .print("Production complete for bin ", MyBin, ". Refilling.");
       refill_bin(MyBin);
       .print("Releasing lock for bin ", MyBin, ".");
       .my_name(MyHumanName);
       .send(bin_locking_agent, achieve, unlock_bin(MyBin, MyHumanName));
       -got_bin_lock.
