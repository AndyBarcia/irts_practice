// Agent file: robot_parts_producer.asl
// Proactively identifies needy bins by iterating through its known_needy_bin beliefs and processes them in a continuous loop.
// Includes random breakdown and repair mechanism.

// --- Initial Beliefs ---
robot_production_time(7000). // Simulate 7 seconds for robot to produce parts
robot_scan_interval(5000).  // Interval between full scan cycles
// NOTE: doesn't work to check inside context of plans for some reason. Instead
// a number is hardcoded in the plans.
//max_bins_to_check(6).         // Maximum bin number to iterate up to during a scan.
breakdown_probability(0.1).  // Probability (0.0 to 1.0) of breaking when starting production
repair_time(30000).         // Time in ms to repair if broken

// --- Beliefs for State Management ---
// +known_needy_bin(BinNumber) : Robot knows this bin needs parts, learned from a broadcast.
// +broken : Robot is currently broken and undergoing repairs.

// --- Initial Goal ---
!check_and_process_known_needy(1).

// --- Plans to React to Broadcasts from Bin Agents  ---

+needs_parts_public(N)[source(BinAgentName)]
    <- +known_needy_bin(N);
       .print("Received needs_parts_public for bin ", N, " (from ", BinAgentName, ").").

+bin_is_full_public(N)[source(BinAgentName)]
    <- -known_needy_bin(N);
       .print("Received bin_is_full_public for bin ", N, " (from ", BinAgentName, ").").

// --- Main Loop: Checking and Processing Known Needy Bins (Iterative Scan) ---

// Case 1: Check bin N if NOT broken.
+!check_and_process_known_needy(CurrentBinToCheck)
    : CurrentBinToCheck <= 6 & known_needy_bin(CurrentBinToCheck) & not broken
    <- .print("Bin ", CurrentBinToCheck, " needs parts. Attempting to acquire lock...");
       .my_name(MyRobotName);
       .send(bin_locking_agent, achieve, try_lock_bin(CurrentBinToCheck, MyRobotName)).

// Case 2: Skip bin N if NOT broken (not needy or already attempting lock).
+!check_and_process_known_needy(CurrentBinToCheck)
    : CurrentBinToCheck <= 6 & not broken & not known_needy_bin(CurrentBinToCheck)
    <- !check_and_process_known_needy(CurrentBinToCheck+1).

// Base Case / Loop Restart: Only restart if NOT broken.
+!check_and_process_known_needy(CurrentBinToCheck)
    : CurrentBinToCheck > 6 & not broken
    <- .print("Finished checking bins up to 6. Restarting cycle...");
       !check_and_process_known_needy(1).

// Case when Broken: Just wait. Repair plan will restart it.
+!check_and_process_known_needy(_)
    : broken
    <- .print("Currently broken. Check loop paused.").

// --- Plans for Handling Lock Agent Responses ---

// Got the lock, now check for breakdown BEFORE starting production.
+got_bin_lock(N)[source(bin_locking_agent)]
    <- ?breakdown_probability(BreakProb);
       .random(R);
       if (R < BreakProb) {
           // Breakdown occurred!
           .print("BREAKDOWN occurred while trying to produce for bin ", N, "!");
           +broken; // Set broken state
           .print("Releasing lock for bin ", N, " due to breakdown.");
           .my_name(MyRobotName);
           .send(bin_locking_agent, achieve, unlock_bin(N, MyRobotName));
       } else {
           // No breakdown, proceed with production
           .print("Lock acquired for bin ", N, ". Starting production (no breakdown).");
           ?robot_production_time(ProdTime);
           .wait(ProdTime);
           .print("Production for bin ", N, " complete. Refilling.");
           refill_bin(N);
           .print("Releasing lock for bin ", N, ".");
           .my_name(MyRobotName);
           .send(bin_locking_agent, achieve, unlock_bin(N, MyRobotName));
           !continue_scan_after_lock_attempt(N);
       }.

+bin_lock_unavailable(N, CurrentHolder)[source(bin_locking_agent)]
    <- .print("Lock for bin ", N, " unavailable (held by ", CurrentHolder,"). Moving on.");
       !continue_scan_after_lock_attempt(N).

+unlocked_bin(N)[source(bin_locking_agent)]
    <- .print("Lock release for bin ", N, " confirmed by server.").

// --- Plan for Self-Repair ---

+broken
    <- ?repair_time(RepairTime);
       .print("Starting repair process (", RepairTime/1000, "s).");
       .wait(RepairTime);
       .print("Repair complete.");
       -broken; // Clear broken state
       .print("Restarting check loop after repair.");
       !check_and_process_known_needy(1). // Restart main loop from beginning

// --- Helper Plan to Continue Scan Iteration ---

+!continue_scan_after_lock_attempt(LastCheckedBin)
    : LastCheckedBin < 6 & not broken // Only continue if not broken
    <- !check_and_process_known_needy(LastCheckedBin + 1).

+!continue_scan_after_lock_attempt(LastCheckedBin)
    : (LastCheckedBin >= 6 | broken) // If reached end OR broken, trigger restart check/wait plan
    <- .print("Reached end of check sequence (or broken) after processing bin ", LastCheckedBin, "). Triggering restart check...");
       !check_and_process_known_needy(LastCheckedBin + 1). // This will match N > 6 or the broken plan

