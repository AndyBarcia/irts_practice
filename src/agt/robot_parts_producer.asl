// Agent file: robot_parts_producer.asl
// Proactively identifies needy bins by iterating through its known_needy_bin beliefs and processes them in a continuous loop.

// --- Initial Beliefs ---
robot_production_time(7000). // Simulate 7 seconds for robot to produce parts
robot_scan_interval(5000).  // Interval between full scan cycles
max_bins_to_check(6).       // Maximum bin number to iterate up to during a scan.

// --- Beliefs for State Management ---
// +known_needy_bin(BinNumber) : Robot knows this bin needs parts, learned from a broadcast.

// --- Initial Goal ---
!check_and_process_known_needy(1). // Start the perpetual loop

// --- Plans to React to Broadcasts from Bin Agents ---

+needs_parts_public(N)[source(BinAgentName)]
    <- +known_needy_bin(N); // Add/ensure belief is present.
       .print("Robot producer: Received needs_parts_public for bin ", N, " (from ", BinAgentName, ").").

+bin_is_full_public(N)[source(BinAgentName)]
    <- -known_needy_bin(N); // Remove belief (if present).
       .print("Robot producer: Received bin_is_full_public for bin ", N, " (from ", BinAgentName, ").").

// --- Main Loop: Checking and Processing Known Needy Bins (Iterative Scan) ---

// Case 1: CurrentBinToCheck is a known needy bin, we can try to process it.
+!check_and_process_known_needy(CurrentBinToCheck)
    : CurrentBinToCheck <= max_bins_to_check(_) & known_needy_bin(CurrentBinToCheck)
    <- .print("Robot producer: Bin ", CurrentBinToCheck, " needs parts. Attempting to acquire lock...");
       .my_name(MyRobotName);
       .send(bin_locking_agent, achieve, try_lock_bin(CurrentBinToCheck, MyRobotName)).

// Case 2: CurrentBinToCheck is NOT a known needy bin. Continue iteration.
+!check_and_process_known_needy(CurrentBinToCheck)
    : CurrentBinToCheck <= max_bins_to_check(_) & not known_needy_bin(CurrentBinToCheck)
    <- .print("Robot producer: Bin ", CurrentBinToCheck, " does not need parts. Moving on.");
       !continue_scan_after_lock_attempt(CurrentBinToCheck).

// Case 3: Loop Restart: Checked all bins up to max_bins_to_check.
+!check_and_process_known_needy(CurrentBinToCheck)
    : CurrentBinToCheck > max_bins_to_check(_)
    <- .print("Robot producer: Finished checking bins up to ", max_bins_to_check(_),". Restarting.");
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
    <- .print("Robot producer: Lock release for bin ", N, " confirmed.").

// --- Helper Plan to Continue Scan Iteration after lock attempt ---

// Case 1: continue with the next bin
+!continue_scan_after_lock_attempt(LastCheckedBin)
    : LastCheckedBin < max_bins_to_check(_)
    <- .print("Robot producer: Continuing with bin ", LastCheckedBin + 1, ".");
       !check_and_process_known_needy(LastCheckedBin + 1).

// Case 2: restart the cycle from bin 1
+!continue_scan_after_lock_attempt(LastCheckedBin)
    : LastCheckedBin >= max_bins_to_check(_)
    <- .print("Robot producer: Reached end of check sequence (after processing bin ", LastCheckedBin, "). Restarting.");
       !check_and_process_known_needy(1).
