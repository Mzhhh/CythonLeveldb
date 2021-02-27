ext:
	CFLAGS='-stdlib=libc++' python setup.py build_ext -i -f

sanity_check: ext
	python -c "import cython"

test: ext
	python ./test/testAll.py