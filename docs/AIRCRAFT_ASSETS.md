# Aircraft Asset Manifest

This document records the source-aircraft archive supplied for Tally and prevents
generic download names from being mistaken for aircraft identities.

## Attribution

All aircraft assets in the supplied archive are credited to
[2001kraft on CGTrader](https://www.cgtrader.com/designers/2001kraft), except the
Airbus A220-300. The A220 attribution must remain separate once its original
listing/author is recorded.

The source archive was supplied by the project owner from free-download
listings. The recovered CGTrader listings currently describe the commercial
aircraft as Editorial License (no AI); “free download” must not be treated as a
generic open-source license. Keep the listing-specific attribution in the
repository and surface it in the app's Credits screen. Do not treat an aircraft
manufacturer's or airline's marks as part of the mesh license; Tally liveries
should be independently authored.

## Recovered identities

| Aircraft | FBX source | Matching OBJ | Evidence |
| --- | --- | --- | --- |
| Airbus A220-300 | `source/AIRBUS A220-300.fbx` | — | Filename, node names, and material names |
| Boeing 737-800 / 737-839B | `3d-model-3.fbx` | `3d-model-4.obj` | Geometry and archive date match the creator's [Central Airlines Boeing 737-839B Interior](https://www.cgtrader.com/free-3d-models/aircraft/commercial-aircraft/central-airlines-boeing-737-839b-interior--2) listing |
| Boeing 757-200 | `3d-model-2.fbx` | `3d-model-3.obj` | Long narrow-body geometry and archive date match the creator's [Template Boeing 757-200](https://www.cgtrader.com/free-3d-models/aircraft/commercial-aircraft/template-boeing-757-200) listing |
| Airbus A320-200 | `3d-model-8.fbx` | `3d-model-9.obj` | Embedded `Thai Airways International Airbus A320-200 Aircraft` node names |
| Cessna 152 | `3d-model-4.fbx` | `3d-model-5.obj` | Embedded `Cessna 152` node names |
| Airbus A380 | `3d-model-10.fbx` | `3d-model-11.obj` | Embedded `Profile-A380-AirFrance...` material and texture reference |
| B-2-derived airframe | `3d-model-6.fbx` | `3d-model-7.obj` | Distinct flying-wing geometry; listing identity still needs confirmation |
| Four-engine high-wing transport | `3d-model-7.fbx` | `3d-model-8.obj` | Distinct transport geometry; exact variant still needs confirmation |

The remaining generic files are intentionally not assigned an aircraft type
until their geometry is matched conclusively. A visual guess must never drive
the type label shown on a collectible card.

## FBX to OBJ pairing

The download suffixes do not consistently pair formats. Pairing was recovered
by matching FBX model-node counts to OBJ group counts:

| FBX | OBJ | Mesh groups |
| --- | --- | ---: |
| `3d-model.fbx` | `3d-model.obj` | 147 |
| *(FBX absent)* | `3d-model-2.obj` | 121 |
| `3d-model-2.fbx` | `3d-model-3.obj` | 118 |
| `3d-model-3.fbx` | `3d-model-4.obj` | 117 |
| `3d-model-4.fbx` | `3d-model-5.obj` | 15 |
| `3d-model-5.fbx` | `3d-model-6.obj` | 377 |
| `3d-model-6.fbx` | `3d-model-7.obj` | 13 |
| `3d-model-7.fbx` | `3d-model-8.obj` | 55 |
| `3d-model-8.fbx` | `3d-model-9.obj` | 54 |
| `3d-model-9.fbx` | `3d-model-10.obj` | 39 |
| `3d-model-10.fbx` | `3d-model-11.obj` | 79 |
| `3d-model-11.fbx` | `3d-model-12.obj` | 148 |

## Technical audit

- The creator FBX files use FBX 7500 and were exported through 3ds Max 2014.
- Their OBJ files reference `3d-model.mtl`, but the archive does not contain the
  MTL files or referenced images.
- Several OBJ files have very sparse texture coordinates. They cannot support a
  reliable full-fuselage livery without UV cleanup.
- The A220 GLB/FBX is substantially heavier than the other sources and contains
  detailed parts and many texture references. It needs exterior-only cleanup,
  decimation, LODs, and mobile texture atlases before shipping.
- Existing airline texture references are provenance clues only. They are not
  bundled and must not be relied on for production rendering.

## Production pipeline

1. Import FBX (or the A220 GLB) into Blender as source geometry.
2. Confirm aircraft identity from geometry and record it above.
3. Normalize scale, forward axis, origin, normals, and smoothing.
4. Remove interiors, hidden geometry, landing-gear detail, and unused materials
   from the card-render version.
5. Split stable material regions such as fuselage, wings, engines, tail, glass,
   and metal. UV unwrap or rebuild only where necessary.
6. Produce independently authored Tally livery atlases and mobile LODs.
7. Export USDZ for RealityKit and render a transparent, deterministic card image
   from the same approved model.
8. Preserve the source-to-export mapping and attribution in this document.

The procedural C++ mesh remains a fallback/debug renderer only. Production cards
must use an approved authored aircraft asset so a 737 can never be represented by
a generic or incorrect silhouette.

## Bundled RealityKit assets

The verified exports below are bundled with the iOS target and resolved only for
an exact approved aircraft type. Any unmatched type continues to use the
procedural fallback until its source geometry is identified conclusively.

| Aircraft | Bundled USDZ |
| --- | --- |
| Airbus A220-300 | `airbus_a220_300.usdz` |
| Airbus A320-200 | `airbus_a320_200.usdz` |
| Airbus A380 | `airbus_a380.usdz` |
| Boeing 737-800 | `boeing_737_800.usdz` |
| Boeing 757-200 | `boeing_757_200.usdz` |
| Cessna 152 | `cessna_152.usdz` |

## One-command conversion

No Blender UI knowledge is required. On macOS, install Blender once and run the
headless processor from the repository root:

```bash
brew install --cask blender
scripts/process_aircraft_assets.sh /path/to/3d-models.zip
```

The processor opens each FBX in Blender's background mode, removes non-mesh scene
objects, normalizes the model, removes unavailable legacy image references while
preserving UVs and material slots, smooths and reduces oversized geometry,
exports a neutral mobile USDZ, and writes a JSON audit under
`build/aircraft-reports`. It never
requires interacting with Blender's interface. When it finishes, upload the
generated `build/tally-aircraft-output.zip` to Codex so the optimized models can
be verified, identified, and wired into the RealityKit renderer.
