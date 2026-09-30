# CS2 API coverage and porting

Reviewed 2026-09-30 against the public [Fatality Lua 2 reference](https://lua2.fatality.win/), Scooby host 2.4 and UI 1.1. This is a capability comparison, not drop-in compatibility. The executable contract is Scooby's host API, editor metadata and regression fixtures. Similar features can have different names, callback timing, types and error behavior.

## Available equivalents

| Reference area | Scooby API | Differences |
| --- | --- | --- |
| [Utility functions](https://lua2.fatality.win/api/instances/utils) | `utils.base64_encode/decode`, `utils.to_bytes/from_bytes`, `utils.hex_encode/decode`, `utils.fnv1a`, `utils.unix_time` | Snake-case names; strict bounded binary conversions. Murmur2, date tables and script clipboard access are not exposed. |
| Pattern/export discovery | `native.scan`, `native.export`, `native.module` | Typed Win64 binding/hooking; scans reject ambiguous matches by default. |
| JSON/files | `json`, `files`, `storage`, `fs` | Script-scoped nested folders, atomic saves and opt-in text-module loading; no arbitrary external paths. JSON null and container tags are explicit. |
| [Math](https://lua2.fatality.win/api/instances/math) | `vector`, `vector2`, `rect`, `color`, `colors`, `mathx`, `render.world_to_screen` | Source-unit vectors, degree angles, normalized RGBA. Adds easing and frame-independent damping. |
| GUI / controls | `ui`, `imgui`, `widgets` / `ui.widgets`, `features` | Immediate-mode callback scopes; use CS2 settings IDs. This does not implement the reference's retained GUI objects. |
| [Drawing](https://lua2.fatality.win/api/instances/draw) | `render`, `draw` | Text, shapes, gradients, arcs, Beziers and window clipping. Texture/font/shader/SVG/animated-resource objects are not exposed. |

## Partial engine coverage

| Area | Current implementation | Missing integration |
| --- | --- | --- |
| [Entities](https://lua2.fatality.win/api/instances/entities) | Copied player/weapon snapshots, validated handles, selected bones and view state | General entity classes, writable schema properties, hitboxes and full weapon metadata |
| [Events](https://lua2.fatality.win/api/instances/events) | update/render/shutdown plus sampled session, health, death, spawn and local-weapon changes | Native server-event payloads and frame-stage/view hooks. `commands.create` now provides isolated command mutation. |
| Native hooks | Fixed Windows x64 scalar calls, detours and isolated worker state | Struct/vector ABI, varargs, LuaJIT FFI and automatic engine SDK bindings |

Sampled health changes do not identify an attacker, hitgroup or authoritative damage event. A native address does not make an engine service available: it still needs a verified prototype, valid objects, the correct thread and an actual host implementation.

## Not exposed

Command-worker shot traces and asynchronous HTTP are exposed with permission/readiness checks. General physics queries, penetration, particle creation, schema reflection, WebSocket and Panorama APIs remain unavailable. Native hooks are not a drop-in implementation of those systems. Script clipboard/date/Murmur2 helpers, managed GPU resources and retained GUI objects are additional gaps. `cs2.capabilities()` reports explicit false entries for the major unavailable categories.

Shared `esp_colors` functions are present for interface consistency but CS2 has no shared entity-color provider. `esp_colors.available()` and `ui.entity_colors()` return false; use `settings.list`, `settings.info`, `settings.get` and `settings.set` for the native CS2 controls.

## Port a script

1. Replace external module names and retained GUI objects with documented Scooby bindings and UI callback scopes.
2. Replace assumed feature IDs with values returned by `settings.list()`.
3. Check optional player/projection results for nil and preserve the full player handle.
4. Replace native-event assumptions with explicitly sampled behavior only when that behavior is sufficient.
5. Use the Console's script filter, Errors only and Copy visible to diagnose failures. Keep initialization outside per-frame callbacks.

The current implementation deliberately reports unsupported capabilities rather than publishing placeholder functions. Next engine work should add verified event payloads, general entity/schema access one service at a time, with thread/lifetime rules and real in-game validation. Native inventory changes and item model previews are available; arbitrary GPU resources and Panorama require further implementation. Command/native model behavior still needs in-game acceptance on the installed build.

## Keeping documentation complete

`python tools/check_lua_api.py --write` refreshes the binding catalog/index from current registration plus reviewed annotations. The check without `--write` rejects missing editor declarations, undocumented exports and stale output. `--runtime build/LuaCoverage20260930/lua.log` compares that inventory against functions enumerated by the real Lua fixture. The site generator imports the host contract, binding index, comparison guide and editor metadata; its `--check` mode rejects stale output.
