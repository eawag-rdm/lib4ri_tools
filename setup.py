#!/usr/bin/env python
# coding=utf-8

"""
Setup for lib4ri_tools

"""

# from __future__ import (absolute_import, division, print_function,
#                         unicode_literals, with_statement)

from setuptools import setup, find_packages


def requirements_file_to_list(fn="requirements.txt"):
    """read a requirements file and create a list that can be used in setup.

    """
    with open(fn, 'r') as f:
        return [x.rstrip() for x in list(f) if x and not x.startswith('#')]

setup(
    name="lib4ri_tools",
    version="0.1.0",
    packages=find_packages(),
    install_requires=requirements_file_to_list(),
    author="d-r-p (Lib4RI) ",
    author_email="d-r-p@users.noreply.github.com",
    maintainer="Laura Konstantaki",
    maintainer_email="not disclosed",
    description="Proof-of-concept web-application hosting tools for Lib4RI",
    long_description=open('README.md').read(),
    license="MIT",
    url="https://github.com/eawag-rdm/lib4ri_tools",
    classifiers=[
        'Development Status :: 3 - Alpha',
        'License :: OSI Approved :: MIT',
        'Programming Language :: Python :: 3.5',
    ]
)
