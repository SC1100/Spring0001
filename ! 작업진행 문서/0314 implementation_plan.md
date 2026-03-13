# Dynamic Title & Transition Implementation Plan

Implement a narrative-driven title screen system and a centralized transition manager.

## Proposed Changes

### [Data Architecture]
#### [NEW] `res://resources/data/PlayerData.gd`
- **Purpose**: Store non-pet-specific progress and settings.
- **Fields**: `var is_game_cleared: bool = false`.

#### [MODIFY] `res://scripts/global/Global.gd`
- Initialize and persist both `PetData` and `PlayerData`.

### [Transition System]
#### [NEW] `res://scenes/components/SceneTransitionComponent.tscn`
- **Structure**: `CanvasLayer` > `ColorRect` (White).
- **Features**: Global white fade-in/out for scene changes.

### [Title Screen & Entrance]
#### [NEW] `res://scenes/ui/TitleScreen.tscn`
- **Dual Viewports**: Switches between `ExteriorCam` (Door) and `InteriorCam` (Window) based on `PlayerData.is_game_cleared`.
- **Entrance Logic**: "Enter" button or Door interaction triggers white fade -> Main Room.

### [Debug Components (Decoupled)]
#### [NEW] `res://scenes/components/DebugEndingTrigger.gd`
- Self-contained component. Upon interaction:
  - Sets `Global.player_data.is_game_cleared = true`.
  - Saves game state.
  - (Optional) Triggers a notification.

#### [NEW] `res://scenes/components/DebugRestartTool.gd`
- Component for `MainRoom`. Upon interaction:
  - Triggers white fade.
  - Reloads Title Screen to show the "2nd Playthrough" state.

## Verification Plan
1. **Entrance**: Start Title -> Click Door -> Confirm white fade -> Confirm spawn inside room.
2. **Ending**: In Room -> Click MediaFrame -> Check Save File (`is_game_cleared: true`).
3. **Restart**: Click Debug Tool -> Returns to Title -> Confirm Title shows Internal view.
