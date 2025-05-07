// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com

// Initial intention: None


// Reserve full assembly area for an agent
@fullLock [atomic]
+!fullAreaLockFor(Agent): (lockedAreaFor(Agent,1) & not lockedAreaFor(_,2)) |
						  (lockedAreaFor(Agent,2) & not lockedAreaFor(_,1)) |
						  (not lockedAreaFor(_,1) & not lockedAreaFor(_,2))
<- .print("Assembly Area Agent: locking full assembly area for ",Agent);
   +lockedAreaFor(Agent,1);
   +lockedAreaFor(Agent,2);
   lock_area(1);
   lock_area(2);
   .send(Agent,tell,lockedArea(1));
   .send(Agent,tell,lockedArea(2));
   .print("Assembly Area Agent: locked assembly area for ",Agent);.
   
+!fullAreaLockFor(Agent).
   
@partialLock [atomic]
+!lockAreaFor(Agent,Area): lockedAreaFor(Agent,Area) | not lockedAreaFor(_,Area)
<- .print("Assembly Area Agent: locking subsector ",Area," for ",Agent);
   +lockedAreaFor(Agent,Area);
   lock_area(Area);
   .send(Agent,tell,lockedArea(Area));
   .print("Assembly Area Agent: locked subsector ",Area," for ",Agent);.
   
+!lockAreaFor(Agent,Area) : true
<- .print("Assembly Area Agent: cannot lock subsector ",Area," for agent ", Agent).

// Unreserve assembly area for an agent
@fullAreaUnlockFor [atomic]
+!fullAreaUnlockFor(Agent) : lockedAreaFor(Agent,1) & lockedAreaFor(Agent,2)
<- -lockedAreaFor(Agent,1);
   -lockedAreaFor(Agent,2);
   .send(Agent,untell,lockedArea(1));
   .send(Agent,untell,lockedArea(2));
   unlock_area(1);
   unlock_area(2).

@unlockAreaFor [atomic]
+!unlockAreaFor(Agent,Area) : lockedAreaFor(Agent,Area)
<- -lockedAreaFor(Agent,Area);
   .send(Agent,untell,lockedArea(Area));
   unlock_area(Area).

+!unlockAreaFor(Agent,Area).   

