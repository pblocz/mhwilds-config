--v1.0.0

--import common
local statics = require("utility/Statics")
--generate enums
local VolumetricFogTextureSizes = statics.generate("via.render.VolumetricFogControl.TextureSize", true)
local VolumetricFogIntegrationTypes = statics.generate("via.render.VolumetricFogControl.IntegrationType", true)
local VolumetricFogJitterNoiseTypes = statics.generate("via.render.VolumetricFogControl.JitterNoiseType", true)

--enums
local volumetricFogTextureSizeOptions = {
    "Lowest (" .. VolumetricFogTextureSizes[2] .. ", Hidden)",
    "Lower (" .. VolumetricFogTextureSizes[3] .. ", Hidden)",
    "Low (" .. VolumetricFogTextureSizes[0] .. ")",
    "High (" .. VolumetricFogTextureSizes[1] .. ")",
}

local volumetricFogTextureSizeValueMap = {
    VolumetricFogTextureSizes.W96xH54xD32,
    VolumetricFogTextureSizes.W96xH54xD64,
    VolumetricFogTextureSizes.W160xH90xD64,
    VolumetricFogTextureSizes.W160xH90xD128
}

--Default settings
local defaultSettings =
{
    volumetricFogTextureSize = 0, -- Low
    ambientLightEnabled = true,
    ambientLightRateMultiplier = 1.0,
    emissionEnabled = true,
    fogCullingDistanceMultiplier = 1.0,
    advancedOptionsEnabled = false,
    shadowEnabled = true,
    depthDecodingParamMultiplier = 1.0,
    softnessMultiplier = 1.0,
    prevFrameBlendFactorMultiplier = 1.0,
    shadowCullingBlendFactorScaleMultiplier = 1.0,
    rejectionEnabled = true,
    rejectSensitivityMultiplier = 1.0,
    rejectSensitivityFactorMultiplier = 1.0,
    leakBiasMultiplier = 1.0,
    overrideIntegrationType = false,
    integrationType = 0,
    overrideJitterNoiseType = false,
    jitterNoiseType = 0,
    overrideFadeDistance = false,
    fadeDistance = -10.0,
    fadeDensity = 10.0
}

--Init settings with defaults
local settings = {}
for k,v in pairs(defaultSettings) do
    settings[k] = v
end

--Saves settings to json
local function SaveSettings()
    json.dump_file("mhwilds_tweak_volumetric_fogs.json", settings)
end

--Loads settings from json and puts into settings table
local function LoadSettings()
    local loadedTable = json.load_file("mhwilds_tweak_volumetric_fogs.json")
    if loadedTable ~= nil then
        for key, val in pairs(loadedTable) do
            settings[key] = loadedTable[key]
        end
    end
end

--Load settings at the start
LoadSettings()
--Get singletons and manager types
local graphicsManager = sdk.get_managed_singleton("app.GraphicsManager")
local volumetricFogControllerType = sdk.find_type_definition("ace.PostEffect.cVolumetricFogController")
local volumetricFogControlControllerType = sdk.find_type_definition("ace.PostEffect.cVolumetricFogControlController")
--Get gameobjects, components, and type definitions
-- local float2Type = sdk.find_type_definition("via.Float2")

--Apply settings on demand
local function ApplySettings()
    --Force a graphic setting refresh, triggering the hook
    local graphicsSetting = graphicsManager:call("get_NowGraphicsSetting")
    graphicsManager:call("setGraphicsSetting", graphicsSetting)
end

--Resets settings to defaults
local function ResetSettings()
    for key, val in pairs(defaultSettings) do
        settings[key] = defaultSettings[key]
    end
    ApplySettings()
end

--Hooks
local function pre_volumetricFogControllerApplyToComponent(args)
    local volumetricFogParam = sdk.to_managed_object(args[3])
    -- if volumetricFogParam:call("get_GlobalFog") and settings.enableGlobalFog then
        -- return
    -- end
    -- if volumetricFogParam:call("get_ExpHeightFog") and settings.enableExpHeightFog then
        -- return
    -- end
    -- volumetricFogParam:call("set_Enabled", false)
    return
end
local function post_volumetricFogControllerApplyToComponent()
end
local function pre_volumetricFogControlControllerApplyToComponent(args)
    local volumetricFogControlParam = sdk.to_managed_object(args[3])
    
    local textureSizeSetting = volumetricFogTextureSizeValueMap[settings.volumetricFogTextureSize]
    volumetricFogControlParam:call("set_TextureSize", textureSizeSetting)

    local currShadowEnabled = volumetricFogControlParam:get_ShadowEnabled()
    volumetricFogControlParam:call("set_ShadowEnabled", currShadowEnabled and settings.shadowEnabled)

    local currAmbientLightEnabled = volumetricFogControlParam:get_AmbientLightEnabled()
    volumetricFogControlParam:call("set_AmbientLightEnabled", currAmbientLightEnabled and settings.ambientLightEnabled)

    if currAmbientLightEnabled and settings.ambientLightEnabled then
        local currAmbientLightRate = volumetricFogControlParam:call("get_AmbientLightRate")
        volumetricFogControlParam:call("set_AmbientLightRate", currAmbientLightRate * settings.ambientLightRateMultiplier)
    end

    local currEmissionEnabled = volumetricFogControlParam:get_EmissionEnabled()
    volumetricFogControlParam:call("set_EmissionEnabled", currEmissionEnabled and settings.emissionEnabled)
    
    local currCullingDistance = volumetricFogControlParam:call("get_FogCullingDistance")
    volumetricFogControlParam:call("set_FogCullingDistance", currCullingDistance * settings.fogCullingDistanceMultiplier)
    
    if settings.advancedOptionsEnabled then
    
        local currDepthDecodingParam = volumetricFogControlParam:call("get_DepthDecodingParam")
        volumetricFogControlParam:call("set_DepthDecodingParam", currDepthDecodingParam * settings.depthDecodingParamMultiplier)

        local currSoftness = volumetricFogControlParam:call("get_VolumetricFogSoftness")
        volumetricFogControlParam:call("set_VolumetricFogSoftness", currSoftness * settings.softnessMultiplier)

        local currPrevFrameBlendFactor = volumetricFogControlParam:call("get_PrevFrameBlendFactor")
        volumetricFogControlParam:call("set_PrevFrameBlendFactors", currPrevFrameBlendFactor * settings.prevFrameBlendFactorMultiplier)

        local currShadowCullingBlendFactorScale = volumetricFogControlParam:call("get_ShadowCullingBlendFactorScale")
        volumetricFogControlParam:call("set_ShadowCullingBlendFactorScale", currShadowCullingBlendFactorScale * settings.shadowCullingBlendFactorScaleMultiplier)

        volumetricFogControlParam:call("set_Rejection", settings.rejectionEnabled)
        if settings.rejectionEnabled then
            local currRejectSensitivity = volumetricFogControlParam:call("get_RejectSensitivity")
            local currRejectSensitivityFactor = volumetricFogControlParam:call("get_RejectSensitivityFactor")
            volumetricFogControlParam:call("set_RejectSensitivity", currRejectSensitivity * settings.rejectSensitivityMultiplier)
            volumetricFogControlParam:call("set_RejectSensitivityFactor", currRejectSensitivityFactor * settings.rejectSensitivityFactorMultiplier)
        end

        local currLeakBias = volumetricFogControlParam:call("get_LeakBias")
        volumetricFogControlParam:call("set_LeakBias", currLeakBias * settings.leakBiasMultiplier)
        
        if settings.overrideIntegrationType then
            volumetricFogControlParam:call("set_IntegrationType", settings.integrationType)
        end
        
        if settings.overrideJitterNoiseType then
            volumetricFogControlParam:call("set_JitterNoise", settings.jitterNoiseType)
        end
       
    end

    if settings.overrideFadeDistance then
        local param = volumetricFogControlParam:call("get_NearFadeParams")
        param.x = settings.fadeDistance
        param.y = settings.fadeDensity
        volumetricFogControlParam:call("set_NearFadeParams", param)
    end

    return
end
local function post_volumetricFogControlControllerApplyToComponent()
end

--Create hook which applies settings when fogs are modified
-- sdk.hook(volumetricFogControllerType:get_method("applyToComponent"), pre_volumetricFogControllerApplyToComponent, post_volumetricFogControllerApplyToComponent)
sdk.hook(volumetricFogControlControllerType:get_method("applyToComponent"), pre_volumetricFogControlControllerApplyToComponent, post_volumetricFogControlControllerApplyToComponent)
--Script generated UI
re.on_draw_ui(function()
    if imgui.tree_node("Tweak volumetric fog(s)") then
        local changed = false
        local thisChanged = false
        -- local applyClicked = false
        local saveClicked = false
        local defaultsClicked = false

        imgui.text("Note: Changes are applied immediately")
        
        imgui.set_next_item_width(200)
        thisChanged, settings.volumetricFogTextureSize = imgui.combo("Volumetric fog resolution", settings.volumetricFogTextureSize, volumetricFogTextureSizeOptions)  changed = changed or thisChanged
        if imgui.is_item_hovered() then
            imgui.set_tooltip("The lower you go the more likely it will look blocky, especially with Accurate fog integration type enabled")
        end
        
        thisChanged, settings.ambientLightEnabled = imgui.checkbox("Ambient light enabled", settings.ambientLightEnabled)  changed = changed or thisChanged
        if settings.ambientLightEnabled then
            imgui.indent(50)
            imgui.set_next_item_width(100)
            thisChanged, settings.ambientLightRateMultiplier = imgui.drag_float("Ambient light amount", settings.ambientLightRateMultiplier, 0.01, 0.0, 10.0)  changed = changed or thisChanged
            imgui.unindent(50)
        end

        thisChanged, settings.emissionEnabled = imgui.checkbox("Emission enabled", settings.emissionEnabled)  changed = changed or thisChanged
        if imgui.is_item_hovered() then
            imgui.set_tooltip("This is a subtle effect")
        end
        
        imgui.text("Fog culling distance")
        imgui.push_id("fogCullingDistance")
        imgui.set_next_item_width(100)
        thisChanged, settings.fogCullingDistanceMultiplier = imgui.drag_float(" ", settings.fogCullingDistanceMultiplier, 0.01, 0.0, 10.0)  changed = changed or thisChanged
        imgui.pop_id()
        
        thisChanged, settings.overrideFadeDistance = imgui.checkbox("Override near fade distance", settings.overrideFadeDistance)  changed = changed or thisChanged
        if imgui.is_item_hovered() then
            imgui.set_tooltip("These are absolute settings (not multipliers), so it might be buggy")
        end
        if settings.overrideFadeDistance then
            imgui.indent(50)
            imgui.set_next_item_width(100)
            thisChanged, settings.fadeDistance = imgui.drag_float("Fade distance", settings.fadeDistance, 0.1, -10.0, 2000.0)  changed = changed or thisChanged
            if imgui.is_item_hovered() then
                imgui.begin_tooltip()
                imgui.text("AKA falloff distance")
                imgui.set_tooltip("Defaults to -10.0 (behind the camera)")
                imgui.end_tooltip()
            end
            imgui.set_next_item_width(100)
            thisChanged, settings.fadeDensity = imgui.drag_float("Fade \"hardness\"", settings.fadeDensity, 0.001, 0.0, 10.0)  changed = changed or thisChanged
            if imgui.is_item_hovered() then
                imgui.begin_tooltip()
                imgui.text("AKA falloff gradient")
                imgui.text("Defaults to 10.0, but seems to max out at around 0.02 - 0.1")
                imgui.end_tooltip()
            end
            imgui.unindent(50)
        end
        
        if imgui.tree_node("Advanced (no visible changes)") then
            thisChanged, settings.advancedOptionsEnabled = imgui.checkbox("Enable advanced options", settings.advancedOptionsEnabled)  changed = changed or thisChanged
            
            if not settings.advancedOptionsEnabled then
                imgui.begin_disabled(true)
            end
            
            thisChanged, settings.shadowEnabled = imgui.checkbox("Shadow enabled", settings.shadowEnabled)  changed = changed or thisChanged
            imgui.push_item_width(100)
            thisChanged, settings.depthDecodingParamMultiplier = imgui.drag_float("Depth decoding parameter", settings.depthDecodingParamMultiplier, 0.01, 0.0, 10.0)  changed = changed or thisChanged
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Seems to affect fog rendering in the far distance")
            end
            thisChanged, settings.softnessMultiplier = imgui.drag_float("Softness", settings.softnessMultiplier, 0.01, 0.0, 10.0)  changed = changed or thisChanged
            thisChanged, settings.prevFrameBlendFactorMultiplier = imgui.drag_float("Previous frame blend factor", settings.prevFrameBlendFactorMultiplier, 0.01, 0.0, 10.0)  changed = changed or thisChanged
            thisChanged, settings.shadowCullingBlendFactorScaleMultiplier = imgui.drag_float("Shadow culling blend factor scale", settings.shadowCullingBlendFactorScaleMultiplier, 0.01, 0.0, 10.0)  changed = changed or thisChanged
            thisChanged, settings.rejectionEnabled = imgui.checkbox("Rejection enabled", settings.rejectionEnabled)  changed = changed or thisChanged
            imgui.pop_item_width(100)
            if settings.rejectionEnabled then
                imgui.indent(40)
                imgui.set_next_item_width(100)
                thisChanged, settings.rejectSensitivityMultiplier = imgui.drag_float("Reject sensitivity", settings.rejectSensitivityMultiplier, 0.01, 0.0, 10.0)  changed = changed or thisChanged
                imgui.set_next_item_width(100)
                thisChanged, settings.rejectSensitivityFactorMultiplier = imgui.drag_float("Reject sensitivity factor", settings.rejectSensitivityFactorMultiplier, 0.01, 0.0, 10.0)  changed = changed or thisChanged
                imgui.unindent(40)
            end
            imgui.set_next_item_width(100)
            thisChanged, settings.leakBiasMultiplier = imgui.drag_float("Leak bias", settings.leakBiasMultiplier, 0.01, 0.0, 10.0)  changed = changed or thisChanged
            
            imgui.push_id("integrationType")
            imgui.set_next_item_width(200)
            if not settings.overrideIntegrationType then
                imgui.begin_disabled(true)
            end
            thisChanged, settings.integrationType = imgui.combo("Fog integration type", settings.integrationType, VolumetricFogIntegrationTypes)  changed = changed or thisChanged
            if imgui.is_item_hovered() then
                imgui.begin_tooltip()
                imgui.text("Accurate makes low-quality blocky artifacts very obvious, why would you do this")
                imgui.text("Defaults to Blurry")
                imgui.end_tooltip()
            end
            if not settings.overrideIntegrationType then
                imgui.end_disabled()
            end
            imgui.same_line()
            thisChanged, settings.overrideIntegrationType = imgui.checkbox("Override", settings.overrideIntegrationType)  changed = changed or thisChanged
            if imgui.is_item_hovered() then
                imgui.begin_tooltip()
                imgui.text("Accurate makes low-quality blocky artifacts very obvious, why would you do this")
                imgui.text("Defaults to Blurry")
                imgui.end_tooltip()
            end
            imgui.pop_id()
            
            imgui.push_id("jitterNoiseType")
            imgui.set_next_item_width(200)
            if not settings.overrideJitterNoiseType then
                imgui.begin_disabled(true)
            end
            thisChanged, settings.jitterNoiseType = imgui.combo("Fog jitter noise type", settings.jitterNoiseType, VolumetricFogJitterNoiseTypes)  changed = changed or thisChanged
            if not settings.overrideJitterNoiseType then
                imgui.end_disabled()
            end
            imgui.same_line()
            thisChanged, settings.overrideJitterNoiseType = imgui.checkbox("Override", settings.overrideJitterNoiseType)  changed = changed or thisChanged
            imgui.pop_id()
            
            if not settings.advancedOptionsEnabled then
                imgui.end_disabled(true)
            end
        
            imgui.tree_pop()
        end

        imgui.push_style_color(21, -16751773)
        saveClicked = imgui.button("Save settings")
        imgui.pop_style_color(1)
        imgui.push_style_color(21, -16777117)
        defaultsClicked = imgui.button("Reset to defaults")
        imgui.pop_style_color(1)

        --Apply settings immediately, but only when any user change is done
        if changed then
            ApplySettings()
            changed = false
        end
        --Save settings
        if saveClicked then
            SaveSettings()
            saveClicked = false
        end
        --Reset settings
        if defaultsClicked then
            ResetSettings()
            defaultsClicked = false
        end

        imgui.tree_pop()
    end
end)