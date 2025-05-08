// Agent file: robot_parts_producer.asl

// --- Initial Beliefs ---
robot_production_time(7000). // Simulate 7 seconds for robot to produce parts
robot_scan_interval(5000).  // Interval between full scan cycles
// NOTE: doesn't work to check inside context of plans for some reason. Instead
// a number is hardcoded in the plans.
//max_bins_to_check(6).         // Maximum bin number to iterate up to during a scan.
breakdown_probability(0.1).  // Probability (0.0 to 1.0) of breaking when starting production
repair_time(30000).         // Time in ms to repair if broken

// --- Beliefs for State Management ---
// +broken : Robot is currently broken and undergoing repairs.

// --- Plans to React to Broadcasts from Bin Agents  ---

+needs_parts_public(N)
    <- .print("Notified that bin ", N, " needs parts.");
       // From now on, we want to lock this bin to work on it.
       !attempt_to_lock_bin(N).

-needs_parts_public(N)
    <- .print("Notified that bin ", N, " no longer needs parts.");
       // From now on we have no interest in locking this bin.
       .drop_desire(attempt_to_lock_bin(N)).

// --- Main Loop: Checking and Processing Known Needy Bins (Iterative Scan) ---

+!attempt_to_lock_bin(N)
    : not broken & not got_bin_lock(_) & needs_parts_public(N)
    <- .print("Attempting to lock bin ", N, "...");
       .my_name(MyRobotName);
       // Try to ask for our bin to be locked, waiting up to 2 seconds for a reply.
       .send(bin_locking_agent, askOne, bin_locked(N, _), bin_locked(N, LockedAgent), 2000);
       // If we were indeed the ones that got the lock, we can start production.
       if (LockedAgent == MyRobotName) {
           !got_bin_lock(N);
       } else {
            .print("Bin ", N, " was already locked by ", LockedAgent, ".");
            .wait(1000);
            !attempt_to_lock_bin(N);
       }.

+!attempt_to_lock_bin(N)
    : not broken & got_bin_lock(_) & needs_parts_public(N)
    <- .print("I'm already working on a bin. Skipping.");
       .wait(4000);
       !attempt_to_lock_bin(N).

+!attempt_to_lock_bin(N)
    : broken & needs_parts_public(N)
    <- .print("I'm broken, so I can't work on this bin. Skipping.");
       .wait(4000);
       !attempt_to_lock_bin(N).

+!attempt_to_lock_bin(N)
    : not needs_parts_public(N)
    <- .print("Bin ", N, " no longer needs parts. Skipping.").

// --- Plans for Handling Lock Agent Responses ---

// Got the lock, now check for breakdown BEFORE starting production.
+!got_bin_lock(N)
    <- ?breakdown_probability(BreakProb);
       .my_name(MyRobotName);
       .random(R);
       if (R < BreakProb) {
           .print("BREAKDOWN occurred while trying to produce for bin ", N, "!");
           +broken;
           // Mantain desire to lock the bin again when we're repaired.
           !attempt_to_lock_bin(N);
       } else {
           .print("Lock acquired for bin ", N, ". Starting production (no breakdown).");
           ?robot_production_time(ProdTime);
           .wait(ProdTime);
           .print("Production for bin ", N, " complete. Refilling.");
           refill_bin(N);
       };
       .print("Releasing lock for bin ", N, ".");
       .send(bin_locking_agent, achieve, unlock_bin(N, MyRobotName)).

// --- Plan for Self-Repair ---

+broken
    <- ?repair_time(RepairTime);
       .print("Starting repair process (", RepairTime/1000, "s).");
       .wait(RepairTime);
       .print("Repair complete.");
       -broken. // Clear broken state
