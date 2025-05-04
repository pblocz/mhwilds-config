#!/usr/bin/python3

import os
import sys
import pyglet

import sys
import subprocess


cmd = sys.argv[1]
filename = sys.argv[2]

if cmd == "view":
    # window = pyglet.window.Window(1920,1280)
    window = pyglet.window.Window(2256,1504)
    image = pyglet.image.load(filename)

    @window.event
    def on_draw():
        window.clear()
        image.blit(0, 0)

    pyglet.app.run()

if cmd == "debug":
    proc = subprocess.Popen(
        [sys.executable, __file__, "view", filename], 
        env={**os.environ, "VKBASALT_LOG_LEVEL": "debug", "VKBASALT_LOG_FILE": "vkBasalt.log", "ENABLE_VKBASALT": "1", "MESA_LOADER_DRIVER_OVERRIDE": "zink", "GALLIUM_DRIVER": "zink", }
    )

    proc.wait()