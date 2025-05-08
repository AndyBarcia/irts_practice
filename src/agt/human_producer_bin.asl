// Agent file: human_producer.asl
// Produces parts for an assigned bin, determined by its instance name and by listening to public broadcasts.

// --- Static Configuration Beliefs ---
production_time(15000).     // Simulate 15 seconds to produce parts for the bin
check_interval(3000).       // Interval to check bin status if not actively working
retry_lock_interval(5000).  // Interval to wait before retrying a failed lock
locking_agent_name(bin_locking_agent). // Name of the locking agent
period_duration(80000). // How long the human works for
quota(10). // How many parts the human must produce in a period
distraction_probability(0.1). // How probable it is that the human will be distracted
min_chat_delay(400). // Minimum delay due to distraction
max_chat_delay(800). // Maximum delay due to distraction

// --- Mapping from agent instance name to the bin number it services ---
human_bin(human_producer_bin1, 1).
human_bin(human_producer_bin2, 2).
human_bin(human_producer_bin3, 3).
human_bin(human_producer_bin4, 4).

// --- Beliefs for State Management ---
// +my_bin_number(N) : The bin this instance is responsible for.
// +my_assigned_bin_needs_parts : Local flag, true if its assigned bin needs parts (learned via broadcast).
// +wants_to_produce : Internal flag indicating intent to produce after lock acquisition.
// +period_start_time(T)
// +produced_in_period(Count)


// --- Initial Goal ---
!start.

// --- Startup Plan (Simplified, direct initialization) ---
+!start : true
    <- .my_name(MySelf);
       ?human_bin(MySelf, MyBinNumber);
       +my_bin_number(MyBinNumber);
       +produced_in_period(0);
       .time(StartTime);
       +period_start_time(StartTime);
       .print(MySelf, \" started. Assigned to bin: \", MyBinNumber, \". Period started at \", StartTime, \".\");
       !monitor_and_produce.

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

+!monitor_and_produce
    : my_bin_number(MyBin) &
      my_assigned_bin_needs_parts & not wants_to_produce
    <- ?period_duration(Duration);
       ?quota(Q);
       .time(Now);
       // Check if period has ended and if we meet the quota
       if (Now >= StartTime + Duration) {
           .print("Period ended. Produced: \", P, \" (Quota: \", Q, \").\");
           if (P < Q) { 
               .print("FAILED TO MEET QUOTA!\") 
           } else { 
               .print("Quota met or exceeded.\") 
           };
           -+produced_in_period(P, 0);
           -+period_start_time(StartTime, Now);
           .print("Starting new period at time \", Now, \".\");
       }
       
       // Deterimne remaining time and remaining quota
       QuotaRemaining = math.max(Q - P, 0);
       TimeRemaining = math.max((StartTime + Duration) - Now, 0);

       // Determine whether we are on schedule or not
       if (QuotaRemaining > 0) {
           NeededAvgTime = TimeRemaining / QuotaRemaining;
           ?production_time(ProdTime);
           if (ProdTime > NeededAvgTime) {
               print("Going behind schedule! Working faster!");
               ProductionTime = NeededAvgTime;
               +behind_schedule;
           } else {
               print("On schedule!");
               ProductionTime = ProdTime;
               -behind_schedule;
           }
       } else {
           print("On schedule and quota already met!");
           ?production_time(ProdTime);
           ProductionTime = ProdTime;
           -behind_schedule;
       }

       // If we are on schedule, we can afford to chat based on probability distraction_probability
       ?distraction_probability(DistractProb);
       .random(R);
       if (R < DistractProb) {
          +bored;
       } else {
          -bored;
       }
       
       .print("My bin ", MyBin, " needs parts. Attempting to acquire lock...");
       +wants_to_produce;
       .my_name(MyHumanName);
       .send(bin_locking_agent, achieve, try_lock_bin(MyBin, MyHumanName)).

+!monitor_and_produce
    : my_bin_number(MyBin) & not my_assigned_bin_needs_parts & not wants_to_produce
    <- ?check_interval(Interval);
       .print("My bin ", MyBin, " does not currently need parts. Will check again in ", Interval/1000, "s.");
       .wait(Interval);
       !monitor_and_produce.

+!monitor_and_produce
    : my_bin_number(MyBin) & wants_to_produce
    <- ?check_interval(Interval);
       .print("Bin ", MyBin, ", currently in lock acquisition/retry phase. Will check again in ", Interval/1000, "s.");
       .wait(Interval);
       !monitor_and_produce.



// --- Plans for Handling Lock Agent Responses ---

+got_bin_lock(MyBin)
    : my_bin_number(MyBin) & wants_to_produce & produced_in_period(P) & period_start_time(StartTime)
    <- .print("Lock acquired for bin ", MyBin, ". Starting production.");       
       .wait(ProdTime);
       .print("Production complete for bin ", MyBin, ". Refilling.");
       refill_bin(MyBin);
       .print("Releasing lock for bin ", MyBin, ".");
       .my_name(MyHumanName);
       .send(bin_locking_agent, achieve, unlock_bin(MyBin, MyHumanName));
       -wants_to_produce;
       ?check_interval(Interval);
       .wait(Interval);
       !monitor_and_produce.

+bin_lock_unavailable(MyBin, CurrentHolder)
    : my_bin_number(MyBin) & wants_to_produce
    <- ?retry_lock_interval(RetryInterval);
       .print("Lock for bin ", MyBin, " unavailable (held by ", CurrentHolder,"). Will re-evaluate in ", RetryInterval/1000, "s.");
       -wants_to_produce;
       .wait(RetryInterval);
       !monitor_and_produce.

+unlocked_bin(MyBin)
    : my_bin_number(MyBin)
    <- .print("Lock release for bin ", MyBin, " confirmed by server.").
