(function () {
  // Generated from RedM/RedM/lua/ScoobyAPI registrations.
  // Keep docs/redm/SCOOBY_NATIVE_EXCLUSIONS.md applied after regeneration.
  var SCOOBY_DATA = {
      "0xDEAD0001": {
          "name": "IS_INJECTED",
          "params": [],
          "results": "int",
          "description": "Returns 1 if Scooby is injected, 0 otherwise. Use to detect if custom natives are available.",
          "hash": "0xDEAD0001",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD0002": {
          "name": "HTTP_REQUEST",
          "params": [
              {
                  "type": "char*",
                  "name": "url"
              },
              {
                  "type": "char*",
                  "name": "method"
              },
              {
                  "type": "char*",
                  "name": "data"
              },
              {
                  "type": "char*",
                  "name": "headers"
              }
          ],
          "results": "int",
          "description": "Starts an async HTTP request. Returns request index (>0) on success, 0 on failure. Use HTTP_POLL to check completion.",
          "hash": "0xDEAD0002",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD0003": {
          "name": "HTTP_POLL",
          "params": [],
          "results": "int",
          "description": "Polls for completed HTTP requests. Returns request index if one completed, 0 if none ready. After this returns non-zero, use HTTP_GET_STATUS, HTTP_BODY_LEN, HTTP_BODY_BYTE to read response.",
          "hash": "0xDEAD0003",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD0004": {
          "name": "HTTP_GET_STATUS",
          "params": [],
          "results": "int",
          "description": "Returns HTTP status code of last polled request (e.g., 200, 404).",
          "hash": "0xDEAD0004",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD0005": {
          "name": "HTTP_BODY_LEN",
          "params": [],
          "results": "int",
          "description": "Returns length in bytes of the response body from last polled HTTP request.",
          "hash": "0xDEAD0005",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD0006": {
          "name": "HTTP_BODY_BYTE",
          "params": [
              {
                  "type": "int",
                  "name": "index"
              }
          ],
          "results": "int",
          "description": "Returns byte at given index from the response body. Use with HTTP_BODY_LEN to read full response.",
          "hash": "0xDEAD0006",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD0007": {
          "name": "HTTP_HEADERS_LEN",
          "params": [],
          "results": "int",
          "description": "Returns length of response headers string from last polled HTTP request.",
          "hash": "0xDEAD0007",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD0008": {
          "name": "HTTP_HEADERS_BYTE",
          "params": [
              {
                  "type": "int",
                  "name": "index"
              }
          ],
          "results": "int",
          "description": "Returns byte at given index from response headers.",
          "hash": "0xDEAD0008",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD0009": {
          "name": "NUI_EXEC",
          "params": [
              {
                  "type": "char*",
                  "name": "code"
              }
          ],
          "results": "int",
          "description": "Executes JavaScript code in the NUI root context. Returns 1 on success, 0 if nui-core.dll not loaded.",
          "hash": "0xDEAD0009",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD000A": {
          "name": "LOAD_ENC",
          "params": [
              {
                  "type": "char*",
                  "name": "path"
              }
          ],
          "results": "int",
          "description": "Decrypts and executes an encrypted Lua file. Returns 1 on success, 0 on failure.",
          "hash": "0xDEAD000A",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD000B": {
          "name": "GET_SRC",
          "params": [],
          "results": "char*",
          "description": "Returns pending Lua source code string queued for execution.",
          "hash": "0xDEAD000B",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD000D": {
          "name": "GET_TIME_WINDOW",
          "params": [],
          "results": "uint32",
          "description": "Returns the current authentication time-window value used by Scooby Lua.",
          "hash": "0xDEAD000D",
          "ns": "SCOOBY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1000": {
          "name": "MEM_SCAN",
          "params": [
              {
                  "type": "char*",
                  "name": "pattern"
              },
              {
                  "type": "char*",
                  "name": "module"
              }
          ],
          "results": "uint64",
          "description": "Scans memory for a byte pattern (IDA-style, e.g., \"48 8B 05 ? ? ? ?\"). Returns address if found, 0 otherwise. Module is optional.",
          "hash": "0xDEAD1000",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1001": {
          "name": "MEM_MODULE_BASE",
          "params": [
              {
                  "type": "char*",
                  "name": "moduleName"
              }
          ],
          "results": "uint64",
          "description": "Returns base address of a loaded module. Pass NULL for main executable.",
          "hash": "0xDEAD1001",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1002": {
          "name": "MEM_RIP",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              }
          ],
          "results": "uint64",
          "description": "Resolves a RIP-relative address (common in x64 code). Reads 4-byte offset at address and returns absolute target.",
          "hash": "0xDEAD1002",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1003": {
          "name": "MEM_ADD",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              },
              {
                  "type": "int",
                  "name": "offset"
              }
          ],
          "results": "uint64",
          "description": "Adds offset to address. Simple pointer arithmetic helper.",
          "hash": "0xDEAD1003",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1004": {
          "name": "MEM_IS_VALID",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              }
          ],
          "results": "BOOL",
          "description": "Returns true if address is readable memory.",
          "hash": "0xDEAD1004",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1010": {
          "name": "MEM_READ_U8",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              }
          ],
          "results": "int",
          "description": "Reads unsigned 8-bit value from address.",
          "hash": "0xDEAD1010",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1011": {
          "name": "MEM_READ_U16",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              }
          ],
          "results": "int",
          "description": "Reads unsigned 16-bit value from address.",
          "hash": "0xDEAD1011",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1012": {
          "name": "MEM_READ_U32",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              }
          ],
          "results": "int",
          "description": "Reads unsigned 32-bit value from address.",
          "hash": "0xDEAD1012",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1013": {
          "name": "MEM_READ_U64",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              }
          ],
          "results": "uint64",
          "description": "Reads unsigned 64-bit value from address.",
          "hash": "0xDEAD1013",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1014": {
          "name": "MEM_READ_F32",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              }
          ],
          "results": "float",
          "description": "Reads 32-bit float from address.",
          "hash": "0xDEAD1014",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1015": {
          "name": "MEM_READ_F64",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              }
          ],
          "results": "float",
          "description": "Reads 64-bit double from address.",
          "hash": "0xDEAD1015",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1016": {
          "name": "MEM_READ_STRING",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              },
              {
                  "type": "int",
                  "name": "maxLen"
              }
          ],
          "results": "char*",
          "description": "Reads null-terminated string from address, up to maxLen bytes (default 256).",
          "hash": "0xDEAD1016",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1020": {
          "name": "MEM_WRITE_U8",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              },
              {
                  "type": "int",
                  "name": "value"
              }
          ],
          "results": "int",
          "description": "Writes 8-bit value to address. Returns 1.",
          "hash": "0xDEAD1020",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1021": {
          "name": "MEM_WRITE_U16",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              },
              {
                  "type": "int",
                  "name": "value"
              }
          ],
          "results": "int",
          "description": "Writes 16-bit value to address. Returns 1.",
          "hash": "0xDEAD1021",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1022": {
          "name": "MEM_WRITE_U32",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              },
              {
                  "type": "int",
                  "name": "value"
              }
          ],
          "results": "int",
          "description": "Writes 32-bit value to address. Returns 1.",
          "hash": "0xDEAD1022",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1023": {
          "name": "MEM_WRITE_U64",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              },
              {
                  "type": "uint64",
                  "name": "value"
              }
          ],
          "results": "int",
          "description": "Writes 64-bit value to address. Returns 1.",
          "hash": "0xDEAD1023",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1024": {
          "name": "MEM_WRITE_F32",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              },
              {
                  "type": "float",
                  "name": "value"
              }
          ],
          "results": "int",
          "description": "Writes 32-bit float to address. Returns 1.",
          "hash": "0xDEAD1024",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1025": {
          "name": "MEM_WRITE_F64",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              },
              {
                  "type": "float",
                  "name": "value"
              }
          ],
          "results": "int",
          "description": "Writes 64-bit double to address. Returns 1.",
          "hash": "0xDEAD1025",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD1026": {
          "name": "MEM_NOP",
          "params": [
              {
                  "type": "uint64",
                  "name": "address"
              },
              {
                  "type": "int",
                  "name": "count"
              }
          ],
          "results": "int",
          "description": "Writes NOP (0x90) bytes at address. Returns 1.",
          "hash": "0xDEAD1026",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2000": {
          "name": "HOOK_INLINE",
          "params": [
              {
                  "type": "uint64",
                  "name": "targetAddress"
              },
              {
                  "type": "char*",
                  "name": "eventName"
              }
          ],
          "results": "int",
          "description": "Adds an inline hook observer at target address. Returns hook handle. Use HOOK_POLL to receive events when the address is called.",
          "hash": "0xDEAD2000",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2002": {
          "name": "HOOK_REMOVE",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              }
          ],
          "results": "BOOL",
          "description": "Removes an inline hook by handle. Returns true on success.",
          "hash": "0xDEAD2002",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2003": {
          "name": "HOOK_POLL",
          "params": [],
          "results": "BOOL",
          "description": "Polls for inline hook events. Returns true if an event is available. Use HOOK_POLL_NAME and HOOK_POLL_ARG to read event data.",
          "hash": "0xDEAD2003",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2004": {
          "name": "HOOK_POLL_NAME",
          "params": [],
          "results": "char*",
          "description": "Returns the event name of the last polled inline hook event.",
          "hash": "0xDEAD2004",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2005": {
          "name": "HOOK_POLL_ARG",
          "params": [
              {
                  "type": "int",
                  "name": "index"
              }
          ],
          "results": "uint64",
          "description": "Returns argument at index (0-3) from the last polled inline hook event.",
          "hash": "0xDEAD2005",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2010": {
          "name": "HOOK_NATIVE",
          "params": [
              {
                  "type": "uint64",
                  "name": "nativeHash"
              },
              {
                  "type": "char*",
                  "name": "eventName"
              }
          ],
          "results": "BOOL",
          "description": "Hooks a native function by hash. Returns true on success. Use HOOK_NATIVE_POLL to receive events when the native is called.",
          "hash": "0xDEAD2010",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2012": {
          "name": "HOOK_NATIVE_REMOVE",
          "params": [
              {
                  "type": "uint64",
                  "name": "nativeHash"
              }
          ],
          "results": "BOOL",
          "description": "Removes a native hook. Returns true on success.",
          "hash": "0xDEAD2012",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2013": {
          "name": "HOOK_NATIVE_POLL",
          "params": [],
          "results": "BOOL",
          "description": "Polls for native hook events. Returns true if an event is available.",
          "hash": "0xDEAD2013",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2014": {
          "name": "HOOK_NATIVE_POLL_NAME",
          "params": [],
          "results": "char*",
          "description": "Returns the event name of the last polled native hook event.",
          "hash": "0xDEAD2014",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2015": {
          "name": "HOOK_NATIVE_POLL_ARG",
          "params": [
              {
                  "type": "int",
                  "name": "index"
              }
          ],
          "results": "uint64",
          "description": "Returns argument at index (0-3) from the last polled native hook event.",
          "hash": "0xDEAD2015",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2016": {
          "name": "HOOK_NATIVE_POLL_RESULT",
          "params": [],
          "results": "uint64",
          "description": "Returns the result value from the last polled native hook event.",
          "hash": "0xDEAD2016",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD2017": {
          "name": "HOOK_NATIVE_POLL_ARGC",
          "params": [],
          "results": "int",
          "description": "Returns the argument count from the last polled native hook event.",
          "hash": "0xDEAD2017",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3001": {
          "name": "SCOOBY_NOTIFY",
          "params": [
              {
                  "type": "char*",
                  "name": "title"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              },
              {
                  "type": "char*",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Shows a Scooby notification from Lua.",
          "hash": "0xDEAD3001",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3002": {
          "name": "SCOOBY_LOG",
          "params": [
              {
                  "type": "char*",
                  "name": "line"
              }
          ],
          "results": "int",
          "description": "Writes a line to the Scooby Lua console/log surface.",
          "hash": "0xDEAD3002",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3003": {
          "name": "SCOOBY_VERSION",
          "params": [],
          "results": "char*",
          "description": "Returns the current Scooby script API version string.",
          "hash": "0xDEAD3003",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3004": {
          "name": "SCOOBY_OPEN_URL",
          "params": [
              {
                  "type": "char*",
                  "name": "url"
              }
          ],
          "results": "int",
          "description": "Scooby Open Url. Registered RedM Scooby native.",
          "hash": "0xDEAD3004",
          "ns": "SCOOBY_SYSTEM",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3005": {
          "name": "SCOOBY_CLIP_GET",
          "params": [],
          "results": "char*",
          "description": "Scooby Clip Get. Registered RedM Scooby native.",
          "hash": "0xDEAD3005",
          "ns": "SCOOBY_SYSTEM",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3006": {
          "name": "SCOOBY_CLIP_SET",
          "params": [
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Clip Set. Registered RedM Scooby native.",
          "hash": "0xDEAD3006",
          "ns": "SCOOBY_SYSTEM",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3007": {
          "name": "SCOOBY_MENU_OPEN",
          "params": [],
          "results": "int",
          "description": "Scooby Menu Open. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3007",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3008": {
          "name": "SCOOBY_MENU_CLOSE",
          "params": [],
          "results": "int",
          "description": "Scooby Menu Close. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3008",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3009": {
          "name": "SCOOBY_MENU_TOGGLE",
          "params": [],
          "results": "int",
          "description": "Scooby Menu Toggle. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3009",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD300A": {
          "name": "SCOOBY_MENU_IS_OPEN",
          "params": [],
          "results": "int",
          "description": "Scooby Menu Is Open. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD300A",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD300B": {
          "name": "SCOOBY_STOP_RES",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Stop Res. Registered RedM Scooby native.",
          "hash": "0xDEAD300B",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD300C": {
          "name": "SCOOBY_INJECT",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Inject. Registered RedM Scooby native.",
          "hash": "0xDEAD300C",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD300D": {
          "name": "SCOOBY_AUTH_KEY",
          "params": [],
          "results": "char*",
          "description": "Returns the current authenticated Scooby user key string.",
          "hash": "0xDEAD300D",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD300E": {
          "name": "SCOOBY_CAM_LOCK",
          "params": [
              {
                  "type": "int",
                  "name": "on"
              }
          ],
          "results": "int",
          "description": "Scooby Cam Lock. Registered RedM Scooby native.",
          "hash": "0xDEAD300E",
          "ns": "SCOOBY_CAMERA",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD300F": {
          "name": "SCOOBY_CAM_POS",
          "params": [
              {
                  "type": "float",
                  "name": "arg0"
              },
              {
                  "type": "float",
                  "name": "arg1"
              },
              {
                  "type": "float",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Cam Pos. Registered RedM Scooby native.",
          "hash": "0xDEAD300F",
          "ns": "SCOOBY_CAMERA",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3010": {
          "name": "SCOOBY_CAM_ROT",
          "params": [
              {
                  "type": "float",
                  "name": "arg0"
              },
              {
                  "type": "float",
                  "name": "arg1"
              },
              {
                  "type": "float",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Cam Rot. Registered RedM Scooby native.",
          "hash": "0xDEAD3010",
          "ns": "SCOOBY_CAMERA",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3011": {
          "name": "SCOOBY_VEH_SPAWN",
          "params": [
              {
                  "type": "uint32",
                  "name": "id"
              },
              {
                  "type": "float",
                  "name": "arg1"
              },
              {
                  "type": "float",
                  "name": "arg2"
              },
              {
                  "type": "float",
                  "name": "arg3"
              },
              {
                  "type": "float",
                  "name": "arg4"
              },
              {
                  "type": "int",
                  "name": "arg5"
              },
              {
                  "type": "int",
                  "name": "arg6"
              },
              {
                  "type": "int",
                  "name": "arg7"
              }
          ],
          "results": "int",
          "description": "Scooby Veh Spawn. Registered RedM Scooby native.",
          "hash": "0xDEAD3011",
          "ns": "SCOOBY_VEHICLE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3012": {
          "name": "SCOOBY_START_RES",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Start Res. Registered RedM Scooby native.",
          "hash": "0xDEAD3012",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3013": {
          "name": "SCOOBY_AVAILABLE",
          "params": [],
          "results": "int",
          "description": "Returns 1 when the Scooby script API native table has been registered.",
          "hash": "0xDEAD3013",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3014": {
          "name": "SCOOBY_UI_MEASURE",
          "params": [
              {
                  "type": "char*",
                  "name": "text"
              },
              {
                  "type": "float",
                  "name": "arg1"
              }
          ],
          "results": "float",
          "description": "Scooby Ui Measure. Registered RedM Scooby native.",
          "hash": "0xDEAD3014",
          "ns": "SCOOBY_UI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3015": {
          "name": "SCOOBY_HOOK_OVERRIDE",
          "params": [],
          "results": "int",
          "description": "Reserved hook override slot. Currently registered so scripts can detect the hash without a missing-native failure.",
          "hash": "0xDEAD3015",
          "ns": "SCOOBY_HOOK",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3016": {
          "name": "SCOOBY_RESOLVE_EXPORT",
          "params": [
              {
                  "type": "char*",
                  "name": "dll"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              }
          ],
          "results": "uint64",
          "description": "Resolves an exported symbol from a loaded DLL and returns its address.",
          "hash": "0xDEAD3016",
          "ns": "SCOOBY_MEMORY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3017": {
          "name": "SCOOBY_NUI_SUB",
          "params": [],
          "results": "uint64",
          "description": "Scooby Nui Sub. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3017",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3018": {
          "name": "SCOOBY_DUI_SUB",
          "params": [],
          "results": "uint64",
          "description": "Scooby Dui Sub. Registered RedM Scooby native.",
          "hash": "0xDEAD3018",
          "ns": "SCOOBY_DUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3019": {
          "name": "SCOOBY_NUI_DRAIN",
          "params": [],
          "results": "int",
          "description": "Scooby Nui Drain. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3019",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD301A": {
          "name": "SCOOBY_INPUT_MODE",
          "params": [
              {
                  "type": "char*",
                  "name": "mode"
              }
          ],
          "results": "int",
          "description": "Scooby Input Mode. Registered RedM Scooby native.",
          "hash": "0xDEAD301A",
          "ns": "SCOOBY_INPUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD301B": {
          "name": "SCOOBY_LOAD_IMAGE",
          "params": [
              {
                  "type": "char*",
                  "name": "bytes"
              },
              {
                  "type": "int",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Load Image. Registered RedM Scooby native.",
          "hash": "0xDEAD301B",
          "ns": "SCOOBY_DRAW",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD301C": {
          "name": "SCOOBY_SHOW_IMAGE",
          "params": [
              {
                  "type": "char*",
                  "name": "path"
              },
              {
                  "type": "float",
                  "name": "arg1"
              },
              {
                  "type": "float",
                  "name": "arg2"
              },
              {
                  "type": "float",
                  "name": "arg3"
              },
              {
                  "type": "float",
                  "name": "arg4"
              }
          ],
          "results": "int",
          "description": "Scooby Show Image. Registered RedM Scooby native.",
          "hash": "0xDEAD301C",
          "ns": "SCOOBY_DRAW",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD301D": {
          "name": "SCOOBY_HIDE_IMAGE",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              }
          ],
          "results": "int",
          "description": "Scooby Hide Image. Registered RedM Scooby native.",
          "hash": "0xDEAD301D",
          "ns": "SCOOBY_DRAW",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD301E": {
          "name": "SCOOBY_PUSH1_FRAME",
          "params": [
              {
                  "type": "int",
                  "name": "kind"
              },
              {
                  "type": "char*",
                  "name": "text"
              },
              {
                  "type": "float",
                  "name": "arg2"
              },
              {
                  "type": "float",
                  "name": "arg3"
              },
              {
                  "type": "float",
                  "name": "arg4"
              },
              {
                  "type": "uint32",
                  "name": "arg5"
              },
              {
                  "type": "int",
                  "name": "arg6"
              },
              {
                  "type": "float",
                  "name": "arg7"
              }
          ],
          "results": "int",
          "description": "Queues a one-frame draw command. kind 0=text, 1=rect, 2=line, 3=circle, 4=image.",
          "hash": "0xDEAD301E",
          "ns": "SCOOBY_DRAW",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD301F": {
          "name": "SCOOBY_LOAD_TEX_BUF",
          "params": [
              {
                  "type": "char*",
                  "name": "bytes"
              },
              {
                  "type": "int",
                  "name": "len"
              }
          ],
          "results": "int",
          "description": "Loads an image texture from a Lua byte buffer; subsequent zero-argument calls return the last decoded width and height.",
          "hash": "0xDEAD301F",
          "ns": "SCOOBY_DRAW",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3020": {
          "name": "SCOOBY_MENU_WINDOW",
          "params": [
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "w"
              },
              {
                  "type": "float",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Window. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3020",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3021": {
          "name": "SCOOBY_MENU_TABBED_WINDOW",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              },
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "w"
              },
              {
                  "type": "float",
                  "name": "h"
              },
              {
                  "type": "float",
                  "name": "tabBarW"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Tabbed Window. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3021",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3022": {
          "name": "SCOOBY_MENU_DESTROY",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Destroy. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3022",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3023": {
          "name": "SCOOBY_MENU_SET_ACCENT",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "r"
              },
              {
                  "type": "int",
                  "name": "g"
              },
              {
                  "type": "int",
                  "name": "b"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Accent. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3023",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3024": {
          "name": "SCOOBY_MENU_SET_KEYBIND",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "vk"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Keybind. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3024",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3025": {
          "name": "SCOOBY_MENU_GROUP",
          "params": [
              {
                  "type": "int",
                  "name": "parent"
              },
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Group. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3025",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3026": {
          "name": "SCOOBY_MENU_ADD_TAB",
          "params": [
              {
                  "type": "int",
                  "name": "window"
              },
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Add Tab. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3026",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3027": {
          "name": "SCOOBY_MENU_SMALL_TEXT",
          "params": [
              {
                  "type": "int",
                  "name": "parent"
              },
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Small Text. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3027",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3028": {
          "name": "SCOOBY_MENU_BUTTON",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "name"
              },
              {
                  "type": "int",
                  "name": "cbId"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Button. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3028",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3029": {
          "name": "SCOOBY_MENU_CHECKBOX",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "name"
              },
              {
                  "type": "int",
                  "name": "cbEn"
              },
              {
                  "type": "int",
                  "name": "cbDis"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Checkbox. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3029",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD302A": {
          "name": "SCOOBY_MENU_SLIDER",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "name"
              },
              {
                  "type": "float",
                  "name": "def"
              },
              {
                  "type": "float",
                  "name": "minV"
              },
              {
                  "type": "float",
                  "name": "maxV"
              },
              {
                  "type": "char*",
                  "name": "unit"
              },
              {
                  "type": "int",
                  "name": "prec"
              },
              {
                  "type": "int",
                  "name": "cbId"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Slider. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD302A",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD302B": {
          "name": "SCOOBY_MENU_TEXT",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Text. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD302B",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD302C": {
          "name": "SCOOBY_MENU_SET_TEXT",
          "params": [
              {
                  "type": "int",
                  "name": "widget"
              },
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Text. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD302C",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD302D": {
          "name": "SCOOBY_MENU_INPUT_BOX",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "text"
              },
              {
                  "type": "char*",
                  "name": "placeholder"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Input Box. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD302D",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD302E": {
          "name": "SCOOBY_MENU_GET_INPUT_BOX",
          "params": [
              {
                  "type": "int",
                  "name": "widget"
              }
          ],
          "results": "char*",
          "description": "Scooby Menu Get Input Box. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD302E",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD302F": {
          "name": "SCOOBY_MENU_DROPDOWN",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "name"
              },
              {
                  "type": "int",
                  "name": "cbId"
              },
              {
                  "type": "char*",
                  "name": "serialised"
              },
              {
                  "type": "int",
                  "name": "count"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Dropdown. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD302F",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3030": {
          "name": "SCOOBY_MENU_POLL_CALLBACK",
          "params": [],
          "results": "int",
          "description": "Scooby Menu Poll Callback. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3030",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3040": {
          "name": "SCOOBY_DUI_TRACK_ADD",
          "params": [
              {
                  "type": "uint64",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Adds a DUI handle to Scooby lifetime tracking for cleanup.",
          "hash": "0xDEAD3040",
          "ns": "SCOOBY_DUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3041": {
          "name": "SCOOBY_DUI_TRACK_REMOVE",
          "params": [
              {
                  "type": "uint64",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Removes a DUI handle from Scooby lifetime tracking.",
          "hash": "0xDEAD3041",
          "ns": "SCOOBY_DUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3042": {
          "name": "SCOOBY_DUI_TRACK_COUNT",
          "params": [],
          "results": "int",
          "description": "Returns the number of DUI handles currently tracked by Scooby.",
          "hash": "0xDEAD3042",
          "ns": "SCOOBY_DUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3060": {
          "name": "SCOOBY_LOGGER_GET",
          "params": [],
          "results": "int",
          "description": "Scooby Logger Get. Registered RedM Scooby native.",
          "hash": "0xDEAD3060",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3061": {
          "name": "SCOOBY_LOGGER_SET",
          "params": [
              {
                  "type": "int",
                  "name": "v"
              }
          ],
          "results": "int",
          "description": "Scooby Logger Set. Registered RedM Scooby native.",
          "hash": "0xDEAD3061",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3062": {
          "name": "SCOOBY_LOGGER_LOCK",
          "params": [
              {
                  "type": "int",
                  "name": "v"
              }
          ],
          "results": "int",
          "description": "Scooby Logger Lock. Registered RedM Scooby native.",
          "hash": "0xDEAD3062",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3063": {
          "name": "SCOOBY_INJECT_THREAD",
          "params": [
              {
                  "type": "char*",
                  "name": "arg1"
              },
              {
                  "type": "char*",
                  "name": "arg2"
              },
              {
                  "type": "char*",
                  "name": "arg3"
              }
          ],
          "results": "int",
          "description": "Scooby Inject Thread. Registered RedM Scooby native.",
          "hash": "0xDEAD3063",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3064": {
          "name": "SCOOBY_ISOLATED_INJECT",
          "params": [
              {
                  "type": "char*",
                  "name": "code"
              }
          ],
          "results": "int",
          "description": "Scooby Isolated Inject. Registered RedM Scooby native.",
          "hash": "0xDEAD3064",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3065": {
          "name": "SCOOBY_INJECT_RES2",
          "params": [
              {
                  "type": "char*",
                  "name": "arg1"
              },
              {
                  "type": "char*",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Inject Res2. Registered RedM Scooby native.",
          "hash": "0xDEAD3065",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3066": {
          "name": "SCOOBY_RESOURCE_INJECTABLE",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Resource Injectable. Registered RedM Scooby native.",
          "hash": "0xDEAD3066",
          "ns": "SCOOBY_API",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3070": {
          "name": "SCOOBY_IMG_LOAD_FILE",
          "params": [
              {
                  "type": "char*",
                  "name": "path"
              }
          ],
          "results": "int",
          "description": "Scooby Img Load File. Registered RedM Scooby native.",
          "hash": "0xDEAD3070",
          "ns": "SCOOBY_IMAGE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3071": {
          "name": "SCOOBY_IMG_LOAD_DATA",
          "params": [
              {
                  "type": "char*",
                  "name": "key"
              },
              {
                  "type": "char*",
                  "name": "bytes"
              },
              {
                  "type": "int",
                  "name": "len"
              }
          ],
          "results": "int",
          "description": "Scooby Img Load Data. Registered RedM Scooby native.",
          "hash": "0xDEAD3071",
          "ns": "SCOOBY_IMAGE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3072": {
          "name": "SCOOBY_IMG_UNLOAD",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Img Unload. Registered RedM Scooby native.",
          "hash": "0xDEAD3072",
          "ns": "SCOOBY_IMAGE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3073": {
          "name": "SCOOBY_IMAGE_INFO_WIDTH",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Image Info Width. Registered RedM Scooby native.",
          "hash": "0xDEAD3073",
          "ns": "SCOOBY_IMAGE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3074": {
          "name": "SCOOBY_IMAGE_INFO_HEIGHT",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Image Info Height. Registered RedM Scooby native.",
          "hash": "0xDEAD3074",
          "ns": "SCOOBY_IMAGE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3075": {
          "name": "SCOOBY_IMAGE_INFO_FRAMES",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Image Info Frames. Registered RedM Scooby native.",
          "hash": "0xDEAD3075",
          "ns": "SCOOBY_IMAGE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3076": {
          "name": "SCOOBY_IMAGE_GIF_FRAME",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Image Gif Frame. Registered RedM Scooby native.",
          "hash": "0xDEAD3076",
          "ns": "SCOOBY_IMAGE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3077": {
          "name": "SCOOBY_IMAGE_GIF_HANDLE",
          "params": [
              {
                  "type": "int",
                  "name": "first"
              },
              {
                  "type": "int",
                  "name": "idx"
              }
          ],
          "results": "int",
          "description": "Scooby Image Gif Handle. Registered RedM Scooby native.",
          "hash": "0xDEAD3077",
          "ns": "SCOOBY_IMAGE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3078": {
          "name": "SCOOBY_MENU_SET_HEADER",
          "params": [
              {
                  "type": "int",
                  "name": "win"
              },
              {
                  "type": "int",
                  "name": "img"
              },
              {
                  "type": "float",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Header. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3078",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3079": {
          "name": "SCOOBY_MENU_SET_BG",
          "params": [
              {
                  "type": "int",
                  "name": "win"
              },
              {
                  "type": "int",
                  "name": "img"
              },
              {
                  "type": "int",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Bg. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3079",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD307A": {
          "name": "SCOOBY_MENU_SET_BADGE",
          "params": [
              {
                  "type": "int",
                  "name": "win"
              },
              {
                  "type": "int",
                  "name": "img"
              },
              {
                  "type": "char*",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Badge. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD307A",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD307B": {
          "name": "SCOOBY_MENU_SET_FOOTER",
          "params": [
              {
                  "type": "int",
                  "name": "win"
              },
              {
                  "type": "char*",
                  "name": "text"
              },
              {
                  "type": "char*",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Footer. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD307B",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD307C": {
          "name": "SCOOBY_MENU_TOGGLE_IMG",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "label"
              },
              {
                  "type": "int",
                  "name": "imgOff"
              },
              {
                  "type": "int",
                  "name": "imgOn"
              },
              {
                  "type": "int",
                  "name": "cbEn"
              },
              {
                  "type": "int",
                  "name": "cbDis"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Toggle Img. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD307C",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD307D": {
          "name": "SCOOBY_MENU_BUTTON_WITH_ICON",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "label"
              },
              {
                  "type": "int",
                  "name": "img"
              },
              {
                  "type": "int",
                  "name": "cb"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Button With Icon. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD307D",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD307E": {
          "name": "SCOOBY_MENU_ROW_WITH_ICON",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "label"
              },
              {
                  "type": "int",
                  "name": "img"
              },
              {
                  "type": "int",
                  "name": "cb"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Row With Icon. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD307E",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3090": {
          "name": "SCOOBY_MENU_OVERLAY",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              },
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "w"
              },
              {
                  "type": "float",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Overlay. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3090",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3091": {
          "name": "SCOOBY_MENU_SET_THEME",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "uint32",
                  "name": "accent"
              },
              {
                  "type": "uint32",
                  "name": "bg"
              },
              {
                  "type": "uint32",
                  "name": "header"
              },
              {
                  "type": "uint32",
                  "name": "text"
              },
              {
                  "type": "uint32",
                  "name": "button"
              },
              {
                  "type": "uint32",
                  "name": "toggleOn"
              },
              {
                  "type": "uint32",
                  "name": "toggleOff"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Theme. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3091",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3092": {
          "name": "SCOOBY_MENU_SET_DRAGGABLE",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "val"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Draggable. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3092",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3093": {
          "name": "SCOOBY_MENU_SET_RESIZABLE",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "val"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Resizable. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3093",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3094": {
          "name": "SCOOBY_MENU_GET_POSITION",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Get Position. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3094",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3095": {
          "name": "SCOOBY_MENU_GET_SIZE",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Get Size. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3095",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3096": {
          "name": "SCOOBY_MENU_WINDOW_IS_OPEN",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Window Is Open. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3096",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3097": {
          "name": "SCOOBY_MENU_SET_OPEN",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "val"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Open. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3097",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3098": {
          "name": "SCOOBY_MENU_SHOW_DIALOG",
          "params": [
              {
                  "type": "char*",
                  "name": "title"
              },
              {
                  "type": "char*",
                  "name": "message"
              },
              {
                  "type": "char*",
                  "name": "buttons"
              },
              {
                  "type": "int",
                  "name": "cbId"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Show Dialog. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3098",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3099": {
          "name": "SCOOBY_MENU_SET_BORDERLESS",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "val"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Borderless. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3099",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD309A": {
          "name": "SCOOBY_MENU_FOCUS",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Focus. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD309A",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD309B": {
          "name": "SCOOBY_MENU_POLL_ARG",
          "params": [],
          "results": "int",
          "description": "Scooby Menu Poll Arg. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD309B",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30C0": {
          "name": "SCOOBY_MENU_SET_OPEN_KEY",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "vk"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Open Key. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30C0",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30C1": {
          "name": "SCOOBY_MENU_SET_CLOSE_KEY",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "vk"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Close Key. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30C1",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30C2": {
          "name": "SCOOBY_MENU_SET_TOGGLE_KEY",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "vk"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Toggle Key. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30C2",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30C3": {
          "name": "SCOOBY_MENU_SET_LINKED_TO_MAIN_MENU",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "val"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Linked To Main Menu. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30C3",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30C4": {
          "name": "SCOOBY_MENU_SET_CLOSE_BUTTON",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              },
              {
                  "type": "int",
                  "name": "val"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Set Close Button. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30C4",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D0": {
          "name": "SCOOBY_LAY_BEGIN_COLUMNS",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "int",
                  "name": "n"
              },
              {
                  "type": "int",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Begin Columns. Registered RedM Scooby native.",
          "hash": "0xDEAD30D0",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D1": {
          "name": "SCOOBY_LAY_NEXT_COLUMN",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Next Column. Registered RedM Scooby native.",
          "hash": "0xDEAD30D1",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D2": {
          "name": "SCOOBY_LAY_END_COLUMNS",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lay End Columns. Registered RedM Scooby native.",
          "hash": "0xDEAD30D2",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D3": {
          "name": "SCOOBY_LAY_SET_COL_WIDTH",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "int",
                  "name": "idx"
              },
              {
                  "type": "float",
                  "name": "w"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Set Col Width. Registered RedM Scooby native.",
          "hash": "0xDEAD30D3",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D4": {
          "name": "SCOOBY_LAY_SAME_LINE",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "float",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Same Line. Registered RedM Scooby native.",
          "hash": "0xDEAD30D4",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D5": {
          "name": "SCOOBY_LAY_NEW_LINE",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lay New Line. Registered RedM Scooby native.",
          "hash": "0xDEAD30D5",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D6": {
          "name": "SCOOBY_LAY_INDENT",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "float",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Indent. Registered RedM Scooby native.",
          "hash": "0xDEAD30D6",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D7": {
          "name": "SCOOBY_LAY_UNINDENT",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "float",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Unindent. Registered RedM Scooby native.",
          "hash": "0xDEAD30D7",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D8": {
          "name": "SCOOBY_LAY_SPACING",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Spacing. Registered RedM Scooby native.",
          "hash": "0xDEAD30D8",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30D9": {
          "name": "SCOOBY_LAY_SEPARATOR",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Separator. Registered RedM Scooby native.",
          "hash": "0xDEAD30D9",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30DA": {
          "name": "SCOOBY_LAY_BEGIN_CHILD",
          "params": [
              {
                  "type": "int",
                  "name": "parent"
              },
              {
                  "type": "char*",
                  "name": "name"
              },
              {
                  "type": "float",
                  "name": "w"
              },
              {
                  "type": "float",
                  "name": "h"
              },
              {
                  "type": "int",
                  "name": "arg4"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Begin Child. Registered RedM Scooby native.",
          "hash": "0xDEAD30DA",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30DB": {
          "name": "SCOOBY_LAY_END_CHILD",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lay End Child. Registered RedM Scooby native.",
          "hash": "0xDEAD30DB",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30DC": {
          "name": "SCOOBY_LAY_BEGIN_PANEL",
          "params": [
              {
                  "type": "int",
                  "name": "parent"
              },
              {
                  "type": "char*",
                  "name": "name"
              },
              {
                  "type": "float",
                  "name": "w"
              },
              {
                  "type": "float",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Begin Panel. Registered RedM Scooby native.",
          "hash": "0xDEAD30DC",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30DD": {
          "name": "SCOOBY_LAY_END_PANEL",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lay End Panel. Registered RedM Scooby native.",
          "hash": "0xDEAD30DD",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30DE": {
          "name": "SCOOBY_LAY_GET_CURSOR",
          "params": [],
          "results": "int",
          "description": "Scooby Lay Get Cursor. Registered RedM Scooby native.",
          "hash": "0xDEAD30DE",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30DF": {
          "name": "SCOOBY_LAY_SET_CURSOR",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              }
          ],
          "results": "int",
          "description": "Scooby Lay Set Cursor. Registered RedM Scooby native.",
          "hash": "0xDEAD30DF",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30E0": {
          "name": "SCOOBY_LAY_GET_AVAIL",
          "params": [],
          "results": "int",
          "description": "Scooby Lay Get Avail. Registered RedM Scooby native.",
          "hash": "0xDEAD30E0",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30E1": {
          "name": "SCOOBY_LAY_GET_ITEM_RECT",
          "params": [],
          "results": "int",
          "description": "Scooby Lay Get Item Rect. Registered RedM Scooby native.",
          "hash": "0xDEAD30E1",
          "ns": "SCOOBY_LAYOUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F0": {
          "name": "SCOOBY_MENU_TREE_NODE",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "label"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Tree Node. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30F0",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F1": {
          "name": "SCOOBY_MENU_TREE_POP",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Tree Pop. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30F1",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F2": {
          "name": "SCOOBY_MENU_SELECTABLE",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "label"
              },
              {
                  "type": "int",
                  "name": "selected"
              },
              {
                  "type": "int",
                  "name": "arg3"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Selectable. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30F2",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F3": {
          "name": "SCOOBY_MENU_PROGRESS",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "float",
                  "name": "frac"
              },
              {
                  "type": "char*",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Progress. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30F3",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F4": {
          "name": "SCOOBY_MENU_COLOR_PICKER",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "label"
              },
              {
                  "type": "int",
                  "name": "r"
              },
              {
                  "type": "int",
                  "name": "g"
              },
              {
                  "type": "int",
                  "name": "b"
              },
              {
                  "type": "int",
                  "name": "a"
              },
              {
                  "type": "int",
                  "name": "cb"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Color Picker. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30F4",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F5": {
          "name": "SCOOBY_MENU_LIST_BOX",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "label"
              },
              {
                  "type": "int",
                  "name": "cb"
              },
              {
                  "type": "char*",
                  "name": "serialised"
              },
              {
                  "type": "int",
                  "name": "count"
              },
              {
                  "type": "int",
                  "name": "curIdx"
              },
              {
                  "type": "int",
                  "name": "heightItems"
              }
          ],
          "results": "int",
          "description": "Scooby Menu List Box. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30F5",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F6": {
          "name": "SCOOBY_MENU_MULTI_SLIDER",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "label"
              },
              {
                  "type": "int",
                  "name": "cb"
              },
              {
                  "type": "int",
                  "name": "count"
              },
              {
                  "type": "float",
                  "name": "v0"
              },
              {
                  "type": "float",
                  "name": "v1"
              },
              {
                  "type": "float",
                  "name": "v2"
              },
              {
                  "type": "float",
                  "name": "v3"
              },
              {
                  "type": "float",
                  "name": "minV"
              },
              {
                  "type": "float",
                  "name": "maxV"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Multi Slider. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30F6",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F7": {
          "name": "SCOOBY_MENU_IMAGE",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "int",
                  "name": "img"
              },
              {
                  "type": "float",
                  "name": "w"
              },
              {
                  "type": "float",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Image. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30F7",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F8": {
          "name": "SCOOBY_STYLE_PUSH_COLOR",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "int",
                  "name": "idx"
              },
              {
                  "type": "int",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Style Push Color. Registered RedM Scooby native.",
          "hash": "0xDEAD30F8",
          "ns": "SCOOBY_STYLE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30F9": {
          "name": "SCOOBY_STYLE_POP_COLOR",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "int",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Style Pop Color. Registered RedM Scooby native.",
          "hash": "0xDEAD30F9",
          "ns": "SCOOBY_STYLE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30FA": {
          "name": "SCOOBY_STYLE_PUSH_VAR",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "int",
                  "name": "idx"
              },
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "arg3"
              }
          ],
          "results": "int",
          "description": "Scooby Style Push Var. Registered RedM Scooby native.",
          "hash": "0xDEAD30FA",
          "ns": "SCOOBY_STYLE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30FB": {
          "name": "SCOOBY_STYLE_POP_VAR",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "int",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Style Pop Var. Registered RedM Scooby native.",
          "hash": "0xDEAD30FB",
          "ns": "SCOOBY_STYLE",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30FC": {
          "name": "SCOOBY_MENU_TOOLTIP",
          "params": [
              {
                  "type": "int",
                  "name": "widget"
              },
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Tooltip. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30FC",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30FD": {
          "name": "SCOOBY_MENU_HOVERED",
          "params": [
              {
                  "type": "int",
                  "name": "widget"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Hovered. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30FD",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30FE": {
          "name": "SCOOBY_MENU_CLICKED",
          "params": [
              {
                  "type": "int",
                  "name": "widget"
              },
              {
                  "type": "int",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Clicked. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30FE",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD30FF": {
          "name": "SCOOBY_MENU_TEXT_COLORED",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "int",
                  "name": "r"
              },
              {
                  "type": "int",
                  "name": "g"
              },
              {
                  "type": "int",
                  "name": "b"
              },
              {
                  "type": "int",
                  "name": "a"
              },
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Text Colored. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD30FF",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3100": {
          "name": "SCOOBY_MENU_TEXT_WRAPPED",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Text Wrapped. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3100",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3101": {
          "name": "SCOOBY_MENU_BULLET_TEXT",
          "params": [
              {
                  "type": "int",
                  "name": "group"
              },
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Menu Bullet Text. Script-owned ImGui menu/window helper used by helper.lua wrappers.",
          "hash": "0xDEAD3101",
          "ns": "SCOOBY_MENU",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3110": {
          "name": "SCOOBY_POOL_PLAYERS",
          "params": [],
          "results": "char*",
          "description": "Scooby Pool Players. Registered RedM Scooby native.",
          "hash": "0xDEAD3110",
          "ns": "SCOOBY_POOL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3111": {
          "name": "SCOOBY_POOL_PEDS",
          "params": [],
          "results": "char*",
          "description": "Scooby Pool Peds. Registered RedM Scooby native.",
          "hash": "0xDEAD3111",
          "ns": "SCOOBY_POOL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3112": {
          "name": "SCOOBY_POOL_VEHICLES",
          "params": [],
          "results": "char*",
          "description": "Scooby Pool Vehicles. Registered RedM Scooby native.",
          "hash": "0xDEAD3112",
          "ns": "SCOOBY_POOL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3113": {
          "name": "SCOOBY_POOL_ANIMALS",
          "params": [],
          "results": "char*",
          "description": "Scooby Pool Animals. Registered RedM Scooby native.",
          "hash": "0xDEAD3113",
          "ns": "SCOOBY_POOL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3114": {
          "name": "SCOOBY_POOL_OBJECTS",
          "params": [],
          "results": "char*",
          "description": "Scooby Pool Objects. Registered RedM Scooby native.",
          "hash": "0xDEAD3114",
          "ns": "SCOOBY_POOL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3115": {
          "name": "SCOOBY_POOL_PLAYER_BY_ID",
          "params": [
              {
                  "type": "int",
                  "name": "pid"
              }
          ],
          "results": "char*",
          "description": "Scooby Pool Player By Id. Registered RedM Scooby native.",
          "hash": "0xDEAD3115",
          "ns": "SCOOBY_POOL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3116": {
          "name": "SCOOBY_POOL_PED_BY_HANDLE",
          "params": [
              {
                  "type": "uint32",
                  "name": "h"
              }
          ],
          "results": "char*",
          "description": "Scooby Pool Ped By Handle. Registered RedM Scooby native.",
          "hash": "0xDEAD3116",
          "ns": "SCOOBY_POOL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3117": {
          "name": "SCOOBY_POOL_VEH_BY_HANDLE",
          "params": [
              {
                  "type": "uint32",
                  "name": "h"
              }
          ],
          "results": "char*",
          "description": "Scooby Pool Veh By Handle. Registered RedM Scooby native.",
          "hash": "0xDEAD3117",
          "ns": "SCOOBY_POOL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3130": {
          "name": "SCOOBY_ENT_POS",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "char*",
          "description": "Scooby Ent Pos. Registered RedM Scooby native.",
          "hash": "0xDEAD3130",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3131": {
          "name": "SCOOBY_ENT_ROT",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "char*",
          "description": "Scooby Ent Rot. Registered RedM Scooby native.",
          "hash": "0xDEAD3131",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3132": {
          "name": "SCOOBY_ENT_HEADING",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "float",
          "description": "Scooby Ent Heading. Registered RedM Scooby native.",
          "hash": "0xDEAD3132",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3133": {
          "name": "SCOOBY_ENT_HEALTH",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "char*",
          "description": "Scooby Ent Health. Registered RedM Scooby native.",
          "hash": "0xDEAD3133",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3134": {
          "name": "SCOOBY_ENT_ARMOR",
          "params": [],
          "results": "char*",
          "description": "Scooby Ent Armor. Registered RedM Scooby native.",
          "hash": "0xDEAD3134",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3135": {
          "name": "SCOOBY_ENT_MODEL",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "uint32",
          "description": "Scooby Ent Model. Registered RedM Scooby native.",
          "hash": "0xDEAD3135",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3136": {
          "name": "SCOOBY_ENT_SPEED",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "float",
          "description": "Scooby Ent Speed. Registered RedM Scooby native.",
          "hash": "0xDEAD3136",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3137": {
          "name": "SCOOBY_ENT_VEL",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "char*",
          "description": "Scooby Ent Vel. Registered RedM Scooby native.",
          "hash": "0xDEAD3137",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3138": {
          "name": "SCOOBY_ENT_IS_DEAD",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Ent Is Dead. Registered RedM Scooby native.",
          "hash": "0xDEAD3138",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3139": {
          "name": "SCOOBY_ENT_IS_ALIVE",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Ent Is Alive. Registered RedM Scooby native.",
          "hash": "0xDEAD3139",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD313A": {
          "name": "SCOOBY_ENT_IS_VISIBLE",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Ent Is Visible. Registered RedM Scooby native.",
          "hash": "0xDEAD313A",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD313B": {
          "name": "SCOOBY_ENT_BONE_POS",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              },
              {
                  "type": "char*",
                  "name": "sname"
              }
          ],
          "results": "char*",
          "description": "Scooby Ent Bone Pos. Registered RedM Scooby native.",
          "hash": "0xDEAD313B",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD313C": {
          "name": "SCOOBY_ENT_PLATE",
          "params": [],
          "results": "char*",
          "description": "Scooby Ent Plate. Registered RedM Scooby native.",
          "hash": "0xDEAD313C",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD313D": {
          "name": "SCOOBY_ENT_DRIVER",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Ent Driver. Registered RedM Scooby native.",
          "hash": "0xDEAD313D",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD313E": {
          "name": "SCOOBY_ENT_OCCUPANTS",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "char*",
          "description": "Scooby Ent Occupants. Registered RedM Scooby native.",
          "hash": "0xDEAD313E",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD313F": {
          "name": "SCOOBY_ENT_DIST",
          "params": [
              {
                  "type": "int",
                  "name": "h1"
              },
              {
                  "type": "int",
                  "name": "h2"
              },
              {
                  "type": "float",
                  "name": "arg2"
              },
              {
                  "type": "float",
                  "name": "arg3"
              }
          ],
          "results": "float",
          "description": "Scooby Ent Dist. Registered RedM Scooby native.",
          "hash": "0xDEAD313F",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3140": {
          "name": "SCOOBY_ENT_DIST_LOCAL",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "float",
          "description": "Scooby Ent Dist Local. Registered RedM Scooby native.",
          "hash": "0xDEAD3140",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3141": {
          "name": "SCOOBY_ENT_IS_PLAYER",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Ent Is Player. Registered RedM Scooby native.",
          "hash": "0xDEAD3141",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3142": {
          "name": "SCOOBY_ENT_IS_ANIMAL",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Ent Is Animal. Registered RedM Scooby native.",
          "hash": "0xDEAD3142",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3143": {
          "name": "SCOOBY_ENT_IS_VEHICLE",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Ent Is Vehicle. Registered RedM Scooby native.",
          "hash": "0xDEAD3143",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3144": {
          "name": "SCOOBY_ENT_IS_OBJECT",
          "params": [
              {
                  "type": "int",
                  "name": "h"
              }
          ],
          "results": "int",
          "description": "Scooby Ent Is Object. Registered RedM Scooby native.",
          "hash": "0xDEAD3144",
          "ns": "SCOOBY_ENTITY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3150": {
          "name": "SCOOBY_MATH_DIST",
          "params": [
              {
                  "type": "float",
                  "name": "x1"
              },
              {
                  "type": "float",
                  "name": "arg1"
              },
              {
                  "type": "float",
                  "name": "arg2"
              },
              {
                  "type": "float",
                  "name": "x2"
              },
              {
                  "type": "float",
                  "name": "arg4"
              },
              {
                  "type": "float",
                  "name": "arg5"
              }
          ],
          "results": "float",
          "description": "Scooby Math Dist. Registered RedM Scooby native.",
          "hash": "0xDEAD3150",
          "ns": "SCOOBY_MATH",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3151": {
          "name": "SCOOBY_MATH_LERP",
          "params": [
              {
                  "type": "float",
                  "name": "a"
              },
              {
                  "type": "float",
                  "name": "b"
              },
              {
                  "type": "float",
                  "name": "t"
              }
          ],
          "results": "float",
          "description": "Scooby Math Lerp. Registered RedM Scooby native.",
          "hash": "0xDEAD3151",
          "ns": "SCOOBY_MATH",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3152": {
          "name": "SCOOBY_MATH_NORM",
          "params": [
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "z"
              }
          ],
          "results": "char*",
          "description": "Scooby Math Norm. Registered RedM Scooby native.",
          "hash": "0xDEAD3152",
          "ns": "SCOOBY_MATH",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3153": {
          "name": "SCOOBY_MATH_LEN",
          "params": [
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "z"
              }
          ],
          "results": "float",
          "description": "Scooby Math Len. Registered RedM Scooby native.",
          "hash": "0xDEAD3153",
          "ns": "SCOOBY_MATH",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3154": {
          "name": "SCOOBY_MATH_ANGLE",
          "params": [
              {
                  "type": "float",
                  "name": "x1"
              },
              {
                  "type": "float",
                  "name": "arg1"
              },
              {
                  "type": "float",
                  "name": "arg2"
              },
              {
                  "type": "float",
                  "name": "x2"
              },
              {
                  "type": "float",
                  "name": "arg4"
              },
              {
                  "type": "float",
                  "name": "arg5"
              }
          ],
          "results": "float",
          "description": "Scooby Math Angle. Registered RedM Scooby native.",
          "hash": "0xDEAD3154",
          "ns": "SCOOBY_MATH",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3155": {
          "name": "SCOOBY_MATH_W2_S",
          "params": [
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "z"
              }
          ],
          "results": "char*",
          "description": "Scooby Math W2 S. Registered RedM Scooby native.",
          "hash": "0xDEAD3155",
          "ns": "SCOOBY_MATH",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3156": {
          "name": "SCOOBY_MATH_IS_IN_FOV",
          "params": [
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "z"
              },
              {
                  "type": "float",
                  "name": "arg3"
              }
          ],
          "results": "int",
          "description": "Scooby Math Is In Fov. Registered RedM Scooby native.",
          "hash": "0xDEAD3156",
          "ns": "SCOOBY_MATH",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3160": {
          "name": "SCOOBY_LOC_PLAYER_ID",
          "params": [],
          "results": "int",
          "description": "Scooby Loc Player Id. Registered RedM Scooby native.",
          "hash": "0xDEAD3160",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3161": {
          "name": "SCOOBY_LOC_PED",
          "params": [],
          "results": "int",
          "description": "Scooby Loc Ped. Registered RedM Scooby native.",
          "hash": "0xDEAD3161",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3162": {
          "name": "SCOOBY_LOC_POS",
          "params": [],
          "results": "char*",
          "description": "Scooby Loc Pos. Registered RedM Scooby native.",
          "hash": "0xDEAD3162",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3163": {
          "name": "SCOOBY_LOC_ROT",
          "params": [],
          "results": "char*",
          "description": "Scooby Loc Rot. Registered RedM Scooby native.",
          "hash": "0xDEAD3163",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3164": {
          "name": "SCOOBY_LOC_HEADING",
          "params": [],
          "results": "float",
          "description": "Scooby Loc Heading. Registered RedM Scooby native.",
          "hash": "0xDEAD3164",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3165": {
          "name": "SCOOBY_LOC_HEALTH",
          "params": [],
          "results": "char*",
          "description": "Scooby Loc Health. Registered RedM Scooby native.",
          "hash": "0xDEAD3165",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3166": {
          "name": "SCOOBY_LOC_VEHICLE",
          "params": [],
          "results": "int",
          "description": "Scooby Loc Vehicle. Registered RedM Scooby native.",
          "hash": "0xDEAD3166",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3167": {
          "name": "SCOOBY_LOC_IN_VEHICLE",
          "params": [],
          "results": "int",
          "description": "Scooby Loc In Vehicle. Registered RedM Scooby native.",
          "hash": "0xDEAD3167",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3168": {
          "name": "SCOOBY_LOC_IS_AIMING",
          "params": [],
          "results": "int",
          "description": "Scooby Loc Is Aiming. Registered RedM Scooby native.",
          "hash": "0xDEAD3168",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3169": {
          "name": "SCOOBY_LOC_IS_SHOOTING",
          "params": [],
          "results": "int",
          "description": "Scooby Loc Is Shooting. Registered RedM Scooby native.",
          "hash": "0xDEAD3169",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD316A": {
          "name": "SCOOBY_CAM_GET_POS",
          "params": [],
          "results": "char*",
          "description": "Scooby Cam Get Pos. Registered RedM Scooby native.",
          "hash": "0xDEAD316A",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD316B": {
          "name": "SCOOBY_CAM_GET_ROT",
          "params": [],
          "results": "char*",
          "description": "Scooby Cam Get Rot. Registered RedM Scooby native.",
          "hash": "0xDEAD316B",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD316C": {
          "name": "SCOOBY_CAM_GET_FOV",
          "params": [],
          "results": "float",
          "description": "Scooby Cam Get Fov. Registered RedM Scooby native.",
          "hash": "0xDEAD316C",
          "ns": "SCOOBY_LOCAL",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3180": {
          "name": "SCOOBY_KEY_DOWN",
          "params": [
              {
                  "type": "int",
                  "name": "vk"
              }
          ],
          "results": "int",
          "description": "Scooby Key Down. Registered RedM Scooby native.",
          "hash": "0xDEAD3180",
          "ns": "SCOOBY_INPUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3181": {
          "name": "SCOOBY_KEY_PRESSED",
          "params": [
              {
                  "type": "int",
                  "name": "vk"
              }
          ],
          "results": "int",
          "description": "Scooby Key Pressed. Registered RedM Scooby native.",
          "hash": "0xDEAD3181",
          "ns": "SCOOBY_INPUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3182": {
          "name": "SCOOBY_CTL_PRESSED",
          "params": [
              {
                  "type": "int",
                  "name": "control"
              },
              {
                  "type": "int",
                  "name": "action"
              }
          ],
          "results": "int",
          "description": "Scooby Ctl Pressed. Registered RedM Scooby native.",
          "hash": "0xDEAD3182",
          "ns": "SCOOBY_INPUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3183": {
          "name": "SCOOBY_CTL_JUST_PRESSED",
          "params": [
              {
                  "type": "int",
                  "name": "control"
              },
              {
                  "type": "int",
                  "name": "action"
              }
          ],
          "results": "int",
          "description": "Scooby Ctl Just Pressed. Registered RedM Scooby native.",
          "hash": "0xDEAD3183",
          "ns": "SCOOBY_INPUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3184": {
          "name": "SCOOBY_CTL_PRESS",
          "params": [
              {
                  "type": "int",
                  "name": "control"
              },
              {
                  "type": "int",
                  "name": "action"
              },
              {
                  "type": "int",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Ctl Press. Registered RedM Scooby native.",
          "hash": "0xDEAD3184",
          "ns": "SCOOBY_INPUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3185": {
          "name": "SCOOBY_GET_MOUSE",
          "params": [],
          "results": "char*",
          "description": "Scooby Get Mouse. Registered RedM Scooby native.",
          "hash": "0xDEAD3185",
          "ns": "SCOOBY_INPUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3186": {
          "name": "SCOOBY_MOUSE_DOWN",
          "params": [
              {
                  "type": "int",
                  "name": "b"
              }
          ],
          "results": "int",
          "description": "Scooby Mouse Down. Registered RedM Scooby native.",
          "hash": "0xDEAD3186",
          "ns": "SCOOBY_INPUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3187": {
          "name": "SCOOBY_AIMING_AT",
          "params": [],
          "results": "int",
          "description": "Scooby Aiming At. Registered RedM Scooby native.",
          "hash": "0xDEAD3187",
          "ns": "SCOOBY_INPUT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3190": {
          "name": "SCOOBY_CMB_NO_RECOIL",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Cmb No Recoil. Registered RedM Scooby native.",
          "hash": "0xDEAD3190",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3191": {
          "name": "SCOOBY_CMB_NO_SPREAD",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Cmb No Spread. Registered RedM Scooby native.",
          "hash": "0xDEAD3191",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3192": {
          "name": "SCOOBY_CMB_INF_AMMO",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Cmb Inf Ammo. Registered RedM Scooby native.",
          "hash": "0xDEAD3192",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3193": {
          "name": "SCOOBY_CMB_TRIGGER_BOT",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              },
              {
                  "type": "int",
                  "name": "onAim"
              },
              {
                  "type": "int",
                  "name": "onCross"
              },
              {
                  "type": "int",
                  "name": "delay"
              }
          ],
          "results": "int",
          "description": "Scooby Cmb Trigger Bot. Registered RedM Scooby native.",
          "hash": "0xDEAD3193",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3194": {
          "name": "SCOOBY_CMB_SHOOT_BULLET",
          "params": [
              {
                  "type": "float",
                  "name": "arg0"
              },
              {
                  "type": "float",
                  "name": "arg1"
              },
              {
                  "type": "float",
                  "name": "arg2"
              },
              {
                  "type": "float",
                  "name": "arg3"
              },
              {
                  "type": "float",
                  "name": "arg4"
              },
              {
                  "type": "float",
                  "name": "arg5"
              },
              {
                  "type": "uint32",
                  "name": "arg6"
              },
              {
                  "type": "int",
                  "name": "arg7"
              },
              {
                  "type": "int",
                  "name": "arg8"
              },
              {
                  "type": "float",
                  "name": "arg9"
              },
              {
                  "type": "int",
                  "name": "arg10"
              }
          ],
          "results": "int",
          "description": "Scooby Cmb Shoot Bullet. Registered RedM Scooby native.",
          "hash": "0xDEAD3194",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3195": {
          "name": "SCOOBY_CMB_SILENT_SET",
          "params": [
              {
                  "type": "uint32",
                  "name": "target"
              },
              {
                  "type": "int",
                  "name": "arg1"
              },
              {
                  "type": "int",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Cmb Silent Set. Registered RedM Scooby native.",
          "hash": "0xDEAD3195",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3196": {
          "name": "SCOOBY_CMB_SILENT_CLEAR",
          "params": [],
          "results": "int",
          "description": "Scooby Cmb Silent Clear. Registered RedM Scooby native.",
          "hash": "0xDEAD3196",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3197": {
          "name": "SCOOBY_CMB_AIM_TARGET",
          "params": [],
          "results": "int",
          "description": "Scooby Cmb Aim Target. Registered RedM Scooby native.",
          "hash": "0xDEAD3197",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3198": {
          "name": "SCOOBY_CMB_GIVE_WEAPON",
          "params": [
              {
                  "type": "uint32",
                  "name": "arg0"
              },
              {
                  "type": "int",
                  "name": "arg1"
              },
              {
                  "type": "int",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Cmb Give Weapon. Registered RedM Scooby native.",
          "hash": "0xDEAD3198",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3199": {
          "name": "SCOOBY_CMB_SET_AMMO",
          "params": [
              {
                  "type": "uint32",
                  "name": "arg0"
              },
              {
                  "type": "int",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Cmb Set Ammo. Registered RedM Scooby native.",
          "hash": "0xDEAD3199",
          "ns": "SCOOBY_COMBAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31B0": {
          "name": "SCOOBY_SPN_PED",
          "params": [
              {
                  "type": "uint32",
                  "name": "model"
              },
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "z"
              },
              {
                  "type": "float",
                  "name": "heading"
              }
          ],
          "results": "int",
          "description": "Queues a RedM ped spawn request and returns its request id. Pass the request id back to poll for the spawned handle.",
          "hash": "0xDEAD31B0",
          "ns": "SCOOBY_SPAWN",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31B1": {
          "name": "SCOOBY_SPN_VEHICLE",
          "params": [
              {
                  "type": "uint32",
                  "name": "model"
              },
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "z"
              },
              {
                  "type": "float",
                  "name": "heading"
              }
          ],
          "results": "int",
          "description": "Queues a RedM vehicle spawn request and returns its request id. Pass the request id back to poll for the spawned handle.",
          "hash": "0xDEAD31B1",
          "ns": "SCOOBY_SPAWN",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31B2": {
          "name": "SCOOBY_SPN_OBJECT",
          "params": [
              {
                  "type": "uint32",
                  "name": "model"
              },
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "z"
              },
              {
                  "type": "float",
                  "name": "heading"
              }
          ],
          "results": "int",
          "description": "Queues a RedM object spawn request and returns its request id. Pass the request id back to poll for the spawned handle.",
          "hash": "0xDEAD31B2",
          "ns": "SCOOBY_SPAWN",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31B3": {
          "name": "SCOOBY_SPN_ANIMAL",
          "params": [
              {
                  "type": "uint32",
                  "name": "model"
              },
              {
                  "type": "float",
                  "name": "x"
              },
              {
                  "type": "float",
                  "name": "y"
              },
              {
                  "type": "float",
                  "name": "z"
              },
              {
                  "type": "float",
                  "name": "heading"
              }
          ],
          "results": "int",
          "description": "Queues a RedM animal spawn request and returns its request id. Pass the request id back to poll for the spawned handle.",
          "hash": "0xDEAD31B3",
          "ns": "SCOOBY_SPAWN",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31B4": {
          "name": "SCOOBY_SPN_DELETE",
          "params": [
              {
                  "type": "int",
                  "name": "handle"
              }
          ],
          "results": "int",
          "description": "Queues a RedM entity delete request and returns its request id. Pass the request id back to poll for completion.",
          "hash": "0xDEAD31B4",
          "ns": "SCOOBY_SPAWN",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31B5": {
          "name": "SCOOBY_SPN_ASSERT_MODEL",
          "params": [
              {
                  "type": "uint32",
                  "name": "model"
              }
          ],
          "results": "int",
          "description": "Scooby Spn Assert Model. Registered RedM Scooby native.",
          "hash": "0xDEAD31B5",
          "ns": "SCOOBY_SPAWN",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D0": {
          "name": "SCOOBY_LFT_GOD_MODE",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lft God Mode. Registered RedM Scooby native.",
          "hash": "0xDEAD31D0",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D1": {
          "name": "SCOOBY_LFT_INVISIBLE",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lft Invisible. Registered RedM Scooby native.",
          "hash": "0xDEAD31D1",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D2": {
          "name": "SCOOBY_LFT_NO_CLIP",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lft No Clip. Registered RedM Scooby native.",
          "hash": "0xDEAD31D2",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D3": {
          "name": "SCOOBY_LFT_FREECAM",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lft Freecam. Registered RedM Scooby native.",
          "hash": "0xDEAD31D3",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D4": {
          "name": "SCOOBY_LFT_SPEED",
          "params": [
              {
                  "type": "float",
                  "name": "mult"
              }
          ],
          "results": "int",
          "description": "Scooby Lft Speed. Registered RedM Scooby native.",
          "hash": "0xDEAD31D4",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D5": {
          "name": "SCOOBY_LFT_TELEPORT",
          "params": [
              {
                  "type": "float",
                  "name": "arg0"
              },
              {
                  "type": "float",
                  "name": "arg1"
              },
              {
                  "type": "float",
                  "name": "arg2"
              }
          ],
          "results": "int",
          "description": "Scooby Lft Teleport. Registered RedM Scooby native.",
          "hash": "0xDEAD31D5",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D6": {
          "name": "SCOOBY_LFT_TP_WAYPOINT",
          "params": [],
          "results": "int",
          "description": "Scooby Lft Tp Waypoint. Registered RedM Scooby native.",
          "hash": "0xDEAD31D6",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D7": {
          "name": "SCOOBY_LFT_TP_ENTITY",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              },
              {
                  "type": "float",
                  "name": "arg1"
              },
              {
                  "type": "float",
                  "name": "arg2"
              },
              {
                  "type": "float",
                  "name": "arg3"
              }
          ],
          "results": "int",
          "description": "Scooby Lft Tp Entity. Registered RedM Scooby native.",
          "hash": "0xDEAD31D7",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D8": {
          "name": "SCOOBY_LFT_WANTED",
          "params": [
              {
                  "type": "int",
                  "name": "lv"
              }
          ],
          "results": "int",
          "description": "Scooby Lft Wanted. Registered RedM Scooby native.",
          "hash": "0xDEAD31D8",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31D9": {
          "name": "SCOOBY_LFT_SET_HEALTH",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Lft Set Health. Registered RedM Scooby native.",
          "hash": "0xDEAD31D9",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31DA": {
          "name": "SCOOBY_LFT_GIVE_ALL",
          "params": [],
          "results": "int",
          "description": "Scooby Lft Give All. Registered RedM Scooby native.",
          "hash": "0xDEAD31DA",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31DB": {
          "name": "SCOOBY_LFT_REMOVE_ALL",
          "params": [],
          "results": "int",
          "description": "Scooby Lft Remove All. Registered RedM Scooby native.",
          "hash": "0xDEAD31DB",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31DC": {
          "name": "SCOOBY_LFT_REPAIR_VEH",
          "params": [],
          "results": "int",
          "description": "Scooby Lft Repair Veh. Registered RedM Scooby native.",
          "hash": "0xDEAD31DC",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31DD": {
          "name": "SCOOBY_LFT_GET_SETTINGS",
          "params": [],
          "results": "int",
          "description": "Scooby Lft Get Settings. Registered RedM Scooby native.",
          "hash": "0xDEAD31DD",
          "ns": "SCOOBY_LOCAL_FEATURES",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31F0": {
          "name": "SCOOBY_AIM_SET_CAM",
          "params": [
              {
                  "type": "float",
                  "name": "pitch"
              },
              {
                  "type": "float",
                  "name": "heading"
              }
          ],
          "results": "int",
          "description": "Scooby Aim Set Cam. Registered RedM Scooby native.",
          "hash": "0xDEAD31F0",
          "ns": "SCOOBY_AIM",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31F1": {
          "name": "SCOOBY_AIM_LOS_ENTITY",
          "params": [
              {
                  "type": "int",
                  "name": "target"
              },
              {
                  "type": "int",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Aim Los Entity. Registered RedM Scooby native.",
          "hash": "0xDEAD31F1",
          "ns": "SCOOBY_AIM",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31F2": {
          "name": "SCOOBY_AIM_GET_BONE",
          "params": [
              {
                  "type": "int",
                  "name": "ped"
              },
              {
                  "type": "char*",
                  "name": "sname"
              }
          ],
          "results": "char*",
          "description": "Scooby Aim Get Bone. Registered RedM Scooby native.",
          "hash": "0xDEAD31F2",
          "ns": "SCOOBY_AIM",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD31F3": {
          "name": "SCOOBY_AIM_LOS_COORD",
          "params": [
              {
                  "type": "int",
                  "name": "from"
              },
              {
                  "type": "float",
                  "name": "tx"
              },
              {
                  "type": "float",
                  "name": "ty"
              },
              {
                  "type": "float",
                  "name": "tz"
              }
          ],
          "results": "int",
          "description": "Scooby Aim Los Coord. Registered RedM Scooby native.",
          "hash": "0xDEAD31F3",
          "ns": "SCOOBY_AIM",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3200": {
          "name": "SCOOBY_NUI_SET_FOCUS",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              },
              {
                  "type": "int",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Set Focus. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3200",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3201": {
          "name": "SCOOBY_NUI_HAS_FOCUS",
          "params": [],
          "results": "int",
          "description": "Scooby Nui Has Focus. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3201",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3202": {
          "name": "SCOOBY_NUI_SET_KEEP_INPUT",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Set Keep Input. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3202",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3203": {
          "name": "SCOOBY_NUI_REG_CALLBACK",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Reg Callback. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3203",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3204": {
          "name": "SCOOBY_NUI_UNREG_CALLBACK",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Unreg Callback. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3204",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3205": {
          "name": "SCOOBY_NUI_POLL_CALLBACK",
          "params": [],
          "results": "char*",
          "description": "Scooby Nui Poll Callback. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3205",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3206": {
          "name": "SCOOBY_NUI_REPLY_CALLBACK",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Reply Callback. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3206",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3207": {
          "name": "SCOOBY_NUI_ON_MESSAGE",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Nui On Message. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3207",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3208": {
          "name": "SCOOBY_NUI_POLL_MESSAGE",
          "params": [],
          "results": "char*",
          "description": "Scooby Nui Poll Message. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3208",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3209": {
          "name": "SCOOBY_NUI_SEND_MESSAGE",
          "params": [],
          "results": "int",
          "description": "Scooby Nui Send Message. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3209",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD320A": {
          "name": "SCOOBY_NUI_SEND_DUI_MESSAGE",
          "params": [],
          "results": "int",
          "description": "Scooby Nui Send Dui Message. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD320A",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD320B": {
          "name": "SCOOBY_NUI_EVAL_BEGIN",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Eval Begin. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD320B",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD320C": {
          "name": "SCOOBY_NUI_EVAL_POLL",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "char*",
          "description": "Scooby Nui Eval Poll. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD320C",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD320D": {
          "name": "SCOOBY_NUI_EVAL_ASYNC",
          "params": [
              {
                  "type": "int",
                  "name": "timeoutMs"
              }
          ],
          "results": "int",
          "description": "Starts an async NUI eval request and returns its request id for later polling.",
          "hash": "0xDEAD320D",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD320E": {
          "name": "SCOOBY_NUI_LOAD_STRING",
          "params": [
              {
                  "type": "char*",
                  "name": "html"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Load String. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD320E",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD320F": {
          "name": "SCOOBY_NUI_LOAD_FILE",
          "params": [
              {
                  "type": "char*",
                  "name": "path"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Load File. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD320F",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3210": {
          "name": "SCOOBY_NUI_LOAD_URL",
          "params": [
              {
                  "type": "char*",
                  "name": "url"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Load Url. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3210",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3211": {
          "name": "SCOOBY_NUI_RELOAD",
          "params": [],
          "results": "int",
          "description": "Scooby Nui Reload. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3211",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3212": {
          "name": "SCOOBY_NUI_IS_ALIVE",
          "params": [
              {
                  "type": "uint64",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Is Alive. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3212",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3213": {
          "name": "SCOOBY_NUI_GET_SIZE",
          "params": [
              {
                  "type": "uint64",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Get Size. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3213",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3214": {
          "name": "SCOOBY_NUI_SET_SIZE",
          "params": [
              {
                  "type": "uint64",
                  "name": "arg0"
              },
              {
                  "type": "int",
                  "name": "w"
              },
              {
                  "type": "int",
                  "name": "hh"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Set Size. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3214",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3215": {
          "name": "SCOOBY_NUI_SET_POSITION",
          "params": [
              {
                  "type": "uint64",
                  "name": "arg0"
              },
              {
                  "type": "int",
                  "name": "x"
              },
              {
                  "type": "int",
                  "name": "y"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Set Position. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3215",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3216": {
          "name": "SCOOBY_NUI_OPEN_DEV_TOOLS",
          "params": [],
          "results": "int",
          "description": "Scooby Nui Open Dev Tools. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3216",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3217": {
          "name": "SCOOBY_NUI_CLOSE_DEV_TOOLS",
          "params": [],
          "results": "int",
          "description": "Scooby Nui Close Dev Tools. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3217",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3218": {
          "name": "SCOOBY_NUI_LAST_ERROR",
          "params": [],
          "results": "char*",
          "description": "Scooby Nui Last Error. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3218",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3219": {
          "name": "SCOOBY_NUI_SET_STREAM_PROOF",
          "params": [
              {
                  "type": "uint64",
                  "name": "arg0"
              },
              {
                  "type": "int",
                  "name": "v"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Set Stream Proof. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD3219",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD321A": {
          "name": "SCOOBY_NUI_GET_STREAM_PROOF",
          "params": [
              {
                  "type": "uint64",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Nui Get Stream Proof. NUI/DUI bridge helper for focus, callbacks, messages, eval, lifecycle, or stream-proof state.",
          "hash": "0xDEAD321A",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3230": {
          "name": "SCOOBY_JSON_ENCODE",
          "params": [],
          "results": "int",
          "description": "Scooby Json Encode. Registered RedM Scooby native.",
          "hash": "0xDEAD3230",
          "ns": "SCOOBY_JSON",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3231": {
          "name": "SCOOBY_JSON_DECODE",
          "params": [],
          "results": "int",
          "description": "Scooby Json Decode. Registered RedM Scooby native.",
          "hash": "0xDEAD3231",
          "ns": "SCOOBY_JSON",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3232": {
          "name": "SCOOBY_JSON_IS_VALID",
          "params": [
              {
                  "type": "char*",
                  "name": "s"
              }
          ],
          "results": "int",
          "description": "Scooby Json Is Valid. Registered RedM Scooby native.",
          "hash": "0xDEAD3232",
          "ns": "SCOOBY_JSON",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3233": {
          "name": "SCOOBY_JSON_PRETTY",
          "params": [],
          "results": "int",
          "description": "Scooby Json Pretty. Registered RedM Scooby native.",
          "hash": "0xDEAD3233",
          "ns": "SCOOBY_JSON",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3240": {
          "name": "SCOOBY_HTTP_BINARY_GET",
          "params": [
              {
                  "type": "char*",
                  "name": "url"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Http Binary Get. Registered RedM Scooby native.",
          "hash": "0xDEAD3240",
          "ns": "SCOOBY_HTTP_BINARY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3241": {
          "name": "SCOOBY_HTTP_BINARY_POST",
          "params": [
              {
                  "type": "char*",
                  "name": "url"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              },
              {
                  "type": "int",
                  "name": "arg2"
              },
              {
                  "type": "char*",
                  "name": "arg3"
              }
          ],
          "results": "int",
          "description": "Scooby Http Binary Post. Registered RedM Scooby native.",
          "hash": "0xDEAD3241",
          "ns": "SCOOBY_HTTP_BINARY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3242": {
          "name": "SCOOBY_HTTP_BINARY_POLL",
          "params": [],
          "results": "int",
          "description": "Scooby Http Binary Poll. Registered RedM Scooby native.",
          "hash": "0xDEAD3242",
          "ns": "SCOOBY_HTTP_BINARY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3243": {
          "name": "SCOOBY_HTTP_BINARY_STATUS",
          "params": [],
          "results": "int",
          "description": "Scooby Http Binary Status. Registered RedM Scooby native.",
          "hash": "0xDEAD3243",
          "ns": "SCOOBY_HTTP_BINARY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3244": {
          "name": "SCOOBY_HTTP_BINARY_LEN",
          "params": [],
          "results": "int",
          "description": "Scooby Http Binary Len. Registered RedM Scooby native.",
          "hash": "0xDEAD3244",
          "ns": "SCOOBY_HTTP_BINARY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3245": {
          "name": "SCOOBY_HTTP_BINARY_BYTE",
          "params": [
              {
                  "type": "int",
                  "name": "i"
              }
          ],
          "results": "int",
          "description": "Scooby Http Binary Byte. Registered RedM Scooby native.",
          "hash": "0xDEAD3245",
          "ns": "SCOOBY_HTTP_BINARY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3246": {
          "name": "SCOOBY_HTTP_BINARY_CHUNK",
          "params": [
              {
                  "type": "int",
                  "name": "off"
              },
              {
                  "type": "int",
                  "name": "arg1"
              }
          ],
          "results": "char*",
          "description": "Scooby Http Binary Chunk. Registered RedM Scooby native.",
          "hash": "0xDEAD3246",
          "ns": "SCOOBY_HTTP_BINARY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3250": {
          "name": "SCOOBY_SCHEME_REGISTER",
          "params": [
              {
                  "type": "char*",
                  "name": "key"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Registers an inline CEF scheme handler route for Scooby NUI/DUI content.",
          "hash": "0xDEAD3250",
          "ns": "SCOOBY_SCHEME",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3251": {
          "name": "SCOOBY_SCHEME_UNREGISTER",
          "params": [
              {
                  "type": "char*",
                  "name": "key"
              }
          ],
          "results": "int",
          "description": "Unregisters an inline CEF scheme handler route.",
          "hash": "0xDEAD3251",
          "ns": "SCOOBY_SCHEME",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3252": {
          "name": "SCOOBY_SCHEME_RESOLVE",
          "params": [
              {
                  "type": "char*",
                  "name": "uri"
              }
          ],
          "results": "char*",
          "description": "Resolves a registered CEF scheme handler route.",
          "hash": "0xDEAD3252",
          "ns": "SCOOBY_SCHEME",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3253": {
          "name": "SCOOBY_JS_BOOTSTRAP",
          "params": [],
          "results": "char*",
          "description": "Returns the JavaScript bootstrap body used by the Scooby NUI bridge.",
          "hash": "0xDEAD3253",
          "ns": "SCOOBY_NUI",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3260": {
          "name": "STREAMPROOF_IS_ACTIVE",
          "params": [],
          "results": "int",
          "description": "Streamproof Is Active. Script-side stream-proof state helper.",
          "hash": "0xDEAD3260",
          "ns": "SCOOBY_STREAMPROOF",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3261": {
          "name": "STREAMPROOF_GET_MODE",
          "params": [],
          "results": "int",
          "description": "Streamproof Get Mode. Script-side stream-proof state helper.",
          "hash": "0xDEAD3261",
          "ns": "SCOOBY_STREAMPROOF",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3262": {
          "name": "STREAMPROOF_SET_MODE",
          "params": [
              {
                  "type": "int",
                  "name": "m"
              }
          ],
          "results": "int",
          "description": "Streamproof Set Mode. Script-side stream-proof state helper.",
          "hash": "0xDEAD3262",
          "ns": "SCOOBY_STREAMPROOF",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3263": {
          "name": "STREAMPROOF_SET_ENABLED",
          "params": [
              {
                  "type": "int",
                  "name": "on"
              }
          ],
          "results": "int",
          "description": "Streamproof Set Enabled. Script-side stream-proof state helper.",
          "hash": "0xDEAD3263",
          "ns": "SCOOBY_STREAMPROOF",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3264": {
          "name": "STREAMPROOF_IS_HIDDEN",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Streamproof Is Hidden. Script-side stream-proof state helper.",
          "hash": "0xDEAD3264",
          "ns": "SCOOBY_STREAMPROOF",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3265": {
          "name": "STREAMPROOF_GET_OVERLAYS",
          "params": [],
          "results": "char*",
          "description": "Streamproof Get Overlays. Script-side stream-proof state helper.",
          "hash": "0xDEAD3265",
          "ns": "SCOOBY_STREAMPROOF",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3290": {
          "name": "SCOOBY_UI_REG_PAGE",
          "params": [
              {
                  "type": "char*",
                  "name": "arg0"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              },
              {
                  "type": "char*",
                  "name": "arg2"
              },
              {
                  "type": "int",
                  "name": "arg3"
              },
              {
                  "type": "int",
                  "name": "arg4"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Page. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3290",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3291": {
          "name": "SCOOBY_UI_REG_FEATURE",
          "params": [
              {
                  "type": "char*",
                  "name": "arg0"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              },
              {
                  "type": "char*",
                  "name": "arg2"
              },
              {
                  "type": "char*",
                  "name": "arg3"
              },
              {
                  "type": "int",
                  "name": "arg4"
              },
              {
                  "type": "int",
                  "name": "arg5"
              },
              {
                  "type": "int",
                  "name": "arg6"
              },
              {
                  "type": "int",
                  "name": "arg7"
              },
              {
                  "type": "int",
                  "name": "arg8"
              },
              {
                  "type": "char*",
                  "name": "arg9"
              },
              {
                  "type": "float",
                  "name": "arg10"
              },
              {
                  "type": "float",
                  "name": "arg11"
              },
              {
                  "type": "float",
                  "name": "arg12"
              },
              {
                  "type": "float",
                  "name": "arg13"
              },
              {
                  "type": "float",
                  "name": "arg14"
              },
              {
                  "type": "float",
                  "name": "arg15"
              },
              {
                  "type": "float",
                  "name": "arg16"
              },
              {
                  "type": "int",
                  "name": "arg17"
              },
              {
                  "type": "int",
                  "name": "arg18"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Feature. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3291",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3292": {
          "name": "SCOOBY_UI_REG_BANNER",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              },
              {
                  "type": "int",
                  "name": "arg1"
              },
              {
                  "type": "int",
                  "name": "arg2"
              },
              {
                  "type": "int",
                  "name": "arg3"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Banner. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3292",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3293": {
          "name": "SCOOBY_UI_REG_UNREG_FEATURE",
          "params": [
              {
                  "type": "char*",
                  "name": "arg0"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Unreg Feature. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3293",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3294": {
          "name": "SCOOBY_UI_REG_UNREG_PAGE",
          "params": [
              {
                  "type": "char*",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Unreg Page. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3294",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3295": {
          "name": "SCOOBY_UI_REG_UNREG_OWNER",
          "params": [
              {
                  "type": "int",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Unreg Owner. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3295",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3296": {
          "name": "SCOOBY_UI_REG_REFRESH",
          "params": [],
          "results": "int",
          "description": "Scooby Ui Reg Refresh. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3296",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3297": {
          "name": "SCOOBY_UI_REG_CUR_SURFACE",
          "params": [],
          "results": "int",
          "description": "Scooby Ui Reg Cur Surface. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3297",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3298": {
          "name": "SCOOBY_UI_REG_POLL",
          "params": [],
          "results": "int",
          "description": "Scooby Ui Reg Poll. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3298",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD3299": {
          "name": "SCOOBY_UI_REG_POLL_PAGE",
          "params": [],
          "results": "char*",
          "description": "Scooby Ui Reg Poll Page. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD3299",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD329A": {
          "name": "SCOOBY_UI_REG_POLL_FEATURE",
          "params": [],
          "results": "char*",
          "description": "Scooby Ui Reg Poll Feature. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD329A",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD329B": {
          "name": "SCOOBY_UI_REG_POLL_ARG_F",
          "params": [],
          "results": "float",
          "description": "Scooby Ui Reg Poll Arg F. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD329B",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD329C": {
          "name": "SCOOBY_UI_REG_POLL_ARG_I",
          "params": [],
          "results": "int",
          "description": "Scooby Ui Reg Poll Arg I. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD329C",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD329D": {
          "name": "SCOOBY_UI_REG_SET_VALUE_B",
          "params": [
              {
                  "type": "char*",
                  "name": "p"
              },
              {
                  "type": "char*",
                  "name": "f"
              },
              {
                  "type": "int",
                  "name": "v"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Set Value B. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD329D",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD329E": {
          "name": "SCOOBY_UI_REG_SET_VALUE_F",
          "params": [
              {
                  "type": "char*",
                  "name": "p"
              },
              {
                  "type": "char*",
                  "name": "f"
              },
              {
                  "type": "float",
                  "name": "v"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Set Value F. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD329E",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD329F": {
          "name": "SCOOBY_UI_REG_SET_VALUE_I",
          "params": [
              {
                  "type": "char*",
                  "name": "p"
              },
              {
                  "type": "char*",
                  "name": "f"
              },
              {
                  "type": "int",
                  "name": "v"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Set Value I. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD329F",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32A0": {
          "name": "SCOOBY_UI_REG_SET_VISIBLE",
          "params": [
              {
                  "type": "char*",
                  "name": "p"
              },
              {
                  "type": "char*",
                  "name": "f"
              },
              {
                  "type": "int",
                  "name": "v"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Set Visible. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD32A0",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32A1": {
          "name": "SCOOBY_UI_REG_REQUEST_REFRESH",
          "params": [],
          "results": "int",
          "description": "Scooby Ui Reg Request Refresh. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD32A1",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32A2": {
          "name": "SCOOBY_UI_REG_COUNT_PAGES",
          "params": [],
          "results": "int",
          "description": "Scooby Ui Reg Count Pages. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD32A2",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32A3": {
          "name": "SCOOBY_UI_REG_COUNT_FEATURES",
          "params": [
              {
                  "type": "char*",
                  "name": "arg0"
              }
          ],
          "results": "int",
          "description": "Scooby Ui Reg Count Features. Unified UI registry helper for script-owned pages and feature rows.",
          "hash": "0xDEAD32A3",
          "ns": "SCOOBY_UI_REGISTRY",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32C0": {
          "name": "SCOOBY_CHAT_SEND",
          "params": [
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Chat Send. Registered RedM Scooby native.",
          "hash": "0xDEAD32C0",
          "ns": "SCOOBY_CHAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32C1": {
          "name": "SCOOBY_CHAT_SEND_SERVER",
          "params": [
              {
                  "type": "char*",
                  "name": "text"
              }
          ],
          "results": "int",
          "description": "Scooby Chat Send Server. Registered RedM Scooby native.",
          "hash": "0xDEAD32C1",
          "ns": "SCOOBY_CHAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32C2": {
          "name": "SCOOBY_CHAT_SEND_PRIVATE",
          "params": [
              {
                  "type": "int",
                  "name": "sid"
              },
              {
                  "type": "char*",
                  "name": "arg1"
              }
          ],
          "results": "int",
          "description": "Scooby Chat Send Private. Registered RedM Scooby native.",
          "hash": "0xDEAD32C2",
          "ns": "SCOOBY_CHAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32C3": {
          "name": "SCOOBY_CHAT_REG_CMD",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Chat Reg Cmd. Registered RedM Scooby native.",
          "hash": "0xDEAD32C3",
          "ns": "SCOOBY_CHAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32C4": {
          "name": "SCOOBY_CHAT_UNREG_CMD",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Chat Unreg Cmd. Registered RedM Scooby native.",
          "hash": "0xDEAD32C4",
          "ns": "SCOOBY_CHAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32C5": {
          "name": "SCOOBY_CHAT_ON_MESSAGE",
          "params": [
              {
                  "type": "int",
                  "name": "on"
              }
          ],
          "results": "int",
          "description": "Scooby Chat On Message. Registered RedM Scooby native.",
          "hash": "0xDEAD32C5",
          "ns": "SCOOBY_CHAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32C6": {
          "name": "SCOOBY_CHAT_ON_COMMAND",
          "params": [
              {
                  "type": "int",
                  "name": "on"
              }
          ],
          "results": "int",
          "description": "Scooby Chat On Command. Registered RedM Scooby native.",
          "hash": "0xDEAD32C6",
          "ns": "SCOOBY_CHAT",
          "apiset": "client",
          "build": "scooby-redm"
      },
      "0xDEAD32C7": {
          "name": "SCOOBY_CHAT_HAS_CMD",
          "params": [
              {
                  "type": "char*",
                  "name": "name"
              }
          ],
          "results": "int",
          "description": "Scooby Chat Has Cmd. Registered RedM Scooby native.",
          "hash": "0xDEAD32C7",
          "ns": "SCOOBY_CHAT",
          "apiset": "client",
          "build": "scooby-redm"
      }
  };

  function injectScooby(natives) {
    var namespaces = {};

    for (var hash in SCOOBY_DATA) {
      var n = SCOOBY_DATA[hash];
      if (!natives[n.ns]) natives[n.ns] = {};
      natives[n.ns][hash] = n;
      namespaces[n.ns] = true;
    }

    console.log("[scooby-natives] injected " + Object.keys(namespaces).length + " namespaces with " + Object.keys(SCOOBY_DATA).length + " custom natives");
  }

  function waitAndInject() {
    var natives = window.__NATIVES__;
    if (natives && typeof natives.then === 'function') {
      window.__NATIVES__ = natives.then(function(data) {
        injectScooby(data);
        return data;
      });
    } else if (natives && typeof natives === 'object') {
      injectScooby(natives);
    } else {
      setTimeout(waitAndInject, 10);
    }
  }

  waitAndInject();
})();
