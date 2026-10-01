# YimMenu and Samurai comparison

Compared on 2026-10-01 against these source revisions:

- [Legacy YimMenu](https://github.com/Mr-X-GTA/YimMenu/tree/e69bbb6adbdbc7e4e99f703bb1c4518b67e6a982): `e69bbb6adbdbc7e4e99f703bb1c4518b67e6a982`.
- [YimMenuV2 enhanced](https://github.com/YimMenu/YimMenuV2/tree/39a0f227782304d7fb3a5f7d3cdaec36a4d348f3): `39a0f227782304d7fb3a5f7d3cdaec36a4d348f3`.
- [Samurais-Scripts](https://github.com/YimMenu-Lua/Samurais-Scripts/tree/09e7568ffe10e329e03d0740b25b78318c73060a): `09e7568ffe10e329e03d0740b25b78318c73060a`.

Scooby can host a modular Lua with its own GUI and RDR2 features. The included
`FrontierWorkbench` package demonstrates that structure. Samurai's GTA V features
cannot run unchanged: their natives, globals/locals, entity/model assumptions,
assets and memory integrations require a game-specific port.

| Area | Reference behavior | Scooby update |
| --- | --- | --- |
| Game execution | Legacy `script.register_looped`/`run_in_fiber`; V2 callback coroutines on the game thread | Game-fiber queue, cooperative sleep/yield, named loops, callback cancellation and cleanup |
| Modules | Samurai uses `require` and an `includes` tree | Package discovery, local/root Lua modules, independent per-script cache |
| GUI | Legacy `gui.add_tab`, `add_imgui`, `add_always_draw_imgui`; Samurai draws custom windows/widgets | Script-owned tabs and custom render callbacks; drawing, styles, flags, clipboard and larger text inputs |
| Widget results | Legacy Yim generally returns value before changed | Existing Scooby order retained; opt-in `compat.yim_imgui` adapter |
| Script ownership | Yim/V2 track resources and callbacks | Tasks, events, timers and config owned by each Lua state; disable/reload releases the state |
| Natives | GTA-specific named native namespaces | Generated RDR2 namespaces and validated scalar/string inputs; 4859 supported declarations |
| Runtime | Legacy uses sol; V2 enhanced uses LuaJIT | Selectable Lua 5.4.6 and LuaJIT 2.1 builds, API/runtime requirements; LuaJIT FFI works, compiled traces disabled for callback budgets |
| Menu integration | V2 owns submenu/category/group command resources | Partial legacy-style `gui` tabs in a themed script window; no claim of V2 `menu` command parity |
| Memory/network internals | Samurai includes GTA-specific integrations | No GTA globals/locals, memory patching or network event adapter; LuaJIT FFI does not provide GTA layouts |

The comparison informed the runtime contracts; GTA implementation code was not
copied into the RDR2 host. Useful primary reference locations are legacy
[`script`](https://github.com/Mr-X-GTA/YimMenu/blob/e69bbb6adbdbc7e4e99f703bb1c4518b67e6a982/docs/lua/tables/script.md)
and [`ImGui`](https://github.com/Mr-X-GTA/YimMenu/blob/e69bbb6adbdbc7e4e99f703bb1c4518b67e6a982/docs/lua/tables/ImGui.md)
documentation, V2's
[`scripting`](https://github.com/YimMenu/YimMenuV2/tree/39a0f227782304d7fb3a5f7d3cdaec36a4d348f3/src/core/scripting)
implementation, and Samurai's
[`SSV2`](https://github.com/YimMenu-Lua/Samurais-Scripts/tree/09e7568ffe10e329e03d0740b25b78318c73060a/SSV2)
package.

## Porting a GUI script

1. Put its entry point and `includes` directory in one package folder.
2. Move game/native work into `onLoad`, `onTick`, named loops, or
   `script.run_in_fiber`. Render callbacks consume cached state and queue actions.
3. Keep Scooby's `changed,value` widget convention, or locally bind
   `local ImGui=compat.yim_imgui` for adapted results, or call `compat.use("yim-legacy")` before importing GUI modules.
4. Port native calls using the generated RDR2 catalog and existing typed helpers.
   Check `Native.is_supported(namespace,name)`; do not reuse GTA hashes or globals.
5. Register unload cleanup for any game state or entities the script changes.
6. Test in RDR2 using the exact built DLL. Fixture tests establish host behavior,
   not acceptance of a GTA script or every RDR2 native.

See [the runtime API](lua-runtime-api.md) for exact signatures and limits.
`compat.targets` now reports partial Yim support; the previous broad booleans did
not establish drop-in compatibility with Yim, 2Take1, Impulse or FiveM.

Fortitude-style `menu.addSubmenu/addButton`, `features`, `pools`, and `sync`
interfaces also remain incompatible. Existing `GusUnlocker.lua`/`RagdollV3.lua`
ports still need their menu and game calls rewritten. `gui.add_tab` is now a
usable UI replacement; lowercase `native` and `natives` retain their `Native`
helper aliases rather than impersonating another host's full API.
## Additional legacy script audit

The [YimMenu-Lua organization](https://github.com/YimMenu-Lua) supplied additional
references: [YimActions](https://github.com/YimMenu-Lua/YimActions) and
[YimToast](https://github.com/YimMenu-Lua/YimToast). YimActions exercised menu,
widget and scheduling conventions; YimToast exposed the need for sizing,
wrapping and font-scale functions. Its GTA memory scan and frontend sounds need
replacement in RDR2. Use `ImGui.GetDisplaySize()` in a render callback instead of
copying a game-specific screen-resolution signature.

Samurai's audited SSV2 tree contains 328 Lua files. Its backend checks Yim-specific
host identifiers and initializes GTA pointers/globals before starting its GUI.
The GUI service imports further GTA audio/game services. It therefore requires
an RDR2 entry point and dependency port, not just more names in `ImGui`.
The current source also contains Lua 5.4 variable attributes; Lua54 is the right
syntax target for that revision. LuaJIT support targets scripts actually written
for its Lua 5.1 language and extensions.

The static audit now recognizes 138 directly referenced host ImGui names and no
missing ImGui-name candidates after excluding helpers defined by Samurai itself.
It still reports 319 unavailable native-name candidates. This includes possible
local-table/comment matches and is not a tested feature count. Name matches do
not establish matching arguments, enum coverage, return values, or RDR2 behavior.
No unchanged Samurai launch or full RDR2 Samurai feature port is claimed.

Run the audit on other scripts without executing their code:

```powershell
powershell -File tools/audit-lua-compat.ps1 `
  -ScriptPath 'path/to/script/package' `
  -Output build/lua-api-evidence/script-audit.json
```

The JSON report lists imported module names, Lua 5.4 attribute syntax, supported
GUI names, missing GUI/native candidates, and host calls needing review. It uses
the generated RDR2 native catalog and current binding source. Dynamic imports,
operator syntax and indirect calls still require manual review. Re-run after
updating the host or script; retain the source revision with the report.
The optional reference smoke test loads the pinned upstream callable.lua,
Vector2.lua, Rect.lua and (Lua54 only) Pair.lua without editing their source,
checks their values and uses the resulting rectangle with the Yim-style drawing
adapter. LuaJIT instead verifies Pair's unsupported Lua 5.4 syntax is rejected.
This exercises these utility modules, not Samurai's entry point or GUI service.

~~~powershell
build/x64/vs2022/tests/Release/LuaApiTests.exe build/lua-api-tests scripts/examples/FrontierWorkbench path/to/SSV2
build/x64/vs2022-luajit/tests/Release/LuaApiTests.exe build/lua-api-tests scripts/examples/FrontierWorkbench path/to/SSV2
~~~
Additional reference revisions: YimActions
712447e6abc981ed07dfa84944cddc7ae1c95157; YimToast
3fafa053c2723f1bf7818c59713f8cde040cea26. Samurai's backend explicitly rejects
LuaJIT/YimMenuV2 and checks for Yim host APIs; this must be changed in an actual
RDR2 port. The host does not impersonate those GTA hosts to bypass that check.