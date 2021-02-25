# cython: language_level=3

from setuptools import setup, Extension
from Cython.Build import cythonize


extra_compile_args = ['-Wall', '-g', '-x', 'c++', '-std=c++11']

ext_modules = [
    Extension(
        'cythondb',
        sources=['python/cylvdb.pyx'],
        include_dirs=['include'],
        libraries=['leveldb'],
        library_dirs=['include'],
        language='c++',
        extra_compile_args=extra_compile_args
    )
]


setup(
    name='cylvdb',
    ext_modules=cythonize(ext_modules, annotate=True)
)
