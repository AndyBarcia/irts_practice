// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com

// Note that bins would usually be environmental entities and not agents:
// But it was easier to implement them as agents for experimental purposes.

!start.

binnumber(1,binagent1).
binnumber(2,binagent2).
binnumber(3,binagent3).
binnumber(4,binagent4).
binnumber(5,binagent5).
binnumber(6,binagent6).

// --- Beliefs ---
// binfull(N) : standard belief, true if the bin is full, false/absent otherwise. The primary state indicator.

// --- Public Signals (broadcasted) ---
// needs_parts_public(BinNumber)

// --- Event Handling ---

// When a bin is no longer full (binfull(N) is retracted), broadcast it needs parts.
-binfull(N)
    : binnumber(N)
    <- .print("Bin agent ", N, " is now empty.");
       .broadcast(tell, needs_parts_public(N)).

// When a bin becomes full (binfull(N) is added), broadcast it's full.
+binfull(N)
    : binnumber(N)
    <- .print("Bin agent ", N, " is now full.");
       .broadcast(untell, needs_parts_public(N)).

// --- Initialisation ---
+!start : true
 <- .my_name(Agent);
    ?binnumber(N,Agent);
    +binnumber(N); // Add belief for the agent's own bin number
    .broadcast(tell, needs_parts_public(N)); // Broadcast public signal
    .print("Bin agent ", N, " started.").
