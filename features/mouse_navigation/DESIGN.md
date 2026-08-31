# Mouse navigation and camera controls

## Player-visible outcome

Desktop players can explore the active 3D homestead entirely with the mouse.
The wheel zooms the orthographic camera, holding and dragging the right button
orbits the camera, and a right-button click without a drag walks the player to
the clicked ground point. Left-clicking an interactable NPC or world object
interacts immediately when the player is close enough; otherwise the player
follows a navigation path to the target and interacts on arrival.

## Ownership

- `MouseNavigationController` owns only mouse gesture state and the pending
  interaction intent. It converts screen-space input into camera, movement, or
  interaction requests.
- `Faux2DCameraRig` remains the sole owner of orthographic size and orbit
  angles. The mouse controller calls its public zoom/orbit methods.
- `HomesteadPlayer3D` remains the sole owner of velocity, locomotion, facing,
  and active path-following state. Keyboard input cancels click-to-move.
- `NavigationRegion3D` owns the runtime-baked walkable surface. The authored
  world collision on physics layer 2 is the only bake source.
- An interactable node owns its immutable title, text, approach point, and
  interaction distance. `HomesteadAdventure3D` owns dialogue presentation.

No persistent profile or `content/*.tres` state is added or mutated.

## Scene tree and public contract

```text
HomesteadAdventure3D
├── World (navigation source group)
├── NavigationRegion3D (runtime-baked NavigationMesh)
├── Player (HomesteadPlayer3D)
│   └── NavigationAgent3D
├── CameraRig (Faux2DCameraRig)
│   └── Camera3D (orthographic)
└── MouseNavigation (MouseNavigationController)
```

Public methods and signals:

- `Faux2DCameraRig.orbit_by(mouse_delta)`
- `Faux2DCameraRig.zoom_by_steps(wheel_steps)`
- `HomesteadPlayer3D.navigate_to(world_position)`
- `HomesteadPlayer3D.cancel_navigation()`
- `HomesteadPlayer3D.navigation_finished(reached)`
- `HomesteadPlayer3D.navigation_cancelled`
- `HomesteadPlayer3D.manual_movement_started`
- `MouseNavigationController.configure(camera_rig, player, region)`
- `MouseNavigationController.navigation_ready`
- `MouseNavigationController.interaction_requested(interactable)`
- `WorldInteractable3D.get_interaction()`
- `WorldInteractable3D.get_interaction_position(from_position)`
- `WorldInteractable3D.can_interact_from(from_position)`

## Input and data flow

```text
mouse event
  -> MouseNavigationController
     -> wheel / right-drag -> Faux2DCameraRig
     -> right-click ray -> nearest navigation point -> HomesteadPlayer3D
     -> left-click ray -> interactable
        -> in range -> interaction_requested
        -> out of range -> HomesteadPlayer3D path -> interaction_requested
```

A movement command projects the ray hit onto the active navigation map before
the player receives it. A right-button gesture becomes an orbit as soon as its
accumulated travel exceeds the drag threshold; releasing after an orbit never
also issues a walk command.

## Failure modes

- Input received before the runtime navigation bake completes is queued and
  replayed after the navigation map synchronizes.
- A ray that misses world collision creates no movement or interaction intent.
- A target freed while the player approaches it cancels the pending action.
- Manual keyboard movement, menus, dialogue, battle, teleporting, or a new
  mouse command cancels the prior path safely.
- An unreachable interaction target ends without firing the interaction.
- UI controls receive mouse input first; gameplay uses `_unhandled_input()` so
  clicking menus does not move the player or orbit the camera.

## Isolated validation

Run `tests/mouse_navigation_smoke_test.tscn` headlessly. It verifies the baked
navigation mesh, a non-empty path across the authored terrain, player path
ownership, camera zoom/orbit clamping, click-versus-drag classification, and
the interactable approach contract. Then run the existing 3D homestead smoke
test, full project startup, and inspect a live gameplay capture.
