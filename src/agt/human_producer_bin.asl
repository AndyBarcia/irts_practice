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
// +my_assigned_bin_needs_parts : Local flag, true if its assigned bin needs parts (learned via broadcast).

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
    : my_bin_number(N)
    <- +my_assigned_bin_needs_parts;
       .print("Learned my bin ", N, " needs parts via broadcast.").

-needs_parts_public(N)
    : my_bin_number(N) & my_assigned_bin_needs_parts
    <- -my_assigned_bin_needs_parts;
       .print("Learned my bin ", N, " is now full via broadcast.").

// --- Plans for Monitoring and Production ---

+!monitor_and_produce
    : my_bin_number(MyBin) & my_assigned_bin_needs_parts & retry_lock_interval(RetryInterval)
    <- .print("My bin ", MyBin, " needs parts. Attempting to acquire lock...");
       .my_name(MyHumanName);

       // Try to ask for our bin to be locked, waiting up to 2 seconds for a reply.
       .send(bin_locking_agent, askOne, bin_locked(MyBin, _), bin_locked(_, LockedAgent), 2000);
       
       // If we were indeed the ones that got the lock, we can start production.
       if (LockedAgent == MyHumanName) {
           +got_bin_lock;
       } else {
           .print("Bin ", MyBin, " was already locked by ", LockedAgent, ". Retrying..."); 
           .wait(RetryInterval);
           !monitor_and_produce;
       }.

+!monitor_and_produce
    : my_bin_number(MyBin) & check_interval(Interval) & not my_assigned_bin_needs_parts
    <- .print("My bin ", MyBin, " does not currently need parts. Will check again in ", Interval/1000, "s.");
       .wait(Interval);
       !monitor_and_produce.

// --- Plans for Handling Lock Agent Responses ---

+got_bin_lock
    : my_bin_number(MyBin) & production_time(ProdTime) & check_interval(Interval)
    <- .print("Lock acquired for bin ", MyBin, ". Starting production.");
       .wait(ProdTime);
       .print("Production complete for bin ", MyBin, ". Refilling.");
       refill_bin(MyBin);
       -my_assigned_bin_needs_parts;
       .print("Releasing lock for bin ", MyBin, ".");
       .my_name(MyHumanName);
       .send(bin_locking_agent, achieve, unlock_bin(MyBin, MyHumanName));
       -got_bin_lock;
       .wait(Interval);
       !monitor_and_produce.
