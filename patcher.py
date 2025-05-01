import configparser
import click
import shutil
import os
import stat

# Command to run in steam
# WINEDLLOVERRIDES="dinput8.dll=n,b" __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1 mangohud gamemoderun %command%

# Define the changes to be applied with the correct sections
# gamescope --fullscreen -w 1280 -h 720 -W 1920 -H 1280 -S integer -F fsr --expose-wayland --mangoapp -- %command%
changes = {
    'Graphics': {
        "Algorithm": "FSR3",
        'Fog_Enable': 'False',
        'VolumetricFogControl_Enable': 'False',
        'VRSSetting': 'Performance',
        "MaxFPS": "60",
        "NormalWindowResolution": "(1920,1280)",
        "Bloom_Enable": "False",

        # "SSAO_HalfResolution": "True",
        # "NormalWindowResolution": "(1280,720)",
    },
    'RenderConfig': {
        'EffectVolume': '0',
        'FilmGrainEnable': 'false',
        'GodRayEnable': 'false',
        'LensDistortionSetting': 'false',
        'LensFlareEnable': 'false',
        'TransparentBufferQuality': 'LOWEST',
        'VRSSetting': 'Performance',
        'NormalWindowResolution': '(1920.000000,1280.000000)',
        "BloomEnable": "false",
        # 'NormalWindowResolution': '(1280.000000,720.000000)',
    },
    "Render": {
        "ParallelBuildCommandList": "Enable",
        "ParallelBuildProcessorCount": "10",
        "RenderWorkerThreadPriorityAboveNormal": "Enable",
    },
    "Graphics/FSR3": {
        "EnableFrameGeneration": "True",
        "EnableSharpness": "True",
        "Sharpness": "0.7",
    },
}


def install_reframework():
    url = "https://github.com/praydog/REFramework/releases/latest/download/MHWILDS.zip"
    p = "MHWILDS.zip"
    Path(p).write_bytes(requests.get(url).content)
    zipfile.ZipFile(p).extract("dinput8.dll", ".")


def mod_installs():
    install_reframework()


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