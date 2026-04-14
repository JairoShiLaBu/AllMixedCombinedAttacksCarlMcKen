local asset = game.ReplicatedStorage.Emotes.VFX.RealAssets.HugeSlash.SLASH.M
local blackFlashVFX = game.ReplicatedStorage:WaitForChild("Resources"):WaitForChild("KJEffects"):WaitForChild("KJWallCombo"):WaitForChild("FinalImpact")
local armVFXAsset = game.ReplicatedStorage:WaitForChild("Resources"):WaitForChild("FiveSeasonsFX"):WaitForChild("CharFX"):WaitForChild("ArmFX")
local demonParticlesAsset = game.ReplicatedStorage:WaitForChild("Emotes"):WaitForChild("DemonParticles"):WaitForChild("RootAttachment")

local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local runService = game:GetService("RunService")

local SCALE = 0.8
local SKIP_COUNT = 3 
local TAKE_COUNT = 3 
local DEBOUNCE_TIME = 0.4
local DRIFT_SPEED = 1.2
local DOWNWARD_FORCE = -0.8 
local SPAWN_DELAY = 0.6
local HITBOX_SIZE = Vector3.new(12, 12, 15)
local HEALTH_LIMITER = 0.235
local isSpawning = false
local vfxDebounce = false 

local VALID_IDS = {
    ["10468665991"] = true
}

local hitbox = Instance.new("Part")
hitbox.Name = "ContinuousHitbox"
hitbox.Size = HITBOX_SIZE
hitbox.Transparency = 1 
hitbox.CanCollide = false
hitbox.CanTouch = false 
hitbox.CanQuery = true  
hitbox.Anchored = true
hitbox.Parent = workspace.Terrain

runService.Heartbeat:Connect(function()
    if root and root.Parent then
        hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -HITBOX_SIZE.Z/2)
    end
end)

local function playSound(id, parent)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. tostring(id):match("%d+")
    s.Parent = parent
    s.Volume = 3
    s:Play()
    game:GetService("Debris"):AddItem(s, 5)
end

local function applyArmVFX(shouldTurnCyan)
    local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    if rightArm then
        local vfxClone = armVFXAsset:Clone()
        vfxClone.Parent = rightArm
        
        vfxClone.Position = Vector3.new(0, -0.8, 0)
        vfxClone.Orientation = Vector3.new(0, 90, 0)

        local cyan = Color3.fromRGB(0, 255, 255)
        local activeEmitters = {}

        for _, child in ipairs(vfxClone:GetChildren()) do
            if child:IsA("ParticleEmitter") then
                if shouldTurnCyan then
                    local oldSequence = child.Color
                    local keypoints = oldSequence.Keypoints
                    local newKeypoints = {}

                    for i, kp in ipairs(keypoints) do
                        local c = kp.Value
                        if c.R > 0.1 and c.R > c.G and c.R > c.B then
                            table.insert(newKeypoints, ColorSequenceKeypoint.new(kp.Time, cyan))
                        else
                            table.insert(newKeypoints, kp)
                        end
                    end
                    child.Color = ColorSequence.new(newKeypoints)
                end
                
                child:Emit(15)
                child.Enabled = true
                table.insert(activeEmitters, child)
            end
        end

        task.spawn(function()
            task.wait(1)
            for _, emitter in ipairs(activeEmitters) do
                if emitter and emitter.Parent then
                    emitter.Enabled = false
                end
            end
            game:GetService("Debris"):AddItem(vfxClone, 3)
        end)
    end
end

local function applyDemonParticles(targetRoot)
    local demonClone = demonParticlesAsset:Clone()
    demonClone.Parent = targetRoot

    for _, child in ipairs(demonClone:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            child:Emit(15)
            child.Enabled = true
        end
    end

    task.delay(1.5, function()
        if demonClone and demonClone.Parent then
            for _, child in ipairs(demonClone:GetChildren()) do
                if child:IsA("ParticleEmitter") then
                    child.Enabled = false
                end
            end
            game:GetService("Debris"):AddItem(demonClone, 3)
        end
    end)
end

local function spawnThirdGroupCleave()
    local fxContainer = Instance.new("Model")
    fxContainer.Name = "ThirdGroupCleave"
    fxContainer.Parent = workspace.Terrain
    
    local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
    local spawnPos = root.Position + (flatLook * 3) + Vector3.new(0, 4, 0) 
    local baseCF = CFrame.lookAt(spawnPos, spawnPos + flatLook)

    for _, obj in ipairs(asset:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if not (name:find("wind") or name:find("floor") or name:find("ground")) then
                local m = obj:Clone()
                m.Parent = fxContainer
                m.CFrame = baseCF
                m.Size = m.Size * SCALE
                m.Transparency = 0
                m.CanCollide = false
                m.Anchored = true
            end
        end
    end

    local totalFound = 0
    local takenCount = 0

    for _, obj in ipairs(asset:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            local pName = obj.Name:lower()
            if not (pName:find("dust") or pName:find("ground") or pName:find("smoke")) then
                totalFound = totalFound + 1
                if totalFound > SKIP_COUNT and takenCount < TAKE_COUNT then
                    takenCount = takenCount + 1
                    local pPart = Instance.new("Part")
                    pPart.Transparency = 1
                    pPart.Size = Vector3.new(1,1,1)
                    pPart.CanCollide = false
                    pPart.Anchored = true
                    pPart.CFrame = baseCF
                    pPart.Parent = fxContainer
                    
                    local p = obj:Clone()
                    p.Parent = pPart
                    
                    local oldKeypoints = p.Size.Keypoints
                    local newKeypoints = {}
                    for i, kp in ipairs(oldKeypoints) do
                        table.insert(newKeypoints, NumberSequenceKeypoint.new(kp.Time, kp.Value * SCALE))
                    end
                    p.Size = NumberSequence.new(newKeypoints)
                    
                    task.spawn(function()
                        p:Emit(15) 
                        for i = 1, 15 do
                            pPart.Position = pPart.Position + (flatLook * DRIFT_SPEED) + Vector3.new(0, DOWNWARD_FORCE, 0)
                            task.wait(0.03)
                        end
                    end)
                end
            end
        end
    end
    game:GetService("Debris"):AddItem(fxContainer, 1.8)
end

local function triggerBlackFlash()
    if vfxDebounce then return end 
    vfxDebounce = true
    
    blackFlashVFX.Archivable = true
    local vfx = blackFlashVFX:Clone()
    
    if vfx:IsA("Model") or vfx:IsA("BasePart") then
        vfx:PivotTo(root.CFrame) 
    end
    
    vfx.Parent = workspace
    
    for _, desc in ipairs(vfx:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Light") or desc:IsA("Trail") then
            desc.Enabled = true
            if desc:IsA("ParticleEmitter") then
                desc:Emit(desc:GetAttribute("EmitCount") or 20)
            end
        end
    end
    
    playSound("73856982721657", root)
    playSound("75307432501177", root)
    
    task.delay(0.6, function()
        if vfx and vfx.Parent then
            for _, desc in ipairs(vfx:GetDescendants()) do
                if desc:IsA("ParticleEmitter") or desc:IsA("Light") or desc:IsA("Trail") then
                    desc.Enabled = false
                end
            end
        end
    end)
    
    game:GetService("Debris"):AddItem(vfx, 4)
    
    task.delay(1, function()
        vfxDebounce = false
    end)
end

local function getTargetData()
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = {char, hitbox}

    local parts = workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size, overlapParams)
    
    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= char then
            local hum = model:FindFirstChild("Humanoid")
            local enemyRoot = model:FindFirstChild("HumanoidRootPart")
            if hum and enemyRoot and hum.Health > 0 then
                local currentHP = hum.Health
                local maxHP = (hum.MaxHealth > 0) and hum.MaxHealth or 100
                local isBelowLimiter = (currentHP / maxHP) <= HEALTH_LIMITER
                return enemyRoot, isBelowLimiter
            end
        end
    end
    return nil, false
end

local function handleAction()
    if isSpawning then return end
    isSpawning = true

    local target, isBelowLimiter = getTargetData()

    -- If no target is found, it stays Cyan. 
    -- If target is found and above limiter, turn Cyan. 
    -- If target is found and below limiter, stay Red (false).
    local shouldTurnCyan = true
    if target and isBelowLimiter then
        shouldTurnCyan = false
    end

    applyArmVFX(shouldTurnCyan)

    if target and isBelowLimiter then
        applyDemonParticles(target)
        task.wait(SPAWN_DELAY)
        triggerBlackFlash()
    else
        task.wait(SPAWN_DELAY)
        spawnThirdGroupCleave()
    end

    task.delay(DEBOUNCE_TIME, function()
        isSpawning = false
    end)
end

animator.AnimationPlayed:Connect(function(track)
    local id = tostring(track.Animation.AnimationId):match("%d+")
    if VALID_IDS[id] then
        handleAction()
    end
end)

local PLAYERS = game:GetService("Players")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local TWEEN_SERVICE = game:GetService("TweenService")
local localPlayer = PLAYERS.LocalPlayer

local OLD_ID = "rbxassetid://10466974800"
local NEW_ID = "rbxassetid://13560306510"
local SOUND_ID = "rbxassetid://101593261986929"
local SPEED_MULTIPLIER = 2.0
local START_TIME = 1.0
local SOUND_SKIP_TIME = 1.2 

local replacementAnim = Instance.new("Animation")
replacementAnim.AnimationId = NEW_ID

local connections = {}
local isPlayingFinisher = false -- Debounce variable

local function track(conn)
    table.insert(connections, conn)
end

local function selfDestruct()
    for _, conn in pairs(connections) do
        if conn then conn:Disconnect() end
    end
    script:Destroy()
end

local function playVFX(path, character, offset, duration)
    local success, source = pcall(function() return path:Clone() end)
    if not success or not source then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    source.Parent = hrp
    source.Position = Vector3.new(0, offset, 0)
    
    local emitters = {}
    for _, child in ipairs(source:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            child:Emit(15)
            child.Enabled = true
            table.insert(emitters, child)
        end
    end
    
    task.delay(duration, function()
        for _, emitter in ipairs(emitters) do
            emitter.Enabled = false
        end
        task.delay(1, function() source:Destroy() end)
    end)
end

local function handleCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    track(humanoid.AnimationPlayed:Connect(function(animationTrack)
        -- Check if it's the correct ID and if we aren't already processing it
        if animationTrack.Animation.AnimationId == OLD_ID and not isPlayingFinisher then
            isPlayingFinisher = true -- Lock the logic
            
            animationTrack:AdjustWeight(0)
            animationTrack:Stop(0) 

            local newTrack = humanoid:LoadAnimation(replacementAnim)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0) 
            newTrack.TimePosition = START_TIME
            newTrack:AdjustSpeed(SPEED_MULTIPLIER)

            local animLength = newTrack.Length
            if animLength <= 0 then animLength = 2.5 end 
            local totalDuration = (animLength - START_TIME) / SPEED_MULTIPLIER
            
            -- Sound Handling
            local sound = Instance.new("Sound")
            sound.SoundId = SOUND_ID
            sound.Volume = 1
            sound.Parent = hrp
            sound.TimePosition = SOUND_SKIP_TIME
            sound:Play()
            
            -- Cleanup sound
            task.delay(5, function()
                if sound then sound:Destroy() end
            end)
            
            -- VFX handling
            local vfx1 = REPLICATED_STORAGE.Emotes.VFX.VfxMods.TrueRage.vfx.FloorFx.Attachment
            local vfx2 = REPLICATED_STORAGE.Resources.Fang.FLASH.flashstep.Attachment
            
            playVFX(vfx1, character, -3, math.max(0.1, totalDuration - 0.5))
            playVFX(vfx2, character, -3.2, math.max(0.1, totalDuration - 0.5))

            -- Reset the lock once the animation is finished
            task.delay(totalDuration, function()
                isPlayingFinisher = false
            end)
        end
    end))

    track(humanoid.Died:Connect(function()
        selfDestruct()
    end))
end

if localPlayer.Character then
    handleCharacter(localPlayer.Character)
end

local PLAYERS = game:GetService("Players")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local TWEEN_SERVICE = game:GetService("TweenService")
local localPlayer = PLAYERS.LocalPlayer

local OLD_ID = "rbxassetid://10471336737"
local NEW_ID = "rbxassetid://109617620932970"
local SPEED_MULTIPLIER = 1.15
local HIT_SOUND_ID = "rbxassetid://73856982721657"
local TRIGGER_SOUND_ID = "rbxassetid://95397612878374"
local DEATH_EXTRA_SOUND = "rbxassetid://119862187200315"

local replacementAnim = Instance.new("Animation")
replacementAnim.AnimationId = NEW_ID

local connections = {}

local function track(conn)
    table.insert(connections, conn)
end

local function smoothDestroy(instance, delayTime)
    task.delay(delayTime, function()
        if not instance then return end
        for _, descendant in ipairs(instance:GetDescendants()) do
            if descendant:IsA("ParticleEmitter") then
                descendant.Enabled = false
            end
        end
        task.wait(2)
        if instance then instance:Destroy() end
    end)
end

local function selfDestruct()
    for _, conn in pairs(connections) do
        if conn then conn:Disconnect() end
    end
    script:Destroy()
end

-- Function to find a target in front of the player immediately
local function getImmediateTarget(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}

    local parts = workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0, 0, -5), Vector3.new(9, 8, 9), params)
    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model:FindFirstChild("Humanoid") then
            return model
        end
    end
    return nil
end

local function triggerBlackFlash(target, playerHrp)
    local targetHrp = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
    local targetHum = target:FindFirstChild("Humanoid")
    if not targetHrp or not playerHrp or not targetHum then return end

    local resources = REPLICATED_STORAGE:WaitForChild("Resources", 5)
    
    -- Main Impact Effect
    local effectSource = resources:WaitForChild("KJEffects"):WaitForChild("KJWallCombo"):WaitForChild("FinalImpact")
    local effectClone = effectSource:Clone()
    
    local hitSound = Instance.new("Sound")
    hitSound.SoundId = HIT_SOUND_ID
    hitSound.Volume = 2
    hitSound.Parent = targetHrp
    hitSound:Play()

    local spawnLookCFrame = CFrame.lookAlong(targetHrp.Position, playerHrp.CFrame.LookVector)
    effectClone.Parent = workspace
    if effectClone:IsA("Model") then effectClone:PivotTo(spawnLookCFrame) else effectClone.CFrame = spawnLookCFrame end

    for _, descendant in ipairs(effectClone:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") then descendant:Emit(descendant:GetAttribute("EmitCount") or 25) end
    end
    smoothDestroy(effectClone, 1.5)

    -- Second Death VFX (Anchored & Punchy)
    if targetHum.Health <= (targetHum.MaxHealth * 0.09) then
        local extraSource = resources:WaitForChild("KJEffects"):WaitForChild("DropkickExtra"):WaitForChild("firstHit"):WaitForChild("Attachment")
        local extraClone = extraSource:Clone()
        
        local anchorPart = Instance.new("Part")
        anchorPart.Size = Vector3.new(1,1,1)
        anchorPart.Transparency = 1
        anchorPart.Anchored = true
        anchorPart.CanCollide = false
        anchorPart.CFrame = targetHrp.CFrame
        anchorPart.Parent = workspace
        
        local extraSound = Instance.new("Sound")
        extraSound.SoundId = DEATH_EXTRA_SOUND
        extraSound.Volume = 3
        extraSound.Parent = anchorPart
        extraSound:Play()

        extraClone.Parent = anchorPart
        for _, child in ipairs(extraClone:GetChildren()) do
            if child:IsA("ParticleEmitter") then child:Emit(15) child.Enabled = true end
        end
        smoothDestroy(anchorPart, 0.8) 
    end
end

local function handleCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    track(humanoid.AnimationPlayed:Connect(function(animationTrack)
        if animationTrack.Animation.AnimationId == OLD_ID then
            animationTrack:Stop(0) 

            -- 1. START INDICATOR IMMEDIATELY
            local immediateTarget = getImmediateTarget(character)
            if immediateTarget then
                local tHum = immediateTarget:FindFirstChild("Humanoid")
                local tHrp = immediateTarget:FindFirstChild("HumanoidRootPart")
                if tHum and tHrp and tHum.Health <= (tHum.MaxHealth * 0.09) then
                    local emotes = REPLICATED_STORAGE:WaitForChild("Emotes", 5)
                    local demonRoot = emotes.DemonParticles.RootAttachment
                    local demonClone = demonRoot:Clone()
                    demonClone.Parent = tHrp
                    
                    for _, child in ipairs(demonClone:GetChildren()) do
                        if child:IsA("ParticleEmitter") then child.Enabled = true child:Emit(15) end
                    end
                    smoothDestroy(demonClone, 2.5) -- Let it run through the animation
                end
            end

            local newTrack = humanoid:LoadAnimation(replacementAnim)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0) 
            newTrack:AdjustSpeed(SPEED_MULTIPLIER)

            task.spawn(function()
                local duration = newTrack.Length > 0 and newTrack.Length or 1.2
                task.wait(math.max(0, (duration / SPEED_MULTIPLIER) - 0.7))
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local params = OverlapParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {character}
                
                local parts = workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0, 0, -5), Vector3.new(9, 8, 9), params)
                local hitTargets = {}
                for _, part in ipairs(parts) do
                    local model = part:FindFirstAncestorOfClass("Model")
                    if model and model:FindFirstChild("Humanoid") and not hitTargets[model] then
                        hitTargets[model] = true
                        triggerBlackFlash(model, hrp)
                    end
                end
            end)
        end
    end))

    track(humanoid.Died:Connect(selfDestruct))
end

if localPlayer.Character then handleCharacter(localPlayer.Character) end
track(localPlayer.CharacterAdded:Connect(handleCharacter))

local PLAYERS = game:GetService("Players")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local DEBRIS = game:GetService("Debris")
local localPlayer = PLAYERS.LocalPlayer

local OLD_ID = "rbxassetid://12510170988"
local NEW_ID = "rbxassetid://16945573694"
local SPEED_MULTIPLIER = 1.0

local VOICE_ID = "rbxassetid://73859356099693"

local BF_HIT_SOUND = "rbxassetid://73856982721657"
local BF_VOICE_SOUND = "rbxassetid://75307432501177"

local replacementAnim = Instance.new("Animation")
replacementAnim.AnimationId = NEW_ID

local connections = {}

local function track(conn)
    table.insert(connections, conn)
end

local function selfDestruct()
    for _, conn in pairs(connections) do
        if conn then conn:Disconnect() end
    end
    script:Destroy()
end

local function playSfx(parent, id, volume, skip)
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Volume = volume or 1
    sound.TimePosition = skip or 0
    sound.RollOffMaxDistance = 150
    sound.Parent = parent
    sound:Play()
    DEBRIS:AddItem(sound, 4)
end

local function getTiltedCF(root)
    local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
    local spawnPos = root.Position + (flatLook * 3) + Vector3.new(0, 4, 0) 
    return CFrame.lookAt(spawnPos, spawnPos + flatLook) * CFrame.Angles(math.rad(45), 0, math.rad(45)), flatLook
end

local function spawnFinalImpact(root)
    local success, asset = pcall(function()
        return REPLICATED_STORAGE:WaitForChild("Resources"):WaitForChild("KJEffects"):WaitForChild("KJWallCombo"):WaitForChild("FinalImpact")
    end)

    if not success or not asset then return end

    local clone = asset:Clone()
    local tiltedCF, _ = getTiltedCF(root)
    
    if clone:IsA("Model") then
        clone:SetPrimaryPartCFrame(tiltedCF)
    elseif clone:IsA("BasePart") then
        clone.CFrame = tiltedCF
    end
    
    clone.Parent = workspace.Terrain

    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("ParticleEmitter") then
            desc:Emit(desc:GetAttribute("EmitCount") or 30)
        end
    end
    
    DEBRIS:AddItem(clone, 3)
end

local function spawnTiltedWind(root)
    local asset = REPLICATED_STORAGE.Emotes.VFX.RealAssets.HugeSlash.SLASH.M
    local fxContainer = Instance.new("Model")
    fxContainer.Name = "WindVFX"
    fxContainer.Parent = workspace.Terrain
    
    local baseCF, flatLook = getTiltedCF(root)

    local emitterCount = 0
    local takenCount = 0

    for _, obj in ipairs(asset:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            emitterCount = emitterCount + 1
            if emitterCount > 3 and takenCount < 3 then
                takenCount = takenCount + 1
                
                local pPart = Instance.new("Part")
                pPart.Transparency = 1
                pPart.Size = Vector3.new(1,1,1)
                pPart.CanCollide = false
                pPart.Anchored = true
                pPart.CFrame = baseCF
                pPart.Parent = fxContainer
                
                local p = obj:Clone()
                p.Parent = pPart
                p:Emit(15)
                
                task.spawn(function()
                    for i = 1, 15 do
                        pPart.Position = pPart.Position + (flatLook * 1.2) + Vector3.new(0, -0.8, 0)
                        task.wait(0.03)
                    end
                end)
            end
        end
    end
    DEBRIS:AddItem(fxContainer, 1.8)
end

local function spawnHitFx(root)
    local source = REPLICATED_STORAGE.Emotes.VFX.VfxMods.LastWill.vfx.Hit1Fx.Attachment
    local clone = source:Clone()
    clone.Parent = root
    clone.Position = Vector3.new(0, -3, 0)
    
    for _, child in ipairs(clone:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            child:Emit(15)
            child.Enabled = true
        end
    end
    DEBRIS:AddItem(clone, 2)
end

local function checkHitbox(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hitboxSize = Vector3.new(8, 8, 8)
    local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -4)

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}

    local parts = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, params)
    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        local targetHum = model and model:FindFirstChild("Humanoid")
        
        if targetHum then
            local isLowHp = targetHum.Health <= (targetHum.MaxHealth * 0.15)

            if isLowHp then
                playSfx(hrp, BF_HIT_SOUND, 3.5, 0)
                playSfx(hrp, BF_VOICE_SOUND, 3.5, 0)
                spawnFinalImpact(hrp) 
            else
                playSfx(hrp, VOICE_ID, 3.0, 1.4)
            end

            spawnHitFx(hrp)
            spawnTiltedWind(hrp)
            break 
        end
    end
end

local function handleCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    track(humanoid.AnimationPlayed:Connect(function(animationTrack)
        if animationTrack.Animation.AnimationId == OLD_ID then
            animationTrack:AdjustWeight(0)
            animationTrack:Stop(0) 

            local newTrack = humanoid:LoadAnimation(replacementAnim)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0) 
            newTrack:AdjustSpeed(SPEED_MULTIPLIER)

            hrp.Anchored = true
            
            task.spawn(function()
                task.wait(0.6)
                checkHitbox(character)
                
                local duration = newTrack.Length
                if duration <= 0 then duration = 1.5 end
                local totalTime = duration / SPEED_MULTIPLIER
                
                local unanchorTime = totalTime - 0.4 - 0.6
                if unanchorTime > 0 then
                    task.wait(unanchorTime)
                end
                hrp.Anchored = false
            end)
        end
    end))

    track(humanoid.Died:Connect(function()
        hrp.Anchored = false
        selfDestruct()
    end))
end

if localPlayer.Character then
    handleCharacter(localPlayer.Character)
end

local PLAYERS = game:GetService("Players")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local DEBRIS = game:GetService("Debris")
local RUN_SERVICE = game:GetService("RunService")
local localPlayer = PLAYERS.LocalPlayer

local ANIM_MAP = {
    ["10469493270"] = "rbxassetid://17325510002",
    ["10469630950"] = "rbxassetid://13491635433",
    ["10469639222"] = "rbxassetid://17889461810",
    ["10469643643"] = "rbxassetid://13294471966"
}

local HITBOX_SIZE = Vector3.new(5, 6, 5)
local HITBOX_OFFSET = 1.0 

-- Hitbox Setup (Invisible)
local visualBox = Instance.new("Part")
visualBox.Name = "ActiveHitbox"
visualBox.Size = HITBOX_SIZE
visualBox.Anchored = true
visualBox.CanCollide = false
visualBox.CanQuery = false
visualBox.Transparency = 1 -- Hitbox is now invisible
visualBox.Parent = workspace

local function spawnPunchVFX(targetHRP)
    if not targetHRP then return end
    
    local emotes = REPLICATED_STORAGE:FindFirstChild("Emotes")
    if not emotes then return end
    
    local source = emotes:FindFirstChild("Punchbarrage", true)
    if not source then return end
    
    local clone = source:Clone()
    
    -- Handle both BaseParts and Attachments
    if clone:IsA("BasePart") then
        clone.CFrame = targetHRP.CFrame
        clone.Anchored = false
        clone.CanCollide = false
        clone.Parent = targetHRP 
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = targetHRP
        weld.Part1 = clone
        weld.Parent = clone
    elseif clone:IsA("Attachment") then
        clone.Parent = targetHRP
    end

    for _, child in ipairs(clone:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            child:Emit(15)
            child.Enabled = true
        end
    end
    
    DEBRIS:AddItem(clone, 2)
end

local function getHitTarget(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local hitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -HITBOX_OFFSET)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character, visualBox}
    
    local parts = workspace:GetPartBoundsInBox(hitboxCFrame, HITBOX_SIZE, params)
    
    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character then
            local enemyHumanoid = model:FindFirstChildOfClass("Humanoid")
            local enemyHRP = model:FindFirstChild("HumanoidRootPart")
            if enemyHumanoid and enemyHRP then
                return enemyHRP
            end
        end
    end
    return nil
end

local function handleCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    
    -- Keep hitbox CFrame updated even if invisible
    RUN_SERVICE.RenderStepped:Connect(function()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp and visualBox then
            visualBox.CFrame = hrp.CFrame * CFrame.new(0, 0, -HITBOX_OFFSET)
        end
    end)

    humanoid.AnimationPlayed:Connect(function(track)
        local idOnly = track.Animation.AnimationId:match("%d+")
        
        if ANIM_MAP[idOnly] then
            track:Stop(0)
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = ANIM_MAP[idOnly]
            local newTrack = animator:LoadAnimation(newAnim)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0)
            
            task.spawn(function()
                -- 1. Initial delay (Wait 0.1s for anim wind-up)
                task.wait(0.1)
                
                local scanStartTime = tick()
                local vfxTriggered = false
                
                -- 2. Scan window (Check for target for next 0.3s)
                while (tick() - scanStartTime) < 0.3 do
                    local enemyHRP = getHitTarget(character)
                    
                    if enemyHRP and not vfxTriggered then
                        spawnPunchVFX(enemyHRP)
                        vfxTriggered = true 
                        break 
                    end
                    
                    task.wait() 
                end
            end)
        end
    end)
end

if localPlayer.Character then handleCharacter(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(handleCharacter)

local PLAYERS = game:GetService("Players")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local DEBRIS = game:GetService("Debris")
local localPlayer = PLAYERS.LocalPlayer

local SKILL_1_OLD = "10470104242" 
local SKILL_1_NEW = "rbxassetid://17858997926"
local SKILL_1_SKIP = 0.6
local SKILL_1_VFX_DELAY = 0.4    
local SKILL_1_VFX_DURATION = 0.2 

local SKILL_2_OLD = "10503381238"
local SKILL_2_NEW = "rbxassetid://14900168720"
local SKILL_2_SKIP = 1.5

local DASH_ANIM_ID = "rbxassetid://10479335397"

local Resources = REPLICATED_STORAGE:WaitForChild("Resources")
local Fang = Resources:WaitForChild("Fang")
local FLASH = Fang:WaitForChild("FLASH")
local flashstep = FLASH:WaitForChild("flashstep")
local VFX_TEMPLATE = flashstep:WaitForChild("Attachment")

local connections = {}

local function cleanup()
    for _, conn in ipairs(connections) do
        if conn then conn:Disconnect() end
    end
    table.clear(connections)
end

local function spawnSkillVFX(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local vfxClone = VFX_TEMPLATE:Clone()
    local spawnOffset = hrp.CFrame.LookVector * 5
    local groundLevel = hrp.Position.Y - 3 
    
    vfxClone.Parent = hrp
    vfxClone.WorldPosition = Vector3.new(hrp.Position.X + spawnOffset.X, groundLevel, hrp.Position.Z + spawnOffset.Z)

    for _, child in ipairs(vfxClone:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            child:Emit(15)
            child.Enabled = true
        end
    end

    task.delay(SKILL_1_VFX_DURATION, function()
        for _, child in ipairs(vfxClone:GetChildren()) do
            if child:IsA("ParticleEmitter") then
                child.Enabled = false
            end
        end
        task.wait(1) 
        if vfxClone then vfxClone:Destroy() end
    end)
end

local function spawnDashVFX(hrp)
    local source = REPLICATED_STORAGE.Emotes.VFX.VfxMods.LastWill.vfx.DashFx.Attachment
    local clone = source:Clone()
    
    clone.Parent = hrp
    clone.Position = Vector3.new(0, 0, -2) 
    
    local emitterIndex = 0
    for _, child in ipairs(clone:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            emitterIndex = emitterIndex + 1
            
            if emitterIndex == 1 then
                child:Destroy()
            else
                child:Emit(15)
                child.Enabled = true
            end
        end
    end
    
    DEBRIS:AddItem(clone, 2)
end

local function handleCharacter(character)
    cleanup()

    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    local animator = humanoid:WaitForChild("Animator")
    
    local animConn = animator.AnimationPlayed:Connect(function(animationTrack)
        local animId = animationTrack.Animation.AnimationId

        if string.find(animId, SKILL_1_OLD) then
            animationTrack:Stop(0)
            
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = SKILL_1_NEW
            local newTrack = animator:LoadAnimation(newAnim)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0)
            
            if newTrack.Length <= 0 then task.wait() end
            newTrack.TimePosition = SKILL_1_SKIP
            newAnim:Destroy()

            task.delay(SKILL_1_VFX_DELAY, function()
                if character and character.Parent then
                    spawnSkillVFX(character)
                end
            end)

            newTrack.Stopped:Connect(function() newTrack:Destroy() end)

        elseif string.find(animId, SKILL_2_OLD) or animId == SKILL_2_OLD then
            animationTrack:Stop(0)
            animationTrack:AdjustWeight(0)

            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = SKILL_2_NEW
            local newTrack = animator:LoadAnimation(newAnim)
            newTrack.Priority = Enum.AnimationPriority.Action4
            newTrack:Play(0)
            
            if newTrack.Length <= 0 then task.wait() end
            newTrack.TimePosition = SKILL_2_SKIP
            newAnim:Destroy()

            newTrack.Stopped:Connect(function() newTrack:Destroy() end)
            
        elseif animId == DASH_ANIM_ID then
            spawnDashVFX(hrp)
        end
    end)
    table.insert(connections, animConn)

    local deathConn = humanoid.Died:Connect(function()
        cleanup()
        script:Destroy()
    end)
    table.insert(connections, deathConn)
end

if localPlayer.Character then
    task.spawn(handleCharacter, localPlayer.Character)
end

local respawnConn = localPlayer.CharacterAdded:Connect(handleCharacter)
table.insert(connections, respawnConn)

loadstring(game:HttpGet("https://raw.githubusercontent.com/JairoShiLaBu/CarlMcKenWallComboYuJi/refs/heads/main/OpenSource.lua"))()

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local ts = game:GetService("TweenService")

local targetAnimId = "rbxassetid://12983333733"
local customAnimId = "rbxassetid://17861840167"
local assetId = 16408664901
local soundId = "rbxassetid://78637547122675"
local quoteSoundId = "rbxassetid://18745916098"

local function runFuga()
    local s = Instance.new("ScreenGui")
    s.Name = "FugaCinematic"
    s.IgnoreGuiInset = true
    s.DisplayOrder = 10
    s.Parent = player:WaitForChild("PlayerGui")

    local quoteGui = Instance.new("ScreenGui")
    quoteGui.Name = "FugaQuote"
    quoteGui.IgnoreGuiInset = true
    quoteGui.DisplayOrder = 15
    quoteGui.Parent = player:WaitForChild("PlayerGui")

    local blackFrame = Instance.new("Frame")
    blackFrame.Size = UDim2.new(1, 0, 1, 0)
    blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blackFrame.BackgroundTransparency = 1
    blackFrame.ZIndex = 1
    blackFrame.Parent = s

    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = s
    textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.Size = UDim2.new(0, 600, 0, 100)
    textLabel.TextSize = 120
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.Font = Enum.Font.Antique
    textLabel.BackgroundTransparency = 1
    textLabel.TextTransparency = 1
    textLabel.ZIndex = 2
    textLabel.Text = "FUGA"

    local quoteFrame = Instance.new("Frame")
    quoteFrame.Parent = quoteGui
    quoteFrame.Position = UDim2.new(0.5, 0, 0.75, 0)
    quoteFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    quoteFrame.Size = UDim2.new(0, 800, 0, 50)
    quoteFrame.BackgroundTransparency = 1
    quoteFrame.ZIndex = 5

    local layout = Instance.new("UIListLayout")
    layout.Parent = quoteFrame
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local words = {"Man,", "You", "Really", "Are", "Boring"}
    local wordLabels = {}

    for i, word in ipairs(words) do
        local label = Instance.new("TextLabel")
        label.Parent = quoteFrame
        label.Size = UDim2.new(0, 0, 1, 0)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.TextSize = 35
        label.TextColor3 = Color3.fromRGB(128, 0, 0)
        label.FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        label.BackgroundTransparency = 1
        label.TextTransparency = 1
        label.TextStrokeTransparency = 1
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Text = word
        label.LayoutOrder = i
        label.ZIndex = 5
        table.insert(wordLabels, label)
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = customAnimId
    local loadAnim = humanoid:LoadAnimation(anim)
    loadAnim:Play()
    loadAnim:AdjustSpeed(0.25)

    -- Dual Explosion Effect Logic (Left & Right Arm)
    task.delay(0.3, function()
        local ExplosionSource = game.Workspace.Cutscenes.Atoms.sphere.Model.atom.root.Explosion
        
        local targets = {
            character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"),
            character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
        }

        for _, limb in ipairs(targets) do
            if limb then
                local explosionClone = ExplosionSource:Clone()
                explosionClone.Parent = limb
                
                local scaleFactor = 0.4 
                
                for _, child in ipairs(explosionClone:GetChildren()) do
                    if child:IsA("ParticleEmitter") then
                        local oldSize = child.Size
                        local newKeypoints = {}
                        for _, kp in ipairs(oldSize.Keypoints) do
                            table.insert(newKeypoints, NumberSequenceKeypoint.new(kp.Time, kp.Value * scaleFactor, kp.Envelope * scaleFactor))
                        end
                        child.Size = NumberSequence.new(newKeypoints)
                        
                        child:Emit(10)
                        child.Enabled = true
                    end
                end
                game:GetService("Debris"):AddItem(explosionClone, 5)
            end
        end
    end)

    task.spawn(function()
        loadAnim.Stopped:Wait()
        
        local qSound = Instance.new("Sound")
        qSound.SoundId = quoteSoundId
        qSound.Volume = 5
        qSound.Parent = game:GetService("SoundService")
        qSound:Play()
        game:GetService("Debris"):AddItem(qSound, 5)

        for _, label in ipairs(wordLabels) do
            ts:Create(label, TweenInfo.new(0.2), {TextTransparency = 0, TextStrokeTransparency = 0.6}):Play()
            task.wait(0.15)
        end
        
        task.wait(1.5)
        
        for _, label in ipairs(wordLabels) do
            ts:Create(label, TweenInfo.new(0.3), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
            task.wait(0.1)
        end
        
        task.wait(0.5)
        quoteGui:Destroy()
    end)

    local cameraCFrame = camera.CFrame
    local isFiring = false
    local effectModel = nil
    
    local camConnection = runService.RenderStepped:Connect(function()
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = cameraCFrame
    end)

    local sidePos = hrp.CFrame * CFrame.new(22, 6, -16)
    cameraCFrame = CFrame.new(sidePos.Position, hrp.Position)

    task.delay(1.6, function()
        local success, effect = pcall(function()
            return game:GetObjects("rbxassetid://" .. assetId)[1]
        end)

        if success and effect then
            effectModel = effect
            effectModel.Parent = workspace
            
            for _, part in pairs(effectModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.Anchored = true
                    part.CanTouch = false
                    part.Transparency = 1
                elseif part:IsA("ParticleEmitter") then
                    part.Enabled = false
                end
            end

            local janitorConnection
            janitorConnection = runService.RenderStepped:Connect(function()
                if not effectModel or not effectModel.Parent or isFiring then 
                    janitorConnection:Disconnect()
                    return 
                end
                effectModel:PivotTo(hrp.CFrame * CFrame.new(0, 0, -3))
            end)
            
            local fadeInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            for _, part in pairs(effectModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    local isGreyBlock = part.Name == "Part" or part.Name == "Handle" or part.Name == "Hitbox" or part.ClassName == "Part"
                    if not isGreyBlock then
                        ts:Create(part, fadeInfo, {Transparency = 0}):Play()
                    end
                elseif part:IsA("ParticleEmitter") then
                    part.Enabled = true
                    part:Emit(15) 
                end
            end
        end
    end)

    task.wait(1.4)
    local fugaSound = Instance.new("Sound")
    fugaSound.SoundId = soundId
    fugaSound.Volume = 3
    fugaSound.Parent = game:GetService("SoundService")
    fugaSound:Play()
    game:GetService("Debris"):AddItem(fugaSound, 10)

    task.wait(1.4)
    ts:Create(blackFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    task.wait(0.5)
    
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/JairoShiLaBu/CarlMcKenSukunaDomainExpansion/refs/heads/main/MalevolentShrine.lua"))()
    end)

    textLabel.TextTransparency = 0
    task.wait(1.5) 
    
    local behindPos = hrp.CFrame * CFrame.new(0, 8, 24)
    local targetLook = hrp.CFrame * CFrame.new(0, 0, -100).Position
    cameraCFrame = CFrame.new(behindPos.Position, targetLook)

    ts:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    ts:Create(blackFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    
    task.wait(0.4)
    isFiring = true

    if effectModel then
        local flyTime = 2.5 
        local distance = 5000 
        local startCFrame = effectModel:GetPivot()
        local targetCFrame = startCFrame * CFrame.new(0, 0, -distance)

        local tweenValue = Instance.new("CFrameValue")
        tweenValue.Value = startCFrame
        
        local tween = ts:Create(tweenValue, TweenInfo.new(flyTime, Enum.EasingStyle.Linear), {Value = targetCFrame})
        
        local moveConn
        moveConn = tweenValue.Changed:Connect(function()
            if effectModel and effectModel.Parent then
                effectModel:PivotTo(tweenValue.Value)
            else
                moveConn:Disconnect()
            end
        end)

        for _, v in pairs(effectModel:GetDescendants()) do
            if v:IsA("ParticleEmitter") then 
                v.Enabled = true
                v:Emit(200) 
            end
        end
        tween:Play()
        
        task.delay(flyTime, function()
            if moveConn then moveConn:Disconnect() end
            if effectModel then effectModel:Destroy() end
            tweenValue:Destroy()
        end)
    end

    task.wait(4.0) 
    camConnection:Disconnect()
    camera.CameraType = Enum.CameraType.Custom
    s:Destroy()
end

humanoid.AnimationPlayed:Connect(function(track)
    if track.Animation.AnimationId == targetAnimId then
        track:Stop()
        runFuga()
    end
end)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

-- CONFIGURATION
local SHRINE_FINAL_HEIGHT = 16 
local SHRINE_DEPTH_START = -100
local SHRINE_DISTANCE_BEHIND = 35
local BLOOD_POOL_SIZE = 4000

local originalSkillAnimId = 11365563255
local newExpansionAnimId = 18459220516
local shrineAssetId = 16639433873
local domainTriggered = false
local systemReady = false

-- 1. ROBUST PRELOADING
local expansionAnim = Instance.new("Animation")
expansionAnim.AnimationId = "rbxassetid://" .. newExpansionAnimId
local shrineCache = nil

local function initialize()
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. shrineAssetId)
    end)
    
    if success and objects and objects[1] then
        shrineCache = objects[1]
        shrineCache.Name = "ShrineCache"
        shrineCache.Parent = game:GetService("ReplicatedStorage")
        if shrineCache:IsA("Model") then 
            shrineCache:PivotTo(CFrame.new(0, -5000, 0)) 
        end
        ContentProvider:PreloadAsync({expansionAnim, shrineCache})
        systemReady = true
    else
        task.wait(1)
        initialize()
    end
end
task.spawn(initialize)

-- 2. LIGHTING DEFAULTS
local originalLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor
}

-- 3. DOMAIN LOGIC
local function triggerDomain(animLength, customTrack)
    if domainTriggered then return end
    domainTriggered = true
    
    local voice = Instance.new("Sound", SoundService)
    voice.SoundId = "rbxassetid://6590147536"
    voice.Volume = 10
    voice:Play()
    game:GetService("Debris"):AddItem(voice, 10)

    -- Instant Lighting Shift
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") or obj:IsA("Sky") then
            local p = obj.Parent
            obj.Parent = nil
            task.delay(animLength + 2, function() obj.Parent = p end)
        end
    end

    Lighting.ClockTime = 0
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(150, 0, 0)
    Lighting.FogEnd = 350
    Lighting.FogColor = Color3.fromRGB(0, 0, 0)

    local instancesToClean = {}

    -- BLOOD POOL (Spawned first so it's visible)
    local bloodFloor = Instance.new("Part")
    bloodFloor.Name = "DomainBloodPool"
    bloodFloor.Size = Vector3.new(BLOOD_POOL_SIZE, 1.2, BLOOD_POOL_SIZE)
    -- Positioned slightly above the ground (0.5) to prevent Z-fighting/clipping
    bloodFloor.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.new(0, -2.5, 0)
    bloodFloor.Anchored = true
    bloodFloor.CanCollide = false
    bloodFloor.Color = Color3.fromRGB(80, 0, 0) -- Brighter red for visibility
    bloodFloor.Material = Enum.Material.Glass
    bloodFloor.Transparency = 0.2
    bloodFloor.Parent = workspace
    table.insert(instancesToClean, bloodFloor)

    -- SHRINE SPAWN
    local weldPart = Instance.new("Part", workspace)
    weldPart.Size = Vector3.new(1, 1, 1)
    weldPart.Transparency = 1
    weldPart.Anchored = true
    weldPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, SHRINE_DEPTH_START, SHRINE_DISTANCE_BEHIND)
    table.insert(instancesToClean, weldPart)

    local loadedObject = shrineCache:Clone()
    loadedObject.Parent = workspace
    table.insert(instancesToClean, loadedObject)
    
    local targetModel = loadedObject:IsA("Model") and loadedObject or loadedObject:FindFirstChildWhichIsA("Model")
    if targetModel then
        for _, p in ipairs(targetModel:GetDescendants()) do 
            if p:IsA("BasePart") then p.Anchored = false p.CanCollide = false end 
        end
        targetModel:PivotTo(weldPart.CFrame)
        local main = targetModel.PrimaryPart or targetModel:FindFirstChildWhichIsA("BasePart")
        if main then
            local w = Instance.new("WeldConstraint", main)
            w.Part0 = main; w.Part1 = weldPart
        end
        
        TweenService:Create(weldPart, TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            CFrame = humanoidRootPart.CFrame * CFrame.new(0, SHRINE_FINAL_HEIGHT, SHRINE_DISTANCE_BEHIND)
        }):Play()
    end

    -- CAMERA
    camera.CameraType = Enum.CameraType.Scriptable
    local head = character:WaitForChild("Head")
    camera.CFrame = head.CFrame * CFrame.new(0, 0.5, -9) * CFrame.Angles(0, math.pi, 0)

    TweenService:Create(camera, TweenInfo.new(2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = head.CFrame * CFrame.new(0, 0.5, -5.5) * CFrame.Angles(0, math.pi, 0)
    }):Play()

    task.delay(2.8, function()
        local behindPos = humanoidRootPart.CFrame * CFrame.new(0, 6, 15)
        camera.CFrame = CFrame.new(behindPos.Position, humanoidRootPart.Position)
        TweenService:Create(camera, TweenInfo.new(animLength - 2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            CFrame = camera.CFrame * CFrame.new(0, 2, 10)
        }):Play()
    end)

    -- CLEANUP & TWEEN DOWN
    task.delay(animLength, function()
        camera.CameraType = Enum.CameraType.Custom
        customTrack:Stop(1.5)
        
        -- Tween Shrine DOWN
        if weldPart then
            TweenService:Create(weldPart, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                CFrame = humanoidRootPart.CFrame * CFrame.new(0, SHRINE_DEPTH_START, SHRINE_DISTANCE_BEHIND)
            }):Play()
        end
        
        -- Tween Blood pool DOWN and OUT
        if bloodFloor then
            TweenService:Create(bloodFloor, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                CFrame = bloodFloor.CFrame * CFrame.new(0, -20, 0),
                Transparency = 1
            }):Play()
        end
        
        TweenService:Create(Lighting, TweenInfo.new(2.5), originalLighting):Play()
        
        task.delay(3.2, function()
            for _, i in ipairs(instancesToClean) do i:Destroy() end
            domainTriggered = false
        end)
    end)
end

-- INTERCEPTOR
animator.AnimationPlayed:Connect(function(track)
    local id = tonumber(track.Animation.AnimationId:match("%d+"))
    if id == originalSkillAnimId then
        track:Stop(0)
        
        if not systemReady then
            repeat task.wait() until systemReady
        end
        
        local newTrack = animator:LoadAnimation(expansionAnim)
        newTrack:Play()
        triggerDomain(track.Length > 0 and track.Length or 6, newTrack)
    end
end)

