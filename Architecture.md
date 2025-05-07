# Existing Agent Architecture Summary (Bicycle Frame Assembly)

This document summarizes the roles and interactions of the agents in the existing bicycle frame assembly system, based on the `.asl` files found in `src/agt`.

## Agent Roles:

*   **`binagent.asl`**:
    *   **Role**: Represents a container for parts. Simulates parts becoming available after a delay.
    *   **Note**: This is NOT for building bins, but for holding components/materials.
    *   **Key Actions/Beliefs**: `refill_bin(N)` (environment action), `binfull(N)` (belief).

*   **`assemblyareaagent.asl`**:
    *   **Role**: Manages exclusive access to "assembly areas" (physical zones 1 and 2) using a locking mechanism.
    *   **Functionality**: Provides goals like `!fullAreaLockFor(Agent)`, `!lockAreaFor(Agent,Area)`, and their unlock counterparts.
    *   **Interaction**: Other agents send `achieve` messages to request/release locks. It calls `lock_area(N)` / `unlock_area(N)` in the environment.

*   **`holdingagent.asl`**:
    *   **Role**: Represents a fixture or jig that holds a specific part (agents `holdingagent1` through `holdingagent6`).
    *   **Functionality**: Reacts to `part_in_place(N)` (likely from `roboticarmagent`) by calling `hold_part(N)` (env action) and broadcasting `holding(N)`. Reacts to `mover(hold)` (from `movingagent`) by calling `unhold_part(N)` and retracting `holding(N)`.
    *   **Interaction**: Responds to environment percepts/agent broadcasts; broadcasts `holding(N)` status.

*   **`roboticarmagent.asl`**:
    *   **Role**: Picks parts from `binagent`s and places them into `holdingagent`s.
    *   **Functionality**: Main goal `!positionParts`. Requests locks from `assemblyareaagent`. Picks parts (`pick_part` env action), moves, signals `part_in_place(N)` to `holdingagent`, waits for `holding(N)` belief, then releases part (`release_part` env action).
    *   **Interaction**: Checks `binfull(Part)`, communicates with `assemblyareaagent` and `holdingagent` (via broadcasts and belief checks).

*   **`weldingagent.asl`**:
    *   **Role**: Performs welding on parts secured by `holdingagent`s.
    *   **Functionality**: Main goal `!weldParts`. Checks `jointPartsInPlace(JointNum)` (derived from `holding(PartNum)` beliefs). Requests locks from `assemblyareaagent`. Moves, performs `weld` (env action), broadcasts `joint(JointNum)`.
    *   **Interaction**: Checks `holding(PartNum)`, communicates with `assemblyareaagent`, broadcasts `joint(JointNum)`.

*   **`movingagent.asl`**:
    *   **Role**: Moves the completed (welded) frame.
    *   **Functionality**: Main goal `!removeFrame`. Waits for `weldingCompleted` (all `joint(N)` true). Requests locks. Picks frame (`pick_part` env action), broadcasts `mover(hold)`. Waits for `holdersReleased` (all `holding(N)` false). Moves frame to stock (`release_part` env action).
    *   **Interaction**: Checks `weldingCompleted`, communicates with `assemblyareaagent`, broadcasts `mover(hold)`, checks `holdersReleased`.

## Overall Interaction Flow (Simplified):

1.  **Parts Supply**: `binagent`s provide parts.
2.  **Area Locking**: `roboticarmagent` & `weldingagent` coordinate access via `assemblyareaagent`.
3.  **Part Placement**: `roboticarmagent` picks parts, places them in `holdingagent`s, which secure them. This involves communication between `roboticarmagent` and `holdingagent`.
4.  **Welding**: `weldingagent` welds parts once `holdingagent`s confirm they are secure. Progress is broadcast.
5.  **Frame Removal**: `movingagent` takes the finished frame after `weldingagent` signals completion and `holdingagent`s release parts upon `mover(hold)` signal.

## Relevance to New Bin-Building Task:

*   The `assemblyareaagent` concept might be reusable for managing shared bin construction zones.
*   Agent interaction patterns (belief broadcasting, goal delegation to specialized agents) are applicable.
*   Existing specific agent logic (for welding, bicycle part manipulation) is too specialized for direct reuse in bin building. New agent definitions and plans will be required for:
    *   **Human agents**: Specialized for one bin type each.
    *   **Robot agents**: Flexible for building any bin type.
*   The environment (`fac1env.java`) will need significant updates for bin artifacts, materials, and new actions. 