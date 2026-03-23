// SPDX-FileCopyrightText: © 2026 Visiosto oy <visiosto@visiosto.fi>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

// Package version provides build and version information of the current binary.
package version

import "github.com/anttikivi/semver"

// Version is the parsed version object of the current build. It is created in
// [init].
var Version *semver.Version //nolint:gochecknoglobals // version must be global

// Build information populated at build time.
//
//nolint:gochecknoglobals // build information must be global
var (
	BuildVersion = "0.1.0-dev"
	Revision     string
)

func init() { //nolint:gochecknoinits // version must be populated when the module is first used
	Version = semver.MustParse(BuildVersion)
}
