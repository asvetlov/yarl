PYXS = $(wildcard yarl/*.pyx)
SRC = yarl tests setup.py

all: test


.install-deps: $(shell find requirements -type f)
	@pip install -U -r requirements/dev.txt
	@touch .install-deps


.install-cython: requirements/cython.txt
	pip install -r requirements/cython.txt
	touch .install-cython


yarl/%.c: yarl/%.pyx
	cython -3 -o $@ $< -I yarl


.cythonize: .install-cython $(PYXS:.pyx=.c)


cythonize: .cythonize


.develop: .install-deps $(shell find yarl -type f) .cythonize
	@pip install -e .
	@touch .develop

flake8:
	flake8 $(SRC)

black-check:
	black --check $(SRC)

lint: flake8 black-check
	if python -c "import sys; sys.exit(sys.version_info<(3,6))"; then \
		black --check $(SRC); \
		mypy yarl tests; \
	fi

fmt:
	black $(SRC)


test: lint .develop
	pytest ./tests ./yarl


vtest: lint .develop
	pytest ./tests ./yarl -v


cov: lint .develop
	pytest --cov yarl --cov-report html --cov-report term ./tests/ ./yarl/
	@echo "open file://`pwd`/htmlcov/index.html"


doc: doctest
	make -C docs html SPHINXOPTS="-W -E"
	@echo "open file://`pwd`/docs/_build/html/index.html"


doctest: .develop
	make -C docs doctest


mypy:
	mypy yarl tests
