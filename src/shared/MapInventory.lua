--!strict
--[[
	MapInventory -- prints what is in the Workspace so the map can be understood
	even where models are not named for what they are.

	HOW TO USE (Roblox Studio command bar, edit mode):
	    require(game.ReplicatedStorage.Shared.MapInventory).print()

	Then in the Output window: click inside it, Ctrl+A, Ctrl+C, and paste the
	result wherever it needs to go. Pass a depth to go one level deeper:
	    require(game.ReplicatedStorage.Shared.MapInventory).print(2)

	Each line: path [class] | descendants / parts / scripts | center x,y,z |
	footprint w x h x d (studs). Lines print in batches so Output keeps them all.
]]

local MapInventory = {}

local BATCH = 25

type Stats = {
	descendants: number,
	parts: number,
	scripts: number,
	min: Vector3?,
	max: Vector3?,
}

local function measure(inst: Instance): Stats
	local stats: Stats = { descendants = 0, parts = 0, scripts = 0, min = nil, max = nil }

	local function include(part: BasePart)
		local half = part.Size / 2
		local lo, hi = part.Position - half, part.Position + half
		stats.min = if stats.min then stats.min:Min(lo) else lo
		stats.max = if stats.max then stats.max:Max(hi) else hi
	end

	if inst:IsA("BasePart") then
		stats.parts += 1
		include(inst)
	end
	for _, d in inst:GetDescendants() do
		stats.descendants += 1
		if d:IsA("BasePart") then
			stats.parts += 1
			include(d)
		elseif d:IsA("LuaSourceContainer") then
			stats.scripts += 1
		end
	end
	return stats
end

local function describe(inst: Instance, path: string): string
	local s = measure(inst)
	local where = "-"
	local size = "-"
	if s.min and s.max then
		local center = (s.min + s.max) / 2
		local extent = s.max - s.min
		where = string.format("%.0f,%.0f,%.0f", center.X, center.Y, center.Z)
		size = string.format("%.0fx%.0fx%.0f", extent.X, extent.Y, extent.Z)
	end
	return string.format(
		"%s [%s] | %d desc / %d parts / %d scripts | center %s | size %s",
		path,
		inst.ClassName,
		s.descendants,
		s.parts,
		s.scripts,
		where,
		size
	)
end

local function collect(parent: Instance, path: string, depth: number, out: { string })
	for _, child in parent:GetChildren() do
		if child:IsA("Terrain") or child:IsA("Camera") then
			continue
		end
		local childPath = path .. "." .. child.Name
		table.insert(out, describe(child, childPath))
		if depth > 1 then
			collect(child, childPath, depth - 1, out)
		end
	end
end

function MapInventory.print(depth: number?)
	local lines: { string } = {}
	collect(workspace, "Workspace", depth or 1, lines)
	table.sort(lines)

	print(("=== MAP INVENTORY: %d items ==="):format(#lines))
	for i = 1, #lines, BATCH do
		print(table.concat(lines, "\n", i, math.min(i + BATCH - 1, #lines)))
	end
	print("=== END MAP INVENTORY ===")
end

return MapInventory
