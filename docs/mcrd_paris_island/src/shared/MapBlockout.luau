--[[
	MapBlockout — stamps placeholder footprints for the real MCRD Parris Island
	landmarks into the Workspace, so we detail each one on top instead of
	building on an empty baseplate.

	HOW TO USE (in Roblox Studio, edit mode, with Rojo connected):
	  1. View tab -> Command Bar
	  2. Paste and press Enter:
	       require(game.ReplicatedStorage.Shared.MapBlockout).build()
	  3. A "MapBlockout" folder appears in Workspace with labeled gray blocks.
	     Move/resize them to match the satellite photo, then build real
	     buildings in their place. Delete a block when its building is done.

	To remove everything it made:
	       require(game.ReplicatedStorage.Shared.MapBlockout).clear()

	Positions are rough relative placement at a shrunk scale (~1600 studs
	across), NOT exact — adjust against the satellite reference.
]]

local MapBlockout = {}

local FOLDER_NAME = "MapBlockout"

local GRAY = Color3.fromRGB(130, 130, 130)
local ROAD = Color3.fromRGB(55, 55, 55)
local GOLD = Color3.fromRGB(230, 190, 40)
local BRICK = Color3.fromRGB(160, 95, 70)

-- name, footprint size (studs), position of footprint center, color
local LANDMARKS = {
	{ name = "Causeway (entrance road)", size = Vector3.new(500, 1, 30), pos = Vector3.new(-750, 0, 0), color = ROAD },
	{ name = "Main Gate", size = Vector3.new(40, 15, 40), pos = Vector3.new(-480, 0, 0), color = BRICK },
	{ name = "Receiving Building", size = Vector3.new(90, 25, 50), pos = Vector3.new(-320, 0, -40), color = GRAY },
	{ name = "YELLOW FOOTPRINTS", size = Vector3.new(30, 0.5, 20), pos = Vector3.new(-320, 0, 10), color = GOLD },
	{ name = "Parade Deck (the Grinder)", size = Vector3.new(320, 0.5, 220), pos = Vector3.new(0, 0, 0), color = Color3.fromRGB(90, 90, 90) },
	{ name = "Iron Mike Statue", size = Vector3.new(10, 20, 10), pos = Vector3.new(-90, 0, -130), color = Color3.fromRGB(80, 70, 50) },
	{ name = "Barracks - 1st Recruit Training Bn", size = Vector3.new(140, 30, 50), pos = Vector3.new(-120, 0, -220), color = BRICK },
	{ name = "Barracks - 2nd Recruit Training Bn", size = Vector3.new(140, 30, 50), pos = Vector3.new(60, 0, -220), color = BRICK },
	{ name = "Barracks - 3rd Recruit Training Bn", size = Vector3.new(140, 30, 50), pos = Vector3.new(240, 0, -220), color = BRICK },
	{ name = "Mess Hall", size = Vector3.new(100, 20, 70), pos = Vector3.new(240, 0, -80), color = GRAY },
	{ name = "Chapel", size = Vector3.new(50, 35, 80), pos = Vector3.new(280, 0, 80), color = Color3.fromRGB(200, 200, 190) },
	{ name = "Confidence Course", size = Vector3.new(200, 1, 120), pos = Vector3.new(-60, 0, 260), color = Color3.fromRGB(110, 140, 80) },
	{ name = "Rifle Range", size = Vector3.new(260, 1, 160), pos = Vector3.new(320, 0, 340), color = Color3.fromRGB(120, 130, 90) },
}

local function addLabel(part: Part, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(250, 45)
	gui.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 800

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = gui

	gui.Parent = part
end

function MapBlockout.build()
	MapBlockout.clear()

	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME

	for _, lm in LANDMARKS do
		local part = Instance.new("Part")
		part.Name = lm.name
		part.Anchored = true
		part.Size = lm.size
		part.Position = lm.pos + Vector3.new(0, lm.size.Y / 2, 0)
		part.Color = lm.color
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		addLabel(part, lm.name)
		part.Parent = folder
	end

	folder.Parent = workspace
	print(("MapBlockout: placed %d landmark footprints in Workspace.%s"):format(#LANDMARKS, FOLDER_NAME))
end

function MapBlockout.clear()
	local existing = workspace:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
		print("MapBlockout: cleared.")
	end
end

return MapBlockout
