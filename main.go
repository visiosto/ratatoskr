// SPDX-FileCopyrightText: © 2026 Visiosto oy <visiosto@visiosto.fi>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

package main

import (
	"fmt"
	"log"
	"os"

	"visiosto.dev/ratatoskr/internal/version"
)

func main() {
	// ctx := context.Background()

	if len(os.Args) > 1 {
		if os.Args[1] == "version" {
			_, err := fmt.Fprintf(os.Stdout, "%s\n", version.Version.ComparableString())
			if err != nil {
				log.Fatal(err)
			}

			return
		}
	}
}
