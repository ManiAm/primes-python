# ---------------------------
# Toolchain & Paths (from PATH)
# ---------------------------
PY        ?= python3
PIP       ?= pip
PYTHON    ?= $(PY)
PYTEST    ?= pytest
BLACK     ?= black
PYLINT    ?= pylint
MYPY      ?= mypy
SPHINX    ?= sphinx-build
BUILD     ?= $(PYTHON) -m build
TWINE     ?= twine
PIP_AUDIT ?= pip-audit
BANDIT    ?= bandit

PKG_NAME  ?= primes
SRC_DIR   ?= src
TEST_DIR  ?= tests
DOCS_DIR  ?= docs

# ---------------------------
# Output directories
# ---------------------------
TEST_OUT  := test-results
COV_OUT   := coverage
DIST_DIR  := dist
DOCS_OUT  := $(DOCS_DIR)/_build/html
REPORTS   := reports

# ---------------------------
# Pylint policy
# ---------------------------
PYLINT_FAIL_ON     ?= E,W           # fail on Errors & Warnings
PYLINT_FAIL_UNDER  ?= 9.0           # minimum acceptable score
PYLINT_TARGETS     ?= $(SRC_DIR) $(TEST_DIR)

# ---------------------------
# Phony targets
# ---------------------------
.PHONY: help format format-check lint type sec test \
        coverage docs build smoke package clean distclean

help:
	@grep -E '^[a-zA-Z_-]+:.*?#' Makefile | sed 's/:.*?#/: /' | sort

# ---------------------------
# Code Formatting (Black)
# ---------------------------
format-check: ## Check formatting (no changes)
	$(BLACK) --check --diff $(SRC_DIR) $(TEST_DIR)

format: ## Apply auto-formatting (Black)
	$(BLACK) $(SRC_DIR) $(TEST_DIR)

# ---------------------------
# Linting (Pylint)
# ---------------------------
lint: ## Lint with pylint (fails on policy violations)
	@mkdir -p $(REPORTS)
	$(PYLINT) --fail-on=$(PYLINT_FAIL_ON) --fail-under=$(PYLINT_FAIL_UNDER) \
	  $(PYLINT_TARGETS) | tee $(REPORTS)/pylint.txt

# ---------------------------
# Static analysis (type/security)
# ---------------------------
type: ## Type-check with mypy
	@mkdir -p $(REPORTS)
	$(MYPY) $(SRC_DIR) | tee $(REPORTS)/mypy.txt

sec: ## Security scans (code + deps)
	@mkdir -p $(REPORTS)
	@echo "Running bandit..."
	@$(BANDIT) -r $(SRC_DIR) -q -f txt -o $(REPORTS)/bandit.txt || true
	@if [ -f requirements.txt ]; then \
	  echo "Running pip-audit (requirements.txt)..."; \
	  $(PIP_AUDIT) -r requirements.txt -f json -o $(REPORTS)/pip-audit.json || true; \
	else \
	  echo "Running pip-audit (environment)..."; \
	  $(PIP_AUDIT) -f json -o $(REPORTS)/pip-audit.json || true; \
	fi
	@echo "Security reports under $(REPORTS)/"

# ---------------------------
# Build (sdist + wheel)
# ---------------------------
build: ## Build package artifacts into dist/ (PEP 517)
	@mkdir -p $(DIST_DIR)
	@if [ -f pyproject.toml ]; then \
	  $(BUILD); \
	elif [ -f setup.py ]; then \
	  $(PYTHON) setup.py sdist bdist_wheel; \
	else \
	  echo "No pyproject.toml or setup.py; nothing to build." && exit 1; \
	fi
	@sha256sum $(DIST_DIR)/* > $(DIST_DIR)/SHA256SUMS.txt

# ---------------------------
# Smoke test built wheel
# ---------------------------
smoke: build ## Install the wheel in a fresh venv and import it
	@rm -rf .smoke && $(PY) -m venv .smoke
	@. .smoke/bin/activate; \
	  pip -q install -U pip >/dev/null; \
	  pip -q install dist/*.whl >/dev/null; \
	  python -c "import $(PKG_NAME), sys; print('OK', getattr($(PKG_NAME), '__version__', 'unknown'))"
	@rm -rf .smoke

# ---------------------------
# Unit Tests
# ---------------------------
test: ## Run pytest (plain) and write JUnit XML
	@mkdir -p $(TEST_OUT)
	PYTHONPATH=$(SRC_DIR):$$PYTHONPATH $(PYTEST) -q --junitxml=$(TEST_OUT)/junit.xml

coverage: ## Run tests with coverage -> XML + HTML
	@mkdir -p $(TEST_OUT) $(COV_OUT)
	PYTHONPATH=$(SRC_DIR):$$PYTHONPATH $(PYTEST) --cov=$(PKG_NAME) --cov-report=term \
	          --cov-report=xml:$(COV_OUT)/coverage.xml \
	          --cov-report=html:$(COV_OUT)/html \
	          --junitxml=$(TEST_OUT)/junit.xml
	@echo "Coverage XML: $(COV_OUT)/coverage.xml"
	@echo "Coverage HTML index: $(COV_OUT)/html/index.html"

# ---------------------------
# Docs (Sphinx)
# ---------------------------
docs: ## Build Sphinx HTML docs
	$(MAKE) -C docs html
	@echo "Docs HTML at docs/build/html/index.html"

# ---------------------------
# Package (bundle artifacts)
# ---------------------------
package: format-check lint type sec build smoke test coverage docs ## Create tarball with artifacts & reports
	@mkdir -p $(DIST_DIR)
	@VER=$$(git describe --tags --always --dirty 2>/dev/null || echo "0.0.0"); \
	SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo "dev"); \
	NAME=$(PKG_NAME)-$$VER+$$SHA; \
	TARBALL=$(DIST_DIR)/$$NAME.tar.gz; \
	echo "Packaging $$TARBALL"; \
	FILES="$(DIST_DIR)"; \
	[ -d "$(DOCS_OUT)" ] && FILES="$$FILES $(DOCS_OUT)"; \
	[ -d "$(COV_OUT)" ] && FILES="$$FILES $(COV_OUT)"; \
	[ -d "$(TEST_OUT)" ] && FILES="$$FILES $(TEST_OUT)"; \
	[ -d "$(REPORTS)" ] && FILES="$$FILES $(REPORTS)"; \
	echo "Built on: $$(date -u)" > MANIFEST.txt; \
	echo "Commit:  $$(git rev-parse HEAD 2>/dev/null || echo dev)" >> MANIFEST.txt; \
	echo "Python:  $$($(PYTHON) --version 2>&1)" >> MANIFEST.txt; \
	FILES="$$FILES MANIFEST.txt"; \
	tar -czf $$TARBALL --transform "s,^,$$NAME/," $$FILES; \
	rm -f MANIFEST.txt; \
	if command -v sha256sum >/dev/null 2>&1; then sha256sum $$TARBALL > $$TARBALL.sha256; fi; \
	echo "Saved artifacts in $(DIST_DIR)/"

# ---------------------------
# Clean
# ---------------------------
clean: ## Remove build/test artifacts (keep dist/)
	@rm -rf .pytest_cache .mypy_cache .coverage \
	        $(TEST_OUT) $(COV_OUT) $(DOCS_OUT) $(REPORTS)

distclean: clean ## Remove dist/ too
	@rm -rf $(DIST_DIR) build/ src/*.egg-info
