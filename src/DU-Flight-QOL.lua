require 'src.slots'

-- Exported (user Edit Lua Parameter) Variables

-- These are from Default Flyer Autoconf, kept unless replaced.
local autoRoll = false --export: [Only in atmosphere]<br>When the pilot stops rolling,  flight model will try to get back to horizontal (no roll)
local turnAssist = true --export: [Only in atmosphere]<br>When the pilot is rolling, the flight model will try to add yaw and pitch to make the construct turn better<br>The flight model will start by adding more yaw the more horizontal the construct is and more pitch the more vertical it is

local autoRollFactor = 2 --export: [Only in atmosphere]<br>When autoRoll is engaged, this factor will increase to strength of the roll back to 0<br>Valid values: Superior or equal to 0.01
local turnAssistFactor = 2 --export: [Only in atmosphere]<br>This factor will increase/decrease the turnAssist effect<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

local pitchSpeedFactor = 0.8 --export: This factor will increase/decrease the player input along the pitch axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local yawSpeedFactor =  1 --export: This factor will increase/decrease the player input along the yaw axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local rollSpeedFactor = 1.5 --export: This factor will increase/decrease the player input along the roll axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
local torqueFactor = 2 --export: Force factor applied to reach rotationSpeed<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

local brakeSpeedFactor = 3 --export: When braking, this factor will increase the brake force by brakeSpeedFactor * velocity<br>Valid values: Superior or equal to 0.01
local brakeFlatFactor = 1 --export: When braking, this factor will increase the brake force by a flat brakeFlatFactor * velocity direction><br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01


-- Other variables from vanilla Default Flyer Autoconf
local pitchInput = 0
local rollInput = 0
local yawInput = 0
local brakeInput = 0

script = {}

function script.onStart ()

    VERSION_NUMBER = 0.11

    Nav = Navigator.new(system, core, unit)
    Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, {1000, 5000, 10000, 20000, 30000})
    Nav.axisCommandManager:setTargetGroundAltitude(4)

    -- element widgets
    -- For now we have to alternate between PVP and non-PVP widgets to have them on the same side.
    _autoconf.displayCategoryPanel(weapon, weapon_size, L_TEXT("ui_lua_widget_weapon", "Weapons"), "weapon", true)
    core.show()
    _autoconf.displayCategoryPanel(radar, radar_size, L_TEXT("ui_lua_widget_periscope", "Periscope"), "periscope")
    placeRadar = true
    if atmofueltank_size > 0 then
        _autoconf.displayCategoryPanel(atmofueltank, atmofueltank_size, L_TEXT("ui_lua_widget_atmofuel", "Atmo Fuel"), "fuel_container")
        if placeRadar then
            _autoconf.displayCategoryPanel(radar, radar_size, L_TEXT("ui_lua_widget_radar", "Radar"), "radar")
            placeRadar = false
        end
    end
    if spacefueltank_size > 0 then
        _autoconf.displayCategoryPanel(spacefueltank, spacefueltank_size, L_TEXT("ui_lua_widget_spacefuel", "Space Fuel"), "fuel_container")
        if placeRadar then
            _autoconf.displayCategoryPanel(radar, radar_size, L_TEXT("ui_lua_widget_radar", "Radar"), "radar")
            placeRadar = false
        end
    end
    _autoconf.displayCategoryPanel(rocketfueltank, rocketfueltank_size, L_TEXT("ui_lua_widget_rocketfuel", "Rocket Fuel"), "fuel_container")
    if placeRadar then -- We either have only rockets or no fuel tanks at all, uncommon for usual vessels
        _autoconf.displayCategoryPanel(radar, radar_size, L_TEXT("ui_lua_widget_radar", "Radar"), "radar")
        placeRadar = false
    end
    if antigrav ~= nil then antigrav.show() end
    if warpdrive ~= nil then warpdrive.show() end
    if gyro ~= nil then gyro.show() end

    -- freeze the player in he is remote controlling the construct
    if Nav.control.isRemoteControlled() == 1 then
        system.freeze(1)
    end

    -- landing gear
    -- make sure every gears are synchonized with the first
    gearExtended = (Nav.control.isAnyLandingGearExtended() == 1) -- make sure it's a lua boolean
    if gearExtended then
        Nav.control.extendLandingGears()
    else
        Nav.control.retractLandingGears()
    end
end

function script.onStop ()
    _autoconf.hideCategoryPanels()
    if antigrav ~= nil then antigrav.hide() end
    if warpdrive ~= nil then warpdrive.hide() end
    if gyro ~= nil then gyro.hide() end
    core.hide()
    Nav.control.switchOffHeadlights()
end

function script.onActionLoop (actionName)
    if actionName == "groundaltitudeup" then
        Nav.axisCommandManager:updateTargetGroundAltitudeFromActionLoop(1.0)    
    elseif actionName == "groundaltitudedown" then
        Nav.axisCommandManager:updateTargetGroundAltitudeFromActionLoop(-1.0)
    elseif actionName == "brake" then
        local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
        if (longitudinalCommandType == axisCommandType.byTargetSpeed) then
            local targetSpeed = Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal)
            if (math.abs(targetSpeed) > constants.epsilon) then
                Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, - utils.sign(targetSpeed))
            end
        end
    elseif actionName == "speedup" then
        Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, 1.0)
    elseif actionName == "speeddown" then
        Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, -1.0)
    end
end

function script.onActionStart (actionName)
    if actionName == "gear" then 
        gearExtended = not gearExtended
        if gearExtended then
            Nav.control.extendLandingGears()
        else
            Nav.control.retractLandingGears()
        end
    elseif actionName == "light" then
        if Nav.control.isAnyHeadlightSwitchedOn() == 1 then
            Nav.control.switchOffHeadlights()
        else
            Nav.control.switchOnHeadlights()
        end
    elseif actionName == "forward" then
        pitchInput = pitchInput - 1
    elseif actionName == "backward" then
        pitchInput = pitchInput + 1
    elseif actionName == "left" then
        rollInput = rollInput - 1
    elseif actionName == "right" then
        rollInput = rollInput + 1
    elseif actionName == "strafeleft" then
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.lateral, -1.0)
    elseif actionName == "straferight" then
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.lateral, 1.0)
    elseif actionName == "up" then
        Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, 1.0)
    elseif actionName == "down" then
        Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, -1.0)
    elseif actionName == "groundaltitudeup" then
        Nav.axisCommandManager:updateTargetGroundAltitudeFromActionStart(1.0)    
    elseif actionName == "groundaltitudedown" then
        Nav.axisCommandManager:updateTargetGroundAltitudeFromActionStart(-1.0)    
    elseif actionName == "yawright" then
        yawInput = yawInput - 1
    elseif actionName == "yawleft" then
        yawInput = yawInput + 1
    elseif actionName == "brake" then
        brakeInput = brakeInput + 1
        local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
        if (longitudinalCommandType == axisCommandType.byTargetSpeed) then
            local targetSpeed = Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal)
            if (math.abs(targetSpeed) > constants.epsilon) then
                Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, - utils.sign(targetSpeed))
            end
        end
    elseif actionName == "booster" then
        Nav:toggleBoosters()
    elseif actionName == "stopengines" then
        Nav.axisCommandManager:resetCommand(axisCommandId.longitudinal)
    elseif actionName == "speedup" then
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, 5.0)
    elseif actionName == "speeddown" then
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, -5.0)
    elseif actionName == "antigravity" then
        if antigrav ~= nil then antigrav.toggle() end
    elseif actionName == "warp" then
        if warpdrive ~= nil then warpdrive.activateWarp() end
    end    
end

function onUpdate()
    Nav:update()
end

function script.onActionStop (actionName)
    if actionName == "forward" then
        pitchInput = pitchInput + 1
    elseif actionName == "backward" then
        pitchInput = pitchInput - 1
    elseif actionName == "left" then
        rollInput = rollInput + 1
    elseif actionName == "right" then
        rollInput = rollInput - 1
    elseif actionName == "strafeleft" then
        Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.lateral, 1.0)
    elseif actionName == "straferight" then
        Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.lateral, -1.0)
    elseif actionName == "up" then
        Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, -1.0)
        Nav.axisCommandManager:activateGroundEngineAltitudeStabilization()
    elseif actionName == "down" then
        Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, 1.0)
        Nav.axisCommandManager:activateGroundEngineAltitudeStabilization()
    elseif actionName == "yawright" then
        yawInput = yawInput + 1
    elseif actionName == "yawleft" then
        yawInput = yawInput - 1
    elseif actionName == "brake" then
        brakeInput = brakeInput - 1
    end
end

function script.onTick (timerId)
  screen.setCenteredText("timer " .. timerId .. " ticked")
end

function script.onFlush()

    -- validate params
    pitchSpeedFactor = math.max(pitchSpeedFactor, 0.01)
    yawSpeedFactor = math.max(yawSpeedFactor, 0.01)
    rollSpeedFactor = math.max(rollSpeedFactor, 0.01)
    torqueFactor = math.max(torqueFactor, 0.01)
    brakeSpeedFactor = math.max(brakeSpeedFactor, 0.01)
    brakeFlatFactor = math.max(brakeFlatFactor, 0.01)
    autoRollFactor = math.max(autoRollFactor, 0.01)
    turnAssistFactor = math.max(turnAssistFactor, 0.01)

    -- final inputs
    local finalPitchInput = pitchInput + system.getControlDeviceForwardInput()
    local finalRollInput = rollInput + system.getControlDeviceYawInput()
    local finalYawInput = yawInput - system.getControlDeviceLeftRightInput()
    local finalBrakeInput = brakeInput

    -- Axis
    local worldVertical = vec3(core.getWorldVertical()) -- along gravity
    local constructUp = vec3(core.getConstructWorldOrientationUp())
    local constructForward = vec3(core.getConstructWorldOrientationForward())
    local constructRight = vec3(core.getConstructWorldOrientationRight())
    local constructVelocity = vec3(core.getWorldVelocity())
    local constructVelocityDir = vec3(core.getWorldVelocity()):normalize()
    local currentRollDeg = getRoll(worldVertical, constructForward, constructRight)
    local currentRollDegAbs = math.abs(currentRollDeg)
    local currentRollDegSign = utils.sign(currentRollDeg)

    -- Rotation
    local constructAngularVelocity = vec3(core.getWorldAngularVelocity())
    local targetAngularVelocity = finalPitchInput * pitchSpeedFactor * constructRight
                                    + finalRollInput * rollSpeedFactor * constructForward
                                    + finalYawInput * yawSpeedFactor * constructUp

    -- In atmosphere?
    if worldVertical:len() > 0.01 and unit.getAtmosphereDensity() > 0.0 then
        local autoRollRollThreshold = 1.0
        -- autoRoll on AND currentRollDeg is big enough AND player is not rolling
        if autoRoll == true and currentRollDegAbs > autoRollRollThreshold and finalRollInput == 0 then
            local targetRollDeg = utils.clamp(0,currentRollDegAbs-30, currentRollDegAbs+30);  -- we go back to 0 within a certain limit
            if (rollPID == nil) then
                rollPID = pid.new(autoRollFactor * 0.01, 0, autoRollFactor * 0.1) -- magic number tweaked to have a default factor in the 1-10 range
            end
            rollPID:inject(targetRollDeg - currentRollDeg)
            local autoRollInput = rollPID:get()

            targetAngularVelocity = targetAngularVelocity + autoRollInput * constructForward
        end
        local turnAssistRollThreshold = 20.0
        -- turnAssist AND currentRollDeg is big enough AND player is not pitching or yawing
        if turnAssist == true and currentRollDegAbs > turnAssistRollThreshold and finalPitchInput == 0 and finalYawInput == 0 then
            local rollToPitchFactor = turnAssistFactor * 0.1 -- magic number tweaked to have a default factor in the 1-10 range
            local rollToYawFactor = turnAssistFactor * 0.025 -- magic number tweaked to have a default factor in the 1-10 range

            -- rescale (turnAssistRollThreshold -> 180) to (0 -> 180)
            local rescaleRollDegAbs = ((currentRollDegAbs - turnAssistRollThreshold) / (180 - turnAssistRollThreshold)) * 180
            local rollVerticalRatio = 0
            if rescaleRollDegAbs < 90 then
                rollVerticalRatio = rescaleRollDegAbs / 90
            elseif rescaleRollDegAbs < 180 then
                rollVerticalRatio = (180 - rescaleRollDegAbs) / 90
            end

            rollVerticalRatio = rollVerticalRatio * rollVerticalRatio

            local turnAssistYawInput = - currentRollDegSign * rollToYawFactor * (1.0 - rollVerticalRatio)
            local turnAssistPitchInput = rollToPitchFactor * rollVerticalRatio

            targetAngularVelocity = targetAngularVelocity
                                + turnAssistPitchInput * constructRight
                                + turnAssistYawInput * constructUp
        end
    end

    -- Engine commands
    local keepCollinearity = 1 -- for easier reading
    local dontKeepCollinearity = 0 -- for easier reading
    local tolerancePercentToSkipOtherPriorities = 1 -- if we are within this tolerance (in%), we don't go to the next priorities

    -- Rotation
    local angularAcceleration = torqueFactor * (targetAngularVelocity - constructAngularVelocity)
    local airAcceleration = vec3(core.getWorldAirFrictionAngularAcceleration())
    angularAcceleration = angularAcceleration - airAcceleration -- Try to compensate air friction
    Nav:setEngineTorqueCommand('torque', angularAcceleration, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)

    -- Brakes
    local brakeAcceleration = -finalBrakeInput * (brakeSpeedFactor * constructVelocity + brakeFlatFactor * constructVelocityDir)
    Nav:setEngineForceCommand('brake', brakeAcceleration)

    -- AutoNavigation regroups all the axis command by 'TargetSpeed'
    local autoNavigationEngineTags = ''
    local autoNavigationAcceleration = vec3()
    local autoNavigationUseBrake = false

    -- Longitudinal Translation
    local longitudinalEngineTags = 'thrust analog longitudinal'
    local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
    if (longitudinalCommandType == axisCommandType.byThrottle) then
        local longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
        Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
    elseif  (longitudinalCommandType == axisCommandType.byTargetSpeed) then
        local longitudinalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.longitudinal)
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. longitudinalEngineTags
        autoNavigationAcceleration = autoNavigationAcceleration + longitudinalAcceleration
        if (Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal) == 0 or -- we want to stop
            Nav.axisCommandManager:getCurrentToTargetDeltaSpeed(axisCommandId.longitudinal) < - Nav.axisCommandManager:getTargetSpeedCurrentStep(axisCommandId.longitudinal) * 0.5) -- if the longitudinal velocity would need some braking
        then
            autoNavigationUseBrake = true
        end

    end

    -- Lateral Translation
    local lateralStrafeEngineTags = 'thrust analog lateral'
    local lateralCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.lateral)
    if (lateralCommandType == axisCommandType.byThrottle) then
        local lateralStrafeAcceleration =  Nav.axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
        Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
    elseif  (lateralCommandType == axisCommandType.byTargetSpeed) then
        local lateralAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.lateral)
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. lateralStrafeEngineTags
        autoNavigationAcceleration = autoNavigationAcceleration + lateralAcceleration
    end

    -- Vertical Translation
    local verticalStrafeEngineTags = 'thrust analog vertical'
    local verticalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.vertical)
    if (verticalCommandType == axisCommandType.byThrottle) then
        local verticalStrafeAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
        Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
    elseif  (verticalCommandType == axisCommandType.byTargetSpeed) then
        local verticalAcceleration = Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.vertical)
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. verticalStrafeEngineTags
        autoNavigationAcceleration = autoNavigationAcceleration + verticalAcceleration
    end

    -- Auto Navigation (Cruise Control)
    if (autoNavigationAcceleration:len() > constants.epsilon) then
        if (brakeInput ~= 0 or autoNavigationUseBrake or math.abs(constructVelocityDir:dot(constructForward)) < 0.95)  -- if the velocity is not properly aligned with the forward
        then
            autoNavigationEngineTags = autoNavigationEngineTags .. ', brake'
        end
        Nav:setEngineForceCommand(autoNavigationEngineTags, autoNavigationAcceleration, dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
    end

    -- Rockets
    Nav:setBoosterCommand('rocket_engine')
end

-- Slot events are available if slot type is set with the --slot command line option.
function script.onMouseDown (x, y)
  --screen.setCenteredText("mouse down: x=" .. x .. " , y=" .. y)
end

-- Call the start event handler
-- Alternatively, initialization code can be placed anywhere in this file.
-- The only requirement is that there is a global "script" object with event handlers
script.onStart()
