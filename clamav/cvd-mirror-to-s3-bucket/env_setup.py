#!/usr/bin/env python3
"""
Environment Setup for CVD Scripts

This module provides functions to set up the correct environment
for running cvdupdate commands within our virtual environment.
"""

import os
import sys
from pathlib import Path


def get_venv_path():
    """Get the path to the virtual environment."""
    script_dir = Path(__file__).parent.absolute()
    venv_path = script_dir / '.venv'
    return venv_path


def get_cvd_command():
    """Get the correct cvd command path."""
    venv_path = get_venv_path()
    cvd_path = venv_path / 'bin' / 'cvd'
    
    if cvd_path.exists():
        return str(cvd_path)
    else:
        # Fallback to python module
        python_path = venv_path / 'bin' / 'python'
        return [str(python_path), '-m', 'cvdupdate']


def get_python_command():
    """Get the correct python command path."""
    venv_path = get_venv_path()
    python_path = venv_path / 'bin' / 'python'
    return str(python_path)


def setup_environment():
    """Set up the environment for running cvdupdate commands."""
    venv_path = get_venv_path()
    
    # Add virtual environment bin to PATH
    venv_bin = str(venv_path / 'bin')
    current_path = os.environ.get('PATH', '')
    
    if venv_bin not in current_path:
        os.environ['PATH'] = f"{venv_bin}:{current_path}"
    
    # Set VIRTUAL_ENV
    os.environ['VIRTUAL_ENV'] = str(venv_path)
    
    return True