// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com

// Translating agent names to holder numbers
holdernumber(1,holdingagent1).
holdernumber(2,holdingagent2).
holdernumber(3,holdingagent3).
holdernumber(4,holdingagent4).
holdernumber(5,holdingagent5).
holdernumber(6,holdingagent6).

// Initial intention
!start.

// Respond to a percept that a part has been placed into a holder
+part_in_place(N) : holdernumber(N)
<- .print("Holding agent ",N,": holding part.");
   hold_part(N);
   .broadcast(tell,holding(N)).
   
// Respond to a belief that the mover has taken grip of the frame
+mover(hold) : true
<- ?holdernumber(N);
   .print("Holding agent ",N,": unholding part.");
   unhold_part(N);
   .broadcast(untell,holding(N)).
   
   
// Initial plan
+!start : true
<- .my_name(Agent);
   ?holdernumber(N,Agent);
   +holdernumber(N);
   .print("Holding agent ",N," : Hello!");
   .print("Holding agent ",N," : Waiting for part...").

