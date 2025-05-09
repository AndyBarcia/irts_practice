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

// --- Main plan ---

!main.

+!main : true
<- .print("Robot starting up...");
   !monitor_bins_for_parts.

// --- Plans for Monitoring Bins for Parts ---

+!monitor_bins_for_parts
    : not broken
    <- .print("Monitoring bins for parts...");
       // Iterate all bins that are known to need parts.
       for ( needs_parts_public(N) ) {
           .print("Notified that bin ", N, " needs parts.");
           .my_name(MyRobotName);
           // Try to ask for our bin to be locked, waiting up to 2 seconds for a reply.
           .send(bin_locking_agent, askOne, bin_locked(N, _), bin_locked(N, LockedAgent), 2000);
           // If we were indeed the ones that got the lock, we can start production.
           if (LockedAgent == MyRobotName) {
               .print("Lock acquired for bin ", N, ". Starting production.");
               !process_bin(N);
               // Drop the desire to monitor bins so that we can focus
               // on the bin we just got the lock for.
               drop_desire(monitor_bins_for_parts);
           } else {
               .print("Bin ", N, " was already locked by ", LockedAgent, ".");
           };
       }
       // If all bins are done, or are being processed by other agents,
       // wait a second and check again.
       .print("No bins to process. Waiting 4 seconds before next check.");
       .wait(4000);
       !monitor_bins_for_parts.

// --- Plans for Handling Lock Agent Responses ---

+!process_bin(N)
    <- ?breakdown_probability(BreakProb);
       .my_name(MyRobotName);
       .random(R);
       if (R < BreakProb) {
           .print("BREAKDOWN occurred while trying to produce for bin ", N, "!");
           .print("Releasing lock for bin ", N, ".");
           .send(bin_locking_agent, achieve, unlock_bin(N, MyRobotName));
           +broken;
       } else {
           .print("Starting production for bin ", N, ".");
           ?robot_production_time(ProdTime);
           .wait(ProdTime);
           .print("Production for bin ", N, " complete. Refilling.");
           refill_bin(N);
           .print("Releasing lock for bin ", N, ".");
           .send(bin_locking_agent, achieve, unlock_bin(N, MyRobotName));
           !monitor_bins_for_parts;
       }.

// --- Plan for Self-Repair ---

+broken
    <- ?repair_time(RepairTime);
       .print("Starting repair process (", RepairTime/1000, "s).");
       .wait(RepairTime);
       .print("Repair complete.");
       -broken;
       !monitor_bins_for_parts.
