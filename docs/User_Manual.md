# Patogen User Manual

67Games · A guide to playing Patogen

Patogen is an infection strategy game for **two local players sharing one computer and screen**. Each player chooses one of six strains, spreads an infection, and spends DNA to evolve it. The team with more infected characters when time runs out wins. In-person playtests with pairs from our class showed that most beta testers felt comfortable with the controls and that players understood the controls and mechanics after two matches. Their only recommendation was to add movement to the map; that feature has since been added.

## Before you play

You need two players, a keyboard, and a mouse. Both players share the keyboard. You can play the Windows build or open the Godot project.

### Launch the Windows build

1. Download [PatoGen-Windows.zip](https://github.com/Code7C26/67Games/raw/refs/heads/main/PatoGen-Windows.zip) from the repository.
2. Extract the complete ZIP file to a folder.
3. Open `PatoGen-Windows/PatoGen.exe`.
4. Click the game window to give it focus, then check that both players can use their keys.

Godot is not required. Share the complete ZIP file because it includes the instructions and licenses.

### Open the project in Godot

1. Install Godot 4.7.1, the version specified by the project configuration.
2. Get the [67Games repository on GitHub](https://github.com/Code7C26/67Games) and extract it if you downloaded it as a ZIP.
3. In Godot, choose **Import** and select `pato-gen/project.godot`.
4. Wait for the project resources to import, then press **F5** to run the full project.

The project does not publish validated minimum hardware requirements. It uses Mobile/Vulkan rendering. If the game does not start, contact the team and include your operating system and the message that appears.

### Start a match

1. The 67Games intro lasts about 3.4 seconds and can be skipped. In the menu, you can choose **English / Español**. The language and tutorial state are saved in the local Windows profile.
2. Choose **New Game with Tutorial** if this is your first time. **Play** starts the normal flow; the first visit may include a skippable introduction.
3. On the strain selection screen, each side can choose with **A / D** for Player 1 (cyan) and **← / →** for Player 2 (magenta), or click a strain. There are six options: Atlético, Área, Exponencial, Garfio, Camaleón, and Rastreador.
4. Continue to map selection. Choose **Shopping**, **Laboratorio AV-07**, or **Pato Splash**, then select **Start Match**.
5. Move your duck during the **3-second opening phase** to choose where to start. When time is up, the duck disappears in an animation, infects the nearest available healthy character, and becomes a ghost.
6. During the **120-second infection phase**, manage DNA, buy mutations, and use abilities. The tutorial may temporarily pause the timer while it teaches an action.

The menu also includes **View Tutorial**, **Reduced Motion**, and **Quit**. Reduced Motion changes some intro and guide animations; it does not change match rules. During a match, press **Esc** to open the pause menu and **F1** to view the guide.

## Game screen

![A current match on the Shopping map](../map-captures/Shopping_after.png)

Shopping match screen with both mutation panels open.

| Element | What it shows |
| --- | --- |
| P1 Cyan and P2 Magenta | Identify the teams. The infected count shows how many characters belong to each team at that moment. |
| Clock and phase message | Show the match phase and remaining time. During the intro, the message may read “Find your host.” |
| DNA | Your available balance for purchases and abilities. Spending DNA does not directly reduce the infected count. |
| Mutation panel | Lets you review and buy the next evolution in each branch. Press E or O to show or hide it. |
| Symbiont indicators | Show each team's progress toward investing 60 DNA. |
| Context button | Shows the available action when you control a Garfio or Camaleón: hook or camouflage. |

Infected characters move automatically. Healthy characters run away, and infected characters look for new hosts. Your ghost lets you intervene; when you possess an infected character, the same movement keys control that character.

**The score that decides the result is the number of infected characters at the end.** A cured character no longer counts for its former team. DNA collected or infections made during the whole match do not replace that final count.

<!-- PAGE -->

## Controls for both players

| Action | Player 1 Cyan | Player 2 Magenta |
| --- | --- | --- |
| Move duck, ghost, or possessed infected character | W A S D | Arrow keys |
| Show or hide mutations | E | O |
| Buy the next evolution in a branch | 1 / 2 / 3 | 8 / 9 / 0 |
| View a branch without buying | Shift + 1 / 2 / 3 | Shift + 8 / 9 / 0 |
| Summon the healing robot | Z | H |
| Place distortion zone | C | K |
| Place hot zone | V | L |
| Possess the nearest allied infected character or use strain action | X | J |
| Invest in the Symbiont or possess its allied host | Q | U |
| Open the in-game guide | F1 | F1 |
| Open or close the pause menu | Esc | Esc |

You can also use the visible buttons in the panel to view and buy options. The shared interface is operated with the mouse. If a description is long, use the mouse wheel to read it.

When controlling a special strain, the **X / J** action changes: Garfio hooks, and Camaleón attempts to camouflage. When you are not controlling a host, the key lets you possess the nearest infected character on your team. On intro or guide screens, follow the on-screen prompt to continue or skip.

### Match phases

**Opening duck phase:** You have 3 seconds to move before the disappearance animation. Infection abilities are available in the next phase.

**Infection:** The duck becomes a ghost and the 120-second clock begins. You can move, manage mutations, and activate abilities when their phase, balance, and cooldown allow it.

**Result:** The game stops and shows a winner or a technical tie. Use the result screen buttons to restart the current map or return to the menu.

### Earning and spending DNA

A rewarded infection adds **1 DNA**. Some duplicates and reinfections do not give a reward. Purchases reduce your team's balance, and mutations improve your current infected characters as well as new ones.

If an action does not activate, check that you are in the infection phase, have enough DNA, and the action's cooldown has ended. In the tutorial, complete the on-screen prompt before trying another action.

<!-- PAGE -->

## Strains and mutations

The six strains offer different play styles. Choose one before the match and read the panel descriptions to learn what each purchase does. In-person playtests confirmed that most beta testers found the controls comfortable and understood the controls and mechanics after two matches.

| Strain | Play style | Distinctive action or advantage |
| --- | --- | --- |
| Atlético | Fast pursuit. | Pressures hosts with its speed. |
| Área | Spread and zone control. | Supports chain infections and zone use. |
| Exponencial | Growth and adaptation. | Can reproduce and improve as the match progresses. |
| Garfio | Capture and drag. | Hooks visible healthy hosts and pulls them closer; the hook can be dodged or blocked, and infection is not guaranteed. |
| Camaleón | Infiltration and ambush. | Camouflages when ready and when no healthy humans are too close; an incompatible action can reveal it. |
| Rastreador | Search and coordination. | Detects and remembers observed prey; some upgrades coordinate allied infected characters. |

| Strain | Branch | Evolutions in order |
| --- | --- | --- |
| Atlético | 1 | Fiebre → Rabia |
| Atlético | 2 | Parásito → Colonia → Mente colmena |
| Atlético | 3 | Caparazón → Regeneración → Infección inmortal |
| Área | 1 | Contagio en cadena → Último aliento → Explosión infecciosa |
| Área | 2 | Esporas → Nube tóxica → Epidemia ambiental |
| Área | 3 | Sobrecarga → Pulso viral → Tormenta infecciosa |
| Exponencial | 1 | Adaptación → Evolución rápida → Supercepa |
| Exponencial | 2 | División celular → Replicación → Brote masivo |
| Garfio | 1 | Presa vulnerable I → II → III |
| Garfio | 2 | Doble tendón I → II → III |
| Garfio | 3 | Reenganche I → II → III |
| Camaleón | 1 | Pigmentación avanzada → Mimetismo → Cromatóforos |
| Camaleón | 2 | Desvanecimiento → Retorno sigiloso → Adaptación fugaz |
| Camaleón | 3 | Ataque sorpresa → Emboscada viral → Golpe furtivo |
| Rastreador | 1 | Llamado de manada I → II → III |
| Rastreador | 2 | Cerco depredador I → II → III |
| Rastreador | 3 | Marca biológica I → II → III |

Each branch progresses in order. The first evolution costs **5 DNA**, the second costs **10 DNA**, and the third costs **15 DNA**, when available. All strains except Exponencial have three branches; Exponencial has two, so its third purchase key has no evolution to offer.

### Purchase example

If you play Atlético as Cyan, **Shift + 1** views the first branch without spending DNA. With 5 DNA available, press **1** to buy Fiebre. The next purchase in that branch costs 10 DNA and unlocks Rabia. One press does not buy every level.

For Magenta, view the first branch with **Shift + 8** and buy it with **8**. The other branches use 2 and 3 for Cyan, and 9 and 0 for Magenta.

### Choosing an upgrade

Before spending, check the time left, your balance, and both teams' infected counts. Mutations use the same DNA as abilities and the Symbiont. Saving resources can be useful, but leftover DNA does not add points to the final result.

## Abilities and events

| Action | Cost | Cooldown | Use |
| --- | --- | --- | --- |
| Possession | No DNA cost | 20 s after activation | Control the nearest infected ally for up to 10 s. If it is cured, possession ends. |
| Healing robot | 10 DNA | 25 s | Summons a robot that can cure infected characters on either team. Consider your own allies before using it. |
| Distortion | 4 DNA | 10 s | Places a zone that attracts healthy characters. |
| Hot zone | 4 DNA | 10 s | Places a zone that changes speed and infection. Its cooldown is independent of Distortion. |

### Symbiont

Both teams compete for a single Symbiont. During infection, press **Q** for Cyan or **U** for Magenta to invest **5 DNA per press**. Each contribution has a **1.5 s cooldown**. The first team to reach **60 DNA invested** wins the race; the other team can no longer invest.

The Symbiont looks for an accessible infected ally and merges on contact. The merge lasts **20 seconds**, improves movement and resistance to healing, and emits an aura that cures infected characters on the opposing team. Cured characters do not automatically join your team.

After the merge, Q or U selects the allied host so you can possess it, subject to possession conditions. X or J still selects the nearest ally as usual. Switching hosts does not reset the timers; if the host is cured, the merge ends.

### Antiviral Colossus

This neutral event can appear when very few healthy characters remain. It cures infected characters from both teams, moves across the map, and leaves according to match conditions. Walls block its pulse, and it avoids curing each team's final infection.

You cannot control it or defeat it for rewards. Watch for the appearance message and changes in the counts. Its presence does not guarantee that the whole population becomes healthy again.

### Using the new strains

- **Garfio:** The AI tries to capture automatically when it can. If you possess a Garfio, aim with movement and press **X / J** or the **Hook** button. The target can escape, a wall can block the attack, and arrival triggers only one infection attempt.
- **Camaleón:** It hides automatically when ready and away from healthy people. When you possess one, press **X / J** or **Camouflage** to try hiding again. Infecting, getting too close, or using certain abilities can reveal it.
- **Rastreador:** It works without an extra key. It remembers a prey's last observed location and, with upgrades, coordinates some allied infected characters. If it loses the trail, it searches again.

Full evolution descriptions appear in the game panel. The [repository](https://github.com/Code7C26/67Games) contains the technical rules for [Garfio and Rastreador](https://github.com/Code7C26/67Games/blob/main/pato-gen/docs/MUTACIONES_GARFIO_RASTREADOR.md) and [Camaleón](https://github.com/Code7C26/67Games/blob/main/pato-gen/docs/CAMALEON.md).

### Comeback mechanic

If your team has at least **5 fewer infected characters** than the opponent, it receives **1 DNA per second** while it remains behind by that amount. Healing adjustments also help limit large differences. These are automatic aids; they do not guarantee a tie or a win.

## First match and help

Start with the tutorial to learn the game. Identify your color, open the panel, view a branch before buying it, and try a possession. Then play another match to compare a different strain or map. You can use any of the three maps from the selector.

### Winning and playing again

When the clock ends, the current infected counts are compared. The higher count wins; equal counts produce a **technical tie**. **Restart** reloads the current map. To change strains or map, return to the menu and start another match.

### Frequently asked questions

| Situation | What to check |
| --- | --- |
| The keyboard does not respond | Click the game window and check your player's keys. Complete or skip the guide if it is active. |
| The duck disappeared | It has changed to ghost mode. If you are possessing an infected character, the ghost stays hidden until possession ends. |
| I cannot see mutations | Press E for Cyan or O for Magenta to show the panel. |
| A purchase or ability does not work | Check the phase, balance, cooldown, and whether the branch is complete. Exponencial has no third branch. |
| X or J does not possess anyone | You need to be in ghost mode, have an infected ally, and have possession ready. If the ally is cured, you lose control. |
| Q or U no longer adds investment | You may lack DNA, be on cooldown, or the race may be over. After the merge, the key selects the allied host. |
| X or J does not hook or camouflage | The special action appears only when possessing Garfio or Camaleón. Check the context button, match phase, and host state. |
| My infected count went down | Natural healing, robots, and the Colossus can reduce it. The opposing Symbiont aura also cures your infected characters. |
| The clock is not moving | The tutorial may hold it while waiting for an action. On the result screen, the match is over. |

### Share feedback

Use the [Patogen survey](https://docs.google.com/forms/d/e/1FAIpQLSdcVXtVcuFnc-ONDs5G1jO4dhMEx9lVbaN2AGFfKulQGXbKgg/viewform?usp=sharing&ouid=109783700324919521831) or the [repository issues](https://github.com/Code7C26/67Games/issues). Include the map, strains, team, attempted action, and what happened. A screenshot can help explain readability or control issues. This guide covers local mode, all six strains, and all three maps; for project updates, see the [documentation index](README.md) and the [game README](../README.md).
