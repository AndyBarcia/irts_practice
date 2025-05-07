// Agent file: human_producer.asl
// Uses context for dynamic beliefs and query (?) for static config beliefs.

// --- Static Configuration Beliefs --- // (Will be queried with ?)
period_duration(80000).
quota(10).
base_production_time(15000).
min_production_time(5000).
distraction_probability(0.1).
min_chat_delay(400).
max_chat_delay(800).
check_interval(1000).
retry_lock_interval(5000).
locking_agent_name(bin_locking_agent).

// --- Mapping --- // (Will be queried with ?)
human_producer_to_bin_map(human_producer1, 1).
human_producer_to_bin_map(human_producer2, 2).
human_producer_to_bin_map(human_producer3, 3).
human_producer_to_bin_map(human_producer4, 4).

// --- Beliefs for State Management --- // (Will be checked in context)
// +my_bin_number(N)
// +my_assigned_bin_needs_parts
// +wants_to_produce
// +period_start_time(T)
// +produced_in_period(Count)

// --- Initial Goal ---
!start.

// --- Startup Plan ---
+!start // No context needed
    <- .my_name(MySelf);
       ?human_producer_to_bin_map(MySelf, MyBinNumber); // Query static map
       +my_bin_number(MyBinNumber);
       +produced_in_period(0);
       .time(StartTime);
       +period_start_time(StartTime);
       .print(MySelf, \" started. Assigned to bin: \", MyBinNumber, \". Period started at \", StartTime, \".\");
       !monitor_and_produce.

// --- Plans to React to Broadcasts ---
+needs_parts_public(N)[source(BinAgentName)]
    // Context checks dynamic state: is it my bin? do I already know it needs parts?
    : my_bin_number(N) & not my_assigned_bin_needs_parts
    <- +my_assigned_bin_needs_parts;
       .print("Learned my bin \", N, \" needs parts via broadcast.\").

+bin_is_full_public(N)[source(BinAgentName)]
    // Context checks dynamic state: is it my bin? did I think it needed parts?
    : my_bin_number(N) & my_assigned_bin_needs_parts
    <- -my_assigned_bin_needs_parts;
       .print("Learned my bin \", N, \" is now full via broadcast.\").

// --- Plans for Monitoring and Production ---

// Check for period end before checking bin needs
+!monitor_and_produce
    // Context binds dynamic state beliefs
    : period_start_time(StartTime) & produced_in_period(P)
    <- ?period_duration(Duration); // Query static config
       ?quota(Q);                 // Query static config
       .time(Now);
       if (Now >= StartTime + Duration) {
           .print("Period ended. Produced: \", P, \" (Quota: \", Q, \").\");
           if (P < Q) { .print("FAILED TO MEET QUOTA!\") }
           else { .print("Quota met or exceeded.\") };
           -+produced_in_period(P, 0);
           -+period_start_time(StartTime, Now);
           .print("Starting new period at time \", Now, \".\");
           !monitor_and_produce
       } else {
           !check_bin_needs_and_lock // Check actual bin needs
       }.

// --- Plan to check needs and attempt lock ---

// Case 1: Bin needs parts, and I'm not already trying to produce.
+!check_bin_needs_and_lock
    // Context checks dynamic state: my bin #, needs parts flag, not wanting to produce flag
    : my_bin_number(MyBin) & my_assigned_bin_needs_parts & not wants_to_produce
    <- ?locking_agent_name(Locker); // Query static config
       .print("Bin \", MyBin, \" needs parts. Attempting to acquire lock...\");
       +wants_to_produce;
       .my_name(MyHumanName);
       .send(Locker, achieve, try_lock_bin(MyBin, MyHumanName)).

// Case 2: Bin doesn't need parts, and I'm not trying to produce. Wait and loop.
+!check_bin_needs_and_lock
    // Context checks dynamic state
    : my_bin_number(MyBin) & not my_assigned_bin_needs_parts & not wants_to_produce
    <- ?check_interval(Interval); // Query static config
       .print("Bin \", MyBin, \" does not currently need parts. Will check again in \", Interval/1000, \"s.\");
       .wait(Interval);
       !monitor_and_produce.

// Case 3: Already trying to produce (waiting for lock or retry). Wait and loop.
+!check_bin_needs_and_lock
    // Context checks dynamic state
    : my_bin_number(MyBin) & wants_to_produce
    <- ?check_interval(Interval); // Query static config
       .print("Bin \", MyBin, \", currently in lock acquisition/retry phase. Waiting...\");
       .wait(Interval);
       !monitor_and_produce.

// --- Plans for Handling Lock Agent Responses ---

// Lock acquired: Calculate time, wait, produce, unlock, loop.
+got_bin_lock(MyBin)[source(Locker)]
    // Context binds dynamic state: my bin #, intent to produce.
    : my_bin_number(MyBin) & wants_to_produce & produced_in_period(P) & period_start_time(StartTime)
    <- // Query static config and dynamic state needed for calculations
       ?period_duration(Duration); 
       ?quota(Q); 
       ?base_production_time(TBase); 
       ?min_production_time(TMin);
       ?distraction_probability(DistractProb); 
       ?min_chat_delay(ChatMin); 
       ?max_chat_delay(ChatMax);
       ?check_interval(Interval);

       .print("Lock acquired for bin \", MyBin, \". Calculating production time...\");
       
       // Compensation Logic
       EffectiveTime = TBase; 
       QuotaRemaining = Q - P;
       if (QuotaRemaining > 0) { 
           .time(Now); 
           TimeRemaining = (StartTime + Duration) - Now;
           if (TimeRemaining > 0) {
               NeededAvgTime = TimeRemaining / QuotaRemaining;
               if (TBase > NeededAvgTime) { 
                   CompensatedTime = math.max(TMin, NeededAvgTime); 
                   EffectiveTime = CompensatedTime;
                   .print("Compensating! Base=\", TBase, \", NeededAvg=\", NeededAvgTime, \", Min=\", TMin, \". Using: \", EffectiveTime) }
               else { 
                   .print("On track for quota. Using base time: \", TBase) 
               }
           } else { 
               EffectiveTime = TMin; 
               .print("Period time elapsed or negative! Using min time: \", TMin) 
           }
       } else { 
          .print("Quota already met. Using base time: \", TBase) 
       };

       // Distraction Logic
       DistractionDelay = 0; 
       .random(R);
       if (R < DistractProb) { 
          ChatDuration = ChatMax - ChatMin; 
          RandomDelayPart = 0;
       if (DistractProb > 0) { 
          RandomDelayPart = math.round(R * (ChatDuration / DistractProb)) 
       };
       DistractionDelay = ChatMin + RandomDelayPart; 
       .print("Got distracted! Adding chat delay: \", DistractionDelay, \"ms.\") };
       
       // Wait and Produce
       TotalWaitTime = math.round(EffectiveTime + DistractionDelay);
       .print("Starting production wait: \", TotalWaitTime, \"ms (Effective: \", math.round(EffectiveTime), \", Distraction: \", DistractionDelay, \").\");
       .wait(TotalWaitTime);
       .print("Production complete for bin \", MyBin, \". Refilling.\");
       refill_bin(MyBin);
       -+produced_in_period(P, P + 1); // Use P bound by context
       
       // Unlock and Loop
       .print("Releasing lock for bin \", MyBin, \".\");
       .my_name(MyHumanName); .send(Locker, achieve, unlock_bin(MyBin, MyHumanName));
       -wants_to_produce; // Update dynamic state
       .wait(Interval); !monitor_and_produce.

// Lock was unavailable
+bin_lock_unavailable(MyBin, CurrentHolder)[source(Locker)]
    // Context binds dynamic state
    : my_bin_number(MyBin) & wants_to_produce
    <- ?retry_lock_interval(RetryInterval); // Query static config
       .print("Lock for bin \", MyBin, \" unavailable (held by \", CurrentHolder,\"). Will re-evaluate in \", RetryInterval/1000, \"s.\");
       -wants_to_produce; // Update dynamic state
       .wait(RetryInterval);
       !monitor_and_produce.

// Lock release confirmed
+unlocked_bin(MyBin)[source(Locker)]
    // Context binds dynamic state
    : my_bin_number(MyBin)
    <- .print("Lock release for bin \", MyBin, \" confirmed by server.\").

// If human_producer_to_bin_map query fails in +!start, MyBinNumber will be unbound,
// and the agent effectively won't initialize its main task properly. 