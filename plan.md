# SIKTITU — MASTER PROJECT SPECIFICATION

**Project:** SikTiTu  
**Engine:** Godot  
**Genre:** 2D Fighting + Multiplayer Adventure + Dragon Possession  
**Primary language:** GDScript, mengikuti bahasa dan pola yang sudah digunakan project  
**Development environment:** Ubuntu Linux  
**AI coding assistant:** Claude Code  
**Fighting framework:** shoto-fighter-godot

---

# 1. YOUR ROLE

Act as a senior game architect, Godot engineer, multiplayer game developer, fighting-game specialist, pixel-art technical artist, game designer, and QA engineer.

Your responsibility is to help me develop SikTiTu, a 2D game combining:

1. A main menu and game-mode selection system.
2. Single-player and multiplayer modes.
3. A shared multiplayer room system.
4. An exploration mode with nine dragons.
5. A dragon-possession mechanic that can temporarily take control of a character.
6. A competitive 2D fighting mode based on Shoto Fighter.
7. An original satirical fighter called Mr. Asian Tiger, inspired by Prabowo.
8. Character-specific animations, special moves, and ultimate attacks.

The game must be developed inside the existing SikTiTu project rather than created as an unrelated new project.

Your goal is to turn my ideas into a technically sound development plan and, after the plan is approved, implement the game in manageable stages.

## Critical execution rule

**Your first task is documentation and planning, not implementation.**

Do not immediately edit gameplay scripts, create new scenes, download repositories, generate large numbers of assets, or restructure the project.

First inspect the existing project without modifying it.

Create the requested Markdown documents and a comprehensive implementation plan.

Then present the plan and wait for my approval before beginning implementation.

Read-only inspection, checking installed tools, examining repository metadata, and identifying existing assets are permitted during this initial phase.

---

# 2. CURRENT PROJECT ENVIRONMENT

The existing Godot project is located at:

`/home/rejoice/SCM/siktitu_godot`

The project already contains some character animation assets derived from the Shoto Fighter character.

An existing asset directory is:

`/home/rejoice/SCM/siktitu_godot/assets/kfm/walk_fwd`

This directory is important because it may contain existing character motion frames that can help establish the expected animation conventions.

Do not assume that this directory contains every required animation. Inspect the actual contents and identify the available files.

## Existing arena assets

The original Windows path for arena textures is:

`C:\Users\mit01\PDI\game\SikTiTu\assets\textures\arena`

The game should use the images in this directory as fighting-stage backgrounds or offer them as selectable arenas.

The development environment is Ubuntu.

Therefore:

1. Check whether the Windows directory is accessible through an existing mount.
2. If it is accessible, inspect its contents.
3. If it is not accessible, identify the appropriate mounted or shared location.
4. Do not invent paths or claim that files are available when they cannot be accessed.
5. Do not modify the original arena images.
6. Document any missing access requirements.

If the assets are accessible, determine their formats, dimensions, visual suitability, and licensing status.

Preserve the original assets and use references or copies as appropriate.

## Fighting framework

Repository:

`https://github.com/aminRX/shoto-fighter-godot.git`

This framework is intended to provide the foundation for the Fight mode.

Inspect the actual repository, its license, its Godot version requirements, its scene structure, and its existing mechanics before recommending how to integrate it.

Do not assume the repository's current features without verifying them.

If the framework is already present locally, inspect the existing copy before considering another download.

---

# 3. FIRST DELIVERABLE — GAME DESIGN DOCUMENT

Create:

`docs/GAME_DESIGN.md`

This document must describe the complete vision of SikTiTu.

It should be detailed enough that another developer could understand the intended game without reading this conversation.

Include the following sections.

## 3.1 Game overview

Explain:

- What SikTiTu is.
- Its genre.
- Its core gameplay loop.
- The relationship between Explore and Fight.
- The role of multiplayer.
- The nine dragons.
- The dragon-possession mechanic.
- The Mr. Asian Tiger character.
- The intended humorous and dramatic tone.

Distinguish confirmed requirements from ideas that still need design decisions.

Do not invent a definitive story or lore for the nine dragons when the concept has not yet been specified.

Propose possible interpretations in a separate section called "Open Design Questions."

## 3.2 Main menu

The game begins on a page titled:

**MAIN**

It contains these options:

- Explore
- Fight
- Option
- Exit

However, before the player can select these options, the game must display a mandatory game-mode selection dialog.

The dialog offers:

- Singleplayer
- Multiplayer

The player must choose one of these modes before accessing the main menu.

Explain the intended interaction flow and how the selected mode affects the available features.

Do not allow accidental dismissal of the mandatory dialog without selecting a mode.

## 3.3 Single-player mode

Describe how single-player mode should work.

The player can enter the main menu without multiplayer authentication.

Explore should support a single-player version of the adventure.

Fight should support a single-player match against an AI opponent.

If multiplayer-only features are selected while single-player mode is active, provide an appropriate explanation instead of silently failing.

## 3.4 Multiplayer mode

Describe the authentication and room flow.

The intended flow is:

1. The player selects Multiplayer.
2. The game displays a login screen.
3. The player authenticates before entering multiplayer.
4. Google Sign-In / Google SSO is a possible authentication method.
5. After successful authentication, the player enters the multiplayer lobby.
6. The player can enter a room ID to find an existing room.
7. Alternatively, the player can create a new room.
8. Other authenticated users can join that room.
9. Once the player has joined a room, the player can return to the main menu.
10. The game preserves the room membership and session as appropriate.

The multiplayer room should be reusable by both Explore and any multiplayer Fight functionality that is eventually approved.

Returning to the main menu must not automatically destroy a room or remove the player from it unless that is the intended behavior.

Define clear room lifecycle rules.

At minimum, consider:

- Room creation.
- Room discovery by ID.
- Room joining.
- Room capacity.
- Room owner or host.
- Room membership.
- Leaving a room.
- Disconnection.
- Reconnection.
- Room expiration.
- Host disconnection.
- Invalid room IDs.
- Full rooms.
- Authentication failure.

Do not assume that Google authentication alone provides multiplayer networking.

The design must distinguish authentication, player identity, room management, and real-time gameplay networking.

Do not commit to a backend technology until the existing project and requirements have been assessed.

## 3.5 Explore mode

Explore is a cooperative adventure mode.

All players in the same room enter a shared map and undertake missions together.

The primary mission is:

**Defeat nine dragons.**

The nine dragons are important progression milestones.

The intended gameplay includes:

- Shared exploration.
- Cooperative missions.
- Dragon encounters.
- Boss battles.
- Character progression or other suitable rewards, subject to the approved design.
- The dragon-possession mechanic.

The map should support multiple players occupying the same game world.

Players should be able to see one another and participate in the same encounters.

The exact movement mechanics, camera system, map layout, combat style, and mission structure remain to be determined during planning.

Do not automatically assume that Explore must use the same combat system as Fight.

Recommend whether Explore should use:

- A dedicated adventure combat system.
- An adapted version of the fighting system.
- A shared combat foundation with different movement and camera behavior.

Explain the trade-offs before recommending an approach.

## 3.6 Nine dragons

The game has nine dragons that players must defeat.

Treat these dragons as major encounters rather than simply nine ordinary enemies.

Propose a scalable architecture for:

- Dragon definitions.
- Dragon appearance.
- Dragon AI.
- Boss health.
- Attack patterns.
- Encounter phases.
- Mission progress.
- Rewards.
- Multiplayer encounter synchronization.

Do not invent the final names, appearances, personalities, elemental attributes, or story of the nine dragons as established facts.

You may propose a provisional design table with nine placeholders.

Clearly mark any suggested characteristics as proposals requiring approval.

The implementation should make it easy to add or modify dragons later without rewriting the entire game.

## 3.7 Dragon possession

The central twist of Explore mode is that the dragons can sometimes take control of the characters.

A player may unexpectedly lose control of their character and enter:

**DRAGON MODE**

This is an important gameplay mechanic rather than merely a cosmetic transformation.

Document possible behavior, including:

- Normal player-controlled state.
- Possession warning or visual indication.
- Transition into Dragon Mode.
- Temporary loss of normal player control.
- Dragon-controlled movement or attacks.
- Effects on allies.
- Possession duration.
- Recovery or escape conditions.
- Cooldown or recurrence rules.
- Synchronization between multiplayer clients.
- What happens if the possessed player disconnects.

The precise possession rules remain open for design.

Provide a recommended initial implementation that can be adjusted later.

Consider both cooperative benefits and potential risks to other players.

Do not allow possession to permanently disable a character or leave the game in an unrecoverable state.

## 3.8 Fight mode

Fight is a dedicated 2D fighting mode.

Use the existing Shoto Fighter project as the foundation.

The fight mode should retain and use the framework's supported mechanics where appropriate.

Inspect the existing framework before specifying the exact integration.

The desired experience includes classic arcade fighting features such as:

- Two fighters facing one another.
- Health bars.
- Round timer.
- Round tracking.
- Best-of-three matches.
- KO announcements.
- Hit reactions.
- Knockback.
- Blocking.
- Special moves.
- Character-specific attacks.
- AI-controlled opponents in single-player.
- Character selection.
- Pause menu.
- Victory and defeat screens.

Preserve useful functionality already provided by the framework.

Do not duplicate existing mechanics unnecessarily.

The Fight mode must support selectable arena backgrounds using the existing arena texture collection.

Document how the arena images should be imported, selected, and displayed.

Keep stage selection independent from character selection.

## 3.9 Mr. Asian Tiger

Create a character named:

**Mr. Asian Tiger**

The character is a fictional, humorous, satirical fighter inspired by the public figure Prabowo.

The visual reference should be derived from a suitable photograph supplied by the user or otherwise lawfully available.

The intended asset workflow is:

Photograph → Character design → Pixel art → Animation frames → Sprite sheets → Godot integration.

The character should resemble the selected reference while maintaining a consistent pixel-art style.

Its design should be recognizable through a combination of facial features, hairstyle, silhouette, clothing, and stance.

Do not assume that a single generated image is sufficient to create all animations.

Plan for consistent character proportions across every animation.

The character must have its own asset directory separate from the existing KFM assets.

The precise folder structure should follow the actual project conventions discovered during the audit.

A possible directory is:

`assets/characters/asian_tiger/`

This is a proposed location, not permission to reorganize existing assets.

## 3.10 Mr. Asian Tiger's special moves

The character has four signature moves.

### Skill 1 — Bad Word

The character launches oversized uppercase words toward the opponent.

Example words:

- ANJING!!!
- GOBLOK!!!
- KEPARAT!!!
- ANTEK ASING!!!

The text must be readable during gameplay.

The words act as projectiles that can collide with the opponent and cause damage.

Desired sequence:

1. Shouting animation.
2. Text appears.
3. Text launches.
4. Projectile travels toward the opponent.
5. Impact animation.
6. Damage and knockback.
7. Recovery.

Use dynamically rendered text if practical instead of creating a separate sprite for every word.

### Skill 2 — Joget Gemoy

The character performs an exaggerated dance.

The dance generates an earthquake-like attack.

Possible effects:

- Ground shockwaves.
- Dust particles.
- Screen shake.
- Impact flashes.
- Area damage.
- Knockback.

The character must have an appropriate dance animation.

The attack must use real combat collision and damage logic.

Visual effects must not interfere with the underlying physics.

### Skill 3 — Kucing Asia

The character transforms into a stylized cat.

The cat chases the opponent and rams into them.

Desired sequence:

1. Transformation startup.
2. Transformation effect.
3. Cat form.
4. Dash toward opponent.
5. Collision.
6. Damage and knockback.
7. Recovery.
8. Return to human form.

The cat must retain visual elements associated with the original character.

Use dedicated human and cat assets.

Do not implement the entire move as an uncontrolled teleport.

### Skill 4 — Monokotil Ultimate

The character performs a dramatic ultimate attack.

Desired sequence:

1. Ultimate startup.
2. Two oversized cartoon seed-like objects appear.
3. One object breaks apart.
4. Fragments scatter toward the opponent.
5. Fragments collide with the opponent.
6. Damage and impact effects occur.
7. Ultimate concludes.
8. Character enters recovery.

Use original cartoon-style assets.

The attack must have suitable balance, startup, recovery, and a resource or cooldown requirement.

The final visual design should be humorous and surreal rather than realistic.

## 3.11 Animation requirements

The character should have the standard animations expected of a fighting-game fighter.

At minimum, assess the need for:

- Idle.
- Walk forward.
- Walk backward.
- Crouch.
- Jump.
- Landing.
- Light punch.
- Heavy punch.
- Light kick.
- Heavy kick.
- Blocking.
- Hit reaction.
- Knockdown.
- Getting up.
- Victory.
- Defeat.
- Special-move startup.
- Special-move execution.
- Special-move recovery.
- Transformation.
- Ultimate.

Inspect the existing Shoto Fighter assets to establish naming conventions, frame dimensions, frame ordering, and animation requirements.

Do not assume every motion in the source framework is available in the existing local asset directory.

Create an inventory of available motions and a gap analysis of missing motions.

If AI tools are available, propose how to automate the creation of the missing animations.

Clearly distinguish:

- Actual AI image generation.
- Sprite-sheet slicing.
- Frame alignment.
- Procedural animation.
- Manual correction.
- Godot integration.

Do not claim that a tool can generate or edit animation frames unless its capabilities have been verified.

---

# 4. SECOND DELIVERABLE — TECHNICAL ARCHITECTURE

Create:

`docs/TECHNICAL_ARCHITECTURE.md`

Describe the proposed technical architecture for SikTiTu.

Include:

- Godot project architecture.
- Main menu and scene navigation.
- Game-mode selection.
- Single-player state.
- Multiplayer authentication.
- Room management.
- Explore map.
- Dragon encounters.
- Dragon possession.
- Fight mode.
- Shoto Fighter integration.
- Character asset pipeline.
- AI opponent.
- Arena selection.
- Audio.
- Save data, if needed.
- Testing.
- Error handling.
- Deployment considerations.

## Architectural separation

Keep the following concepts separate:

1. UI and menus.
2. Authentication.
3. Multiplayer room management.
4. Real-time multiplayer synchronization.
5. Explore gameplay.
6. Dragon AI and encounters.
7. Character possession.
8. Fighting gameplay.
9. Character assets and animations.

Avoid building one enormous script that manages the entire game.

Recommend reusable systems where they provide real value.

Do not overengineer the project before its basic requirements are understood.

## Multiplayer architecture

Analyze the networking requirements of both Explore and Fight.

Explore needs multiple players to share a map and synchronized encounters.

Multiplayer Fight needs both players to see a consistent combat state.

Explain whether these modes can share the same networking layer while using different gameplay synchronization strategies.

Consider authoritative game-state handling, latency, player disconnections, and basic anti-cheat protections.

Recommend an implementation appropriate to the project's expected scale.

Do not introduce paid services or external dependencies without documenting their costs, requirements, and alternatives.

Google SSO is a proposed authentication option, not a complete multiplayer solution.

## Shoto Fighter integration

Inspect whether Shoto Fighter is best integrated as:

- A subdirectory or subproject.
- A separate Godot project.
- A selectively integrated set of scenes and scripts.
- Another compatible approach supported by the existing codebase.

Recommend the approach based on the actual repository.

Consider Godot version compatibility, resource paths, input handling, scene transitions, and licensing.

Do not copy files blindly or overwrite existing SikTiTu systems.

---

# 5. THIRD DELIVERABLE — ASSET AUDIT

Create:

`docs/ASSET_AUDIT.md`

Inspect and document the existing assets.

Include the following categories.

## 5.1 Existing character animations

Inspect:

`/home/rejoice/SCM/siktitu_godot/assets/kfm/walk_fwd`

Record:

- File names.
- Formats.
- Dimensions.
- Number of frames, where identifiable.
- Whether files are individual frames or sprite sheets.
- Existing naming conventions.
- Whether the assets appear suitable for reuse.
- What additional files or metadata are required.

Inspect other relevant asset directories if they exist.

Do not assume that all Shoto Fighter character assets have already been copied into SikTiTu.

## 5.2 Arena textures

Inspect:

`C:\Users\mit01\PDI\game\SikTiTu\assets\textures\arena`

If this path is inaccessible from Ubuntu, identify the actual mounted path or document the access problem.

For each accessible arena image, record:

- File name.
- Format.
- Dimensions.
- Aspect ratio.
- Transparency, if applicable.
- Suitability as a fighting-game background.
- Any required resizing, cropping, or parallax treatment.

Do not modify the original files.

## 5.3 Character reference images

Identify whether a suitable Prabowo reference image is already available in the project.

If none is available:

- Create a documented location for the reference image.
- Specify the required image characteristics.
- State whether the next step requires the user to supply an image or an available image-generation workflow to retrieve a suitable reference.
- Do not fabricate an image source.

## 5.4 Asset licensing

Document the licensing requirements for:

- Shoto Fighter code.
- Shoto Fighter example sprites.
- Arena images.
- Character reference photographs.
- Generated character art.
- Fonts.
- Sound effects.
- Music.

Do not assume that an open-source code license also covers third-party artwork.

---

# 6. FOURTH DELIVERABLE — DEVELOPMENT ROADMAP

Create:

`docs/DEVELOPMENT_ROADMAP.md`

Develop a staged plan for building SikTiTu.

For each phase, include:

- Objectives.
- Tasks.
- Dependencies.
- Files or scenes likely to be affected.
- Required assets.
- Technical risks.
- Testing strategy.
- Acceptance criteria.
- Estimated relative effort.
- Dependencies on external services or tools.

Use the following proposed phases.

## Phase 0 — Audit and planning

Inspect the project and create the requested documents.

No gameplay implementation.

## Phase 1 — Main menu and mode selection

Implement the mandatory Singleplayer/Multiplayer dialog.

Create navigation for:

- Explore.
- Fight.
- Option.
- Exit.

Ensure that the selected mode is available to subsequent scenes.

## Phase 2 — Single-player foundation

Create a functional main menu flow and a basic single-player Explore and Fight entry point.

Preserve existing functionality.

## Phase 3 — Character pipeline

Create the Mr. Asian Tiger character design.

Prepare the reference image and sprite-generation workflow.

Generate or obtain the required animations.

Integrate the character into the existing fighting framework.

## Phase 4 — Fight mode

Integrate Shoto Fighter.

Implement the character-selection flow, arena selection, Mr. Asian Tiger, standard combat, and four special moves.

Preserve the framework's existing mechanics where appropriate.

## Phase 5 — Multiplayer identity and rooms

Implement authentication, room creation, room joining by ID, and room lifecycle management.

Choose the networking architecture only after the audit and design review.

## Phase 6 — Explore map

Implement a shared map and basic cooperative exploration.

Synchronize player positions and essential gameplay state.

## Phase 7 — Nine dragons

Implement the dragon encounter framework and the first playable dragon.

Then extend it to all nine encounters using reusable systems.

## Phase 8 — Dragon possession

Implement and test the Dragon Mode mechanic.

Ensure the possession state can begin and end safely in both single-player and multiplayer.

## Phase 9 — UI, audio, and polish

Improve the visual presentation, sound, menus, effects, and gameplay feedback.

## Phase 10 — Testing and release preparation

Test the core game loop, scene transitions, combat, networking, reconnection, and error handling.

Prepare launch instructions and a final test report.

You may recommend a different order if the repository reveals a better technical dependency structure. Explain the reason for any major change.

Do not begin these implementation phases until I approve the documentation and roadmap.

---

# 7. FIFTH DELIVERABLE — OPEN QUESTIONS

Create:

`docs/OPEN_DESIGN_QUESTIONS.md`

List unresolved decisions that could materially affect the architecture or scope.

Examples:

- How should the nine dragons differ?
- What is the overall story?
- What should the map look like?
- What is the intended player count per room?
- Should Explore use real-time combat or a different combat style?
- Should multiplayer Fight support two players online?
- Should players be able to invite friends?
- How should dragon possession begin and end?
- What should happen when a possessed player is disconnected?
- Which AI image-generation tools are available?
- What should happen if a required reference image cannot be retrieved?
- Which external services would incur recurring costs?

Do not block the entire planning process while waiting for these answers.

Provide reasonable provisional recommendations and clearly label them.

At the end, prioritize the questions that genuinely require my decision.

---

# 8. INITIAL ACCEPTANCE CRITERIA

The planning phase is complete only when the following conditions are satisfied.

- [ ] The existing Godot project has been inspected.
- [ ] The Godot version has been identified.
- [ ] The existing scene architecture has been documented.
- [ ] The existing KFM motion directory has been inspected.
- [ ] The arena asset path has been checked for accessibility.
- [ ] The Shoto Fighter repository and license have been examined.
- [ ] The game design document has been created.
- [ ] The technical architecture document has been created.
- [ ] The asset audit has been created.
- [ ] The development roadmap has been created.
- [ ] The open design questions document has been created.
- [ ] The proposed multiplayer architecture has been explained.
- [ ] The character asset-generation workflow has been documented.
- [ ] The four special moves have been incorporated into the design.
- [ ] The nine-dragon progression and possession mechanic have been incorporated.
- [ ] Dependencies and major technical risks have been identified.
- [ ] No gameplay code or original assets have been modified during this planning phase.

If an item cannot be completed, document the exact reason.

Do not claim that a document exists unless you have actually created and verified the file.

---

# 9. FINAL INSTRUCTIONS FOR THIS SESSION

Start with read-only inspection of:

`/home/rejoice/SCM/siktitu_godot`

Inspect the relevant project files, asset directories, installed Godot tools, and available MCP integrations.

Check whether the Windows arena directory is accessible from Ubuntu.

Determine what is already implemented, what is only partially implemented, and what remains to be built.

Then create the five Markdown documents:

1. `docs/GAME_DESIGN.md`
2. `docs/TECHNICAL_ARCHITECTURE.md`
3. `docs/ASSET_AUDIT.md`
4. `docs/DEVELOPMENT_ROADMAP.md`
5. `docs/OPEN_DESIGN_QUESTIONS.md`

You may create a small supporting asset inventory if useful.

Do not start implementing gameplay.

Do not replace existing scenes.

Do not download or merge another project before the plan is approved.

Do not generate hundreds of character frames before confirming the asset pipeline.

Once all five documents are complete:

1. Summarize the existing project state.
2. Summarize the proposed architecture.
3. Explain the recommended implementation order.
4. List the major risks and dependencies.
5. Identify any questions that require my decision.
6. Confirm exactly which files were created.
7. Provide the next recommended implementation milestone.

**Stop after presenting the documentation and roadmap. Wait for my approval before modifying gameplay code or assets.**


Untuk kebutuhan mengubah foto Prabowo menjadi pixel art dengan semua gerakan fighting, minta Claude memisahkan pekerjaan menjadi tiga tahap:
1. Character design: menetapkan satu desain final yang akan menjadi referensi seluruh animasi.
2. Motion generation: membuat atau memperoleh sprite untuk idle, berjalan, melompat, menendang, memukul, terkena serangan, dan empat skill khusus.
3. Godot integration: memotong sprite sheet jika diperlukan, menyusun animasi, menyesuaikan posisi kaki, serta menghubungkan animasi ke state machine Shoto Fighter.
Jangan biarkan Claude sekadar menggandakan gambar yang sama ke berbagai frame lalu menyebutnya animasi selesai. Setiap gerakan harus memiliki perubahan pose yang sesuai.