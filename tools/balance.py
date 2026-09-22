#!/usr/bin/env python3
"""
Economy checker for the pure shared modules (Config/*, Catalog, Roller, Format).

Bundles them into one Luau script with a fake `script` tree, then runs
tools/balance_driver.luau with the `luau` CLI (https://github.com/luau-lang/luau/releases).

    python3 tools/balance.py                 # EV table + roll check + progression sim
    python3 tools/balance.py --quick         # EV table only
    LUAU=/path/to/luau python3 tools/balance.py

Nothing here runs inside Roblox; it only reads the same config the game uses.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHARED = os.path.join(ROOT, "src", "shared")
MODULES = [
    "Config/Rarities",
    "Config/Brands",
    "Config/Items",
    "Config/Mutations",
    "Config/Cases",
    "Config/GameConfig",
    "Catalog",
    "Roller",
    "Format",
]

PRELUDE = r"""
Color3 = { fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end }

local __Node = {}
__Node.__index = function(self, key)
	local child = rawget(self, "__children")[key]
	if child == nil then
		error("fake instance '" .. rawget(self, "Name") .. "' has no child '" .. tostring(key) .. "'", 2)
	end
	return child
end
local function __node(name, parent)
	local node = setmetatable({ Name = name, Parent = parent, __children = {} }, __Node)
	if parent then
		rawget(parent, "__children")[name] = node
	end
	return node
end
local __cache = {}
local function require(node)
	local cached = __cache[node]
	if cached == nil then
		cached = rawget(node, "__load")(node)
		__cache[node] = cached
	end
	return cached
end
local __shared = __node("Shared", nil)
local __config = __node("Config", __shared)
"""


def module_source(rel):
    with open(os.path.join(SHARED, rel + ".luau"), encoding="utf-8") as f:
        source = f.read()
    # Type exports are only legal at the top level; inside the wrapper they become local types.
    return re.sub(r"^export type", "type", source, flags=re.M)


def bundle(driver_path):
    parts = [PRELUDE]
    for rel in MODULES:
        folder, _, name = rel.rpartition("/")
        parent = "__config" if folder == "Config" else "__shared"
        var = "__m_" + name
        parts.append(f"local {var} = __node({name!r}, {parent})")
        parts.append(f"rawset({var}, '__load', function(script)\n{module_source(rel)}\nend)")
    parts.append("local Shared = __shared")
    with open(driver_path, encoding="utf-8") as f:
        parts.append(f.read())
    return "\n".join(parts)


def main():
    luau = os.environ.get("LUAU", "luau")
    driver = os.path.join(ROOT, "tools", "balance_driver.luau")
    source = bundle(driver)
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False, encoding="utf-8") as f:
        f.write(source)
        path = f.name
    try:
        args = [luau, "-O2", path, "-a"] + sys.argv[1:]
        return subprocess.call(args)
    except FileNotFoundError:
        print("Could not find the luau CLI. Install it or set LUAU=/path/to/luau.", file=sys.stderr)
        return 1
    finally:
        os.unlink(path)


if __name__ == "__main__":
    sys.exit(main())
