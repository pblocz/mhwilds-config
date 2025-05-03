#%%

import configparser
from pathlib import Path
import click
import shutil
import os
import stat
import requests
import zipfile

# WINEDLLOVERRIDES="dinput8.dll=n,b" DXVK_FRAME_RATE=48 mangohud gamemoderun %command%

# https://www.nexusmods.com/monsterhunterwilds/mods/234?tab=description

# Define the changes to be applied with the correct sections
# gamescope --fullscreen -w 1280 -h 720 -W 1920 -H 1280 -S integer -F fsr --expose-wayland --mangoapp -- %command%

# # Very low
# changes = {
#     'Graphics': {
#         "Algorithm": "FSR3",
#         "Bloom_Enable": "False",
#         'Fog_Enable': 'False',
#         'VolumetricFogControl_Enable': 'False',
#         'VRSSetting': 'Performance',
#         "MaxFPS": "120",  # Move this configuration to steam launch DXVK_FRAME_RATE=48
#         "NormalWindowResolution": "(1920,1280)",
#         "VSync": "False",

#         # "SSAO_HalfResolution": "True",
#         # "NormalWindowResolution": "(1280,720)",
#     },
#     'RenderConfig': {
#         "BloomEnable": "false",
#         'EffectVolume': '0',
#         'FilmGrainEnable': 'false',
#         'GodRayEnable': 'false',
#         'LensFlareEnable': 'false',
#         'LensDistortionSetting': 'false',
#         'TransparentBufferQuality': 'LOWEST',
#         'VRSSetting': 'Performance',
#         "VSync": "false",
#         'NormalWindowResolution': '(1920.000000,1280.000000)',

#         "RayTracingGIEnable": "true",
#         "RayTracingReflectionEnable": "true",
#         "RayTracingShadowEnable": "true",
#         "RayTracingTransparentEnable": "true",
#         "EffectRayTracingVolume": "0",
#         # 'NormalWindowResolution': '(1280.000000,720.000000)',

#     },
#     "Render": {
#         "ParallelBuildCommandList": "Enable",
#         "ParallelBuildProcessorCount": "12",
#         "RenderWorkerThreadPriorityAboveNormal": "Enable",
#     },
#     "Graphics/FSR3": {
#         "EnableFrameGeneration": "False",
#         "EnableSharpness": "True",
#         "Sharpness": "0.8",
#     },
# }


# low / medium
changes = {
    'Graphics': {
        "Algorithm": "FSR3",
        "Bloom_Enable": "False",
        'Fog_Enable': 'False',
        'VolumetricFogControl_Enable': 'False',
        'VRSSetting': 'Performance',
        "MaxFPS": "120",  # Move this configuration to steam launch DXVK_FRAME_RATE=48
        "NormalWindowResolution": "(1920,1280)",
        "VSync": "False",

        # For higher quality
        "Quality": "Performance",
        "SamplerQuality": "Anisotropic2",
        "ShadowQuality": "STANDARD",
        "StreamingTextureLoadLevelBias": "1", # 2 is low, 0 is high

        # "SSAO_HalfResolution": "True",
    },
    'RenderConfig': {
        "BloomEnable": "false",
        'EffectVolume': '0',
        'FilmGrainEnable': 'false',
        'GodRayEnable': 'false',
        'LensFlareEnable': 'false',
        'LensDistortionSetting': 'false',
        'TransparentBufferQuality': 'LOWEST',
        'VRSSetting': 'Performance',
        "VSync": "false",
        'NormalWindowResolution': '(1920.000000,1280.000000)',

        "RayTracingGIEnable": "true",
        "RayTracingReflectionEnable": "true",
        "RayTracingShadowEnable": "true",
        "RayTracingTransparentEnable": "true",
        "EffectRayTracingVolume": "0",

        "SamplerQuality": "Anisotropic2",
        "ShadowQuality": "STANDARD",
        "StreamingTextureLoadLevelBias": "1",

    },
    "Render": {
        "ParallelBuildCommandList": "Enable",
        "ParallelBuildProcessorCount": "12",
        "RenderWorkerThreadPriorityAboveNormal": "Enable",
    },
    "Graphics/FSR3": {
        "EnableFrameGeneration": "True",
        "EnableSharpness": "True",
        "Sharpness": "0.8",
    },
}

#%%

def install_reframework():
    # url = "https://github.com/praydog/REFramework/releases/latest/download/MHWILDS.zip"
    url = "https://github.com/praydog/REFramework-nightly/releases/latest/download/MHWILDS.zip"

    p = "MHWILDS.zip"
    Path(p).write_bytes(requests.get(url).content)
    zipfile.ZipFile(p).extract("dinput8.dll", ".")

def install_disablepostpo():
    # Disable Post Processing Effects
    # https://www.nexusmods.com/monsterhunterwilds/mods/221?tab=description
    url = "https://github.com/TonWonton/MHWilds_DisablePostProcessingEffects/releases/download/v1.3.1/mhwilds_disablepostprocessingeffects.v1.3.1.zip"

    p = "mhwilds_disablepostprocessingeffects.zip"
    Path(p).write_bytes(requests.get(url).content)
    archive = zipfile.ZipFile(p)
    
    for file in archive.namelist():
        if file.startswith('reframework/'):
            archive.extract(file, '.')

def install_volumentric_fog_mod():
    # https://www.nexusmods.com/monsterhunterwilds/mods/455?tab=files&file_id=2419
    p = "Tweak Volumetric Fogs-455-1-0-0-1742139119.zip"
    archive = zipfile.ZipFile(p)
    
    for file in archive.namelist():
        if file.startswith('reframework/'):
            archive.extract(file, '.')

def install_graphics_options_mod():
    # https://www.nexusmods.com/monsterhunterwilds/mods/455?tab=files&file_id=2419
    p = "graphics_options_v1.5.1-816-1-5-1-1746051399.zip"
    archive = zipfile.ZipFile(p)
    
    for file in archive.namelist():
        if file.startswith('reframework/'):
            archive.extract(file, '.')

def mod_installs():
    install_reframework()
    install_disablepostpo()
    install_volumentric_fog_mod()
    install_graphics_options_mod()

# mod_installs()

#%%

def update_config(file_path, changes):
    # Read the original config file
    config = configparser.ConfigParser()
    config.optionxform=str
    config.read(file_path)

    # Apply the changes
    for section, options in changes.items():
        if not config.has_section(section):
            config.add_section(section)
        for option, value in options.items():
            config.set(section, option, value)

    # Write the updated config back to the file
    with open(file_path, 'w') as configfile:
        config.write(configfile, space_around_delimiters=False)

def set_read_only(file_path, read_only=True):
    """Set the file to read-only or writable."""
    if read_only:
        os.chmod(file_path, stat.S_IREAD)
    else:
        os.chmod(file_path, stat.S_IREAD | stat.S_IWRITE)

@click.group()
def cli():
    pass

@click.command()
@click.argument('file_path')
def backup(file_path):
    """Create a backup of the original config file."""
    backup_path = file_path + '.bak'
    shutil.copy(file_path, backup_path)
    click.echo(f'Backup created: {backup_path}')

@click.command()
@click.argument('file_path')
def patch(file_path):
    """Apply patches to the config file."""
    # Make the file writable
    set_read_only(file_path, read_only=False)
    update_config(file_path, changes)
    # Set the file back to read-only
    set_read_only(file_path, read_only=True)
    click.echo(f'Config file patched: {file_path}')

@click.command()
@click.argument('file_path')
def restore(file_path):
    """Restore the config file from the backup."""
    backup_path = file_path + '.bak'
    if os.path.exists(backup_path):
        # Make the file writable
        set_read_only(file_path, read_only=False)
        shutil.copy(backup_path, file_path)
        # Set the file back to read-only
        set_read_only(file_path, read_only=True)
        click.echo(f'Config file restored from backup: {file_path}')
    else:
        click.echo(f'Backup file not found: {backup_path}')

cli.add_command(backup)
cli.add_command(patch)
cli.add_command(restore)

if __name__ == '__main__':
    cli()

"""
https://www.nexusmods.com/monsterhunterwilds/mods/816?tab=description

Current list of options:

﻿- Environmental object culling: Hides various small environmental objects which can lead to a significant increase in framerate! See the images for examples.
﻿In addition, there are options for what object types to hide:
﻿﻿- Tall grass. Significantly increases framerate in the Windward Plains' open grassy area.
﻿﻿- Flowers, shrubs, some trees.
﻿﻿- Rocks, ice, rubble.
﻿﻿- Decorative objects (not the stuff you slot in your gear).
﻿﻿- Decals.
﻿﻿- Lights. Specifically small light sources like from torches and Scoutfly cages.
﻿﻿- Particles. Dust, sand, leaves, etc. 

﻿- Mesh level of detail (LOD) bias: Controls the level of detail of many objects including monsters. This can lead to funny low poly monsters like those screenshots from the beta.

﻿- Small object culling ratio: The strength of culling (hiding) small objects. This affects a lot of objects and can lead to weird things like NPCs with missing heads when set too high.

- Foliage LOD offset/bias: Controls the level of detail of environmental objects like plants and rocks. This can help a lot for framerate, but there may be a lot more noticeable pop-in.

﻿- Disable texture streaming: Forces all faces to use super low resolution textures, making the game look extra muddy and smudgy.

﻿- Texture LOD bias: Changes the way the game samples textures with distance. Does not work with Special K for some reason.

﻿- Disable dynamic shadows: Does as stated.

﻿- Dynamic shadow quality: Controls the resolution of dynamic shadows. You can set it below the game's "lowest" setting.

﻿- Disable particle effects: Does as stated, but not advisable because it makes combat harder by hiding some projectiles and environmental hazards.

"""