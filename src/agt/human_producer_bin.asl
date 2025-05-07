// Agent file: human_producer.asl
// Produces parts for an assigned bin, determined by its instance name and by listening to public broadcasts.

// --- Static Configuration Beliefs ---
production_time(15000).     // Simulate 15 seconds to produce parts for the bin
check_interval(3000).       // Interval to check bin status if not actively working
retry_lock_interval(5000).  // Interval to wait before retrying a failed lock
locking_agent_name(bin_locking_agent). // Name of the locking agent

// --- Mapping from agent instance name to the bin number it services ---
human_bin(human_producer_bin1, 1).
human_bin(human_producer_bin2, 2).
human_bin(human_producer_bin3, 3).
human_bin(human_producer_bin4, 4).

// --- Beliefs for State Management ---
// +my_bin_number(N) : The bin this instance is responsible for.
// +my_assigned_bin_needs_parts : Local flag, true if its assigned bin needs parts (learned via broadcast).
// +wants_to_produce : Internal flag indicating intent to produce after lock acquisition.

// --- Initial Goal ---
!start.

// --- Startup Plan (Simplified, direct initialization) ---
+!start : true
    <- .my_name(MySelf);
       ?human_bin(MySelf, MyBinNumber);
       +my_bin_number(MyBinNumber);
       .print(MySelf, " started. Assigned to bin: ", MyBinNumber, ". Listening for broadcasts.");
       !monitor_and_produce.

// --- Plans to React to Broadcasts from Bin Agents ---

+needs_parts_public(N)
    : my_bin_number(N) & not my_assigned_bin_needs_parts
    <- +my_assigned_bin_needs_parts;
       .print("Learned my bin ", N, " needs parts via broadcast.").

+bin_is_full_public(N)
    : my_bin_number(N) & my_assigned_bin_needs_parts
    <- -my_assigned_bin_needs_parts;
       .print("Learned my bin ", N, " is now full via broadcast.").

// --- Plans for Monitoring and Production ---

+!monitor_and_produce
    : my_bin_number(MyBin) & locking_agent_name(Locker) &
      my_assigned_bin_needs_parts & not wants_to_produce
    <- .print("My bin ", MyBin, " needs parts. Attempting to acquire lock...");
       +wants_to_produce;
       .my_name(MyHumanName);
       .send(Locker, achieve, try_lock_bin(MyBin, MyHumanName)).

+!monitor_and_produce
    : my_bin_number(MyBin) & check_interval(Interval) & locking_agent_name(Locker) &
      not my_assigned_bin_needs_parts & not wants_to_produce
    <- .print("My bin ", MyBin, " does not currently need parts. Will check again in ", Interval/1000, "s.");
       .wait(Interval);
       !monitor_and_produce.

+!monitor_and_produce
    : my_bin_number(MyBin) & wants_to_produce & check_interval(Interval)
    <- .print("Bin ", MyBin, ", currently in lock acquisition/retry phase. Waiting...");
       .wait(Interval);
       !monitor_and_produce.

// --- Plans for Handling Lock Agent Responses ---

+got_bin_lock(MyBin)
    : my_bin_number(MyBin) & wants_to_produce &
      production_time(ProdTime) & locking_agent_name(Locker) & check_interval(Interval)
    <- .print("Lock acquired for bin ", MyBin, ". Starting production.");
       .wait(ProdTime);
       .print("Production complete for bin ", MyBin, ". Refilling.");
       refill_bin(MyBin);
       .print("Releasing lock for bin ", MyBin, ".");
       .my_name(MyHumanName);
       .send(Locker, achieve, unlock_bin(MyBin, MyHumanName));
       -wants_to_produce;
       .wait(Interval);
       !monitor_and_produce.

+bin_lock_unavailable(MyBin, CurrentHolder)
    : my_bin_number(MyBin) & wants_to_produce &
      retry_lock_interval(RetryInterval)
    <- .print("Lock for bin ", MyBin, " unavailable (held by ", CurrentHolder,"). Will re-evaluate in ", RetryInterval/1000, "s.");
       -wants_to_produce;
       .wait(RetryInterval);
       !monitor_and_produce.

+unlocked_bin(MyBin)
    : my_bin_number(MyBin)
    <- .print("Lock release for bin ", MyBin, " confirmed by server.").
