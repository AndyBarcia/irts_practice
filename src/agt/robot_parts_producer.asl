// Agent file: robot_parts_producer.asl
// Proactively identifies needy bins by iterating through its known_needy_bin beliefs and processes them in a continuous loop.

// --- Initial Beliefs ---
robot_production_time(7000). // Simulate 7 seconds for robot to produce parts
robot_scan_interval(5000).  // Interval between full scan cycles
// NOTE: doesn't work to check inside context of plans for some reason. Instead
// a number is hardcoded in the plans.
//max_bins_to_check(6).         // Maximum bin number to iterate up to during a scan.

// --- Beliefs for State Management ---
// +known_needy_bin(BinNumber) : Robot knows this bin needs parts, learned from a broadcast.

// --- Initial Goal ---
!check_and_process_known_needy(1).

// --- Plans to React to Broadcasts from Bin Agents ---

+needs_parts_public(N)[source(BinAgentName)]
    <- +known_needy_bin(N);
       .print("Robot producer: Received needs_parts_public for bin ", N, " (from ", BinAgentName, ").").

+bin_is_full_public(N)[source(BinAgentName)]
    <- -known_needy_bin(N);
       .print("Robot producer: Received bin_is_full_public for bin ", N, " (from ", BinAgentName, ").").

// --- Main Loop: Checking and Processing Known Needy Bins (Iterative Scan) ---

// Case 1: CurrentBinToCheck is a known needy bin, and not currently attempting a lock.
+!check_and_process_known_needy(CurrentBinToCheck)
    : CurrentBinToCheck <= 6 & known_needy_bin(CurrentBinToCheck)
    <- .print("Robot producer: Bin ", CurrentBinToCheck, " needs parts. Attempting to acquire lock...");
       .my_name(MyRobotName);
       .send(bin_locking_agent, achieve, try_lock_bin(CurrentBinToCheck, MyRobotName)).

// Case 2: CurrentBinToCheck is NOT a known needy bin, or robot is busy with another lock. Continue iteration.
+!check_and_process_known_needy(CurrentBinToCheck)
    : CurrentBinToCheck <= 6 & (not known_needy_bin(CurrentBinToCheck))
    <- .print("Robot producer: Bin ", CurrentBinToCheck, " does not need parts. Moving on.");
       !check_and_process_known_needy(CurrentBinToCheck+1).

// Base Case / Loop Restart: Checked all bins up to max_bins_to_check.
+!check_and_process_known_needy(CurrentBinToCheck)
    : CurrentBinToCheck > 6 & robot_scan_interval(Interval)
    <- .print("Robot producer: Finished checking bins up to ", 6,". Restarting after interval...");
       .wait(Interval);
       !check_and_process_known_needy(1).

// --- Plans for Handling Lock Agent Responses (modified to continue iteration) ---

+got_bin_lock(N)[source(bin_locking_agent)]
    : robot_production_time(ProdTime)
    <- .print("Robot producer: Lock acquired for bin ", N, ". Starting production.");
       .wait(ProdTime);
       .print("Robot producer: Production for bin ", N, " complete. Refilling.");
       refill_bin(N);
       .print("Robot producer: Releasing lock for bin ", N, ".");
       .my_name(MyRobotName);
       .send(bin_locking_agent, achieve, unlock_bin(N, MyRobotName));
       !continue_scan_after_lock_attempt(N).

+bin_lock_unavailable(N, CurrentHolder)[source(bin_locking_agent)]
    <- .print("Robot producer: Lock for bin ", N, " unavailable (held by ", CurrentHolder,"). Moving on.");
       !continue_scan_after_lock_attempt(N).

+unlocked_bin(N)[source(bin_locking_agent)]
    <- .print("Robot producer: Lock release for bin ", N, " confirmed by server.").

// --- Helper Plan to Continue Scan Iteration ---

+!continue_scan_after_lock_attempt(LastCheckedBin)
    : LastCheckedBin < 6
    <- !check_and_process_known_needy(LastCheckedBin + 1).

+!continue_scan_after_lock_attempt(LastCheckedBin)
    : LastCheckedBin >= 6
    <- .print("Robot producer: Reached end of check sequence (after processing bin ", LastCheckedBin, "). Triggering restart check...");
       !check_and_process_known_needy(1).

