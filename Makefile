# SPDX-FileCopyrightText: © 2026 Visiosto oy <visiosto@visiosto.fi>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

.POSIX:
.SUFFIXES:

VERSION =
RATATOSKR_VERSION = 0.1.0

GOFLAGS =

GCI_VERSION = 0.14.0
GO_LICENSES_VERSION = 2.0.1
GOFUMPT_VERSION = 0.9.2
GOLANGCI_LINT_VERSION = 2.11.4
GOLINES_VERSION = 0.15.0

ALLOWED_LICENSES = AGPL-3.0,Apache-2.0,BSD-2-Clause,BSD-3-Clause,GPL-3.0,LGPL-3.0,MIT,MPL-2.0

GO_MODULE = visiosto.dev/ratatoskr

all: build

# CODE QUALITY & CHECKS

audit: FORCE license-check test lint
	go mod tidy -diff
	go mod verify

license-check: FORCE bin/go-licenses
	go mod verify
	go mod download
	./bin/go-licenses check --include_tests $(GO_MODULE)/... --allowed_licenses="$(ALLOWED_LICENSES)"
	command -v uvx >/dev/null 2>&1 && uvx reuse lint

lint: FORCE bin/golangci-lint
	./bin/golangci-lint config verify
	./bin/golangci-lint run

test: FORCE
	go test $(GOFLAGS) ./...

# DEVELOPMENT & BUILDING

tidy: FORCE bin/gci bin/gofumpt bin/golines
	command -v uvx >/dev/null 2>&1 && uvx reuse annotate -c "Visiosto oy <visiosto@visiosto.fi>" -l AGPL-3.0-or-later --copyright-prefix spdx-symbol *.go internal/**/*.go .golangci.yml .github/**/*
	go mod tidy -v
	./bin/gci write .
	./bin/golines -m 120 -t 4 --no-chain-split-dots --no-reformat-tags -w .
	./bin/gofumpt -extra -l -w .

build: FORCE
	@version="$(VERSION)"; \
	revision=""; \
	\
	if [ -n "$${version}" ]; then \
		untrimmed="$$(git describe --always --abbrev=40 --dirty 2>/dev/null)"; \
		revision="$$(echo "$${untrimmed}" | tr -d ' \n\r')"; \
		revision="$${revision%-dirty}"; \
	else \
		if git describe --match 'v*.*.*' --exclude '*-*' --tags >/dev/null 2>&1; then \
			untrimmed="$$(git describe --match 'v*.*.*' --exclude '*-*' --tags 2>/dev/null)"; \
			git_describe="$$(echo "$${untrimmed}" | tr -d ' \n\r')"; \
			hyphens="$$(printf '%s' "$${git_describe}" | tr -dc '-' | wc -c)"; \
			\
			if [ "$${hyphens}" -eq 0 ]; then \
				if [ "$${git_describe}" != "v$(RATATOSKR_VERSION)" ]; then \
					echo "git tag does not match the version number" >&2; \
					exit 1; \
				fi; \
				\
				untrimmed_revision="$$(git rev-parse "v$(RATATOSKR_VERSION)^{commit}" 2>/dev/null)"; \
				revision="$$(echo "$${untrimmed_revision}" | tr -d ' \n\r')"; \
				version="$(RATATOSKR_VERSION)"; \
			else \
				if [ "$${hyphens}" -eq 2 ]; then \
					old_ifs="$$IFS"; \
					IFS="-"; \
					\
					set -- $${git_describe}; \
					\
					tagged_ancestor="$$1"; \
					commit_height="$$2"; \
					commit_id="$$3"; \
					IFS="$${old_ifs}"; \
					\
					if [ "$(RATATOSKR_VERSION)" = "$${tagged_ancestor}" ]; then \
						echo "version number in the Makefile \"$(RATATOSKR_VERSION)\" must be greater than tagged version \"$${tagged_ancestor}\"" >&2; \
						exit 1; \
					fi; \
					\
					if [ -z "$${commit_id}" ]; then \
						echo "unexpected \`git describe\` output: $${git_describe}" >&2; \
						exit 1; \
					fi; \
					\
					case "$${commit_id}" in \
						g*) \
							revision="$$(printf '%s' "$${commit_id#g}" | tr -d ' \n\r')"; \
							;; \
						*) \
							echo "unexpected \`git describe\` output: $${git_describe}" >&2; \
							exit 1; \
							;; \
					esac; \
					\
					version="$(RATATOSKR_VERSION)-dev.$${commit_height}+$${revision}"; \
				else \
					echo "unexpected \`git describe\` output: $${git_describe}" >&2; \
					exit 1; \
				fi; \
			fi; \
		else \
			untrimmed="$$(git describe --always --abbrev=40 --dirty 2>/dev/null)"; \
			revision="$$(echo "$${untrimmed}" | tr -d ' \n\r')"; \
			\
			case "$${revision}" in \
				*-dirty) \
					revision="$${revision%-dirty}"; \
					build_time="$$(date -u +%Y%m%d%H%M%S)"; \
					;; \
				*) \
					revision="$${revision%-dirty}"; \
					build_time="$$(TZ=UTC0 git show -s --date=format-local:%Y%m%d%H%M%S --format=%cd "$${revision}" 2>/dev/null)"; \
					;; \
			esac; \
			version="$(RATATOSKR_VERSION)-dev.$${build_time}+$${revision}"; \
		fi; \
	fi; \
	\
	if [ -z "$${version}" ]; then \
		echo "failed to create a version string"; \
		exit 1; \
	fi; \
	\
	if [ -z "$${revision}" ]; then \
		echo "failed to create parse the built revision"; \
		exit 1; \
	fi; \
	\
	ldflags="-X $(GO_MODULE)/internal/version.BuildVersion=$${version} -X $(GO_MODULE)/internal/version.Revision=$${revision}"; \
	\
	go build $(GOFLAGS) -ldflags "$${ldflags}" -o ratatoskr$$(go env GOEXE) .

clean: FORCE
	rm -f bifrost$$(go env GOEXE)
	rm -rf bin

# TOOL INSTALLS

bin/gci: bin/vendor/gci-$(GCI_VERSION)
	ln -sf vendor/gci-$(GCI_VERSION) $@
bin/vendor/gci-$(GCI_VERSION):
	mkdir -p bin/vendor
	GOBIN="$(PWD)/bin/vendor" go install github.com/daixiang0/gci@v$(GCI_VERSION)
	mv bin/vendor/gci $@

bin/go-licenses: bin/vendor/go-licenses-$(GO_LICENSES_VERSION)
	ln -sf vendor/go-licenses-$(GO_LICENSES_VERSION) $@
bin/vendor/go-licenses-$(GO_LICENSES_VERSION):
	mkdir -p bin/vendor
	GOBIN="$(PWD)/bin/vendor" go install github.com/google/go-licenses/v2@v$(GO_LICENSES_VERSION)
	mv bin/vendor/go-licenses $@

bin/gofumpt: bin/vendor/gofumpt-$(GOFUMPT_VERSION)
	ln -sf vendor/gofumpt-$(GOFUMPT_VERSION) $@
bin/vendor/gofumpt-$(GOFUMPT_VERSION):
	mkdir -p bin/vendor
	GOBIN="$(PWD)/bin/vendor" go install mvdan.cc/gofumpt@v$(GOFUMPT_VERSION)
	mv bin/vendor/gofumpt $@

bin/golangci-lint: bin/vendor/golangci-lint-$(GOLANGCI_LINT_VERSION)
	ln -sf vendor/golangci-lint-$(GOLANGCI_LINT_VERSION) $@
bin/vendor/golangci-lint-$(GOLANGCI_LINT_VERSION):
	mkdir -p bin/vendor
	GOBIN="$(PWD)/bin/vendor" go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v$(GOLANGCI_LINT_VERSION)
	mv bin/vendor/golangci-lint $@

bin/golines: bin/vendor/golines-$(GOLINES_VERSION)
	ln -sf vendor/golines-$(GOLINES_VERSION) $@
bin/vendor/golines-$(GOLINES_VERSION):
	mkdir -p bin/vendor
	GOBIN="$(PWD)/bin/vendor" go install github.com/golangci/golines@v$(GOLINES_VERSION)
	mv bin/vendor/golines $@

# SPECIAL TARGET

FORCE: ;
