# DELTARUNE Chapter 8: THE RALSEIVERSE

A fan-made DELTARUNE chapter, built as a real [KRISTAL](https://kristal.cc) mod —
Lua, `mod.json`, generated map data, original music. Not a web mockup, and not
something you import into DELTARUNE itself (DELTARUNE is a compiled GameMaker
build with no mod format; KRISTAL is the engine fangames are made in).

**It is a cute chapter.** There are no encounters, no enemies, no waves, no
bullets. Nothing in it can hurt you. The whole thing is about walking into rooms
and meeting people.

Fan work. Not official DELTARUNE. Not affiliated with Toby Fox or the KRISTAL
team. Uses KRISTAL's own bundled character sprites.

---

## Installing

1. Get KRISTAL. Source (`love .`) is what this was built and tested against:
   <https://kristal.cc/wiki/downloading>
2. Copy `ralseiverse.zip` into KRISTAL's mods folder, **still zipped**:

   | Platform | Path |
   | --- | --- |
   | Linux | `~/.local/share/love/kristal/mods/` |
   | macOS | `~/Library/Application Support/LOVE/Kristal/mods/` |
   | Windows (source) | `%APPDATA%\LOVE\Kristal\mods\` |
   | Windows (nightly) | `%APPDATA%\Kristal\mods\` |

   The archive must keep the **`.zip`** extension. Kristal only mounts archives
   ending in `.zip` (`src/engine/loadthread.lua:76`), so a `.love` is never
   mounted: if it appears in the mod list at all, it loads with no maps and dies
   with *"Attempt to create non existent map \"confluence\""*. Renaming the file
   to `.zip` is the whole fix.

   You can also copy the project folder itself instead of the archive, but it
   must not end up nested (`mods/ralseiverse/ralseiverse/…` will not load).
3. Start KRISTAL and pick **THE RALSEIVERSE** from the mod list.

Requires KRISTAL `v0.11.0-dev` or later.

---

## What is in it

The Confluence is a small glass hub with a cracked fountain in the middle. Doors
grow out of the crack, and every one of them has Ralsei's face on it.

Seven rooms, seven Ralseis, and one thing each of them wants to show you:

| Room | Ralsei | Title | The thing he shows you |
| --- | --- | --- | --- |
| `room_prime` | Ralsei | THE RALSEI | tea, four cups, one of them tiny |
| `room_knight` | Sir Ralsei | THE KNIGHT | a duel, which he wins by accident |
| `room_neon` | R4L531 | THE GLITCH | an arcade cabinet with one high score |
| `room_tide` | Coral Ralsei | THE TIDE | a crab race that always ties |
| `room_bloom` | Bloom Ralsei | THE GARDEN | naming a flower |
| `room_ash` | Ralsei | THE ASHEN | lighting a lantern for someone |
| `room_static` | Sketch | THE UNMADE | being drawn |

Befriend four of the seven and the door in the floor opens. At the bottom is the
Quiet Room, and the Ralsei who never got to be anybody. Welcoming Null opens a new way onward: **The Afterword**, a post-Null chapter
with three gentle, combat-free adventures in the Draft, the Echo, and the Wish.
Once that page is written, a second gate opens into **the Field**: a branching,
flower-filled overworld inspired by the lush, winding feel of the Field of Hopes
and Dreams. Five trail adventures take you through a hedge maze, a creek and
stepping-stone bridge, a bell hill, a firefly meadow, and a moonflower grove.
Meet six new Ralseis, gather fifteen small field memories, then join everyone
for a picnic in the hilltop clearing. The path stays open after the ending.

There is also **The Ralsei Café**, at the top, run by two of them who could not
decide which one of them was the barista. It is a real KRISTAL shop:
CafeBlend (D$40), WarmBread (D$60), ScarfPatch (D$90), plus the engine's own
Dark Burger and Dark Candy. You start with D$200.

Everything is optional. The Afterword and Field remember their own quest
progress separately from the original seven Ralsei activities. Explore at your
own pace; no battles, timers, or missable choices are involved.

---

## Layout

```
mod.json                    chapter, party, starting inventory, config
mod.lua                     globals, the ralsei_npc map event, dev-mode hook

scripts/
  globals/multiverse.lua    the variant table -- every Ralsei, in one place
  objects/tint.lua          the recolour shader
  objects/selftest.lua      the automated play-through (dev mode only)
  data/actors/              ralsei_variant: the engine's Ralsei, recoloured
  data/items/               cafeblend, warmbread, scarfpatch, plushie
  shops/cafe.lua            the café
  world/cutscenes/          confluence, variants, activities, cafe, quietroom, afterword, field
  world/maps/               25 rooms (generated)
  world/tilesets/           original Card Castle sheet plus appended field biome tiles

assets/
  sprites/tilesets/         ralseiverse.png (generated)
  sprites/field/            transparent crops from the user-supplied Field art sheet
  music/                    generated loops; quiet piano MIDI/render; Creative Spaces MIDI, custom SF2, and bitcrushed render

The Creative Spaces source is the user's supplied MP3. The Art Studio uses the
direct-from-MP3 version, pitched up two semitones and bitcrushed. An approximate
MIDI transcription and original four-patch SF2 are also included as an alternate
experiment; they are not the main game's current music.

tools/
  make_tileset.py           legacy base-sheet drawing tool
  make_field_tiles.py       adds animated grass, 24 Field tiles, and black exterior
  make_maps.py              writes every map
  make_music.py             synthesises the procedural chiptune loops
  render_quiet_soundfont.py renders the quiet MIDI with SGM SF2 and room reverb
  make_creative_spaces_remix.py transcribes the MP3, builds a custom SF2, renders, then bitcrushes
  make_creative_spaces_bitcrush.py pitch-shifts the original recording and applies the final bitcrush
  validate.py               static checks; non-zero exit on problems
  sync.sh                   copies the project into the engine's mods folder
```

The variants do not ship copied sprites. `data/actors/ralsei_variant.lua`
constructs the engine's real `ralsei` actor, takes his sprite path, animations,
portrait and voice wholesale, and recolours the result at draw time.

---

## Developing

```sh
python3 tools/make_field_tiles.py # append the Field biome (preserves original 60 tiles)
python3 tools/make_maps.py        # rewrite every map
python3 tools/make_music.py       # rebuild the procedural loops (needs ffmpeg)
python3 tools/render_quiet_soundfont.py /path/to/SGM-V2.01.sf2
                                  # rebuild quiet piano (FluidSynth + ffmpeg)
python3 tools/validate.py         # static checks
sh    tools/package.sh            # build ralseiverse.zip
sh    tools/sync.sh               # copy into ~/.local/share/love/kristal/mods
cd <kristal> && love . --console --mod ralseiverse --auto-mod-start
```

`tools/validate.py` checks that every map loads as Lua, that every door and
interactable names a cutscene that exists, that every tile GID is inside the
tileset, that every named actor/item/music track exists, and that `mod.json` is
not left in dev mode. It exits non-zero if it finds anything.

### The self-test

Set `"dev": true` in `mod.json` and the project plays itself on boot:
`scripts/objects/selftest.lua` walks the intro, visits the original rooms, plays
the Afterword, explores all five Field trails, gathers each trail's three
memories, and reaches both endings. It triggers every relevant NPC and quest
interaction, prints PASS/FAIL per step, and exits with the matching status code.

```
$ love . --console --mod ralseiverse --auto-mod-start --disable-stdout-buffer
[Ralseiverse] [INFO] self-test: 54/54 steps passed
```

It works around three engine details, all recorded at the top of that file:
the console overlay swallows all dialogue input headless; `DialogueText` only
polls input from inside its own update, so textboxes are advanced through
`DialogueText:advance()`; and every Event carries an `interact_buffer` that makes
`Player:interact()` silently no-op, so events are triggered through their own
`onInteract`.

Leave `dev` false when you ship. `tools/validate.py` fails if you do not.

Ship with `sh tools/package.sh`, which runs the checks and builds
`ralseiverse.zip`. Do not rename it to `.love`.

---

## The web port

There is a browser build of this chapter next door, in `../website/`: same
rooms, same writing, same flow, in HTML/CSS/JS instead of Lua. `../ralseiverse-web.html`
is a single self-contained file you can just open. It exists because dropping a
`.zip` into a mods folder has several ways to go wrong; the web port has none.

## Known limits

* The secret room (`room_secret`) is real: `World:loadMap` is hooked in
  `Mod:postInit`, and every doorway that leaves the Confluence rolls for it at
  1-in-8, guaranteed by the sixth crossing -- the same trick the real game uses
  for the tree room at 1-in-50. The roll is skipped under `dev = true` so the
  self-test play-through can't be diverted by chance.
* There are six original loops: four procedural chiptune tracks, the quiet-room
  score rendered with SGM v2.01's Acoustic Grand Piano preset and bitcrushed to
  7-bit / 5x sample reduction, and the secret-room solo piano
  (`tools/make_piano.py`). The Art Studio loop is a bright original motif,
  transposed up two semitones and lightly bitcrushed. The SGM preset is by Shan, shared under
  CC BY 4.0; see https://www.polyphone.io/en/soundfonts/instrument-sets/256-sgm-v2-01.
  The game ships the rendered audio and MIDI, not the full SoundFont.
  The tileset is not — it is the engine's own hand-drawn Card Castle art from
  `mod_template/`, 60 tiles in the real dark-world palette. `tools/make_maps.py`
  authors rooms in semantic tile names and maps them onto that art.
* The character sprites are KRISTAL's bundled Ralsei, Kris and Susie. Only the
  recolour is original.
* Tested on KRISTAL `0.11.0-dev` at `v0.10.0`'s asset tree. Registry hooks into
  engine `data/` scripts do not work from a project (hooks load before `data/`),
  so all visual effects use stock engine features.
