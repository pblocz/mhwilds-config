-- Thanks for checking out my mod!
-- I left a bunch of comments to help you understand what this script does.

--log.debug("low graphics mod starting...")

local config_path = "detail_config.json"

local settings = { -- Default settings
    mesh_lod_bias = 0,
    speedtree_lod_bias = 0,
    speedtree_min_lod = 2,
    disable_shadows = false,
    disable_tex_stream = false,
    texture_sampler_bias = 0,
    object_culling_ratio = 24,
    shadow_quality = 384,
    disable_particles = false,

    disable_footprints = false,

    culling_amount = 0,
    min_culling_dist = 10,

    hide_grass = true,
    hide_plants = true,
    hide_rocks = true,
    hide_decor = true,
    hide_decals = false,
    hide_lights = false,
    hide_particles = false,
    
    table_update_interval = 20.0,
    table_reload_interval = 5.0,
    reload_increment_steps = 50,
}
-- Load config json
local function load_settings()
    local loadedTable = json.load_file(config_path)
    if loadedTable ~= nil then
        for key, val in pairs(loadedTable) do
            settings[key] = loadedTable[key]
        end
    end
end

local function save_settings()
    json.dump_file(config_path, settings)
end

if json ~= nil then
    file = json.load_file(configPath)
    if file ~= nil then
		settings = file
    else
        json.dump_file(configPath, settings)
    end
end

local reset = false

local function reset_settings() -- Reset to defaults
    settings = {
        mesh_lod_bias = 0,
        speedtree_lod_bias = 0,
        speedtree_min_lod = 2,
        disable_shadows = false,
        disable_tex_stream = false,
        texture_sampler_bias = 0,
        object_culling_ratio = 24,
        shadow_quality = 384,
        disable_particles = false,

        disable_footprints = false,
        
        culling_amount = 0,
        min_culling_dist = 10,

        hide_grass = true,
        hide_plants = true,
        hide_rocks = true,
        hide_decor = true,
        hide_decals = false,
        hide_lights = false,
        hide_particles = false,
        
        table_update_interval = 20.0,
        table_reload_interval = 5.0,
        reload_increment_steps = 50,
    }
    --log.debug("settings reset.")
end

load_settings()

function string:startswith(start)
    return self:sub(1, #start) == start
end

local SceneManager = sdk.get_native_singleton("via.SceneManager")
local SceneManager_type = sdk.find_type_definition("via.SceneManager")

local function get_current_scene()
    local scene = sdk.call_native_func(SceneManager, SceneManager_type, "get_CurrentScene()")
    if scene == nil then
        return nil
    else
        return scene
    end
end

local current_scene = get_current_scene()

-- TO DO: Split into sub-modules

local MeshRenderer = sdk.get_native_singleton("via.render.MeshRenderer")
local MeshRenderer_type = sdk.find_type_definition("via.render.MeshRenderer")

function update_MeshRenderer()
    sdk.call_native_func(MeshRenderer, MeshRenderer_type, "set_LodBias", settings.mesh_lod_bias)
    --log.debug("StreamingLoadLodRate " ..sdk.call_native_func(MeshRenderer, MeshRenderer_type, "get_StreamingLoadLodRate"))
    --log.debug("MeshRenderer stuff set.")
end

local SpeedTree = sdk.get_managed_singleton("via.speedtree.SpeedTreeMasterInstance")
local SpeedTree_type = sdk.find_type_definition("via.speedtree.SpeedTreeMasterInstance")

function update_SpeedTree()
    sdk.call_native_func(SpeedTree, SpeedTree_type, "set_LodBias", settings.speedtree_lod_bias)
    sdk.call_native_func(SpeedTree, SpeedTree_type, "set_StreamingMeshMinimumLod", settings.speedtree_min_lod)
    --log.debug("SpeedTree stuff set.")
end

local Renderer = sdk.get_native_singleton("via.render.Renderer")
local Renderer_type = sdk.find_type_definition("via.render.Renderer")

function update_Renderer()
    if settings.disable_shadows == true then
        sdk.call_native_func(Renderer, Renderer_type, "set_DynamicShadowEnable", false)
    else
        sdk.call_native_func(Renderer, Renderer_type, "set_DynamicShadowEnable", true)
    end
    sdk.call_native_func(Renderer, Renderer_type, "set_DisableStreamingTexture", settings.disable_tex_stream)
    sdk.call_native_func(Renderer, Renderer_type, "set_SmallObjectCullingRatio", settings.object_culling_ratio) 
    --log.debug("Renderer stuff set.")
end
    
local Sampler = sdk.get_native_singleton("via.render.Sampler")
local Sampler_type = sdk.find_type_definition("via.render.Sampler")

function update_Sampler()
    sdk.call_native_func(Sampler, Sampler_type, "set_Bias", settings.texture_sampler_bias)
    --log.debug("Sampler stuff set.")
end

local LightRenderer = sdk.get_managed_singleton("via.render.LightRenderer")
local LightRenderer_type = sdk.find_type_definition("via.render.LightRenderer")

function update_LightRenderer()
    sdk.call_native_func(LightRenderer, LightRenderer_type, "set_ShadowResolution", settings.shadow_quality) 
    --log.debug("LightRenderer stuff set.")
end

local PlayerManager = sdk.get_managed_singleton("via.effect.detail.PlayerManager")
local PlayerManager_type = sdk.find_type_definition("via.effect.detail.PlayerManager")

function update_PlayerManager() -- fire, ambient dust, scoutflies, trails 
    if settings.disable_particles == true then
        sdk.call_native_func(PlayerManager, PlayerManager_type, "set_EnableDraw", false) -- Disables particle effects and a bunch of other stuff
    else
        sdk.call_native_func(PlayerManager, PlayerManager_type, "set_EnableDraw", true)
    end
    --log.debug("PlayerManager stuff set.")
end

local MasterFieldManager = sdk.get_managed_singleton('app.MasterFieldManager')
local MasterFieldManager_type = sdk.find_type_definition("app.MasterFieldManager")

local function get_current_stage()
    return sdk.call_native_func(MasterFieldManager, MasterFieldManager_type, "get_CurrentStageNumber")
end

local current_stage = -1 -- More efficient filtering of objects, as it filters based on what level you're on.
-- Stage -1 is the title screen.

local function update_all_settings()
    update_MeshRenderer()
    update_SpeedTree()
    update_Renderer()
    update_Sampler()
    update_LightRenderer()
    update_PlayerManager()
end

local get_component = sdk.find_type_definition('via.GameObject'):get_method('getComponent(System.Type)')

local function get_gameobject_component(gameObject, componentType)
    return get_component:call(gameObject, sdk.typeof(componentType))
end

local find_scene_objects = sdk.find_type_definition('via.Scene'):get_method('findComponents(System.Type)')
local get_object_components = sdk.find_type_definition('via.Component'):get_method('get_GameObject')
local get_name = sdk.find_type_definition('via.GameObject'):get_method('get_Name')
local get_draw = sdk.find_type_definition('via.GameObject'):get_method('get_DrawSelf')
local set_draw = sdk.find_type_definition('via.GameObject'):get_method('set_DrawSelf')
local set_update = sdk.find_type_definition('via.GameObject'):get_method('set_UpdateSelf')
local set_timescale = sdk.find_type_definition('via.GameObject'):get_method('set_TimeScale')

local cam_pos = { x = 0, y = 0, z = 0 } -- Camera position
local camera_transform = nil;
local cam_initialised = false;

local transform_get_position = sdk.find_type_definition("via.Transform"):get_method("get_Position")
function get_camera()
    --log.debug("get_camera")
    local camera = sdk.get_primary_camera()
    
    local camera_gameobject = camera:call("get_GameObject")
    camera_transform = camera_gameobject:call("get_Transform")

    cam_pos = transform_get_position:call(camera_transform)
    cam_initialised = true
end

get_camera()

-- Needed for culling distance
function update_cam_pos()
    cam_pos = transform_get_position:call(camera_transform)
end

-- Calculates distance between the camera and provided coordinates.
function dist(pos)
    if cam_initialised == false then
        
    end
    --log.debug("cam_pos = {"..tostring(cam_pos.x)..", "..tostring(cam_pos.y)..", "..tostring(cam_pos.z).."}")
    local distance = math.sqrt((pos.x - cam_pos.x)^2 + (pos.y - cam_pos.y)^2 + (pos.z - cam_pos.z)^2)
    --log.debug(distance)
    return distance 
end

local function get_full_table()
    --log.debug("get_full_table")
    --current_scene = get_current_scene()
    local tbl = find_scene_objects:call(current_scene, sdk.typeof('via.Transform'))
    tbl = tbl and tbl:get_elements() or {}
    --log.debug("#tbl = " ..#tbl)
    return tbl
end

local full_scene_table = get_full_table()

local obj_tables_reload_ready = false

local grass_table = {}
local plants_table = {}
local rocks_table = {}
local decor_table = {}
local decals_table = {}
local lights_table = {}
local particles_table = {}

local function get_filtered_tables() -- This is meant only for when the script initialises or is manually reset.
    --log.debug("get_filtered_tables()")
    full_scene_table = get_full_table()

    grass_table = {}
    plants_table = {}
    rocks_table = {}
    decor_table = {}
    decals_table = {}
    lights_table = {}
    particles_table = {}
    
    for i = 1, #full_scene_table do
        local s, object = pcall(get_object_components.call, get_object_components, full_scene_table[i])
        if s and object then
            local name = get_name:call(object)
            -- This filters the objects to be made hidden
            -- Some are hand picked through trial and error, making sure the script doesn't hide core level geometry.
            -- More to be added!
                if not name:match("Reduction") 
                and not name:startswith("Sound") 
                and not name:startswith("evpe") 
                and not name:startswith("envp") 
                and not name:lower():startswith("npc") 
                and not name:lower():match("pointgraph") 
                and not name:lower():match("tcol") 
                and not name:lower():match("tree") -- Trees often have collision, so hiding them may lead to awkward situations in game.
                and not name:lower():match("zone") 
                and not name:lower():match("dammy") 
                and not name:lower():startswith("em") 
                and not name:startswith("st102_a01_03")
                and not name:startswith("st102_a01_04_n04_p00_p06")
                and not name:startswith("st402_a01_04")
                then
                if settings.hide_grass == true then
                    if 
                    name:startswith("st101_a08_Grass") -- long grass
                    or name:startswith("st101_a08_GreenGrass") 
                    or name:startswith("st102_a01_01_n05_p00")
                    or name:startswith("st102_a05_00_p01")
                    or (current_stage == 104
                    and (name:startswith("st103_a08") -- plant
                    or name:startswith("st103_a10")) -- plant
                    )
                    -- st104 = iceshard cliffs
                    or (current_stage == 104
                    and (name:startswith("st104_a06_01_n")
                    or name:startswith("st104_a12_01_n1"))
                    )
                    or name:startswith("st105_a30_01_p0")
                    or name:startswith("st402_a01_01") 
                    or name:startswith("st402_a01_02") 
                    or name:startswith("st402_a01_03") 
                    or name:startswith("st402_a01_05") 
                    or name:startswith("st402_a01_06")
                    then
                        --tbl[#tbl+1] = item
                        grass_table[#grass_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_plants == true then
                    if  name:lower():match("flower") 
                    or name:lower():match("plant") 
                    -- st101 = windward plains
                    or name:startswith("st101_a08_lowgrass") -- short grass
                    -- st102 = scarlet forest
                    or (current_stage == 102 --forest
                    and (name:startswith("st102_a01_01_n04_p00")
                    -- or name:startswith("st102_a01_04_n00")
                    --or name:startswith("st102_a01_04_n01")
                    or name:startswith("st102_a01_02")
                    or name:startswith("st102_a01_04")
                    or name:startswith("st102_a01_05")
                    or name:startswith("st102_a01_06")
                    or name:startswith("st102_a01_07")
                    or name:startswith("st102_a01_08")
                    or name:startswith("st102_a01_09")
                    or name:startswith("st102_a01_12")
                    or name:startswith("st102_a05_02")
                    or name:startswith("st102_a05_03")
                    or name:startswith("st102_a05_09")
                    or name:startswith("st102_a06_02") 
                    or name:startswith("st102_a06_05") 
                    or name:startswith("st102_a06_06")
                    or name:startswith("st102_a08_Grass")
                    or name:startswith("st102_a08_Plant"))
                    )
                    -- st103 = oilwell basin
                    or name:startswith("st103_a01_0")

                    or (current_stage == 105 --W******
                    and (name:startswith("st105_a03_02")

                    or name:startswith("sm01_112")
                    
                    or name:startswith("sm11_066")
                    or name:startswith("sm11_062") --plant
                
                    or name:startswith("sm13_013") --plant
                    or name:startswith("sm13_041") --plant
                    or name:startswith("sm13_034")
                    or name:startswith("sm13_039")
                
                    or name:startswith("sm15_003")
                    or name:startswith("sm15_006")
                    or name:startswith("sm15_009"))
                    )
                    then
                        plants_table[#plants_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_rocks == true then
                    if name:lower():match("ston") 
                    or name:lower():match("dust") 
                    or name:lower():match("sand") 
                    or name:lower():match("rubble") 
                    or name:lower():match("fulug") --rocks
                    
                    or name == "st102_a08_Rubble_00_p14_p00_p01"

                    or (current_stage == 103
                    and (name:startswith("sm22_008")--oilwell
                    or name:startswith("sm22_201")--oilwell
                    or name:startswith("sm22_208")--oilwell
                    or name:startswith("sm23_201")--oilwell
                    or name:startswith("sm43_404") -- oilwell
                    or name:startswith("sm43_405")) -- oilwell
                    )
                    or name:startswith("sm22_219")
                    or name:startswith("sm22_300")
                    or name:startswith("sm22_309")
                    or name:startswith("sm22_305") --ice
                    or name:startswith("sm22_307")
                    or name:startswith("sm22_310")
                    
                    or name:startswith("sm23_032")--rock
                    or name:startswith("sm23_09")--rock
                    or name:startswith("sm23_120")
                    or name:startswith("sm23_142")
                    or name:startswith("sm23_149")
                    or name:startswith("sm43_166")
                    or name:startswith("sm43_504")
                    or name:startswith("sm43_501")
                    or name:startswith("sm43_506")

                    or name:startswith("sm41_751")

                    or name:startswith("sm42_7")

                    or name:startswith("sm45_076")
                    or name:startswith("sm45_090")
                    or name:startswith("sm45_091")
                    or name:startswith("sm45_094")
                    or name:startswith("sm45_506")
                    or name:startswith("sm45_134")

                    or name:startswith("sm47_02") 

                    or name:startswith("sm48_000") 
                    or name:startswith("sm48_002") 
                    or name:startswith("sm48_010") 
                    or name:startswith("sm48_014")
                    then
                        rocks_table[#rocks_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_decor == true then
                    if not name:startswith("sm41_002")
                    and not name:startswith("sm41_053")
                    and not name:startswith("sm42_006")
                    and not name:startswith("sm42_016")
                    and
                    (
                    name:startswith("sm41_120_00")
                    or name:startswith("sm41_008")
                    or name:startswith("sm41_01")
                    or name:startswith("sm41_020")
                    or name:startswith("sm41_027")
                    or name:startswith("sm41_05")
                    or name:startswith("sm41_051")
                    or name:startswith("sm41_07")
                    or name:startswith("sm41_097")
                    or name:startswith("sm41_099")
                    or name:startswith("sm41_144")
                    or name:startswith("sm41_19")
                    or name:startswith("sm42_01")
                    or name:startswith("sm42_001")
                    or name:startswith("sm43_004")
                    or name:startswith("sm45_04")
                    )
                    then
                        decor_table[#decor_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_decals == true then
                    if name == "Decal"
                    or name:lower():match("decal")
                    or name:lower():match("dacal_") 
                    then
                        decals_table[#decals_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_lights == true then
                    if name:startswith("Basic00_SpotLight")
                    or name:startswith("Basic00_ProjSpotLight")
                    or name:startswith("Basic00_PointLight")
                    then
                        lights_table[#lights_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_particles == true then
                    if name == "no_name_effect"
                    or name:startswith("11_Sand")
                    or name:match("sandwave")
                    then
                        particles_table[#particles_table+1] = full_scene_table[i]
                    end
                end
            end
        end
    end
    return tbl
end

local tbl_stage = 1

local obj_tables_update_ready = true
local grass_done = false
local plants_done = false
local rocks_done = false
local decor_done = false
local decals_done = false
local lights_done = false
local particles_done = false

-- Getting and filtering every single object in the scene at once causes a hitch. 
-- This system makes it smooth by doing it incrementally over several frames.
local function get_filtered_tables_incremental()
    -- See the function above for how this works
    --log.debug("get_filtered_tables_incremental at stage "..tbl_stage)
    full_scene_table = get_full_table()

    local range_min = 1
    local range_max = 1000
    
    if tbl_stage == 1 then
        range_min = 1
        range_max = math.ceil(#full_scene_table / settings.reload_increment_steps)
    else
        range_min = math.floor((#full_scene_table / settings.reload_increment_steps) * (tbl_stage - 1))
        range_max = math.ceil((#full_scene_table / settings.reload_increment_steps) * tbl_stage)
    end
    
    --log.debug("getting objects "..range_min.." to "..range_max)
    for i = range_min, range_max do
        --log.debug("tostring(list["..i.."]) = "..tostring(full_scene_table[i]))
            local s, object = pcall(get_object_components.call, get_object_components, full_scene_table[i])
            if s and object then
                local name = get_name:call(object)
                -- Starting with stuff to filter out, so it quickly skips to the next object.
                if not name:match("Reduction") 
                and not name:startswith("Sound") 
                and not name:startswith("evpe") 
                and not name:startswith("envp") 
                and not name:lower():startswith("npc") 
                and not name:lower():match("pointgraph") 
                and not name:lower():match("tcol") 
                and not name:lower():match("tree") -- Trees often have collision, so hiding them may lead to awkward situations in game.
                and not name:lower():match("zone") 
                and not name:lower():match("dammy") 
                and not name:lower():startswith("em") 
                and not name:startswith("st102_a01_03")
                and not name:startswith("st102_a01_04_n04_p00_p06")
                and not name:startswith("st402_a01_04")
                then
                if settings.hide_grass == true then
                    if 
                    name:startswith("st101_a08_Grass") -- long grass
                    or name:startswith("st101_a08_GreenGrass") 
                    or (current_stage == 102
                    and (name:startswith("st102_a01_01_n05_p00")
                    or name:startswith("st102_a05_00_p01"))
                    )
                    or name:startswith("st103_a08") -- plant
                    or name:startswith("st103_a10") -- plant
                    -- st104 = iceshard cliffs
                    or (current_stage == 104
                    and (name:startswith("st104_a06_01_n")
                    or name:startswith("st104_a12_01_n1"))
                    )
                    or name:startswith("st105_a30_01_p0")
                    or name:startswith("st402_a01_01") 
                    or name:startswith("st402_a01_02") 
                    or name:startswith("st402_a01_03") 
                    or name:startswith("st402_a01_05") 
                    or name:startswith("st402_a01_06")
                    then
                        --tbl[#tbl+1] = item
                        grass_table[#grass_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_plants == true then
                    if  name:lower():match("flower") 
                    or name:lower():match("plant") 
                    -- st101 = windward plains
                    or name:startswith("st101_a08_lowgrass") -- short grass
                    -- st102 = scarlet forest
                    or (current_stage == 102 --forest
                    and (name:startswith("st102_a01_01_n04_p00")
                    -- or name:startswith("st102_a01_04_n00")
                    --or name:startswith("st102_a01_04_n01")
                    or name:startswith("st102_a01_02")
                    or name:startswith("st102_a01_04")
                    or name:startswith("st102_a01_05")
                    or name:startswith("st102_a01_06")
                    or name:startswith("st102_a01_07")
                    or name:startswith("st102_a01_08")
                    or name:startswith("st102_a01_09")
                    or name:startswith("st102_a01_12")
                    or name:startswith("st102_a05_02")
                    or name:startswith("st102_a05_03")
                    or name:startswith("st102_a05_09")
                    or name:startswith("st102_a06_02") 
                    or name:startswith("st102_a06_05") 
                    or name:startswith("st102_a06_06")
                    or name:startswith("st102_a08_Grass")
                    or name:startswith("st102_a08_Plant"))
                    )
                    -- st103 = oilwell basin
                    or name:startswith("st103_a01_0")
                    
                    or (current_stage == 105 --W******
                    and (name:startswith("st105_a03_02")

                    or name:startswith("sm01_112")
                    
                    or name:startswith("sm11_066")
                    or name:startswith("sm11_062") --plant
                
                    or name:startswith("sm13_013") --plant
                    or name:startswith("sm13_041") --plant
                    or name:startswith("sm13_034")
                    or name:startswith("sm13_039")
                
                    or name:startswith("sm15_003")
                    or name:startswith("sm15_006")
                    or name:startswith("sm15_009"))
                    )
                    then
                        plants_table[#plants_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_rocks == true then
                    if name:lower():match("ston") 
                    or name:lower():match("dust") 
                    or name:lower():match("sand") 
                    or name:lower():match("rubble") 
                    or name:lower():match("fulug") --rocks
                    
                    or name == "st102_a08_Rubble_00_p14_p00_p01"
                    
                    or (current_stage == 103
                    and (name:startswith("sm22_008")--oilwell
                    or name:startswith("sm22_201")--oilwell
                    or name:startswith("sm22_208")--oilwell
                    or name:startswith("sm23_201")--oilwell
                    or name:startswith("sm43_404") -- oilwell
                    or name:startswith("sm43_405")) -- oilwell
                    )
                    or name:startswith("sm22_219")
                    or name:startswith("sm22_300")
                    or name:startswith("sm22_309")
                    or name:startswith("sm22_305") --ice
                    or name:startswith("sm22_307")
                    or name:startswith("sm22_310")
                    
                    or name:startswith("sm23_032")--rock
                    or name:startswith("sm23_09")--rock
                    or name:startswith("sm23_120")
                    or name:startswith("sm23_142")
                    or name:startswith("sm23_149")
                    or name:startswith("sm43_166")
                    or name:startswith("sm43_504")
                    or name:startswith("sm43_501")
                    or name:startswith("sm43_506")

                    or name:startswith("sm41_751")

                    or name:startswith("sm42_7")

                    or name:startswith("sm45_076")
                    or name:startswith("sm45_090")
                    or name:startswith("sm45_091")
                    or name:startswith("sm45_094")
                    or name:startswith("sm45_506")
                    or name:startswith("sm45_134")

                    or name:startswith("sm47_02") 

                    or name:startswith("sm48_000") 
                    or name:startswith("sm48_002") 
                    or name:startswith("sm48_010") 
                    or name:startswith("sm48_014")
                    then
                        rocks_table[#rocks_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_decor == true then
                    if not name:startswith("sm41_002")
                    and not name:startswith("sm41_053")
                    and not name:startswith("sm42_006")
                    and not name:startswith("sm42_016")
                    and
                    (
                    name:startswith("sm41_120_00")
                    or name:startswith("sm41_008")
                    or name:startswith("sm41_01")
                    or name:startswith("sm41_020")
                    or name:startswith("sm41_027")
                    or name:startswith("sm41_05")
                    or name:startswith("sm41_051")
                    or name:startswith("sm41_07")
                    or name:startswith("sm41_097")
                    or name:startswith("sm41_099")
                    or name:startswith("sm41_144")
                    or name:startswith("sm41_19")
                    or name:startswith("sm42_01")
                    or name:startswith("sm42_001")
                    or name:startswith("sm43_004")
                    or name:startswith("sm45_04")
                    )
                    then
                        decor_table[#decor_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_decals == true then
                    if name == "Decal"
                    or name:lower():match("decal")
                    or name:lower():match("dacal_") 
                    then
                        decals_table[#decals_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_lights == true then
                    if name:startswith("Basic00_SpotLight")
                    or name:startswith("Basic00_ProjSpotLight")
                    or name:startswith("Basic00_PointLight")
                    then
                        lights_table[#lights_table+1] = full_scene_table[i]
                    end
                end
                if settings.hide_particles == true then
                    if name == "no_name_effect"
                    or name:startswith("11_Sand")
                    or name:match("sandwave")
                    then
                        particles_table[#particles_table+1] = full_scene_table[i]
                    end
                end
            end
        end
    end
    if tbl_stage >= settings.reload_increment_steps then
        tbl_stage = 1 
        grass_done = true
        plants_done = true
        rocks_done = true
        decor_done = true
        decals_done = true
        lights_done = true
        particles_done = true
        obj_tables_reload_ready = false
    else
        tbl_stage = tbl_stage + 1
    end
end


local prev_culling_amount = settings.culling_amount

local function update_all_game_objects()
    --log.debug("update all objects")

    if settings.hide_grass == true then
    for i = 1, #grass_table do
        local s, object = pcall(get_object_components.call, get_object_components, grass_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                            set_draw:call(object, false)
                    else
                            set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
        end
    end
        grass_done = true
    end

    if settings.hide_plants == true then
    for i = 1, #plants_table do
        local s, object = pcall(get_object_components.call, get_object_components, plants_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                            set_draw:call(object, false)
                    else
                            set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
        end
    end
        plants_done = true
    end

    if settings.hide_rocks == true then
    for i = 1, #rocks_table do
        local s, object = pcall(get_object_components.call, get_object_components, rocks_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                            set_draw:call(object, false)
                    else
                            set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
        end
    end
        rocks_done = true
    end

    if settings.hide_decor == true then
    for i = 1, #decor_table do
        local s, object = pcall(get_object_components.call, get_object_components, decor_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                            set_draw:call(object, false)
                    else
                            set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
        end
    end
        decor_done = true
    end

    if settings.hide_decals == true then
    for i = 1, #decals_table do
        local s, object = pcall(get_object_components.call, get_object_components, decals_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                            set_draw:call(object, false)
                            --log.debug("hiding object " ..i)
                    else
                            set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
        end
    end
        decals_done = true
    end

    if settings.hide_lights == true then
    for i = 1, #lights_table do
        local s, object = pcall(get_object_components.call, get_object_components, lights_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                            set_draw:call(object, false)
                            --log.debug("hiding object " ..i)
                    else
                            set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
        end
    end
        lights_done = true
    end

    if settings.hide_particles == true then
    for i = 1, #particles_table do
        local s, object = pcall(get_object_components.call, get_object_components, particles_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                    set_update:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                        set_draw:call(object, false)
                        set_update:call(object, false)
                        --log.debug("hiding object " ..i)
                    else
                        set_draw:call(object, true)
                        set_update:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
                set_update:call(object, true)
            end
        end
    end
        particles_done = true
    end

    obj_tables_update_ready = false
end

-- Same as the above but incremental so it's smooth and doesn't impact framerate.
local previous_max_grass = 1
local function update_game_objects_amount_grass(amount) 
    --log.debug("updating grass")
    if grass_done == true then
        return
    end
    if #grass_table == 0 or settings.hide_grass == false then 
        grass_done = true
        return
    end
    --log.debug("updating grass "..previous_max_grass.." to "..previous_max_grass + amount.." of "..#grass_table)
    for i = previous_max_grass, previous_max_grass + amount do
        --log.debug("Processing index " ..j.."")
        local s, object = pcall(get_object_components.call, get_object_components, grass_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if objectTransform ~= nil then
            --log.debug("dist = " ..dist(objectTransform:call("get_Position")))
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                        set_draw:call(object, false)
                    else
                        set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
            end
        end

        previous_max_grass = i
        if i >= #grass_table then
            grass_done = true
            --log.debug("grass_done")
        end
    end
end

local previous_max_plants = 1
local function update_game_objects_amount_plants(amount)
    --log.debug("updating plants")
    if plants_done == true then
        return
    end
    if #plants_table == 0 or settings.hide_plants == false then 
        plants_done = true
        return
    end
    --log.debug("updating plants "..previous_max_plants.." to "..previous_max_plants + amount.." of "..#plants_table)
    for i = previous_max_plants, previous_max_plants + amount do
        --log.debug("Processing index " ..j.."")
        local s, object = pcall(get_object_components.call, get_object_components, plants_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if objectTransform ~= nil then
            --log.debug("dist = " ..dist(objectTransform:call("get_Position")))
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                        set_draw:call(object, false)
                    else
                        set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
            end
        end
        
        previous_max_plants = i
        if i >= #plants_table then
            plants_done = true
            --log.debug("plants_done")
        end
    end
end

local previous_max_rocks = 1
local function update_game_objects_amount_rocks(amount)
    --log.debug("updating rocks")
    if rocks_done == true then
        return
    end
    if #rocks_table == 0 or settings.hide_rocks == false then 
        rocks_done = true
        return
    end
    --log.debug("updating rocks "..previous_max_rocks.." to "..previous_max_rocks + amount.." of "..#rocks_table)
    for i = previous_max_rocks, previous_max_rocks + amount do
        --log.debug("Processing index " ..j.."")
        local s, object = pcall(get_object_components.call, get_object_components, rocks_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if objectTransform ~= nil then
            --log.debug("dist = " ..dist(objectTransform:call("get_Position")))
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                        set_draw:call(object, false)
                    else
                        set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
            end
        end
        
        previous_max_rocks = i
        if i >= #rocks_table then
            rocks_done = true
            --log.debug("rocks_done")
        end
    end
end

local previous_max_decor = 1
local function update_game_objects_amount_decor(amount)
    --log.debug("updating decor")
    if decor_done == true then
        return
    end
    if #decor_table == 0 or settings.hide_decor == false then 
        decor_done = true
        return
    end
    --log.debug("updating decor "..previous_max_decor.." to "..previous_max_decor + amount.." of "..#decor_table)
    for i = previous_max_decor, previous_max_decor + amount do
        --log.debug("Processing index " ..i.. " of " ..(previous_max_decor + amount))
        local s, object = pcall(get_object_components.call, get_object_components, decor_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if objectTransform ~= nil then
            --log.debug("dist = " ..dist(objectTransform:call("get_Position")))
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                        set_draw:call(object, false)
                    else
                        set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
            end
        end
        
        previous_max_decor = i
        --log.debug("previous_max_decor = " ..previous_max_decor)
        if i >= #decor_table then
            decor_done = true
            --log.debug("decor_done")
        end
    end
end

local previous_max_decals = 1
local function update_game_objects_amount_decals(amount)
    --log.debug("updating decals")
    if decals_done == true then
        return
    end
    if #decals_table == 0 or settings.hide_decals == false then 
        decals_done = true
        return
    end
    --log.debug("updating decals "..previous_max_decals.." to "..previous_max_decals + amount.." of "..#decals_table)
    for i = previous_max_decals, previous_max_decals + amount do
        --log.debug("Processing index " ..j.."")
        local s, object = pcall(get_object_components.call, get_object_components, decals_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if objectTransform ~= nil then
            --log.debug("dist = " ..dist(objectTransform:call("get_Position")))
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                        set_draw:call(object, false)
                    else
                        set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
            end
        end
        
        previous_max_decals = i
        if i >= #decals_table then
            decals_done = true
            --log.debug("decals_done")
        end
    end
end

local previous_max_lights = 1
local function update_game_objects_amount_lights(amount)
    --log.debug("updating lights")
    if lights_done == true then
        return
    end
    if #lights_table == 0 or settings.hide_lights == false then 
        lights_done = true
        return
    end
    --log.debug("updating lights "..previous_max_lights.." to "..previous_max_lights + amount.." of "..#lights_table)
    for i = previous_max_lights, previous_max_lights + amount do
        --log.debug("Processing index " ..j.."")
        local s, object = pcall(get_object_components.call, get_object_components, lights_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if objectTransform ~= nil then
            --log.debug("dist = " ..dist(objectTransform:call("get_Position")))
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist + 10 then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                        set_draw:call(object, false)
                    else
                        set_draw:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
            end
            end
        end
        
        previous_max_lights = i
        if i >= #lights_table then
            lights_done = true
            --log.debug("lights_done")
        end
    end
end

local previous_max_particles = 1
local function update_game_objects_amount_particles(amount)
    --log.debug("updating particles")
    if particles_done == true then
        return
    end
    if #particles_table == 0 or settings.hide_particles == false then 
        particles_done = true
        return
    end
    --log.debug("updating particles "..previous_max_particles.." to "..previous_max_particles + amount.." of "..#particles_table)
    for i = previous_max_particles, previous_max_particles + amount do
        --log.debug("Processing index " ..j.."")
        local s, object = pcall(get_object_components.call, get_object_components, particles_table[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if objectTransform ~= nil then
            --log.debug("dist = " ..dist(objectTransform:call("get_Position")))
            if dist(objectTransform:call("get_Position")) > settings.min_culling_dist + 10 then
                if settings.culling_amount == 0 and prev_culling_amount ~= 0 then
                    set_draw:call(object, true)
                    set_update:call(object, true)
                else
                    if i % 10 < settings.culling_amount then
                        set_draw:call(object, false)
                        set_update:call(object, false)
                    else
                        set_draw:call(object, true)
                        set_update:call(object, true)
                    end
                end
            else
                set_draw:call(object, true)
                set_update:call(object, true)
            end
            end
        end
        
        previous_max_particles = i
        if i >= #particles_table then
            particles_done = true
            --log.debug("particles_done")
        end
    end
end

local function set_all_to_visible(tbl)
    --log.debug("set_all_to_visible")
    for i = 1, #tbl do
        local s, object = pcall(get_object_components.call, get_object_components, tbl[i])
        if s and object then
            local objectTransform = get_gameobject_component(object, 'via.Transform')
            if objectTransform ~= nil then
                set_draw:call(object, true)
            end
        end
    end
end

local reloaded_after_load = false

local time_since_setOneFrameInstantiateLimit = 0
-- If this was just called, it usually means the game is loading.
-- Getting the object table while it's loading can cause errors and even crashing.
sdk.hook(sdk.find_type_definition('app.AppInstantiateManager'):get_method("setOneFrameInstantiateLimit"), 
    function(args)
    --log.debug("app.AppInstantiateManager.setOneFrameInstantiateLimit")
    time_since_setOneFrameInstantiateLimit = 0
    reloaded_after_load = false
end)

local via_app = sdk.get_native_singleton('via.Application')
local via_app_type = sdk.find_type_definition('via.Application')
local dt = 1/30.0

local time_since_registerZoneController = 0 -- This is way to tell if the game is loading areas.
sdk.hook(sdk.find_type_definition('app.ZoneManager'):get_method("registerZoneController"), 
    function(args)
    time_since_registerZoneController = 0
end)

sdk.hook(sdk.find_type_definition('app.EPVExpertFootLandingCustom'):get_method("playEffect"), 
    function(args)
    --log.debug("app.EPVExpertFootLandingCustom.playEffect")
    if settings.disable_footprints == true then
        return sdk.PreHookResult.SKIP_ORIGINAL -- This prevents footprints from spawning
    else
        return sdk.PreHookResult.CALL_ORIGINAL
    end
end)

local dt_mult = 1

local options_update_timer = 0

local fast_update_tick = 0
local scene_update_timer = 0
local reload_table_timer = 0
local update_table_timer = 0
local cam_update_timer = 0

local culling_system_ready = false

local status = "initailising"

local n = 0
local tables_to_hide = 0

re.on_frame(function()
    dt = sdk.call_native_func(via_app, via_app_type, "get_ElapsedSecond()")
    -- Delta time, just the amount of time in seconds since the last frame.
    -- This is used for consistent update scheduling regardless of how fast (or slow) the game is running.

    time_since_setOneFrameInstantiateLimit = time_since_setOneFrameInstantiateLimit + dt
    -- The script can break and return errors if stuff happens in a loading screen.
    -- This helps prevent that.
    if cam_pos.x ~= 0
    and cam_pos.y ~= 0
    and cam_pos.z ~= 0
    and time_since_setOneFrameInstantiateLimit > 3.0 -- This is just a guess of when scene loading stops.
    -- This causes a bit of a hitch after the game loads, but it's a good interrim solution.
    then
        culling_system_ready = true
        if reloaded_after_load == false then
            current_scene = get_current_scene()
            if current_stage ~= get_current_stage() then
                obj_tables_reload_ready = true
            end
            current_stage = get_current_stage()
            full_scene_table = get_full_table()
            get_filtered_tables()
            --obj_tables_reload_ready = true
            reloaded_after_load = true
        end
    else
        culling_system_ready = false
    end

    if culling_system_ready == false then
        obj_tables_update_ready = false 
        obj_tables_reload_ready = false
        fast_update_tick = 0
        reload_table_timer = 0
        update_table_timer = 0
    end

    time_since_registerZoneController = time_since_registerZoneController + dt
     -- This is a way to detect if you're moving.
    if time_since_registerZoneController < 2.0 then
        dt_mult = 2 -- This speeds up the refresh timers so they keep up if you're moving around the map.
        -- This way it's ready to cull objects when you stop moving.
    else
        dt_mult = 1
    end

    scene_update_timer = scene_update_timer + dt
    if scene_update_timer > 60.0 then
        current_scene = get_current_scene()
        if current_stage ~= get_current_stage() then -- Scene change detected.
            obj_tables_reload_ready = true
        end
        current_stage = get_current_stage()
        full_scene_table = {}
        full_scene_table = get_full_table()
        scene_update_timer = 0
    end

    -- This staggered updating system helps keep a smooth framerate when updating and reloading.
    if obj_tables_update_ready == true or obj_tables_reload_ready == true then
        fast_update_tick = fast_update_tick + 1
        if fast_update_tick > (2) then -- Every 3 frames, starting at zero.
            if obj_tables_update_ready == true and obj_tables_reload_ready == false then

                if settings.hide_grass == true then
                    update_game_objects_amount_grass(math.ceil(#grass_table / settings.reload_increment_steps) + 1)
                end

                if settings.hide_plants == true then
                    update_game_objects_amount_plants(math.ceil(#plants_table / settings.reload_increment_steps) + 1)
                end

                if settings.hide_rocks == true then
                    update_game_objects_amount_rocks(math.ceil(#rocks_table / settings.reload_increment_steps) + 1)
                end

                if settings.hide_decor == true then
                    update_game_objects_amount_decor(math.ceil(#decor_table / settings.reload_increment_steps) + 1)
                end

                if settings.hide_decals == true then
                    update_game_objects_amount_decals(math.ceil(#decals_table / settings.reload_increment_steps) + 1)
                end

                if settings.hide_lights == true then
                    update_game_objects_amount_lights(math.ceil(#lights_table / settings.reload_increment_steps) + 1)
                end

                if settings.hide_particles == true then
                    update_game_objects_amount_particles(math.ceil(#particles_table / settings.reload_increment_steps) + 1)
                end

                n = 0
                if grass_done == true then
                    n = n + 1
                end
                if plants_done == true then
                    n = n + 1
                end
                if rocks_done == true then
                    n = n + 1
                end
                if decor_done == true then
                    n = n + 1
                end
                if decals_done == true then
                    n = n + 1
                end
                if lights_done == true then
                    n = n + 1
                end
                if particles_done == true then
                    n = n + 1
                end

                --log.debug("n = " ..n)
                if n >= tables_to_hide then
                    n = 0
                    obj_tables_update_ready = false
                    grass_done = false
                    plants_done = false
                    rocks_done = false
                    decor_done = false
                    decals_done = false
                    lights_done = false
                    particles_done = false

                    previous_max_grass = 0
                    previous_max_plants = 0
                    previous_max_rocks = 0
                    previous_max_decor = 0
                    previous_max_decals = 0
                    previous_max_lights = 0
                    previous_max_particles = 0
                end
                --[[
                log.debug("previous_max_grass = " ..previous_max_grass)
                log.debug("previous_max_plants = " ..previous_max_plants)
                log.debug("previous_max_rocks = " ..previous_max_rocks)
                log.debug("previous_max_decor = " ..previous_max_decor)
                log.debug("previous_max_decals = " ..previous_max_decals)
                log.debug("previous_max_lights = " ..previous_max_lights)
                log.debug("previous_max_particles = " ..previous_max_particles)
                ]]--
                table_update_timer = 0
                reload_table_timer = reload_table_timer - dt
            else
            end

            if obj_tables_reload_ready == true then
                get_filtered_tables_incremental()
                --[[
                log.debug("#grass_table = " ..#grass_table)
                log.debug("#plants_table = " ..#plants_table)
                log.debug("#rocks_table = " ..#rocks_table)
                log.debug("#decor_table = " ..#decor_table)
                log.debug("#decals_table = " ..#decals_table)
                log.debug("#lights_table = " ..#lights_table)
                log.debug("#particles_table = " ..#particles_table)
                ]]--
                reload_table_timer = 0
                table_update_timer = 0
            end
        
            fast_update_tick = 0
        else
        end
    end

    -- This helps to confirm if it's working.
    -- If you experiece hitching or stutters and this says "idle", then it's not the script's fault. I hope.
    if obj_tables_update_ready == true then
        status = "updating"
    elseif obj_tables_reload_ready == true then
        status = "reloading"
    else
        status = "idle"
    end

    reload_table_timer = reload_table_timer + (dt * dt_mult)
   if reload_table_timer > settings.table_reload_interval * 60 then -- Default is 5 minutes
        --log.debug("Tables should reload now.")
        if culling_system_ready == true then
            -- reload tables
            full_scene_table = {}
            full_scene_table = get_full_table()
            grass_table = {}
            plants_table = {}
            rocks_table = {}
            decor_table = {}
            decals_table = {}
            lights_table = {}
            particles_table = {}
            tbl_stage = 1
            obj_tables_reload_ready = true
        else
            obj_tables_reload_ready = false
        end
        reload_table_timer = 0
    end

    update_table_timer = update_table_timer + (dt * dt_mult)
    if update_table_timer > settings.table_update_interval then -- Update current list of objects. Default is 10 seconds
        --log.debug("Tables should update now.")
        --log.debug("culling_system_ready = " ..tostring(culling_system_ready))

        if culling_system_ready == true then
            tables_to_hide = 0
            if settings.hide_grass == true then
                tables_to_hide = tables_to_hide + 1
            end
            if settings.hide_plants == true then
                tables_to_hide = tables_to_hide + 1
            end
            if settings.hide_rocks == true then
                tables_to_hide = tables_to_hide + 1
            end
            if settings.hide_decor == true then
                tables_to_hide = tables_to_hide + 1
            end
            if settings.hide_decals == true then
                tables_to_hide = tables_to_hide + 1
            end
            if settings.hide_lights == true then
                tables_to_hide = tables_to_hide + 1
            end
            if settings.hide_particles == true then
                tables_to_hide = tables_to_hide + 1
            end

            full_scene_table = {}
            full_scene_table = get_full_table()
            obj_tables_update_ready = true
        else
            obj_tables_update_ready = false
        end

        update_table_timer = 0
    end
    
    cam_update_timer = cam_update_timer + (dt * dt_mult)
    if cam_update_timer > 1.0 then
        update_cam_pos() -- Needed for the minimum culling distance parameter.
        --log.debug("cam_pos = {" ..(cam_pos.x).. ", "..(cam_pos.y)..", "..(cam_pos.z).."}")
        prev_culling_amount = settings.culling_amount
        cam_update_timer = 0
    end

    options_update_timer = options_update_timer + dt
    if options_update_timer > 10.0 then -- It doesn't need to update every frame, so instead it updates every 10 seconds.
        --log.debug("Graphics stuff updated.")
        update_all_settings()
        save_settings()
        --[[
        log.debug("#grass_table = " ..#grass_table)
        log.debug("#plants_table = " ..#plants_table)
        log.debug("#rocks_table = " ..#rocks_table)
        log.debug("#decals_table = " ..#decals_table)
        log.debug("#lights_table = " ..#lights_table)
        log.debug("#particles_table = " ..#particles_table)
        log.debug("")
        ]]--

        collectgarbage("collect") -- This helps with reducing memory usage
        options_update_timer = 0
    end
end
) 

-- Script Generated UI
re.on_draw_ui(function()
    if imgui.tree_node("More graphics options") then
        local i = 1
        
        imgui.text("Object culling amount")
        imgui.push_id(i)
        changed, settings.culling_amount = imgui.slider_int("", settings.culling_amount, 0, 10, (settings.culling_amount/10))
        if changed == true then 
            obj_tables_update_ready = true
            update_all_game_objects() 
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("The proportion of objects to hide. It might take a second to see the effect.")
        end
        imgui.pop_id()
        i = i + 1
        
        imgui.text("Minimum culling distance*")
        -- Some objects have coordinates {0, 0, 0} despite being right in front of the camera, which is weird.
        imgui.push_id(i)
        changed, settings.min_culling_dist = imgui.slider_int("", settings.min_culling_dist, 1, 100)
        if changed == true then 
            update_all_game_objects()
            obj_tables_update_ready = true
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("How far away before objects start to be hidden\n*Doesn't affect all objects.")
        end
        imgui.pop_id()
        i = i + 1

        imgui.text("Mesh LOD bias")
        imgui.push_id(i)
        changed, settings.mesh_lod_bias = imgui.slider_int("Default: 0", settings.mesh_lod_bias, 0, 4)
        if changed == true then 
            update_MeshRenderer()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Controls the level of detail for models, doesn't really affect foliage.\nHigher values = less datail.\nSet it to 2 or more to get those funny low poly monsters some people seen in the beta!")
        end
        imgui.pop_id()
        i = i + 1
        
        imgui.text("Foliage LOD bias")
        imgui.push_id(i)
        changed, settings.speedtree_lod_bias = imgui.slider_int("Default: 0", settings.speedtree_lod_bias, 0, 6)
        if changed == true then 
            update_SpeedTree()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Controls the level of detail over distance for foliage and other environmental objects.\nThis adds some pop-in.")
        end
        imgui.pop_id()
        i = i + 1
        
        imgui.text("Foliage minimum LOD")
        imgui.push_id(i)
        changed, settings.speedtree_min_lod = imgui.slider_int("Default: 1", settings.speedtree_min_lod, 0, 6)
        if changed == true then 
            update_SpeedTree()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Controls the level of detail for foliage and other environmental objects.\nThis is set by the game's 'grass quality' setting but only up to 3.")       
        end
        imgui.pop_id()
        i = i + 1
        
        --Disable texture streaming
        imgui.push_id(i)
        changed, settings.disable_tex_stream = imgui.checkbox("Disable texture streaming", settings.disable_tex_stream)
        if changed == true then 
            update_Renderer()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Forces lowest resolution textures, making everything look extra muddy.\nDefault: off")
        end
        imgui.pop_id()
        i = i + 1
        
        -- Texture load bias
        imgui.push_id(i)
        imgui.text("Texture sampler bias")
        changed, settings.texture_sampler_bias = imgui.slider_float("Default: 0", settings.texture_sampler_bias, -2.0, 4.0)
        if changed == true then 
            update_Sampler()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Affects texture quality.\nPositive = lower res, negative = higher res.\nSet to 5 for flat colours instead of textures!\n*Does not work with Special K for some reason.*\nDefault: 0")
        end
        imgui.pop_id()
        i = i + 1
        
        imgui.text("Small object culling ratio")
        imgui.push_id(i)
        changed, settings.object_culling_ratio = imgui.slider_float("Default: 24", settings.object_culling_ratio, 0, 100)
        if changed == true then 
            update_Renderer()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Controls how much the game hides small objects. Game deafult is 16.\nThe engine is weird in how it detemines what a 'small object' is.\nSetting this above 24 can lead to weird results like characters missing heads when set high enough.")
	    end
        imgui.pop_id()
        i = i + 1
        
        imgui.push_id(i)
        changed, settings.disable_footprints = imgui.checkbox("Disable footprints", settings.disable_footprints)
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Toggles footprints and similar effects on the ground.\nDefault: off")
        end
        imgui.pop_id()
        i = i + 1
        
        --Disable dynamic shadows
        imgui.push_id(i)
        changed, settings.disable_shadows = imgui.checkbox("Disable dynamic shadows", settings.disable_shadows)
        if changed == true then 
            update_Renderer()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Toggles dynamic shadows.\nDefault: off")
        end
        imgui.pop_id()
        i = i + 1
        
        imgui.text("Shadow quality")
        imgui.push_id(i)
        changed, settings.shadow_quality = imgui.slider_int("Default: 384", settings.shadow_quality, 64, 2048)
        if changed == true then 
            update_LightRenderer()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("Sets the quality of all shadows.\nGame settings:\nlowest = 384\nlow = 512\nmedium = 768\nhigh = 1024")
        end
        imgui.pop_id()
        i = i + 1
        
        --Disable particles
        imgui.push_id(i)
        changed, settings.disable_particles = imgui.checkbox("Disable particles *WARNING*", settings.disable_particles)
        if changed == true then 
            update_PlayerManager()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("WARNING: THIS MAKES COMBAT HARDER because you can't see some projectiles and other objects!\nDisables particles and water rippling effects.\n*A smarter system to reduce particles is in the works.*\nDefault: off")
        end
        imgui.pop_id()
        i = i + 1
        
        imgui.push_id(i)
	    if imgui.button("Reset settings") then
            reset_settings()
            save_settings()
            reload_table_timer = 0
            update_table_timer = 0
	    end
        imgui.pop_id()
        i = i + 1
         
        if imgui.tree_node("Advanced") then
        
            imgui.text("Status: " ..status)

            imgui.text("Object types to hide")
            imgui.push_id(i)
            changed, settings.hide_grass = imgui.checkbox("Grass", settings.hide_grass)
            if changed == true then 
                if settings.hide_grass == false then
                    set_all_to_visible(grass_table)
                end
                obj_tables_update_ready = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Hides tall grass and some short grass.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.push_id(i)
            changed, settings.hide_plants = imgui.checkbox("Plants", settings.hide_plants)
            if changed == true then 
                if settings.hide_plants == false then
                    set_all_to_visible(plants_table)
                end
                obj_tables_update_ready = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Hides short grass, flowers, bushes, moss, branches, and some trees.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.push_id(i)
            changed, settings.hide_rocks = imgui.checkbox("Rocks", settings.hide_rocks)
            if changed == true then 
                if settings.hide_rocks == false then
                    set_all_to_visible(rocks_table)
                end
                obj_tables_update_ready = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Hides rocks, ice blocks, rubble, stalactites and stalagmites.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.push_id(i)
            changed, settings.hide_decor = imgui.checkbox("Decor", settings.hide_decor)
            if changed == true then 
                if settings.hide_decor == false then
                    set_all_to_visible(decor_table)
                end
                obj_tables_update_ready = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Hides boxes, books, carpets, pots, etc. Mostly things in camps and villages.\nNot the gems you slot in your gear!")
            end
            imgui.pop_id()
            i = i + 1

            imgui.push_id(i)
            changed, settings.hide_decals = imgui.checkbox("Decals", settings.hide_decals)
            if changed == true then 
                if settings.hide_decals == false then
                    set_all_to_visible(decals_table)
                end
                obj_tables_update_ready = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Hides decals.\nDecals contribute a lot to the colours and contrast in the levels, so this is disabled by default.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.push_id(i)
            changed, settings.hide_lights = imgui.checkbox("Lights", settings.hide_lights)
            if changed == true then 
                if settings.hide_lights == false then
                    set_all_to_visible(lights_table)
                end
                obj_tables_update_ready = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Hides small lights, noticeable in villages.\nDisabled by default.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.push_id(i)
            changed, settings.hide_particles = imgui.checkbox("Particles", settings.hide_particles)
            if changed == true then 
                if settings.hide_particles == false then
                    set_all_to_visible(particles_table)
                end
                obj_tables_update_ready = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Hides particles such as sand, dust and leaves.\nThis has a tendency to create errors so it is disabled by default.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.text("Object table update interval (seconds)")
            imgui.push_id(i)
            changed, settings.table_update_interval = imgui.slider_float("Default: 20", settings.table_update_interval, 1, 120)
            if changed == true then 
                reload_table_timer = 0
                update_table_timer = 0
                obj_tables_update_ready = true
                obj_tables_reload_ready = false
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Interval, in seconds, between updating the visibility state of objects.\nThis is meant for the minimum distance parameter keeping up with where you are in the level.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.text("Object table reload interval (minutes)")
            imgui.push_id(i)
            changed, settings.table_reload_interval = imgui.slider_float("Default: 5", settings.table_reload_interval, 0.25, 30)
            if changed == true then 
                reload_table_timer = 0
                update_table_timer = 0
                obj_tables_update_ready = false
                obj_tables_reload_ready = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Interval, in minutes, between the scripts reloads the list of objects which can be made hidden.\nThis is used for when different objects load as you move around the level.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.text("Table reload increment steps - 'smoothness'")
            imgui.push_id(i)
            changed, settings.reload_increment_steps = imgui.slider_int("Default: 40", settings.reload_increment_steps, 4, 100)
            if changed == true then 
                reload_table_timer = 0
                update_table_timer = 0
                obj_tables_update_ready = false
                obj_tables_reload_ready = false
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("The higher the number, the smoother and slower table processing stuff is.\nSet this to a high number if you experience hitching due to this script.\nSet to a low number if you prefer to have a brief spike every few minutes instead.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.push_id(i)
	        if imgui.button("Force reset objects to hide") then
                get_filtered_tables()
                update_all_game_objects()
                reload_table_timer = 0
                update_table_timer = 0
	        end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Forcefully resets the list of objects to be made hidden.\nUse this if you think the script isn't working.")
            end
            imgui.pop_id()
            i = i + 1

            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
end)

update_all_settings()

--log.debug("low graphics mod ready.")