// CSCK504 Multi-agent systems group assignment: Team E
// 07 October 2021
// Contact: benjamin.schlup@schlup.com

// Beliefs mapping agent names to their specific resting positions.
welding_rest_position(weldingagent1, 1000, 470).
welding_rest_position(weldingagent2, 800, 613).

// Let's assume a welder percept is not always available: let's retry
// (Background are limitations of the environment simulation.)
+?welder(X,Y) : true
  <-?welder(X,Y).

// Rules for parts that shall be welded together
jointPartsInPlace(1) :- holding(1) & holding(2) & holding(3).
jointPartsInPlace(2) :- holding(2) & holding(4).
jointPartsInPlace(3) :- holding(3) & holding(4) & holding(6).
jointPartsInPlace(4) :- holding(4) & holding(5).
jointPartsInPlace(5) :- holding(5) & holding(6).

// Rule for complete holder release
holdersReleased(N) :- not holding(N) & (N = 1 | holdersReleased(N-1)). 
holdersReleased :- holders(N) & holdersReleased(N).

// Embrace initial plan
!main.

+!main : true
<- .my_name(MyAgentName);
   ?welding_rest_position(MyAgentName, RestX, RestY);
   +my_waiting_position(RestX, RestY);
   .print("Welding robot ", MyAgentName, " initialized. Waiting position: (", RestX, ",", RestY, ")");
   !weldParts.

// Forget welded joints if all holders have been released
+!weldParts : joint(_) & holdersReleased
<- !forgetJoints;
   !weldParts.
   
// In case that we see that required parts for joint 1 have been fixed,
// we check if we need to weld it. 
// If we need to move the welder to the assembly area, lock it first.
+!weldParts : jointPartsInPlace(1) & not joint(1) & not lockedArea(2)
<- .print("Welding robot: requesting access to assembly area 2.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,lockAreaFor(Agent,2));
   .send(assemblyareaagent,achieve,unlockAreaFor(Agent,1));
   .wait(200); // be careful to not request access too frequently
   !weldParts.
   
// Now that the area is locked, we move the welder to the joint position and 
// do our job.
+!weldParts : (Joint = 1 & jointPartsInPlace(Joint) & not joint(Joint) & lockedArea(2)) |
              (Joint > 1 & jointPartsInPlace(Joint) & not joint(Joint) & lockedArea(1) & lockedArea(2))
<- .print("Welding robot: welding joint ", Joint);
   .drop_intention(parkArm);
   ?jointPosition(Joint,X,Y);
   !moveTo(X,Y);
   weld;
   +joint(Joint);
   .broadcast(tell,joint(Joint));
   !!parkArm;
   !weldParts.   
   
// In case parts required for another joint are in place, lock area
+!weldParts : Joint > 1 & jointPartsInPlace(Joint) & not joint(Joint) & (not lockedArea(1) | not lockedArea(2))
<- .print("Welding robot: requesting access to assembly areas 1 and 2.");
   .my_name(Agent);
   .send(assemblyareaagent,achieve,fullAreaLockFor(Agent));
   .wait(200); // be careful to not request access too frequently
   !weldParts.
   
+!weldParts : true
<- !weldParts.

// Forget all joints
+!forgetJoints : joint(N)
<- -joint(N);
   .broadcast(untell,joint(N));
   !forgetJoints.
   
+!forgetJoints.   
   
// Plan for moving the welding tool around 
+!moveTo(X,Y) : not welder(X,Y)
  <- move_towards(X,Y,0);
     !moveTo(X,Y).
	 
// We declare success when the welder percept confirms arrival at the target position 
+!moveTo(X,Y) : welder(X,Y).

// When the robot has no job, park the arm outside the main assembly area
+!parkArm : my_waiting_position(ParkX,ParkY) & not welder(ParkX,ParkY)
<- !moveTo(ParkX,ParkY);
   !parkArm.
   
+!parkArm 
   : lockedArea(Area) & my_waiting_position(ParkX, ParkY)
<- !moveTo(ParkX, ParkY); // Move to its own parking spot first
   .print("Welding arm agent: releasing lock from area ",Area);
   .my_name(Agent);
   .send(assemblyareaagent,achieve,unlockAreaFor(Agent,Area));
   .wait(200);
   !parkArm.
   
+!parkArm.
  
   
