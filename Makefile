### Config ############################################################################
# This section contains various special targets and variables that affect the behavior
# of make.

# Delete targets that fail (to prevent subsequent attempts to make incorrectly
# assuming the target is up to date). Especially useful with the envoy pattern.
.DELETE_ON_ERROR: ;

SHELL=/bin/bash


### Definitions #######################################################################
# This section contains reusable functionality such as
# * Macros (or _recursively expanded variables_)
# * Constants (or _simply expanded variables_)

define PRINT_HELP
import re, sys

targets: dict[str, str] = {
    match.group("target"): match.group("summary")
    for match in re.finditer(
        r"^(?P<target>[a-zA-Z_-]+):.*?## (?P<summary>.*)$$",
        sys.stdin.read(),
        re.MULTILINE,
    )
}
max_len = max(map(len, targets))
for target, summary in targets.items():
    if summary == "...":
        summary = target.capitalize().replace("_", " ")
    print(f"{target:>{max_len}}: {summary}")
endef
export PRINT_HELP

CLEAN_DIR_TARGET = git clean -xdf $(@D); mkdir -p $(@D)


### Verbs #############################################################################
# This section contains targets that
# * May have side effect
# * Should not have side effects should not affect nouns

help: ## Print this help message
	@python -c "$$PRINT_HELP" < $(MAKEFILE_LIST)

check_all: check_format check_lint check_tests ## Run all checks that have not yet passed
	rm $^

check_format: ## ...
	isort --check tests/
	black --check tests/
	touch $@

check_lint: ## ...
	pylint tests/
	flake8 tests/
	touch $@

# TODO: Consider moving into tox for cases where non-universal wheels are built for more than one target
check_dist: dist/_envoy; ## Check that distribution can be built and will render correctly on PyPi
	touch $@

# No coverage here to avoid race conditions?
check_tests: ## Check that unit tests pass
	pytest --durations=10 tests/
	touch $@

fix_format: ## ...
	isort tests/
	black tests/

### Nouns #############################################################################
# This section contains targets that
# * Should have no side effects
# * Must have no side effects on other nouns
# * Must not have any prerequisites that are verbs
# * Ordered first by specificity, second by name

constraints.txt: $(wildcard requirements/*.txt)
	pip-compile --allow-unsafe --strip-extras --output-file $@ $^ > /dev/null
