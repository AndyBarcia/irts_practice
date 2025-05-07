// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com
// Belief of a position where we can park the welding tool outside
// the main assembly area
waitingposition(500,70).
framestockposition(-400,300).

// Rule for complete holder release
holdersReleased(N) :- not holding(N) & (N = 1 | holdersReleased(N-1)). 
holdersReleased :- holdersReleased(6).

// Rule for noticing when welding completed
jointDone(N) :- joint(N) & (N = 1 | jointDone(N-1)). 
weldingCompleted :- joints(N) & jointDone(N).


// Let's assume a mover percept is not always available: let's retry
// (Background are limitations of the environment simulation.)
+?mover(X,Y) : true
  <-?mover(X,Y).

// Embrace initial plan
!start.

+!start : true
<- .print("Moving robot: waiting for finished frame");
   !removeFrame.

// Act on a request to move the frame away
+!removeFrame : weldingCompleted & not (lockedArea(1) & lockedArea(2))
<- .print("Moving robot: requesting access to assembly area.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,fullAreaLockFor(Agent));
   .wait(200);
   !removeFrame.
   
+!removeFrame : weldingCompleted & lockedArea(1) & lockedArea(2)
<- .print("Moving robot: moving finished frame away.");
   !pickFrame;
   !moveAway;
   !removeFrame.
   
+!removeFrame : not weldingCompleted
<- .wait(200);
   !removeFrame.
   
// Pickup the whole frame
+!pickFrame : true
<- ?partPosition(4,X,Y,_);
   !moveTo(X,Y);
   pick_part(4);
   .broadcast(tell,mover(hold)).
   
// Moving the frame away from the main assembly area
+!moveAway : holdersReleased
<- ?framestockposition(X2,Y2);  	
   !moveTo(X2,Y2);
   release_part;
   .broadcast(untell,mover(hold));
   !awaitUnlockArea;
   !parkArm.

// In case holders still fix the frame, retry after 200ms
+!moveAway : true
<- .wait(200);
   !moveAway.

// Plan for moving the mover around 
+!moveTo(X,Y) : not mover(X,Y)
  <- move_towards(X,Y,0);
     !moveTo(X,Y).
	 
// We declare success when the mover percept confirms arrival at the target position 
+!moveTo(X,Y) : mover(X,Y).

// When the robot has no job, park the arm outside the main assembly area
+!parkArm : true
<- ?waitingposition(X,Y);
   !moveTo(X,Y).
   
   
// Wait until assembly area is not locked any longer
+!awaitUnlockArea : lockedArea(_)
<- .print("Moving robot: giving way to others.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,fullAreaUnlockFor(Agent));
   .wait(200);
   !awaitUnlockArea.
   
+!awaitUnlockArea.
   
