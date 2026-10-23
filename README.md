# Matthew's Sandbox (Godot edition)

A pixel-art ragdoll physics sandbox, built in Godot 4.3 (GDScript). All art and sounds are generated in code, so the project has no image or audio files apart from the app icon.

## What's in this version
- Pixel ragdoll characters (10 body parts each) that walk-wobble, tumble, get knocked out and get back up.
- Random character machine in the Lab, plus a Random slot in People. Tap **Keep** to save a random friend.
- Character maker: skin, 8 hair styles, hair colour, 7 tops, colours, sleeves, bottoms, shoes, size and name.
- Things: crate, ball, balloon, TNT, duck, brick, plank, steel box, bowling ball, trampoline.
- Tools: Drag, Poke, Boom, Heal, Delete, Magnet, Wind, Grow, Shrink, Copy.
- Stages: Lab, Park, Beach, Candy Land (bouncy floor) and Space (low gravity).

## Files
- `project.godot`, `main.tscn` - the project and its one scene
- `scripts/pix.gd` - pixel art for characters, items, icons, backgrounds and the machine
- `scripts/rag.gd` - the pixel ragdoll
- `scripts/sfx.gd` - sound synthesizer
- `scripts/main.gd` - world, tools, items, stages, menus
- `export_presets.cfg`, `signing/debug.keystore`, `.github/workflows/build-apk.yml` - the APK build

## Get the APK
Every push to `main` builds the APK. Download it from **Releases > apk-latest** (or from the Actions run's Artifacts).
