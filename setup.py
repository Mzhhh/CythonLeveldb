# cython: language_level=3

from os.path import expanduser
from setuptools import setup, Extension
from Cython.Build import cythonize


extra_compile_args = ['-Wall', '-g', '-x', 'c++', '-std=c++11', '-fno-rtti']

# TODO: REPLACE WITH YOUR PYTHON INCLUDE DIRECTORY
PYTHON_INCLUDE_PATH = expanduser('~/anaconda3/include/python3.7m')

ext_modules = [
    Extension(
        'cythondb',
        sources=['python/cylvdb.pyx', 'cpp/pycomparator.cpp'],
        include_dirs=['include', 'cpp', PYTHON_INCLUDE_PATH],
        libraries=['leveldb'],
        library_dirs=['include'],
        language='c++',
        extra_compile_args=extra_compile_args
    )
]


setup(
    name='cython-leveldb',
    ext_modules=cythonize(ext_modules, annotate=True)
)
