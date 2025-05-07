// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com

// Initial configuration option: maximum duration until a part arrives
timer(25000).

// Note that bins would usually be environmental entities and not agents:
// But it was easier to implement them as agents for experimental purposes.

!start.

binnumber(1,binagent1).
binnumber(2,binagent2).
binnumber(3,binagent3).
binnumber(4,binagent4).
binnumber(5,binagent5).
binnumber(6,binagent6).


-binfull(N) 
    : binnumber(N)
    <- !refill.

+!start : true
 <- .my_name(Agent);
    ?binnumber(N,Agent);
	+binnumber(N);
    .print("Bin agent ", N, " started.");
	!refill.

+!refill : true
 <- ?binnumber(N);
    ?timer(T);
    .random(X);
	.print("Bin agent ",N," waiting ",X*T div 1000, " seconds for new parts...");
    .wait(X*T);
	.print("Bin agent ",N," has received new parts.");
    refill_bin(N).
                       
