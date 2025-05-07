# Practice Statement

The practice will consist of modifying the assembly factory version to weld bicycle frames.

*   The practice has a common section for all teams and a specific section for each team.
*   The common section will consist of modifying the binagents code so that we have four agents simulating bin construction by humans (bob, alice, tom and mary) and the rest by robots.
    *   Each human agent specializes in building one type of bin (from one to four), while robots can build any type of bin (as needed).
    *   The human agents work within a pre-established period (80000 ms), and each generates at least (in the worst case) a different and fixed number of bins in each period.
    *   The human agents can increase their production (become faster) if they need (to get more money or to recover time).
    *   The human agents may occasionally become distracted (become slower) by chatting with the other human agents (each human agent chose to chat when bored 400-800 ms), but they are never so distracted that they cannot meet their daily quota (if they produce less, they do not get money), so they must compensate for any delays in their production.
    *   Robot agents are never distracted and always make the same number of parts (regardless of class), unless they break (the probability of this happening is between 5-10 %), in which case they always take a fixed amount of time to be repaired.
*   The specific part will consist of duplicating one of the manufacturing agents and positioning it in the environment as follows:
    *   Team 1 will have two moving agents in its factory, which must work together to move the assembled bicycle frames.
    *   Team 2 will have two welding agents in its factory. Each one can only weld in one assembly area, but they can weld simultaneously.
    *   Team 3 will have two robotic arm agents in its factory that can place any of the parts in the assembly areas and operate simultaneously.
    *   Team 4 will have two welding agents in its factory that can operate in any assembly area and weld simultaneously.
    *   Team 5 will have two robotic arm agents in their factory, one responsible for placing odd-numbered parts and the other for even-numbered parts, but they can only operate in shifts.
    *   Team 6 will have a new robot in their factory capable of performing any of the other robots' tasks and replacing them when they break (the failure rate for robots is 10-20%) and they require a repair time of 12000 ms.
    *   Team 7 will have two robotic arm agents and two moving agents in their factory. The moving agents must synchronize their operation to remove the assembled bicycle frame; while the robotic arm agents must operate sequentially (one acts first, then the other) to place the remaining parts in the assembly area.