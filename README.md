# Vapa v2
```
loadstring(game:HttpGet("https://raw.githubusercontent.com/Nickyangtpe/Vapa-v2/main/Vapav2.lua", true))()
```
```
loadstring(game:HttpGet("https://raw.githubusercontent.com/Nickyangtpe/Vapa-v2/refs/heads/main/Vapav2-Arsenal.lua", true))()
```

# Vapa v3

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Nickyangtpe/Vapa-v2/main/Vapav3.lua", true))()
```

## Powerful Roblox Exploit Library (Closed Source)

Vapa v3 is a feature-rich, closed-source exploit library for Roblox, designed to enhance your gaming experience with a wide array of functionalities. This library provides a user-friendly graphical interface (GUI) to easily access and control various exploit features, categorized for intuitive navigation.

**Please be aware that Vapa v3 is a closed-source project and is provided as-is. Using exploits is against Roblox's Terms of Service and carries significant risks.**

---

## ⚠️ Important Disclaimer ⚠️

**Using exploits in Roblox is against the Roblox Terms of Service and may result in account suspension or permanent ban. Vapa v3 is provided for educational and testing purposes only. The developers of Vapa v3 are not responsible for any consequences resulting from its use. Use Vapa v3 entirely at your own risk.**

**Vapa v3 is a closed-source project. Redistribution or modification of Vapa v3 is strictly prohibited.**

**Be aware of the potential risks associated with running closed-source software from untrusted sources. Always exercise caution when using exploits.**

---

## Features

## Features

Vapa v3 is packed with features across several categories, giving you extensive control and abilities within Roblox games.

**Combat:**

*   **Aim Assist:** Enhance your aiming precision with various modes.
    *   **Modes:** None, SnapBack, Lock-On, ForceAim (Selectable behavior)
    *   **Smooth Speed:** Adjustable aim smoothing factor.
    *   **Wall Check:** Aim only at targets visible through walls (toggle).
    *   **Team Check:** Ignore teammates when aiming (toggle).
    *   **Health Check:** Ignore dead or downed players (toggle).
    *   **FOV:** Limit aim assist activation to a specific Field of View radius around the crosshair (toggle).
    *   **Input:** Choose aim input method (Camera manipulation or Mouse movement).
    *   **Target Part:** Select the specific body part to aim at (Head, Torso, etc.).
*   **TPAura (Teleport Aura):** Periodically teleport behind nearby players.
    *   **Target:** Select a specific player, "None" for random, or use range-based random. (Dynamic list)
    *   **Team Check:** Avoid teleporting to teammates (toggle).
    *   **Interval:** Adjust the time between teleports.
    *   **Duration:** Adjust how long you stay teleported after each interval trigger.
    *   **Distance:** Adjust the distance behind the target to teleport.
    *   **Range:** Enable/disable teleporting only to players within a specific X/Y range (toggle).
    *   **Range X/Y:** Define the horizontal range for targeted teleports.
*   **SpinBot:** Rapidly rotate your character model.
    *   **Speed:** Adjust the rotation speed.

**Visuals:**

*   **FullBright:** Increase game brightness for better visibility.
    *   **Level:** Adjust the brightness intensity.
*   **Trajectories (Player Trails):** Leave a visual trail behind your character.
    *   **Lifetime:** Adjust how long the trail lasts.
    *   **Width:** Adjust the thickness of the trail.
    *   **Length:** Adjust the minimum and maximum length of the trail segments (Range Slider).
*   **Custom FOV:** Override the game's default Field of View.
    *   **Size:** Adjust the desired FOV value.
*   **ESP (Extra Sensory Perception - Player Boxes):** Highlight players with boxes.
    *   **Style:** Choose between 2D screen-space boxes or 3D world-space boxes.
    *   **Health:** Display health bars next to ESP boxes (toggle).
    *   **Thickness:** Adjust the thickness of the ESP box lines.
    *   **Update Interval:** Adjust how frequently ESP updates (lower values are smoother but potentially more performance-intensive).
    *   **Color:** Choose the default color for ESP boxes.
    *   **Team Color:** Use player team colors for ESP boxes (toggle).
*   **Creature ESP (NPC/Monster Boxes):** Highlight non-player characters.
    *   **Color:** Choose the color for creature ESP boxes.
*   **Glow (Player Outline Glow):** Add a glowing outline to players using `Highlight`.
    *   *(Note: Color customization might be implicitly tied to ESP color or default)*
*   **Noclip Camera:** Prevents the camera from being obstructed by parts (Invisicam).
*   **View Force:** Force the camera into a specific mode.
    *   **Mode:** Choose between Classic (None) or LockFirstPerson.
*   **Infinite Sight:** Removes the maximum zoom-out distance limit for the camera.
*   **DVD (Bouncing Logo):** Display a text label that bounces around the screen like the classic DVD logo.
    *   **Text:** Customize the text displayed.
    *   **Bounce Change Color:** Change the text color randomly on each screen edge bounce (toggle).
    *   **Color:** Set the default text color (used when Bounce Change Color is off).
*   **Skeleton ESP (Bone ESP):** Draw lines connecting player character bones.
    *   **Team Check:** Use player team colors for skeleton lines (toggle).
    *   **Color:** Choose the default color for skeleton lines.
*   **Name Tags:** Customize player name tags shown via ESP.
    *   **Visible:** Toggle name tag visibility (toggle).
    *   **Health:** Display health percentage below the name tag (toggle).
    *   **Distance:** Display distance to the player below the name tag (toggle).
    *   **Team Color:** Use player team colors for name tags (toggle).
    *   **Size:** Adjust the text size of name tags.
    *   **Color:** Choose the default color for name tags.
*   **Tracers (Line Tracers to Players):** Draw lines from a screen point to players.
    *   **Team Color:** Use player team colors for tracers (toggle).
    *   **Thickness:** Adjust the thickness of the tracer lines.
    *   **Style:** Choose the origin point of the tracer lines (Bottom, Left, Right, Top, RightTop, LeftTop).
    *   **Color:** Choose the default color for tracer lines.
*   **China Hat (Cone Hat Visual):** Add a cosmetic cone hat to your character.
    *   **RGB:** Enable rainbow color cycling for the hat (toggle).
    *   **RGB Speed:** Adjust the speed of the RGB color cycle.
    *   **Transparency:** Adjust the transparency of the hat.
    *   **Glow Intensity:** Adjust the intensity of the hat's glow effect (using `Highlight`).
    *   **Height:** Adjust the vertical offset of the hat relative to the head.
*   **FOV Circle (Aim Assist FOV Circle):** Display a circle representing the Aim Assist FOV radius.
    *   **Radius:** Adjust the size of the circle (linked to Aim Assist FOV setting).
    *   **Color:** Choose the color of the circle.
*   **Custom Crosshair:** Replace the default game crosshair.
    *   **Thickness:** Adjust the thickness of the crosshair lines.
    *   **Length:** Adjust the length of the crosshair lines.
    *   **Gap:** Adjust the gap between the center and the crosshair lines.
    *   **Dot Size:** Adjust the size of the center dot (set > 0 to enable).
    *   **Color:** Choose the color of the crosshair.
*   **Jump Wave (Jump Effect):** Create a visual wave effect on the ground when landing.
    *   **Size:** Adjust the maximum radius of the wave effect.
    *   **Duration:** Adjust how long the wave effect lasts.
*   **Back Runner:** Force your character to face away from the camera while moving.
*   **TargetHUD:** Display an animated HUD with detailed information (Avatar, Name, Health, Distance) about the current Aim Assist target. (Toggle)

**Player:**

*   **Player Teleport:** Teleport directly to a selected player.
    *   **Target:** Select the target player from a dynamic list.
*   **Click Teleport:** Teleport to the location clicked by your mouse in the 3D world.
*   **Spamming (Chat Spammer):** Automatically send messages to the game chat.
    *   **Interval:** Adjust the time between messages.
    *   **Text:** Customize the message to be spammed.
*   **Anti-AFK:** Prevent being kicked for inactivity by simulating input.
*   **LeaveNotification:** Display a message when a player leaves the game.
*   **HealthWarning:** Display a warning message when your health drops below a threshold.
    *   **Health (%):** Set the health percentage threshold for the warning.

**Movement:**

*   **Noclip (No Clip):** Allow passing through walls and objects.
*   **Air Step:** Maintain altitude briefly when walking off ledges if not moving.
*   **Fly:** Enable free flight mode.
    *   **Speed:** Adjust flight speed.
*   **Walk Speed:** Modify your character's walking speed.
    *   **Speed:** Adjust the desired walk speed value.
    *   **Mode:** Choose movement mode (None or BHop - Bunny Hopping).
*   **High Jump:** Increase your character's jump height.
    *   **Height (Power):** Adjust the jump power.
*   **Air Jump:** Allow jumping while in mid-air.
    *   **Infinite:** Allow unlimited jumps in the air (toggle).
*   **Gravity:** Modify the workspace gravity.
    *   **Value:** Adjust the gravity strength (can be negative).
*   **Auto Walk:** Automatically walk forward based on character facing direction.
    *   **Speed:** Adjust the auto walk speed multiplier (can be negative for backwards).
*   **Fast Stop:** Instantly stop horizontal movement when movement keys are released.

**Misc:**

*   **HUD (Heads-Up Display):** Toggle the visibility of the on-screen stats display (FPS, Ping, Coords - *if implemented by the library*).
*   **Config (Configuration System):** Manage exploit settings.
    *   **Configs Dropdown:** Select a saved configuration file to load on the next launch (requires script restart).
    *   **Config Name Textbox:** Enter the name for saving the current configuration.
    *   **Save Button:** Save the current settings to the specified config name.

---

## How to Use

1.  **Inject Vapa v3 into Roblox:** You will need a Roblox exploit injector tool. Vapa v3 itself does not include an injector. Follow the instructions provided by your chosen injector.
2.  **Open the GUI:** Press the **`Right Shift`** key on your keyboard to toggle the main Vapa v3 GUI window on or off.
    *   **Mobile Users:** A draggable circular "UI" button should appear on screen. Tap this button to toggle the main GUI. You can drag this button to reposition it.
3.  **Navigate the Menu:** The main "VAPA v3" window lists the different feature categories (Combat, Visuals, Player, Movement, Misc). Click on a category name (which acts as a toggle) to show or hide its corresponding window.
4.  **Toggle and Configure Features:**
    *   Inside each category window, click on a feature name (e.g., "Aim Assist") to toggle it **On** or **Off**. The item will change appearance (usually background color/text color) to indicate its state.
    *   Features with a **gear icon (⚙️)** next to them have additional settings. Click the gear icon or **Right-Click** the feature name to expand/collapse its settings panel below it.
    *   Use the sliders, toggles, dropdown menus, text boxes, and color pickers within the settings panel to customize the feature's behavior.
5.  **Utilize the ArrayListUI:** When certain features are enabled, they might appear in a list at the top-right corner of your screen. This provides a quick visual overview of active modules.
6.  **Save/Load Configs:**
    *   Go to the **Misc** window and expand the **Config** item.
    *   To save your current settings, type a name into the **Config Name** textbox and click the **Save** button.
    *   To set a config to load the *next time* you inject Vapa v3, select it from the **Configs** dropdown menu. The selected config file name will be saved, but changes require restarting/re-injecting.

---

**Final Disclaimer:**

**Remember, using exploits like Vapa v3 violates Roblox's Terms of Service and can lead to disciplinary action against your account, including permanent bans. The creators and distributors of Vapa v3 assume no responsibility for any actions taken against your account or any issues arising from the use of this software. Use it responsibly and ethically, or not at all.**

**As Vapa v3 is closed-source, you cannot inspect the code yourself. Be extremely cautious when running software from untrusted sources.**

**Do not redistribute or attempt to modify Vapa v3.**

---

**Vapa v3 - Enhance your Roblox experience, but use responsibly.**
