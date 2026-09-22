--[[
	Plays the sounds configured in Shared/Config/Sounds.luau. Sounds with no id are skipped.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundsConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.Sounds)

local Sound = {}

local templates: { [string]: Sound } = {}
local folder: Folder? = nil

local function getTemplate(name: string): Sound?
	local existing = templates[name]
	if existing then
		return existing
	end
	local config = (SoundsConfig :: any)[name]
	if not config or config.Id == "" then
		return nil
	end
	if not folder then
		local created = Instance.new("Folder")
		created.Name = "VermeilSounds"
		created.Parent = SoundService
		folder = created
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = config.Id
	sound.Volume = config.Volume
	sound.Parent = folder
	templates[name] = sound
	return sound
end

export type Options = { Pitch: number?, Volume: number? }

function Sound.play(name: string, options: Options?): Sound?
	local template = getTemplate(name)
	if not template then
		return nil
	end
	local sound = template:Clone()
	if options then
		sound.PlaybackSpeed = options.Pitch or 1
		sound.Volume = template.Volume * (options.Volume or 1)
	end
	sound.Parent = template.Parent
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	task.delay(math.max(sound.TimeLength, 1) / sound.PlaybackSpeed + 10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
	return sound
end

-- Starts a looping sound; call the returned function to stop it.
function Sound.loop(name: string, options: Options?): () -> ()
	local template = getTemplate(name)
	if not template then
		return function() end
	end
	local sound = template:Clone()
	sound.Looped = true
	if options then
		sound.PlaybackSpeed = options.Pitch or 1
		sound.Volume = template.Volume * (options.Volume or 1)
	end
	sound.Parent = template.Parent
	sound:Play()
	return function()
		sound:Stop()
		sound:Destroy()
	end
end

function Sound.preload()
	for name in SoundsConfig do
		getTemplate(name)
	end
end

return Sound
