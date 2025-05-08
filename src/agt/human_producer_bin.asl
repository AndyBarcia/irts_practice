// Agent file: human_producer.asl
// Produces parts for an assigned bin, determined by its instance name and by listening to public broadcasts.

// --- Static Configuration Beliefs ---
production_time(15000).     // Simulate 15 seconds to produce parts for the bin
check_interval(3000).       // Interval to check bin status if not actively working
retry_lock_interval(5000).  // Interval to wait before retrying a failed lock
period_duration(80). // How long the human works for
quota(2). // How many parts the human must produce in a period
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
// +period_start_time(T)
// +produced_in_period(Count)
// +working_speed(S) : The speed at which the human is working

// --- Initial Goal ---
!start.

// --- Startup Plan (Simplified, direct initialization) ---
+!start : true
    <- .my_name(MySelf);
       ?human_bin(MySelf, MyBinNumber);
       +my_bin_number(MyBinNumber);       
       +working_speed(ProdTime);
       +period_start_time(0);
       .print(MySelf, " started. Assigned to bin: ", MyBinNumber, ".");
       !start_period.

+!start_period
    <- .print("Standard period started.");
       
       +produced_in_period(0);
       +on_schedule;
       .time(H,M,S);
       StartTime = H * 3600 + M * 60 + S;
       -+period_start_time(StartTime);
       ?period_start_time(TestTime);
       !monitor_quota;

       ?period_duration(Duration);
       .wait(Duration*1000);

       .print("Period ended. Produced: ", P, " (Quota: ", Q, ").");
        if (P < Q) { 
            .print("FAILED TO MEET QUOTA!") 
        } else { 
            .print("Quota met or exceeded.") 
        };
        -+produced_in_period(0);
        !start_period.       

// --- Plan to Monitor Quota ---
+!monitor_quota
    : my_bin_number(MyBin)
    <- ?period_duration(Duration);
       ?period_start_time(StartTime);
       ?quota(Q);
       ?produced_in_period(P);
       .time(H,M,S);
       Now = H * 3600 + M * 60 + S;

       // Determine remaining time and remaining quota
       QuotaRemaining = math.max(Q - P, 0);
       TimeRemaining = math.max((StartTime + Duration) - Now, 0);

       // Determine whether we are on schedule or not
       ?production_time(ProdTime);
       if (QuotaRemaining > 0) {
           NeededAvgTime = (TimeRemaining / QuotaRemaining)*1000;
           if (ProdTime > NeededAvgTime) {
               -on_schedule;
               +working_speed(NeededAvgTime);
           } else {
               +on_schedule;
               +working_speed(ProdTime);
           }
       } else {
           +on_schedule;
           +working_speed(ProdTime);
       }

       // Randomly be bored.
       ?distraction_probability(DistractProb);
       .random(R);
       if (R < DistractProb) {
          +bored;
       } else {
          -bored;
       };

       .wait(5000);
       !monitor_quota.

// --- Plans to React to Behind Schedule ---

-on_schedule
    <- .print("Going behind schedule! Working faster!").

+on_schedule
    <- .print("On schedule!").

// --- Plans to React to Boredom ---

+bored
    <- .print("I'm bored!");
       .my_name(MyHumanName);
       .broadcast(tell, bored(MyHumanName)).

-bored
    <- .print("Not bored anymore!");
       .my_name(MyHumanName);
       .broadcast(untell, bored(MyHumanName)).

// --- Talk to other bored humans if on schedule ---

+bored[source(OtherHumanName)]
    : bored & on_schedule
    <- ?max_chat_delay(MaxDelay);
       ?min_chat_delay(MinDelay);
       .random(R);
       ChatDelay = MinDelay + (MaxDelay - MinDelay) * R;
       .print("Chatting with ", OtherHumanName, " for ", ChatDelay/1000, " seconds.");
       .wait(ChatDelay);
       -bored.

+bored[source(OtherHumanName)]
    : not bored | not on_schedule
    <- .print("Sorry, I'm busy right now!").

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
    : my_bin_number(MyBin) & not got_bin_lock
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

// If already got the lock for the bin, do nothing.
+!attempt_to_lock_bin : got_bin_lock.

// --- Plans for Handling Lock Agent Responses ---

+got_bin_lock
    : my_bin_number(MyBin)
    <- .print("Lock acquired for bin ", MyBin, ". Starting production.");
       ?working_speed(ProdTime);
       .wait(ProdTime);
       .print("Production complete for bin ", MyBin, ". Refilling.");
       refill_bin(MyBin);
       ?produced_in_period(P);
       -+produced_in_period(P+1);
       .print("Releasing lock for bin ", MyBin, ".");
       .my_name(MyHumanName);
       .send(bin_locking_agent, achieve, unlock_bin(MyBin, MyHumanName));
       -got_bin_lock.
