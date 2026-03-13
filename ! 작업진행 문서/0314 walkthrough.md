# Title & Transition System Walkthrough

The title screen and transition system have been implemented to create a seamless, narrative-driven entry into the game world.

## 🎬 Cinematic Title Screen
The title screen dynamically adapts its viewpoint based on user progress.
- **New Players**: Experience an exterior view, looking at the door they are about to enter.
- **Returning Players (Game Cleared)**: Experience an interior view, looking through the windows with a sense of peace.

## 🎞️ Global Transitions
A white fade effect is used for all major scene changes, reinforcing the "memory/heavenly" aesthetic of the project. This is handled by a global `SceneTransition` component.

## 🚪 Entrance Logic
Regardless of the playthrough count, players always begin their journey outside the room, emphasizing the act of "visiting" or "returning" to the memorial space.

## 🛠️ Testing Tools (Debug)
For development, two diagnostic objects have been placed in the room:
- **🔵 Blue Ball**: Triggers the "Game Cleared" status and saves data.
- **🔴 Red Ball**: Resets the state and returns the player to the title screen.

### Verification of Fixes
- **Camera Clipping**: Interior camera moved forward to avoid wall clipping.
- **UID Resolving**: Cleaned up scene resource dependencies.
- **Robustness**: Scripts now dynamically find cameras and components to prevent parser/node errors.
