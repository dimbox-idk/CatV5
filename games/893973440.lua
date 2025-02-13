local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local tweenService = cloneref(game:GetService('TweenService'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo

local store = {
	Beast = nil,
    Map = "",
    Computers = {
        Left = 0,
        Hacked = 0,
		Current = nil,
		Objects = {}
    },
    Status = "",
    Timer = "",
    Escaped = false,
    Captured = false,
    Progress = 0,
	Kills = 0,
	GameStarted = Instance.new("BindableEvent"),
	GameWon = Instance.new("BindableEvent"),
	ComputerHacked = Instance.new("BindableEvent"),
	PlayerFrozen = Instance.new("BindableEvent")
}
local ViewmodelTool
local ViewmodelMotor

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChild("Hammer")
end

local function notif(...) 
	return vape:CreateNotification(...) 
end

for _, v in {'HitBoxes', 'AutoRejoin'} do
	vape:Remove(v)
end

task.spawn(function()
    local teams = game:GetService("Teams")
    if not teams:FindFirstChild("Survivors") then
        local Survivors = Instance.new("Team", teams)
        Survivors.Name = "Survivors"
        Survivors.TeamColor = BrickColor.new("Bright blue")
        Survivors.AutoAssignable = true
    end
    if not teams:FindFirstChild("Beast") then
        local Beast = Instance.new("Team", teams)
        Beast.Name = "Beast"
        Beast.TeamColor = BrickColor.new("Bright red")
        Beast.AutoAssignable = true
    end
    local survivor = teams.Survivors
    local beast = teams.Beast
    vape:Clean(playersService.PlayerAdded:Connect(function(p)
        p.Team = survivor
    end))
	vape:Clean(workspace.DescendantAdded:Connect(function(v)
		if v.Name == "ComputerTable" then
			table.insert(store.Computers.Objects, v)
		end
	end))
	pcall(function()
		for i, v in replicatedStorage.CurrentMap.Value:GetChildren() do
			if v.Name == "ComputerTable" then
				table.insert(store.Computers.Objects, v)
			end
		end
	end)
	local oldescaped = false
	vape:Clean(replicatedStorage.GameStatus:GetPropertyChangedSignal("Value"):Connect(function()
		if replicatedStorage.GameStatus.Value:find("GAME STARTING") then
			store.GameStarted:Fire()
		elseif replicatedStorage.GameStatus.Value:find("GAME OVER") and store.Beast == lplr then
			store.GameWon:Fire()
		end
	end))
	vape:Clean(lplr.TempPlayerStatsModule.Escaped:GetPropertyChangedSignal("Value"):Connect(function()
		if lplr.TempPlayerStatsModule.Escaped.Value and oldescaped ~= lplr.TempPlayerStatsModule.Escaped.Value then
			store.GameWon:Fire()
		end
		oldescaped = lplr.TempPlayerStatsModule.Escaped.Value
	end))
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "FireClient" and checkcaller() then
			print("HEyyyyy")
            local args = {...}
            if args[2]:find("is frozen") and store.Beast == lplr then
                store.PlayerFrozen:Fire()
				print("hey")
            end
            return old(self, ...)
        end
        return old(self, ...)
    end)
    vape:Clean(runService.PreSimulation:Connect(function()
		if replicatedStorage.CurrentMap.Value.Name ~= store.Map.Name then
			table.clear(store.Computers.Objects)
		end
        store.Map = replicatedStorage.CurrentMap.Value
        store.Computers.Left = replicatedStorage.ComputersLeft.Value
        store.Status = replicatedStorage.GameStatus.Value
        store.Timer = replicatedStorage.GameTimer.Value
        store.Escaped = lplr.TempPlayerStatsModule.Escaped.Value
        store.Captured = lplr.TempPlayerStatsModule.Captured.Value
        store.Progress = lplr.TempPlayerStatsModule.ActionProgress.Value * 100

        for i, v in playersService:GetPlayers() do
            pcall(function()
                if store.Timer > 0 then
                    if v.Character:FindFirstChild("BeastPowers") == nil then
                        v.Team = survivor
                    else
                        v.Team = beast
						store.Beast = v
                        if v.Character:FindFirstChild("WarningNotifDetector") == nil then
                            local p = Instance.new("Part", v.Character)
                            p.Name = "WarningNotifDetector"
                        end
                    end
                else
                    v.Team = survivor
                    store.beast = nil
                end
            end)
        end
    end))
end)

local kills = sessioninfo:AddItem('Kills')
local comps = sessioninfo:AddItem('Computers')
local wins = sessioninfo:AddItem('Wins')
local games = sessioninfo:AddItem('Games')
local credits = sessioninfo:AddItem('Credits gained')
local levels = sessioninfo:AddItem('Levels gained')

sessioninfo:AddItem('Map', 0, function()
	return store.Map and string.split(tostring(store.Map):gsub("By", "by"), " by ")[1] or 'Camp Lapis'
end, false)

local oldcredits = lplr.SavedPlayerStatsModule.Credits.Value
vape:Clean(lplr.SavedPlayerStatsModule.Credits:GetPropertyChangedSignal("Value"):Connect(function()
	oldcredits = lplr.SavedPlayerStatsModule.Credits.Value
	if lplr.SavedPlayerStatsModule.Credits.Value > oldcredits then
		credits:Increment(lplr.SavedPlayerStatsModule.Credits.Value - oldcredits)
	end
end))

local oldlevel = lplr.SavedPlayerStatsModule.Level.Value
vape:Clean(lplr.SavedPlayerStatsModule.Level:GetPropertyChangedSignal("Value"):Connect(function()
	oldlevel = lplr.SavedPlayerStatsModule.Level.Value
	if lplr.SavedPlayerStatsModule.Level.Value > oldlevel then
		levels:Increment(lplr.SavedPlayerStatsModule.Level.Value - oldlevel)
	end
end))

vape:Clean(store.GameStarted.Event:Connect(function()
	games:Increment()
end))
vape:Clean(store.GameWon.Event:Connect(function()
	wins:Increment()
	if sessioninfo.Objects['Games'].Value < sessioninfo.Objects['Wins'].Value then
		games:Increment(sessioninfo.Objects['Wins'].Value - sessioninfo.Objects['Games'].Value)
	end
end))
vape:Clean(store.ComputerHacked.Event:Connect(function()
	comps:Increment()
end))
vape:Clean(store.PlayerFrozen.Event:Connect(function()
	kills:Increment()
end))

run(function()
	local Killaura
	local Targets
	local CPS
	local SwingRange
	local FaceTarget
	local AttackRange
	local AngleSlider
	local Max
	local Mouse
	local Swing
	local BoxSwingColor
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
    local LegitAura
	local Rope
	local Particles, Boxes, AttackDelay, SwingDelay, ClickDelay = {}, {}, tick(), tick(), tick()

	local function getAttackData()
		if Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end
		if LegitAura.Enabled then 
			if ClickDelay < tick() then return false end
		end
		
		return getTool()
	end

    Killaura = vape.Categories.Blatant:CreateModule({
        Name = "Killaura",
        Tooltip = "Automatically hit people near you.",
        Function = function(callback: boolean)
            if callback then
                repeat
                    local plrs = entitylib.AllPosition({
                        Range = SwingRange.Value,
                        Wallcheck = Targets.Walls.Enabled or nil,
                        Part = 'RootPart',
                        Players = Targets.Players.Enabled,
                        NPCs = Targets.NPCs.Enabled,
                        Limit = Max.Value
                    })

                    if #plrs > 0 then
                        local selfpos = entitylib.character.RootPart.Position
                        local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)

                        for _, v in plrs do
                            if store.Beast == lplr then
								local delta = (v.RootPart.Position - selfpos)
								local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
								if angle > (math.rad(AngleSlider.Value) / 2) then continue end
								targetinfo.Targets[v] = tick() + 1

								local tool = getAttackData()
								
								if not Swing.Enabled and SwingDelay < tick() and not target.Player.TempPlayerStatsModule.Ragdoll.Value and tool then
									SwingDelay = tick() + 0.7
									entitylib.character.Humanoid.Animator:LoadAnimation(tool.AnimSwing):Play()
								end

								if delta.Magnitude > AttackRange.Value then continue end
								if AttackDelay < tick() and tool then
									AttackDelay = tick() + (0.1 / CPS.GetRandomValue())
									if not target.Player.TempPlayerStatsModule.Ragdoll.Value then tool.HammerEvent:FireServer("HammerHit", v.Head) end
									if Rope.Enabled then tool.HammerEvent:FireServer("HammerTieUp", v.Head, lplr.Character.HumanoidRootPart.Position) end
									if FaceTarget.Enabled then
										lplr.Character:SetPrimaryPartCFrame(CFrame.new(lplr.Character.PrimaryPart.Position, Vector3.new(v.HumanoidRootPart.Position.X, lplr.Character.PrimaryPart.Position.Y, v.HumanoidRootPart.Position.Z)))
									end
								end
							end
						end
                    end

                    for i, v in Boxes do
                        v.Adornee = attacked[i] and attacked[i].Entity.RootPart or nil
                        if v.Adornee then
                            v.Color3 = Color3.fromHSV(attacked[i].Check.Hue, attacked[i].Check.Sat, attacked[i].Check.Value)
                            v.Transparency = 1 - attacked[i].Check.Opacity
                        end
                    end

                    for i, v in Particles do
                        v.Position = attacked[i] and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
                        v.Parent = attacked[i] and gameCamera or nil
                    end
                    task.wait()
                until not Killaura.Enabled
            else
				for _, v in Boxes do
					v.Adornee = nil
				end
				for _, v in Particles do
					v.Parent = nil
				end
            end
        end
    })
	Targets = Killaura:CreateTargets({Players = true})
	CPS = Killaura:CreateTwoSlider({
		Name = 'Attacks per Second',
		Min = 1,
		Max = 20,
		DefaultMin = 12,
		DefaultMax = 12
	})
	SwingRange = Killaura:CreateSlider({
		Name = 'Swing range',
		Min = 1,
		Max = 16,
		Default = 16,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AttackRange = Killaura:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 16,
		Default = 16,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AngleSlider = Killaura:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 360
	})
	Max = Killaura:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 10,
		Default = 10
	})
	Rope = Killaura:CreateToggle({Name = "Auto rope", Default = true})
	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
	Swing = Killaura:CreateToggle({Name = 'No Swing'})
	Killaura:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxSwingColor.Object.Visible = callback
			BoxAttackColor.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = vape.gui
					Boxes[i] = box
				end
			else
				for _, v in Boxes do
					v:Destroy()
				end
				table.clear(Boxes)
			end
		end
	})
	BoxSwingColor = Killaura:CreateColorSlider({
		Name = 'Target Color',
		Darker = true,
		DefaultHue = 0.6,
		DefaultOpacity = 0.5,
		Visible = false
	})
	BoxAttackColor = Killaura:CreateColorSlider({
		Name = 'Attack Color',
		Darker = true,
		DefaultOpacity = 0.5,
		Visible = false
	})
	Killaura:CreateToggle({
		Name = 'Target particles',
		Function = function(callback)
			ParticleTexture.Object.Visible = callback
			ParticleColor1.Object.Visible = callback
			ParticleColor2.Object.Visible = callback
			ParticleSize.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local part = Instance.new('Part')
					part.Size = Vector3.new(2, 4, 2)
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = 1
					part.CanQuery = false
					part.Parent = Killaura.Enabled and gameCamera or nil
					local particles = Instance.new('ParticleEmitter')
					particles.Brightness = 1.5
					particles.Size = NumberSequence.new(ParticleSize.Value)
					particles.Shape = Enum.ParticleEmitterShape.Sphere
					particles.Texture = ParticleTexture.Value
					particles.Transparency = NumberSequence.new(0)
					particles.Lifetime = NumberRange.new(0.4)
					particles.Speed = NumberRange.new(16)
					particles.Rate = 128
					particles.Drag = 16
					particles.ShapePartial = 1
					particles.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
					})
					particles.Parent = part
					Particles[i] = part
				end
			else
				for _, v in Particles do 
					v:Destroy() 
				end
				table.clear(Particles)
			end
		end
	})
	FaceTarget = Killaura:CreateToggle({
		Name = "Face Target",
		Function = void,
	})
	ParticleTexture = Killaura:CreateTextBox({
		Name = 'Texture',
		Default = 'rbxassetid://14736249347',
		Function = function()
			for _, v in Particles do
				v.ParticleEmitter.Texture = ParticleTexture.Value
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor1 = Killaura:CreateColorSlider({
		Name = 'Color Begin',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor2 = Killaura:CreateColorSlider({
		Name = 'Color End',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, val))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleSize = Killaura:CreateSlider({
		Name = 'Size',
		Min = 0,
		Max = 1,
		Default = 0.14,
		Decimal = 100,
		Function = function(val)
			for _, v in Particles do
				v.ParticleEmitter.Size = NumberSequence.new(val)
			end
		end,
		Darker = true,
		Visible = false
	})
	LegitAura = Killaura:CreateToggle({
		Name = 'Click only',
		Function = function()
			if Killaura.Enabled then 
				Killaura:Toggle()
				Killaura:Toggle()
			end
		end,
		Tooltip = 'Only attacks while clicking manually'
	})
end)

run(function()
	local AutoComputer
	local Mode
	AutoComputer = vape.Categories.Minigames:CreateModule({
		Name = "AutoComputer",
		Tooltip = "Automatically complete the computer minigame.",
		Function = function(callback: boolean)
			if callback then
				repeat
					if Mode.Value == "Blatant" then
						replicatedStorage.RemoteEvent:FireServer("SetPlayerMinigameResult", true)
					else
						if lplr.TempPlayerStatsModule.TimingPinPosition.Value == lplr.TempPlayerStatsModule.TimingGoalPosition.Value then
							replicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
							replicatedStorage.RemoteEvent:FireServer("SetPlayerMinigameResult", true)
						end
					end
					task.wait()
				until not AutoComputer.Enabled
			end
		end,
		ExtraText = function() return Mode.Value end
	})
	Mode = AutoComputer:CreateDropdown({
		Name = "Mode",
		List = {"Blatant", "Legit"},
		Functon = void
	})
end)

run(function()
	local CameraUnlock
	CameraUnlock = vape.Legit:CreateModule({
		Name = "Camera Unlocker",
		Tooltip = "Unlocks your camera to move freely.",
		Function = function(callback: boolean)
			if callback then
				repeat
					workspace.CurrentCamera.CameraSubject = lplr.Character:FindFirstChildWhichIsA("Humanoid")
					workspace.CurrentCamera.CameraType = "Custom"
			        lplr.CameraMode = "Classic"
			        lplr.Character.Head.Anchored = false
                    lplr.CameraMaxZoomDistance = 25
                    lplr.CameraMinZoomDistance = 0.5
					task.wait()
				until not CameraUnlock.Enabled
			else
                lplr.CameraMaxZoomDistance = 10
                lplr.CameraMinZoomDistance = 0.5
			end
		end
	})
end)

run(function()
	local NoSlowdown
	NoSlowdown = vape.Categories.Blatant:CreateModule({
		Name = "NoSlowdown",
		Tooltip = "Removes the slowdown effect from some actions.",
		Function = function(callback: boolean)
			if callback then
				repeat
					if lplr.Character then
						if lplr.Character.Humanoid then
							if lplr.Character.Humanoid.WalkSpeed < 16 then
								lplr.Character.Humanoid.WalkSpeed = 16
							end
						end
					end
					task.wait()
				until not NoSlowdown.Enabled
			end
		end
	})
end)

run(function()
	local GUIFixer
	GUIFixer = vape.Legit:CreateModule({
		Name = "GuiFixer",
		Tooltip = "Fixes the gui being invisible.",
		Function = function(callback: boolean)
			lplr.PlayerGui.ScreenGui.MenusTabFrame.Visible = true
		end
	})
end)

run(function()
	local Viewmodel
	local oldtool
	
	local function newCharacter(char)
		Viewmodel:Clean(char.Character.ChildAdded:Connect(function(obj)
			if obj.Name == "Hammer" then 
				oldtool = obj
				ViewmodelTool = oldtool:WaitForChild("Handle"):Clone()
				ViewmodelTool.CanCollide = false
				ViewmodelTool.Massless = true
				ViewmodelTool.Anchored = true
				ViewmodelTool.Parent = gameCamera
				ViewmodelTool:ClearAllChildren()
				ViewmodelTool.LocalTransparencyModifier = 0
				oldtool.Handle.LocalTransparencyModifier = 1
			end
		end))
		
		Viewmodel:Clean(char.Character.ChildRemoved:Connect(function(obj)
			if obj == oldtool then 
				ViewmodelTool:Destroy()
				ViewmodelTool = nil
				oldtool = nil
			end
		end))
	end
	
	Viewmodel = vape.Legit:CreateModule({
		Name = 'Viewmodel',
		Function = function(callback)
			if callback then 
				ViewmodelMotor = Instance.new('Motor6D')
				vape:Clean(ViewmodelMotor)
				vape:Clean(runService.RenderStepped:Connect(function()
					if ViewmodelTool then 
						local dcf = ((CFrame.new(2.06, -2.44, -2.24) * CFrame.new(0.6, -0.2, -0.6)) * CFrame.Angles(math.rad(99), math.rad(2), math.rad(-4))) * ViewmodelMotor.C0
						local offsetcf = (CFrame.new(0, -0.15, -1.56) * CFrame.Angles(math.rad(-90), math.rad(-90), 0))
						ViewmodelTool.CFrame = ((gameCamera.CFrame * dcf) * offsetcf)
					end
				end))
				vape:Clean(entitylib.Events.LocalAdded:Connect(newCharacter))
				if entitylib.isAlive then 
					newCharacter(entitylib.character) 
				end
			else
				if ViewmodelTool then 
					ViewmodelTool:Destroy() 
				end
			end
		end,
		Tooltip = 'Replaces the default viewmodel'
	})
end)

run(function()
	local AutoWin
	local SaveCaptured
	local AutoRejoin
	local AutoServerhop
	local function getComputer()
		if store.Status:find("FIND") then return nil end
		for i, v in store.Map:GetChildren() do
			if v.Name == "ComputerTable" then
				if v.Screen.BrickColor ~= BrickColor.new("Dark green") then
					local mag = (store.Beast.Character.HumanoidRootPart.Position - v.ComputerTrigger3.Position).magnitude
					if mag > 70 then
						local s = 3
						for i2, v2 in pairs(playersService:GetChildren()) do
							local mag2 = (v2.Character.HumanoidRootPart.Position - v["ComputerTrigger"..s].Position).magnitude
							if mag2 < 1.15 and v2 ~= lplr then
								s -= 1
							end
						end
						if s > 0 then
							local data = {
								Object = v,
								Index = i,
								CFrame = v["ComputerTrigger"..s].CFrame,
								Position = v["ComputerTrigger"..s].Position
							}
							return data
						end
					end
				end
			end
        end
        return nil
	end
	local function getExit()
        for i, v in store.Map:GetChildren() do
            if v.Name == "ExitDoor" then
                local mag = (store.Beast.Character.HumanoidRootPart.Position - v.ExitArea.Position).magnitude
                if mag > 15 then
                    return v
                end
            end
        end
        return nil
    end
    local function getPod()
        for i, v in pairs(store.Map:GetChildren()) do       --print(v)
            if v.Name == "FreezePod" then
                return v
            end
        end
        return nil
    end
    local function getAllPods()
	    local pods = {}
        for i, v in pairs(store.Map:GetChildren()) do       --print(v)
            if v.Name == "FreezePod" then
                table.insert(pods, v)
            end
        end
        return pods
    end
	local function getEmptyPod()
        for i, v in pairs(store.Map:GetChildren()) do
            if v.Name == "FreezePod" and v.PodTrigger.CapturedTorso.Value == nil then
                return v
            end
        end
        return nil
    end
    local function getPlayerInPod(pod)
		if pod:FindFirstChild("PodTrigger") then
			local cap = pod.PodTrigger.CapturedTorso
			if cap.Value ~= nil then
				return cap.Value
			end
		end
        return nil
    end

	local cloned
	local clone, old
	local function doClone()
		if cloned then return end
		if not entitylib.isAlive then
			return
		end
		cloned = true
        lplr.Character.Parent = replicatedStorage
        lplr.Character.HumanoidRootPart.Archivable = true
        old = lplr.Character.HumanoidRootPart 
        old.Anchored = false
        clone = old:Clone()
        clone.Parent = lplr.Character
        old.Parent = workspace
        lplr.Character.PrimaryPart = clone
        entitylib.character.HumanoidRootPart = clone
        lplr.Character.Parent = workspace
		gameCamera.CameraSubject = computer
		old.Transparency = 0
	end
	local function endClone()
        if not cloned then return end
        cloned = false
        old.CFrame = clone.CFrame
        old.Transparency = 1
        lplr.Character.Parent = replicatedStorage
        old.Parent = lplr.Character
        clone.Parent = workspace
        lplr.Character.PrimaryPart = old
        lplr.Character.Parent = workspace
        entitylib.character.HumanoidRootPart = old
	end

	local computer
	local oldcomputer
	local exit
	local pod
	local tweening = false
	local twn
	local computers = 0
	local jumpTick = 0
	local saving = false
	local function tween(pos, time, safe)
		if store.Escaped then return end
		safe = safe or false
		time = time or 0
        local comp = computer or {CFrame = 0, Position = 0}
        if pos == comp.CFrame then
        	if store.status == "exits" then
        		return nil
        	end
            local mag = (comp.Position - lplr.Character.HumanoidRootPart.Position).magnitude
            if mag <= 12 then
                time = 0.5
            end
            if computers <= 0 then
            	time = 0.1
            end
            computers += 1
        end
        lplr.Character.HumanoidRootPart.CFrame = CFrame.new(lplr.Character.HumanoidRootPart.CFrame.X, pos.Y + (safe and 150 or 0), lplr.Character.HumanoidRootPart.CFrame.Z)
        lplr.Character.Humanoid.CameraOffset = Vector3.new(0,safe and -150 or 0,0)
        twn = tweenService:Create(lplr.Character.HumanoidRootPart, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = pos * CFrame.new(0,safe and 150 or 0,0)})
        twn:Play()
        tweening = true
        twn.Completed:Connect(function()
			if safe then
				lplr.Character.HumanoidRootPart.CFrame = pos
				lplr.Character.Humanoid.CameraOffset = Vector3.new(0,0,0)
			end
			twn = nil
            tweening = false
        end)
	end

	local function cloneTween(pos, delay)
		doClone()
		old.CFrame = pos
		task.wait(delay)
		old.CFrame = pos
		endClone()
		lplr.Character.HumanoidRootPart.CFrame = pos - Vector3.new(0, 5, 0)
	end

	local function getSpeed(pos1, pos2, walkspeed)
		local distance = (pos1 - pos2).magnitude
		return distance / walkspeed
	end

	AutoWin = vape.Categories.Minigames:CreateModule({
		Name = "AutoWin",
		Tooltip = "Automatically wins the game for you.",
		Function = function(callback: boolean)
			computers = 0
			if callback then
                AutoWin:Clean(game:GetService("GuiService").ErrorMessageChanged:Connect(function() -- credits to Infinite Yield
                    if not AutoRejoin.Enabled then return end
                    repeat 
						vape.Modules.ServerHop:Toggle()
						task.wait(1)
					until false
                end))
				repeat
					pcall(function()
						if store.Escaped or not store.Beast or store.Status:find("GAME OVER") or store.Status:find("INTERMISSION") then
							lplr.Character.HumanoidRootPart.CFrame = CFrame.new(103.5, 8.207777976989746, -417)
							if #playersService:GetPlayers() < 3 and AutoServerhop.Enabled then
								vape.Modules.ServerHop:Toggle()
								task.wait(0.1)
							end
							if twn then twn:Cancel() twn = nil end
						else
							local mag = store.Status:find("15 SEC") and 5000 or (store.Beast.Character.HumanoidRootPart.Position - lplr.Character.HumanoidRootPart.Position).magnitude
							replicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
							if store.Beast ~= lplr then -- SURVIVOR
								lplr.Character.HumanoidRootPart.Velocity = Vector3.zero
								if mag <= 25 and (not store.Escaped and not store.Status:find("GAME OVER")) then
									--tween:Cancel()
									
									lplr.Character.HumanoidRootPart.CFrame *= CFrame.new(0,100,0)
									if twn then twn:Cancel() twn = nil end
									jumpTick = 0
								else
									task.wait(0)
									replicatedStorage.RemoteEvent:FireServer("SetPlayerMinigameResult", true)
									jumpTick += 1
									local pods = getAllPods()
									local captured
									for i, v in pods do
										local plr = getPlayerInPod(v)
										if plr then
											captured = plr
										end
									end
									local mag2 = 500
									if captured then
										mag2 = (captured.Position - store.Beast.Character.HumanoidRootPart.Position).magnitude
									end
									if (captured and SaveCaptured.Enabled) and mag2 >= 20 then
										oldcomputer = computer
										lplr.Character.HumanoidRootPart.CFrame = captured.CFrame * CFrame.new(0,-2,4)
										if twn then
											twn:Cancel()
											tweening = false
											twn = nil
										else
											if not saving then
												computers = 0
												computer = oldcomputer
											end
										end
										saving = true
									else
										saving = false
										if store.Status:find("COMPUTER") then -- COMPUTERS
											local pos = lplr.Character.HumanoidRootPart.Position
											if not computer or not computer.Object or not computer.Object:FindFirstChild("Screen") or computer.Object.Screen.BrickColor == BrickColor.new("Dark green") or mag <= 30 then
												if mag <= 20 then
													notif("Cat", "The beast is near!", 3, "alert")
												end
												if computer then
													if computer.Object:FindFirstChild("Screen") and computer.Object.Screen.BrickColor == BrickColor.new("Dark green") then
														notif("Cat", "Computer successfully hacked!", 3)
														store.ComputerHacked:Fire()
													end
												end
												notif("Cat", "Finding new computer...", 1)
												computer = getComputer()
											end
											if not tweening and computer then
												if pos.X ~= computer.Position.X or pos.Z ~= computer.Position.Z then
													--cloneTween(computer.CFrame, 5)
													if not store.Status:find("FIND") then
														local tme = getSpeed(pos, computer.Position, 16)
														if tme > 13 then tme = 13 end
														tween(computer.CFrame, tme, true)
														notif("Cat", "Found! Arriving in "..math.floor(tme).." seconds...", tme - 0.3)
													end
												end
											end
											for i2, v2 in pairs(playersService:GetChildren()) do
												if computer and v2.Character and v2.Character.HumanoidRootPart then
													local mag2 = (v2.Character.HumanoidRootPart.Position - computer.Position).magnitude
													if mag2 < 1.15 and v2 ~= lplr then
														computer = getComputer()
													end
												end
											end
											if tweening then
												jumpTick = 0
											end
											if jumpTick == 50 then
												lplr.Character.HumanoidRootPart.CFrame += Vector3.new(0, 3, 0)
												task.wait(0.01)
												jumpTick = 0
												if not store.Status:find("FIND") then tween(computer.CFrame, 0, true) end
											end
										elseif store.Status:find("FIND") and not store.Escaped then -- EXITS
											local pos = lplr.Character.HumanoidRootPart.Position
											jumpTick = 0
											if twn then twn:Cancel() twn = nil end
											local additionalPos = CFrame.new(0,0,0)
											if not exit or mag <= 25 then
												if mag <= 25 then
													notif("Cat", "The beast is near!", 3, "alert")
												end
												exit = getExit()
											end
											local partTP = exit.ExitArea
											local speed = 3
											
											if exit.Door.Hinge.Rotation.Y == 0 and exit:FindFirstChild("ExitDoorTrigger") or exit.Door.Hinge.Rotation.Y == 90 and exit:FindFirstChild("ExitDoorTrigger") or exit.Door.Hinge.Rotation.Y == 180 and exit:FindFirstChild("ExitDoorTrigger") or exit.Door.Hinge.Rotation.Y == 270 and exit:FindFirstChild("ExitDoorTrigger") then
												partTP = exit.ExitDoorTrigger
												speed = 0.65
											end
											if exit.Door.Hinge.Rotation.Y == -90 and exit:FindFirstChild("ExitDoorTrigger") or exit.Door.Hinge.Rotation.Y == -180 and exit:FindFirstChild("ExitDoorTrigger") or exit.Door.Hinge.Rotation.Y == -270 and exit:FindFirstChild("ExitDoorTrigger") then
												partTP = exit.ExitDoorTrigger
												speed = 0.65
											end
											if mag >= 15 then
												if not tweening then
													if pos.X ~= partTP.Position.X or pos.Z ~= partTP.Position.Z then
														tween(partTP.CFrame, speed, false)
													end
												end
											else
												exit = getExit()
											end
										end
									end
								end
							else -- BEAST
								lplr.Character.HumanoidRootPart.Velocity = Vector3.zero
								if lplr.Character:FindFirstChild("Part") and lplr.Character.Part:FindFirstChild("RopeConstraint") then
									local pod = getEmptyPod()
									lplr.Character.HumanoidRootPart.CFrame = pod.PodTrigger.CFrame
									store.Kills += 1
								else
									--print("beast")
									target = nil
									for i, v in entitylib.AllPosition({
										Range = 300,
										Wallcheck = false,
										Part = 'RootPart',
										Players = true,
										NPCs = false,
										Limit = 10
									}) do
										target = v
										--print("targets")
										if target ~= nil and not target.Player.TempPlayerStatsModule.Captured.Value then
											--print("go!!!")
											if not vape.Modules.Killaura.Enabled then vape.Modules.Killaura:Toggle() end
											lplr.Character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0,0,4)
										end
									end
								end
							end
						end
					end)
					task.wait()
				until not AutoWin.Enabled
			end
		end
	})
	SaveCaptured = AutoWin:CreateToggle({Name = "Save captured players", Default = true})
	AutoRejoin = AutoWin:CreateToggle({Name = "Auto rejoin", Default = true})
	AutoServerhop = AutoWin:CreateToggle({Name = "Auto ServerHop", Default = true})
end)

run(function()
	local AlwaysCrawl
	AlwaysCrawl = vape.Categories.Blatant:CreateModule({
		Name = "AlwaysCrawl",
		Tooltip = "Always be able to crawl, even as beast.",
		Function = function(callback: boolean)
			if callback then
				repeat
					if store.Beast == lplr then
						if lplr.TempPlayerStatsModule.DisableCrawl.Value then
							lplr.TempPlayerStatsModule.DisableCrawl.Value = false
						end
						if lplr.Character then
							 if lplr.Character.CrawlScript.Disabled then
								lplr.Character.CrawlScript.Enabled = true
							 end
						end
						for i, v in store.Map:GetChildren() do
							if v.Name == "Vent" then
								v.VentBlock.CanCollie = false
							end
						end
					end
					task.wait()
				until not AlwaysCrawl.Enabled
			end
		end
	})
end)