#!/usr/bin/env bash

(
    cd inp2rad
    pip3 install .
)

(
    cd build
    pyinstaller --onefile ../inp2rad/inp2rad.py
    python3 install.py
)
