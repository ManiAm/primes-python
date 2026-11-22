# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os
import sys

# Adding src/ to path so autodoc finds primes
sys.path.insert(0, os.path.abspath("../src"))

project = 'primes'
copyright = '2025, Mani Amoozadeh'
author = 'Mani Amoozadeh'
release = '0.1.0'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.autodoc",          # Pull in docstrings
    "sphinx.ext.napoleon",         # Support Google/NumPy style docstrings
    "sphinx_autodoc_typehints",    # Show type hints in docs
]

templates_path = ['_templates']
exclude_patterns = []

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'furo'
html_static_path = ['_static']
